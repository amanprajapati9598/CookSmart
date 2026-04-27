import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AvatarUtils {
  static ImageProvider getAvatarProvider(String type, String customPath) {
    if (type == 'custom' && customPath.isNotEmpty) {
      if (kIsWeb || customPath.startsWith('http') || customPath.startsWith('blob')) {
        return NetworkImage(customPath);
      } else {
        return FileImage(File(customPath));
      }
    } else if (type == 'male' || type == 'female') {
      return AssetImage('assets/avatars/$type.png');
    }
    // Default fallback asset
    return const AssetImage('assets/avatars/male.png');
  }

  static Widget buildAvatar({
    required String type, 
    required String customPath, 
    double radius = 20,
    Color? borderColor,
    double borderWidth = 0,
  }) {
    ImageProvider? provider;
    bool showIcon = false;

    if (type == 'none') {
      showIcon = true;
    } else {
      provider = getAvatarProvider(type, customPath);
    }

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: provider,
      child: showIcon ? Icon(Icons.person, size: radius * 1.2, color: Colors.grey.shade600) : null,
    );

    if (borderWidth > 0 && borderColor != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: avatar,
      );
    }

    return avatar;
  }
}
