import {Client, ClientChannel, ConnectConfig} from 'ssh2';
import {EventEmitter} from 'events';
import {TerminalSize, SshProfile} from '../../types/ssh';
import {Terminal} from 'xterm-headless';

export type TerminalEvent =
  | {type: 'connected'}
  | {type: 'data'; payload: string}
  | {type: 'closed'; error?: Error}
  | {type: 'resized'; size: TerminalSize};

export interface SshDependencies {
  logger?: (message: string, meta?: Record<string, unknown>) => void;
}

export class SshService extends EventEmitter {
  private client = new Client();
  private channel?: ClientChannel;
  private terminal = new Terminal({cols: 80, rows: 24});

  constructor(private readonly deps: SshDependencies = {}) {
    super();
    this.terminal.onData(data => this.emit('terminal', {type: 'data', payload: data}));
  }

  async connect(profile: SshProfile, size: TerminalSize): Promise<void> {
    const config: ConnectConfig = {
      host: profile.host,
      port: profile.port,
      username: profile.auth.username,
      readyTimeout: 10000,
      tryKeyboard: false,
    };

    if (profile.auth.type === 'password') {
      config.password = profile.auth.password;
    } else {
      config.privateKey = profile.auth.privateKey;
      config.passphrase = profile.auth.passphrase;
    }

    return new Promise((resolve, reject) => {
      this.client
        .on('ready', () => {
          this.deps.logger?.('ssh:ready');
          this.startShell(size, profile).then(resolve).catch(reject);
        })
        .on('error', error => {
          this.deps.logger?.('ssh:error', {error});
          reject(error);
        })
        .on('end', () => this.emit('terminal', {type: 'closed'}))
        .connect(config);
    });
  }

  private async startShell(size: TerminalSize, profile: SshProfile) {
    this.client.shell({cols: size.cols, rows: size.rows}, (err, stream) => {
      if (err) {
        this.emit('terminal', {type: 'closed', error: err});
        return;
      }
      this.channel = stream;
      this.emit('terminal', {type: 'connected'});

      stream
        .on('data', data => {
          const chunk = data.toString('utf8');
          this.terminal.write(chunk);
        })
        .on('close', () => this.emit('terminal', {type: 'closed'}))
        .stderr.on('data', data => this.deps.logger?.('ssh:stderr', {data: data.toString()}));

      if (profile.tmuxAttach) {
        stream.write(`${profile.tmuxAttach}\n`);
      }
    });
  }

  send(input: string) {
    this.channel?.write(input);
  }

  resize(size: TerminalSize) {
    this.channel?.setWindow(size.rows, size.cols, size.rows * 16, size.cols * 8);
    this.emit('terminal', {type: 'resized', size});
  }

  runCommand(command: string) {
    this.send(`${command}\n`);
  }

  dispose() {
    this.channel?.close();
    this.client.end();
    this.removeAllListeners();
  }
}
