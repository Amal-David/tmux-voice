import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

class AppTerminalTheme {
  final String id;
  final String name;
  final Color background;
  final Color foreground;
  final Color cursor;
  final Color selection;
  final List<Color> ansiColors;

  const AppTerminalTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.foreground,
    required this.cursor,
    required this.selection,
    required this.ansiColors,
  });

  TerminalTheme toXTermTheme() {
    return TerminalTheme(
      cursor: cursor,
      selection: selection,
      foreground: foreground,
      background: background,
      black: ansiColors[0],
      red: ansiColors[1],
      green: ansiColors[2],
      yellow: ansiColors[3],
      blue: ansiColors[4],
      magenta: ansiColors[5],
      cyan: ansiColors[6],
      white: ansiColors[7],
      brightBlack: ansiColors[8],
      brightRed: ansiColors[9],
      brightGreen: ansiColors[10],
      brightYellow: ansiColors[11],
      brightBlue: ansiColors[12],
      brightMagenta: ansiColors[13],
      brightCyan: ansiColors[14],
      brightWhite: ansiColors[15],
      searchHitBackground: selection,
      searchHitBackgroundCurrent: cursor,
      searchHitForeground: foreground,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'background': background.value,
        'foreground': foreground.value,
        'cursor': cursor.value,
        'selection': selection.value,
        'ansiColors': ansiColors.map((c) => c.value).toList(),
      };

  factory AppTerminalTheme.fromJson(Map<String, dynamic> json) {
    return AppTerminalTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      background: Color(json['background'] as int),
      foreground: Color(json['foreground'] as int),
      cursor: Color(json['cursor'] as int),
      selection: Color(json['selection'] as int),
      ansiColors: (json['ansiColors'] as List)
          .map((value) => Color(value as int))
          .toList(),
    );
  }
}

class AppTerminalThemes {
  // Dracula Theme
  static const dracula = AppTerminalTheme(
    id: 'dracula',
    name: 'Dracula',
    background: Color(0xFF282a36),
    foreground: Color(0xFFf8f8f2),
    cursor: Color(0xFFf8f8f2),
    selection: Color(0xFF44475a),
    ansiColors: [
      Color(0xFF21222c), // black
      Color(0xFFff5555), // red
      Color(0xFF50fa7b), // green
      Color(0xFFf1fa8c), // yellow
      Color(0xFFbd93f9), // blue
      Color(0xFFff79c6), // magenta
      Color(0xFF8be9fd), // cyan
      Color(0xFFf8f8f2), // white
      Color(0xFF6272a4), // bright black
      Color(0xFFff6e6e), // bright red
      Color(0xFF69ff94), // bright green
      Color(0xFFffffa5), // bright yellow
      Color(0xFFd6acff), // bright blue
      Color(0xFFff92df), // bright magenta
      Color(0xFFa4ffff), // bright cyan
      Color(0xFFffffff), // bright white
    ],
  );

  // One Dark Theme
  static const oneDark = AppTerminalTheme(
    id: 'one-dark',
    name: 'One Dark',
    background: Color(0xFF282c34),
    foreground: Color(0xFFabb2bf),
    cursor: Color(0xFF528bff),
    selection: Color(0xFF3e4451),
    ansiColors: [
      Color(0xFF282c34), // black
      Color(0xFFe06c75), // red
      Color(0xFF98c379), // green
      Color(0xFFe5c07b), // yellow
      Color(0xFF61afef), // blue
      Color(0xFFC678dd), // magenta
      Color(0xFF56b6c2), // cyan
      Color(0xFFabb2bf), // white
      Color(0xFF5c6370), // bright black
      Color(0xFFe06c75), // bright red
      Color(0xFF98c379), // bright green
      Color(0xFFe5c07b), // bright yellow
      Color(0xFF61afef), // bright blue
      Color(0xFFC678dd), // bright magenta
      Color(0xFF56b6c2), // bright cyan
      Color(0xFFffffff), // bright white
    ],
  );

  // Monokai Theme
  static const monokai = AppTerminalTheme(
    id: 'monokai',
    name: 'Monokai',
    background: Color(0xFF272822),
    foreground: Color(0xFFf8f8f2),
    cursor: Color(0xFFf8f8f0),
    selection: Color(0xFF49483e),
    ansiColors: [
      Color(0xFF272822), // black
      Color(0xFFf92672), // red
      Color(0xFFa6e22e), // green
      Color(0xFFf4bf75), // yellow
      Color(0xFF66d9ef), // blue
      Color(0xFFae81ff), // magenta
      Color(0xFFa1efe4), // cyan
      Color(0xFFf8f8f2), // white
      Color(0xFF75715e), // bright black
      Color(0xFFf92672), // bright red
      Color(0xFFa6e22e), // bright green
      Color(0xFFf4bf75), // bright yellow
      Color(0xFF66d9ef), // bright blue
      Color(0xFFae81ff), // bright magenta
      Color(0xFFa1efe4), // bright cyan
      Color(0xFFf9f8f5), // bright white
    ],
  );

