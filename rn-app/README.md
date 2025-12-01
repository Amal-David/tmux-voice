# Tmux Voice React Native rewrite

This directory contains a React Native (0.73) implementation scaffold mirroring the original Flutter experience. It keeps the core feature areas—profiles, SSH sessions, terminal rendering, and configuration—in place while stubbing room for voice and monitoring features.

## Structure
- `src/navigation` – React Navigation stack for connections, terminal, settings, and profile CRUD.
- `src/state` – Zustand store with AsyncStorage persistence for SSH profiles and active sessions.
- `src/services/ssh` – SSH transport bridge built on `ssh2` plus a headless `xterm` buffer to render terminal output.
- `src/terminal` – Lightweight renderer that feeds the headless terminal buffer into React Native components.
- `src/services/config` – Environment-driven configuration via `react-native-config`.

## Running
Install dependencies with `npm install` or `yarn`, then use the standard React Native CLI commands:

```bash
npm run start
npm run android
npm run ios
```

The SSH transport expects valid credentials; tmux auto-attach uses the `tmuxAttach` profile field by default.
