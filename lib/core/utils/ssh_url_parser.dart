// SSH URL Parser for tmux-voice
// Supports formats:
// - ssh://user@host:port
// - user@host:port
// - user@host
// - host

class SshUrlParser {
  static ParsedSshUrl? parse(String url) {
    if (url.trim().isEmpty) return null;

    String cleanUrl = url.trim();
    String? username;
    String? host;
    int port = 22;

    // Remove ssh:// prefix if present
    if (cleanUrl.startsWith('ssh://')) {
      cleanUrl = cleanUrl.substring(6);
    }

    // Check for username@host format
    if (cleanUrl.contains('@')) {
      final parts = cleanUrl.split('@');
      if (parts.length == 2) {
        username = parts[0].trim();
        cleanUrl = parts[1].trim();
      }
    }

    // Check for host:port format
    if (cleanUrl.contains(':')) {
      final parts = cleanUrl.split(':');
      if (parts.length == 2) {
        host = parts[0].trim();
        final portStr = parts[1].trim();
        port = int.tryParse(portStr) ?? 22;
      }
    } else {
      host = cleanUrl;
    }

    if (host == null || host.isEmpty) {
      return null;
    }

    return ParsedSshUrl(
      username: username,
      host: host,
      port: port,
    );
  }
}

class ParsedSshUrl {
  const ParsedSshUrl({
    this.username,
    required this.host,
    required this.port,
  });

  final String? username;
  final String host;
  final int port;
}
