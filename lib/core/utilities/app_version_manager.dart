// Class to manage app versions
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n.dart';
import '../core.dart';

class AppVersionManager {
  // Store URLs
  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.tkweenstore.tkween_app';
  static const String _iosStoreUrl =
      'https://apps.apple.com/us/app/tkween-%D8%AA%D9%83%D9%88%D9%8A%D9%86/id6743707369';

  // Get appropriate store URL based on platform
  static String get storeUrl =>
      Platform.isIOS ? _iosStoreUrl : _androidStoreUrl;

  // Check if update is needed
  static Future<bool> isUpdateNeeded() async {
    try {
      final upgrader = Upgrader();
      await Upgrader.clearSavedSettings(); // Clear cached settings
      await upgrader.initialize();

      final playStoreVersion = upgrader.currentAppStoreVersion;
      // final playStoreVersion = "1.0.3";
      final currentVersion = upgrader.currentInstalledVersion;
      // final currentVersion = "1.0.3";
      log('App version: $currentVersion | Store version: $playStoreVersion');

      if (currentVersion == null) return false;

      return _isVersionHigher(
        playStoreVersion.toString(),
        currentVersion.toString(),
      );
    } catch (e) {
      log('Error checking for updates: $e');
      return false;
    }
  }

  // Compare version strings
  static bool _isVersionHigher(String storeVersion, String currentVersion) {
    final storeParts = storeVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    // Ensure both lists have equal length
    while (storeParts.length < currentParts.length) {
      storeParts.add(0);
    }
    while (currentParts.length < storeParts.length) {
      currentParts.add(0);
    }

    // Compare version segments
    for (int i = 0; i < storeParts.length; i++) {
      if (storeParts[i] > currentParts[i]) {
        return true; // Store version is higher
      } else if (storeParts[i] < currentParts[i]) {
        return false; // Current version is higher or equal
      }
    }
    log('Versions are equal: $storeVersion == $currentVersion');

    return false; // Versions are equal
  }

  // Launch app store
  static Future<bool> launchStore(BuildContext context) async {
    final Uri url = Uri.parse(storeUrl);

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        context.showErrorSnackBar(S.of(context).storeOpenError);
        return false;
      }
    } catch (e) {
      log('Error launching store: $e');
      context.showErrorSnackBar(S.of(context).storeOpenException);
      return false;
    }
  }
}

class UpdateOverlay extends StatelessWidget {
  final VoidCallback onUpdatePressed;

  const UpdateOverlay({super.key, required this.onUpdatePressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54, // Semi-transparent overlay
      child: Center(child: UpdatePopup(onUpdatePressed: onUpdatePressed)),
    );
  }
}

class UpdatePopup extends StatelessWidget {
  final VoidCallback onUpdatePressed;

  const UpdatePopup({super.key, required this.onUpdatePressed});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.system_security_update_rounded,
              size: 50,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).updateAvailableTitle,

              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context).updateAvailableDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            AppButton(onPressed: onUpdatePressed, text: S.of(context).updateNow),
          ],
        ),
      ),
    );
  }
}
