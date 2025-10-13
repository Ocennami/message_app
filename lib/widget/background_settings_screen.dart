import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:message_app/services/background_service.dart';

/// Widget cho Background Settings
/// Mobile: Long press vào màn hình chat để mở
/// Desktop: Vào Settings menu
class BackgroundSettingsScreen extends StatelessWidget {
  const BackgroundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2ECF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2535)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Background Settings',
          style: TextStyle(
            color: Color(0xFF2D2535),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<BackgroundService>(
        builder: (context, service, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Auto Change Background Setting
              _buildSectionTitle('Auto Background'),
              _buildAutoChangeCard(context, service),
              const SizedBox(height: 24),

              // Current Background
              _buildSectionTitle('Current Background'),
              _buildCurrentBackgroundCard(context, service),
              const SizedBox(height: 24),

              // Available Backgrounds
              _buildSectionTitle('Choose Background'),
              _buildBackgroundGrid(context, service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D2535),
        ),
      ),
    );
  }

  Widget _buildAutoChangeCard(BuildContext context, BackgroundService service) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: const Text('Auto Change Background'),
        subtitle: const Text(
          'Automatically change background based on holidays and birthdays',
          style: TextStyle(fontSize: 12, color: Color(0xFF7F7F88)),
        ),
        value: service.autoChangeBackground,
        activeColor: const Color(0xFF2D2535),
        onChanged: (value) async {
          await service.setAutoChangeBackground(value);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? 'Auto background enabled'
                      : 'Auto background disabled',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCurrentBackgroundCard(
    BuildContext context,
    BackgroundService service,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(service.currentBackground),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // Fallback to placeholder
            },
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: const Text(
            'Current Background',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGrid(BuildContext context, BackgroundService service) {
    final backgrounds = service.getAvailableBackgrounds();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: backgrounds.length,
      itemBuilder: (context, index) {
        final background = backgrounds[index];
        final isSelected = service.currentBackground == background.path;

        return _buildBackgroundItem(context, service, background, isSelected);
      },
    );
  }

  Widget _buildBackgroundItem(
    BuildContext context,
    BackgroundService service,
    BackgroundOption background,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        await service.setCustomBackground(background.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Background changed to ${background.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Card(
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: Color(0xFF2D2535), width: 3)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              background.path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: Colors.grey,
                  ),
                );
              },
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),

            // Name and selected indicator
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    background.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (background.isDefault)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),

            // Selected check mark
            if (isSelected)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Color(0xFF2D2535),
                  radius: 16,
                  child: Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialog hiển thị khi long press vào màn hình chat (Mobile)
class BackgroundSettingsDialog extends StatelessWidget {
  const BackgroundSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wallpaper, size: 48, color: Color(0xFF2D2535)),
            const SizedBox(height: 16),
            const Text(
              'Background Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2535),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Would you like to customize your chat background?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF7F7F88)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackgroundSettingsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2535),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
