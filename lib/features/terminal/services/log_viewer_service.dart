import '../../ssh/services/ssh_repository.dart';

class LogViewerService {
  LogViewerService(this._sshRepository);

  final SshRepository _sshRepository;

  Future<String> fetchLogs({
    required String sessionId,
    required String command,
  }) async {
    final output = await _sshRepository.runCommand(sessionId, command);
    return output.trim().isEmpty ? 'No output' : output;
  }

  Future<List<String>> dockerContainers(String sessionId) async {
    final output = await _sshRepository.runCommand(
      sessionId,
      r"docker ps --format '{{.Names}}'",
    );
    return output
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}
