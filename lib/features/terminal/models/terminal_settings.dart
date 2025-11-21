class TerminalSettings {
  final String themeId;
  final double fontSize;
  final String fontFamily;
  final CursorStyle cursorStyle;
  final bool cursorBlink;
  final int terminalPadding;
  final double lineHeight;

  const TerminalSettings({
    this.themeId = 'dracula',
    this.fontSize = 14.0,
    this.fontFamily = 'Courier',
    this.cursorStyle = CursorStyle.block,
    this.cursorBlink = true,
    this.terminalPadding = 8,
    this.lineHeight = 1.2,
  });

  TerminalSettings copyWith({
    String? themeId,
    double? fontSize,
    String? fontFamily,
    CursorStyle? cursorStyle,
    bool? cursorBlink,
    int? terminalPadding,
    double? lineHeight,
  }) {
    return TerminalSettings(
      themeId: themeId ?? this.themeId,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      cursorStyle: cursorStyle ?? this.cursorStyle,
      cursorBlink: cursorBlink ?? this.cursorBlink,
      terminalPadding: terminalPadding ?? this.terminalPadding,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeId': themeId,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'cursorStyle': cursorStyle.name,
        'cursorBlink': cursorBlink,
        'terminalPadding': terminalPadding,
        'lineHeight': lineHeight,
      };

  factory TerminalSettings.fromJson(Map<String, dynamic> json) {
    return TerminalSettings(
      themeId: json['themeId'] as String? ?? 'dracula',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontFamily: json['fontFamily'] as String? ?? 'Courier',
      cursorStyle: CursorStyle.values.firstWhere(
        (e) => e.name == json['cursorStyle'],
        orElse: () => CursorStyle.block,
      ),
      cursorBlink: json['cursorBlink'] as bool? ?? true,
      terminalPadding: json['terminalPadding'] as int? ?? 8,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
    );
  }

  static const defaults = TerminalSettings();
}

enum CursorStyle {
  block,
  underline,
  bar,
}

class QuickCommand {
  final String id;
  final String label;
  final String command;
  final int order;

  const QuickCommand({
    required this.id,
    required this.label,
    required this.command,
    this.order = 0,
  });

  QuickCommand copyWith({
    String? id,
    String? label,
    String? command,
    int? order,
  }) {
    return QuickCommand(
      id: id ?? this.id,
      label: label ?? this.label,
      command: command ?? this.command,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'command': command,
        'order': order,
      };

  factory QuickCommand.fromJson(Map<String, dynamic> json) {
    return QuickCommand(
      id: json['id'] as String,
      label: json['label'] as String,
      command: json['command'] as String,
      order: json['order'] as int? ?? 0,
    );
  }
}

class CommandSnippet {
  final String id;
  final String name;
  final String template;
  final List<String> variables;
  final String? description;

  const CommandSnippet({
    required this.id,
    required this.name,
    required this.template,
    this.variables = const [],
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'template': template,
        'variables': variables,
        'description': description,
      };

  factory CommandSnippet.fromJson(Map<String, dynamic> json) {
    return CommandSnippet(
      id: json['id'] as String,
      name: json['name'] as String,
      template: json['template'] as String,
      variables: (json['variables'] as List?)?.cast<String>() ?? [],
      description: json['description'] as String?,
    );
  }

  String fillVariables(Map<String, String> values) {
    var result = template;
    for (final variable in variables) {
      final value = values[variable] ?? '';
      result = result.replaceAll('\${$variable}', value);
    }
    return result;
  }
}

// Default quick commands
class DefaultQuickCommands {
  static const List<QuickCommand> defaults = [
    QuickCommand(id: '1', label: 'ls -la', command: 'ls -la', order: 0),
    QuickCommand(id: '2', label: 'cd ..', command: 'cd ..', order: 1),
    QuickCommand(id: '3', label: 'docker ps', command: 'docker ps', order: 2),
    QuickCommand(id: '4', label: 'git status', command: 'git status', order: 3),
    QuickCommand(id: '5', label: 'top', command: 'top', order: 4),
    QuickCommand(id: '6', label: 'clear', command: 'clear', order: 5),
  ];
}

// Default command snippets
class DefaultSnippets {
  static const List<CommandSnippet> defaults = [
    CommandSnippet(
      id: '1',
      name: 'SSH to server',
      template: 'ssh \${user}@\${host}',
      variables: ['user', 'host'],
      description: 'Connect to a server via SSH',
    ),
    CommandSnippet(
      id: '2',
      name: 'Docker exec',
      template: 'docker exec -it \${container} \${shell}',
      variables: ['container', 'shell'],
      description: 'Execute command in running container',
    ),
    CommandSnippet(
      id: '3',
      name: 'Git clone',
      template: 'git clone \${repo_url}',
      variables: ['repo_url'],
      description: 'Clone a git repository',
    ),
    CommandSnippet(
      id: '4',
      name: 'Find files',
      template: 'find \${path} -name "\${pattern}"',
      variables: ['path', 'pattern'],
      description: 'Find files by name pattern',
    ),
    CommandSnippet(
      id: '5',
      name: 'SCP file',
      template: 'scp \${source} \${user}@\${host}:\${destination}',
      variables: ['source', 'user', 'host', 'destination'],
      description: 'Copy file to remote server',
    ),
  ];
}
