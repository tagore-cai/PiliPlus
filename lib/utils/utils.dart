import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class Utils {
  static final Random random = Random();

  static const channel = MethodChannel("PiliPlus");

  static bool? _isIpad;

  static bool? _isTv;

    /// 检测是否为TV设备
  static Future<bool> isAndroidTv() async {
    if (_isTv != null) return _isTv!;

    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final info = await deviceInfo.androidInfo;
      _isTv = info.systemFeatures.contains("android.software.leanback");
      return  _isTv ?? false;
    }
    
    return _isTv = false;
  }

  static Future<bool> isIpad() async {
    if (_isIpad != null) {
      return _isIpad!;
    }
    if (!Platform.isIOS) {
      return false;
    }
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    IosDeviceInfo info = await deviceInfo.iosInfo;
    _isIpad = info.model.toLowerCase().contains("ipad");
    return _isIpad!;
  }

  static Future<void> shareText(String text) async {
    try {
      Rect? sharePositionOrigin;
      if (await isIpad()) {
        sharePositionOrigin = Rect.fromLTWH(0, 0, Get.width, Get.height / 2);
      }
      Share.share(
        text,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  static String buildShadersAbsolutePath(
      String baseDirectory, List<String> shaders) {
    List<String> absolutePaths = shaders.map((shader) {
      return path.join(baseDirectory, shader);
    }).toList();
    return absolutePaths.join(':');
  }

  static final numericRegex = RegExp(r'^[\d\.]+$');
  static bool isStringNumeric(String str) {
    return numericRegex.hasMatch(str);
  }

  static String generateRandomString(int length) {
    const characters = '0123456789abcdefghijklmnopqrstuvwxyz';

    return String.fromCharCodes(Iterable.generate(length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }

  static void copyText(
    String text, {
    bool needToast = true,
    String? toastText,
  }) {
    Clipboard.setData(ClipboardData(text: text));
    if (needToast) {
      SmartDialog.showToast(toastText ?? '已复制');
    }
  }

  static String makeHeroTag(v) {
    return v.toString() + random.nextInt(9999).toString();
  }

  static int findClosestNumber(int target, List<int> numbers) {
    List<int> filterNums = numbers.where((number) => number <= target).toList();
    return filterNums.isNotEmpty
        ? filterNums.reduce((a, b) => a > b ? a : b)
        : numbers.reduce((a, b) => a > b ? b : a);
  }

  static List<int> generateRandomBytes(int minLength, int maxLength) {
    return List<int>.generate(
      minLength + random.nextInt(maxLength - minLength + 1),
      (_) => 0x26 + random.nextInt(0x59), // dm_img_str不能有`%`
    );
  }

  static String base64EncodeRandomString(int minLength, int maxLength) {
    final randomBytes = generateRandomBytes(minLength, maxLength);
    final randomBase64 = base64.encode(randomBytes);
    return randomBase64.substring(0, randomBase64.length - 2);
  }

  static String getFileName(String uri, {bool fileExt = true}) {
    final i0 = uri.lastIndexOf('/') + 1;
    final i1 = fileExt ? uri.length : uri.lastIndexOf('.');
    return uri.substring(i0, i1);
  }
}
