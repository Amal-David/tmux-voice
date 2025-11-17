class SshProfile {
  const SshProfile({
    required this.label,
    required this.host,
    required this.port,
    required this.username,
    this.password,
    this.privateKey,
    this.tmuxSession,
    this.autoAttachTmux = true,
  });

  final String label;
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKey;
  final String? tmuxSession;
  final bool autoAttachTmux;

  SshProfile copyWith({
    String? label,
    String? host,
    int? port,
    String? username,
    String? password,
    String? privateKey,
    String? tmuxSession,
    bool? autoAttachTmux,
  }) {
    return SshProfile(
      label: label ?? this.label,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      tmuxSession: tmuxSession ?? this.tmuxSession,
      autoAttachTmux: autoAttachTmux ?? this.autoAttachTmux,
    );
  }

  factory SshProfile.fromJson(Map<String, dynamic> json) {
    return SshProfile(
      label: json['label'] as String,
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      username: json['username'] as String,
      password: json['password'] as String?,
      privateKey: json['privateKey'] as String?,
      tmuxSession: json['tmuxSession'] as String?,
      autoAttachTmux: json['autoAttachTmux'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'privateKey': privateKey,
      'tmuxSession': tmuxSession,
      'autoAttachTmux': autoAttachTmux,
    };
  }

  @override
  int get hashCode => Object.hash(label, host, port, username, password, privateKey, tmuxSession, autoAttachTmux);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SshProfile) return false;
    return label == other.label &&
        host == other.host &&
        port == other.port &&
        username == other.username &&
        password == other.password &&
        privateKey == other.privateKey &&
        tmuxSession == other.tmuxSession &&
        autoAttachTmux == other.autoAttachTmux;
  }
}