  // Solarized Dark Theme
  static const solarizedDark = AppTerminalTheme(
    id: 'solarized-dark',
    name: 'Solarized Dark',
    background: Color(0xFF002b36),
    foreground: Color(0xFF839496),
    cursor: Color(0xFF839496),
    selection: Color(0xFF073642),
    ansiColors: [
      Color(0xFF073642), // black
      Color(0xFFdc322f), // red
      Color(0xFF859900), // green
      Color(0xFFb58900), // yellow
      Color(0xFF268bd2), // blue
      Color(0xFFd33682), // magenta
      Color(0xFF2aa198), // cyan
      Color(0xFFeee8d5), // white
      Color(0xFF002b36), // bright black
      Color(0xFFcb4b16), // bright red
      Color(0xFF586e75), // bright green
      Color(0xFF657b83), // bright yellow
      Color(0xFF839496), // bright blue
      Color(0xFF6c71c4), // bright magenta
      Color(0xFF93a1a1), // bright cyan
      Color(0xFFfdf6e3), // bright white
    ],
  );

  // Nord Theme
  static const nord = AppTerminalTheme(
    id: 'nord',
    name: 'Nord',
    background: Color(0xFF2e3440),
    foreground: Color(0xFFd8dee9),
    cursor: Color(0xFFd8dee9),
    selection: Color(0xFF4c566a),
    ansiColors: [
      Color(0xFF3b4252), // black
      Color(0xFFbf616a), // red
      Color(0xFFa3be8c), // green
      Color(0xFFebcb8b), // yellow
      Color(0xFF81a1c1), // blue
      Color(0xFFb48ead), // magenta
      Color(0xFF88c0d0), // cyan
      Color(0xFFe5e9f0), // white
      Color(0xFF4c566a), // bright black
      Color(0xFFbf616a), // bright red
      Color(0xFFa3be8c), // bright green
      Color(0xFFebcb8b), // bright yellow
      Color(0xFF81a1c1), // bright blue
      Color(0xFFb48ead), // bright magenta
      Color(0xFF8fbcbb), // bright cyan
      Color(0xFFeceff4), // bright white
    ],
  );

  // Gruvbox Dark Theme
  static const gruvboxDark = AppTerminalTheme(
    id: 'gruvbox-dark',
    name: 'Gruvbox Dark',
    background: Color(0xFF282828),
    foreground: Color(0xFFebdbb2),
    cursor: Color(0xFFebdbb2),
    selection: Color(0xFF504945),
    ansiColors: [
      Color(0xFF282828), // black
      Color(0xFFcc241d), // red
      Color(0xFF98971a), // green
      Color(0xFFd79921), // yellow
      Color(0xFF458588), // blue
      Color(0xFFb16286), // magenta
      Color(0xFF689d6a), // cyan
      Color(0xFFa89984), // white
      Color(0xFF928374), // bright black
      Color(0xFFfb4934), // bright red
      Color(0xFFb8bb26), // bright green
      Color(0xFFfabd2f), // bright yellow
      Color(0xFF83a598), // bright blue
      Color(0xFFd3869b), // bright magenta
      Color(0xFF8ec07c), // bright cyan
      Color(0xFFebdbb2), // bright white
    ],
  );

  // Tokyo Night Theme
  static const tokyoNight = AppTerminalTheme(
    id: 'tokyo-night',
    name: 'Tokyo Night',
    background: Color(0xFF1a1b26),
    foreground: Color(0xFFc0caf5),
    cursor: Color(0xFFc0caf5),
    selection: Color(0xFF283457),
    ansiColors: [
      Color(0xFF15161e), // black
      Color(0xFFf7768e), // red
      Color(0xFF9ece6a), // green
      Color(0xFFe0af68), // yellow
      Color(0xFF7aa2f7), // blue
      Color(0xFFbb9af7), // magenta
      Color(0xFF7dcfff), // cyan
      Color(0xFFa9b1d6), // white
      Color(0xFF414868), // bright black
      Color(0xFFf7768e), // bright red
      Color(0xFF9ece6a), // bright green
      Color(0xFFe0af68), // bright yellow
      Color(0xFF7aa2f7), // bright blue
      Color(0xFFbb9af7), // bright magenta
      Color(0xFF7dcfff), // bright cyan
      Color(0xFFc0caf5), // bright white
    ],
  );

  // Catppuccin Mocha Theme
  static const catppuccin = AppTerminalTheme(
    id: 'catppuccin',
    name: 'Catppuccin Mocha',
    background: Color(0xFF1e1e2e),
    foreground: Color(0xFFcdd6f4),
    cursor: Color(0xFFf5e0dc),
    selection: Color(0xFF585b70),
    ansiColors: [
      Color(0xFF45475a), // black
      Color(0xFFf38ba8), // red
      Color(0xFFa6e3a1), // green
      Color(0xFFf9e2af), // yellow
      Color(0xFF89b4fa), // blue
      Color(0xFFf5c2e7), // magenta
      Color(0xFF94e2d5), // cyan
      Color(0xFFbac2de), // white
      Color(0xFF585b70), // bright black
      Color(0xFFf38ba8), // bright red
      Color(0xFFa6e3a1), // bright green
      Color(0xFFf9e2af), // bright yellow
      Color(0xFF89b4fa), // bright blue
      Color(0xFFf5c2e7), // bright magenta
      Color(0xFF94e2d5), // bright cyan
      Color(0xFFa6adc8), // bright white
    ],
  );

  static const List<AppTerminalTheme> all = [
    dracula,
    oneDark,
    monokai,
    solarizedDark,
    nord,
    gruvboxDark,
    tokyoNight,
    catppuccin,
  ];

  static AppTerminalTheme? getById(String id) {
    try {
      return all.firstWhere((theme) => theme.id == id);
    } catch (_) {
      return null;
    }
  }
}
