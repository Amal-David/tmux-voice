export type AuthMethod =
  | {type: 'password'; username: string; password: string}
  | {type: 'key'; username: string; privateKey: string; passphrase?: string};

export interface SshProfile {
  id: string;
  host: string;
  port: number;
  auth: AuthMethod;
  tmuxAttach?: string;
  description?: string;
}

export interface TerminalSize {
  cols: number;
  rows: number;
}

export interface SshSession {
  id: string;
  profile: SshProfile;
  connectedAt: number;
}
