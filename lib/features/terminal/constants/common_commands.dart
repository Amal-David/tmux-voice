/// Top 100 common Linux/Unix commands and their variations
const List<String> commonCommands = [
  // Docker commands
  'docker ps',
  'docker ps -a',
  'docker logs',
  'docker logs -f',
  'docker exec -it',
  'docker run',
  'docker stop',
  'docker start',
  'docker restart',
  'docker rm',
  'docker rmi',
  'docker images',
  'docker pull',
  'docker push',
  'docker build',
  'docker compose up',
  'docker compose down',
  'docker compose ps',
  'docker compose logs',
  'docker network ls',
  'docker volume ls',
  
  // Git commands
  'git status',
  'git add .',
  'git commit -m',
  'git push',
  'git pull',
  'git branch',
  'git checkout',
  'git merge',
  'git log',
  'git diff',
  'git clone',
  'git fetch',
  'git rebase',
  'git stash',
  'git tag',
  
  // File operations
  'ls',
  'ls -la',
  'ls -lh',
  'cd',
  'pwd',
  'mkdir',
  'rmdir',
  'rm -rf',
  'cp',
  'mv',
  'touch',
  'cat',
  'less',
  'more',
  'head',
  'tail',
  'tail -f',
  'grep',
  'find',
  'locate',
  
  // System commands
  'sudo',
  'apt update',
  'apt upgrade',
  'apt install',
  'yum update',
  'yum install',
  'systemctl status',
  'systemctl start',
  'systemctl stop',
  'systemctl restart',
  'service',
  'ps aux',
  'top',
  'htop',
  'kill',
  'killall',
  'df -h',
  'du -sh',
  'free -m',
  'uname -a',
  
  // Network commands
  'ping',
  'curl',
  'wget',
  'ssh',
  'scp',
  'netstat',
  'ifconfig',
  'ip addr',
  'nslookup',
  'dig',
  
  // Process management
  'npm install',
  'npm start',
  'npm run build',
  'npm run dev',
  'yarn install',
  'yarn start',
  'pip install',
  'python',
  'node',
  
  // Text editing
  'nano',
  'vi',
  'vim',
  'echo',
  'sed',
  'awk',
  
  // Compression
  'tar -xzf',
  'tar -czf',
  'unzip',
  'zip',
  
  // Permissions
  'chmod',
  'chown',
  'chgrp',
];

/// Get command suggestions based on input
List<String> getCommandSuggestions(String input) {
  if (input.isEmpty) return [];
  
  final lowerInput = input.toLowerCase();
  final suggestions = commonCommands
      .where((cmd) => cmd.toLowerCase().startsWith(lowerInput))
      .toList();
  
  // Also include partial matches
  final partialMatches = commonCommands
      .where((cmd) => 
          cmd.toLowerCase().contains(lowerInput) && 
          !cmd.toLowerCase().startsWith(lowerInput))
      .toList();
  
  return [...suggestions, ...partialMatches].take(5).toList();
}
