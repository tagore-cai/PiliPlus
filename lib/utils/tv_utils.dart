import 'dart:io';
import 'package:flutter/services.dart';

class TvUtils {
  static const MethodChannel _channel = MethodChannel('PiliPlus');
  static bool? _isTv;
  
  /// 检测是否为TV设备
  static Future<bool> get isTv async {
    if (_isTv != null) return _isTv!;
    
    if (Platform.isAndroid) {
      try {
        _isTv = await _channel.invokeMethod('isTvDevice');
        return _isTv ?? false;
      } catch (e) {
        // 如果方法调用失败，使用屏幕尺寸判断
        return _isTv = _isLargeScreen();
      }
    }
    
    return _isTv = false;
  }
  
  /// 通过屏幕尺寸判断是否为大屏设备
  static bool _isLargeScreen() {
    // 这里可以根据屏幕尺寸判断，通常TV屏幕较大
    // 可以在main.dart中获取屏幕信息后调用
    return false;
  }
  
  /// 重置缓存（用于测试）
  static void reset() {
    _isTv = null;
  }
  
  /// 同步获取TV状态（需要先调用过异步方法）
  static bool get isTvSync => _isTv ?? false;
}