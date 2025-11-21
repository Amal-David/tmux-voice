import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../core/app_theme.dart';
import '../../../core/widgets/believe_button.dart';
import '../../../core/widgets/believe_text_field.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/utils/ssh_key_generator.dart';
import '../services/ssh_key_storage.dart';

class SshKeysPage extends StatefulWidget {
  const SshKeysPage({super.key});

  @override
  State<SshKeysPage> createState() => _SshKeysPageState();
}

class _SshKeysPageState extends State<SshKeysPage> {
  List<SshKeyInfo> _keys = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() => _isLoading = true);
    final keys = await SshKeyStorage.listKeys();
    setState(() {
      _keys = keys;
      _isLoading = false;
    });
  }

  Future<void> _generateNewKey() async {
    final labelController = TextEditingController(text: 'mobile-key-${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
    int selectedBitLength = 2048;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Generate SSH Key',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new RSA key pair for SSH authentication',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              BelieveTextField(
                controller: labelController,
                label: 'Key Label',
                hint: 'my-phone-key',
                prefixIcon: const Icon(CupertinoIcons.tag),
              ),
              const SizedBox(height: 20),

              const Text(
                'Key Strength',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _KeyStrengthOption(
                      label: '2048-bit',
                      subtitle: 'Standard',
                      isSelected: selectedBitLength == 2048,
                      onTap: () => setModalState(() => selectedBitLength = 2048),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KeyStrengthOption(
                      label: '4096-bit',
                      subtitle: 'Extra secure',
                      isSelected: selectedBitLength == 4096,
                      onTap: () => setModalState(() => selectedBitLength = 4096),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              BelieveButton(
                onPressed: () => Navigator.of(context).pop(true),
                isFullWidth: true,
                child: const Text('Generate Key Pair'),
              ),
              const SizedBox(height: 12),
              BelieveTextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Center(child: Text('Cancel')),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != true) return;

    setState(() => _isGenerating = true);

    try {
      // Generate key pair (works on both Android & iOS!)
      final keyPair = await SshKeyGenerator.generateRsaKeyPair(
        bitLength: selectedBitLength,
        label: labelController.text.trim(),
      );

      // Store securely
      await SshKeyStorage.storeKey(keyPair);

      // Reload keys
      await _loadKeys();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Key "${keyPair.label}" generated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        // Show the new key details
        _showKeyDetails(keyPair);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating key: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _showKeyDetails(SshKeyPair keyPair) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(CupertinoIcons.checkmark_seal, color: AppTheme.successGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Key Generated!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          keyPair.label,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Public Key Section
                    const Text(
                      'Public Key',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add this to your server\'s ~/.ssh/authorized_keys file',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceFilled,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        keyPair.publicKey,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    BelieveButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: keyPair.publicKey));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Public key copied to clipboard!'),
                            backgroundColor: AppTheme.successGreen,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      isFullWidth: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                          SizedBox(width: 8),
                          Text('Copy Public Key'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(CupertinoIcons.info_circle, color: AppTheme.accentTeal, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'How to add to your server',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. SSH into your server with password\n'
                            '2. Run: mkdir -p ~/.ssh\n'
                            '3. Run: nano ~/.ssh/authorized_keys\n'
                            '4. Paste the public key (new line)\n'
                            '5. Save and exit (Ctrl+X, Y, Enter)\n'
                            '6. Run: chmod 600 ~/.ssh/authorized_keys',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fingerprint
                    Row(
                      children: [
                        const Icon(CupertinoIcons.shield_lefthalf_fill, size: 16, color: AppTheme.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            keyPair.fingerprint,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              BelieveSecondaryButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Center(child: Text('Done')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteKey(SshKeyInfo keyInfo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete SSH Key?'),
        content: Text('Are you sure you want to delete "${keyInfo.label}"?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await SshKeyStorage.deleteKey(keyInfo.id);
    await _loadKeys();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Key deleted'),
          backgroundColor: AppTheme.textSecondary,
        ),
      );
    }
  }

  Future<void> _viewKeyDetails(SshKeyInfo keyInfo) async {
    final keyPair = await SshKeyStorage.getKey(keyInfo.id);
    if (keyPair != null) {
      _showKeyDetails(keyPair);
    }
  }

  Future<void> _showHelpInstructions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(CupertinoIcons.book, color: AppTheme.accentTeal, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'How to Use SSH Keys',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildInstructionSection(
                      '1. Generate Key Pair',
                      'Create a new SSH key on your device',
                      [
                        'Tap "Generate New Key" button below',
                        'Choose a memorable label (e.g., "my-phone")',
                        'Select key strength (2048-bit is standard, 4096-bit is more secure)',
                        'Tap "Generate Key Pair" and wait 1-2 seconds',
                      ],
                      CupertinoIcons.wand_stars,
                      AppTheme.primaryPurple,
                    ),

                    _buildInstructionSection(
                      '2. Copy Public Key',
                      'Get your public key from the generated pair',
                      [
                        'After generation, tap "Copy Public Key" button',
                        'Or tap any key in the list to view details',
                        'The public key starts with "ssh-rsa ..."',
                        'You\'ll paste this on your server',
                      ],
                      CupertinoIcons.doc_on_clipboard,
                      AppTheme.accentGold,
                    ),

                    _buildInstructionSection(
                      '3. Add to Server',
                      'Different methods for different server types',
                      [],
                      CupertinoIcons.cube_box,
                      AppTheme.accentTeal,
                    ),

                    // Linux/macOS Server
                    _buildServerGuide(
                      'Linux / macOS Server',
                      [
                        'SSH into your server with password:',
                        '  ssh username@server.com',
                        '',
                        'Create SSH directory (if not exists):',
                        '  mkdir -p ~/.ssh',
                        '  chmod 700 ~/.ssh',
                        '',
                        'Add your public key:',
                        '  nano ~/.ssh/authorized_keys',
                        '  (paste your public key on a new line)',
                        '  (save: Ctrl+X, Y, Enter)',
                        '',
                        'Set correct permissions:',
                        '  chmod 600 ~/.ssh/authorized_keys',
                        '',
                        'Test connection:',
                        '  exit',
                        '  ssh username@server.com',
                        '  (should connect without password!)',
                      ],
                    ),

                    // Ubuntu/Debian
                    _buildServerGuide(
                      'Ubuntu / Debian',
                      [
                        'Quick one-liner (if you have password access):',
                        '  echo "YOUR_PUBLIC_KEY" >> ~/.ssh/authorized_keys',
                        '',
                        'Or use ssh-copy-id (from another computer):',
                        '  ssh-copy-id -i public_key.pub username@server',
                        '',
                        'Verify:',
                        '  cat ~/.ssh/authorized_keys',
                      ],
                    ),

                    // AWS EC2
                    _buildServerGuide(
                      'AWS EC2',
                      [
                        '1. Connect to EC2 with existing key',
                        '',
                        '2. Add your mobile key:',
                        '   echo "YOUR_PUBLIC_KEY" >> ~/.ssh/authorized_keys',
                        '',
                        '3. Ensure security group allows SSH (port 22)',
                        '',
                        '4. Connect from app using your private key',
                        '',
                        'Note: EC2 user is usually "ubuntu" or "ec2-user"',
                      ],
                    ),

                    // DigitalOcean
                    _buildServerGuide(
                      'DigitalOcean Droplet',
                      [
                        'Option 1 - Via Console:',
                        '1. Log into DigitalOcean console',
                        '2. Access → Droplet Console',
                        '3. Run: echo "YOUR_KEY" >> ~/.ssh/authorized_keys',
                        '',
                        'Option 2 - Via existing SSH:',
                        '1. SSH with password',
                        '2. nano ~/.ssh/authorized_keys',
                        '3. Paste key, save',
                        '',
                        'Option 3 - Add to account (for new droplets):',
                        'Settings → Security → SSH Keys → Add',
                      ],
                    ),

                    // Raspberry Pi
                    _buildServerGuide(
                      'Raspberry Pi',
                      [
                        '1. Enable SSH on Pi:',
                        '   sudo raspi-config',
                        '   → Interface Options → SSH → Enable',
                        '',
                        '2. Find Pi IP address:',
                        '   hostname -I',
                        '',
                        '3. From computer or Pi terminal:',
                        '   mkdir -p ~/.ssh',
                        '   nano ~/.ssh/authorized_keys',
                        '   (paste your public key)',
                        '',
                        '4. Set permissions:',
                        '   chmod 700 ~/.ssh',
                        '   chmod 600 ~/.ssh/authorized_keys',
                        '',
                        'Default user: pi',
                      ],
                    ),

                    _buildInstructionSection(
                      '4. Connect from App',
                      'Use your private key to authenticate',
                      [
                        'Go to Connections → Add new profile',
                        'Fill in server details (host, port, username)',
                        'Scroll to "Private Key" section',
                        'Tap "Choose PEM/PPK File"',
                        'Select your generated key from the list',
                        'Tap "Save Profile" → "Connect Now"',
                        'No password needed! 🎉',
                      ],
                      CupertinoIcons.checkmark_seal_fill,
                      AppTheme.successGreen,
                    ),

                    const SizedBox(height: 16),
                    _buildTroubleshootingSection(),
                    
                    const SizedBox(height: 16),
                    _buildSecurityTips(),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              BelieveSecondaryButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Center(child: Text('Got It!')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionSection(
    String title,
    String subtitle,
    List<String> steps,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildServerGuide(String serverType, List<String> commands) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFilled,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textTertiary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                serverType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              commands.join('\n'),
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningYellow.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningYellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.exclamationmark_triangle, color: AppTheme.warningYellow, size: 20),
              SizedBox(width: 12),
              Text(
                'Troubleshooting',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTroubleshootItem(
            'Connection refused',
            'SSH server may not be running:\n  sudo systemctl start sshd',
          ),
          _buildTroubleshootItem(
            'Permission denied',
            'Check authorized_keys permissions:\n  chmod 600 ~/.ssh/authorized_keys\n  chmod 700 ~/.ssh',
          ),
          _buildTroubleshootItem(
            'Still asking for password',
            '1. Ensure key is in authorized_keys\n2. Check file ownership:\n   chown \$USER:\$USER ~/.ssh/authorized_keys\n3. Verify SSH config allows key auth:\n   sudo nano /etc/ssh/sshd_config\n   PubkeyAuthentication yes',
          ),
          _buildTroubleshootItem(
            'Wrong key format',
            'This app generates OpenSSH format.\nIf server needs different format, use:\n  ssh-keygen -p -m PEM -f key_file',
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String issue, String solution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $issue',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            solution,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.lock_shield_fill, color: AppTheme.successGreen, size: 20),
              SizedBox(width: 12),
              Text(
                'Security Best Practices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '✓ Use 4096-bit keys for sensitive servers\n'
            '✓ Label keys with device names\n'
            '✓ Delete keys from servers if device is lost\n'
            '✓ Never share private keys\n'
            '✓ Keys are stored in encrypted device keychain\n'
            '✓ Public keys are safe to share',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Keys'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceFilled,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.question_circle, color: AppTheme.accentTeal, size: 20),
            ),
            onPressed: _showHelpInstructions,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _isGenerating
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CupertinoActivityIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Generating key pair...',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _keys.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _keys.length,
                              itemBuilder: (context, index) => _buildKeyCard(_keys[index]),
                            ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceFilled,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.lock_shield, size: 48, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 24),
            const Text(
              'No SSH Keys',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate a key pair to use SSH authentication without passwords',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyCard(SshKeyInfo keyInfo) {
    final age = DateTime.now().difference(keyInfo.createdAt).inDays;
    final ageText = age == 0 ? 'Today' : '$age ${age == 1 ? 'day' : 'days'} ago';

    return BelieveCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => _viewKeyDetails(keyInfo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.lock_shield_fill, color: AppTheme.primaryPurple, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keyInfo.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RSA ${keyInfo.bitLength}-bit • $ageText',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.trash, color: AppTheme.errorRed, size: 20),
                onPressed: () => _deleteKey(keyInfo),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceFilled,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.shield_lefthalf_fill, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    keyInfo.fingerprint,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppTheme.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.elevation1,
      ),
      child: SafeArea(
        top: false,
        child: BelieveButton(
          onPressed: _generateNewKey,
          isFullWidth: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(CupertinoIcons.add, size: 20),
              SizedBox(width: 8),
              Text('Generate New Key'),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyStrengthOption extends StatelessWidget {
  const _KeyStrengthOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple.withOpacity(0.1) : AppTheme.surfaceFilled,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
