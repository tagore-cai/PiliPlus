import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/pair.dart';
import 'package:PiliPlus/common/widgets/progress_bar/segment_progress_bar.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models/common/audio_normalization.dart';
import 'package:PiliPlus/models/common/sponsor_block/segment_type.dart';
import 'package:PiliPlus/models/common/sponsor_block/skip_type.dart';
import 'package:PiliPlus/models/user/danmaku_rule.dart';
import 'package:PiliPlus/models/video_shot/data.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/data_source.dart';
import 'package:PiliPlus/plugin/pl_player/models/data_status.dart';
import 'package:PiliPlus/plugin/pl_player/models/fullscreen_mode.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/plugin/pl_player/utils/fullscreen.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/page_utils.dart' show PageUtils;
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:universal_platform/universal_platform.dart';

class PlPlayerController {
  Player? _videoPlayerController;
  VideoController? _videoController;

  // 添加一个私有静态变量来保存实例
  static PlPlayerController? _instance;

  // 流事件  监听播放状态变化
  StreamSubscription? _playerEventSubs;

  /// [playerStatus] has a [status] observable
  final PlPlayerStatus playerStatus = PlPlayerStatus();

  ///
  final PlPlayerDataStatus dataStatus = PlPlayerDataStatus();

  // bool controlsEnabled = false;

  /// 响应数据
  /// 带有Seconds的变量只在秒数更新时更新，以避免频繁触发重绘
  // 播放位置
  final Rx<Duration> _position = Rx(Duration.zero);
  final RxInt positionSeconds = 0.obs;
  final Rx<Duration> _sliderPosition = Rx(Duration.zero);
  final RxInt sliderPositionSeconds = 0.obs;
  // 展示使用
  final Rx<Duration> _sliderTempPosition = Rx(Duration.zero);
  final Rx<Duration> _duration = Rx(Duration.zero);
  final Rx<Duration> durationSeconds = Duration.zero.obs;
  final Rx<Duration> _buffered = Rx(Duration.zero);
  final RxInt bufferedSeconds = 0.obs;

  final RxInt _playerCount = 0.obs;

  late double lastPlaybackSpeed = 1.0;
  final RxDouble _playbackSpeed = 1.0.obs;
  final RxDouble _longPressSpeed = 2.0.obs;
  final RxDouble _currentVolume = 1.0.obs;
  final RxDouble _currentBrightness = (-1.0).obs;

  final RxBool _mute = false.obs;
  final RxBool _showControls = false.obs;
  final RxBool _showVolumeStatus = false.obs;
  final RxBool _showBrightnessStatus = false.obs;
  final RxBool _longPressStatus = false.obs;
  final RxBool _controlsLock = false.obs;
  final RxBool _isFullScreen = false.obs;
  // 默认投稿视频格式
  static RxString _videoType = 'archive'.obs;

  final RxString _direction = 'horizontal'.obs;

  final Rx<BoxFit> _videoFit = Rx(BoxFit.contain);
  late StreamSubscription<DataStatus> _dataListenerForVideoFit;
  late StreamSubscription<DataStatus> _dataListenerForEnterFullscreen;

  /// 后台播放
  late final RxBool _continuePlayInBackground = false.obs;

  late final RxBool _flipX = false.obs;

  late final RxBool _flipY = false.obs;

  ///
  final RxBool _isSliderMoving = false.obs;
  PlaylistMode _looping = PlaylistMode.none;
  bool _autoPlay = false;
  final bool _listenersInitialized = false;

  // 记录历史记录
  String _bvid = '';
  int _cid = 0;
  dynamic _epid;
  dynamic _seasonId;
  dynamic _subType;
  int _heartDuration = 0;
  int? width;
  int? height;

  late DataSource dataSource;

  Timer? _timer;
  Timer? _timerForSeek;
  Timer? _timerForVolume;
  Timer? _timerForShowingVolume;
  Timer? _timerForGettingVolume;
  Timer? timerForTrackingMouse;

  final RxList<Segment> viewPointList = <Segment>[].obs;
  final RxBool showVP = true.obs;
  final RxList<Segment> segmentList = <Segment>[].obs;

  Box get setting => GStorage.setting;

  // final Durations durations;

  String get bvid => _bvid;
  int get cid => _cid;

  /// 数据加载监听
  Stream<DataStatus> get onDataStatusChanged => dataStatus.status.stream;

  /// 播放状态监听
  Stream<PlayerStatus> get onPlayerStatusChanged => playerStatus.status.stream;

  /// 视频时长
  Rx<Duration> get duration => _duration;
  Stream<Duration> get onDurationChanged => _duration.stream;

  /// 视频当前播放位置
  Rx<Duration> get position => _position;
  Stream<Duration> get onPositionChanged => _position.stream;

  /// 视频播放速度
  double get playbackSpeed => _playbackSpeed.value;

  // 长按倍速
  double get longPressSpeed => _longPressSpeed.value;

  /// 视频缓冲
  Rx<Duration> get buffered => _buffered;
  Stream<Duration> get onBufferedChanged => _buffered.stream;

  // 视频静音
  RxBool get mute => _mute;
  Stream<bool> get onMuteChanged => _mute.stream;

  /// [videoPlayerController] instance of Player
  Player? get videoPlayerController => _videoPlayerController;

  /// [videoController] instance of Player
  VideoController? get videoController => _videoController;

  RxBool get isSliderMoving => _isSliderMoving;

  /// 进度条位置及监听
  Rx<Duration> get sliderPosition => _sliderPosition;
  Stream<Duration> get onSliderPositionChanged => _sliderPosition.stream;

  Rx<Duration> get sliderTempPosition => _sliderTempPosition;
  // Stream<Duration> get onSliderPositionChanged => _sliderPosition.stream;

  /// 是否展示控制条及监听
  RxBool get showControls => _showControls;
  Stream<bool> get onShowControlsChanged => _showControls.stream;

  /// 音量控制条展示/隐藏
  RxBool get showVolumeStatus => _showVolumeStatus;
  Stream<bool> get onShowVolumeStatusChanged => _showVolumeStatus.stream;

  /// 亮度控制条展示/隐藏
  RxBool get showBrightnessStatus => _showBrightnessStatus;
  Stream<bool> get onShowBrightnessStatusChanged =>
      _showBrightnessStatus.stream;

  /// 音量控制条
  RxDouble get volume => _currentVolume;
  Stream<double> get onVolumeChanged => _currentVolume.stream;

  /// 亮度控制条
  RxDouble get brightness => _currentBrightness;
  Stream<double> get onBrightnessChanged => _currentBrightness.stream;

  /// 是否循环
  PlaylistMode get looping => _looping;

  /// 是否自动播放
  bool get autoplay => _autoPlay;

  /// 视频比例
  Rx<BoxFit> get videoFit => _videoFit;

  /// 后台播放
  RxBool get continuePlayInBackground => _continuePlayInBackground;

  /// 听视频
  late final RxBool onlyPlayAudio = false.obs;

  /// 镜像
  RxBool get flipX => _flipX;

  RxBool get flipY => _flipY;

  /// 是否长按倍速
  RxBool get longPressStatus => _longPressStatus;

  RxBool isBuffering = true.obs;

  /// 屏幕锁 为true时，关闭控制栏
  RxBool get controlsLock => _controlsLock;

  /// 全屏状态
  RxBool get isFullScreen => _isFullScreen;

  /// 全屏方向
  RxString get direction => _direction;

  RxInt get playerCount => _playerCount;

  ///
  RxString get videoType => _videoType;

  /// 弹幕开关
  RxBool isOpenDanmu = false.obs;

  bool autoPiP =
      GStorage.setting.get(SettingBoxKey.autoPiP, defaultValue: false);

  void enterPip() {
    if (Get.currentRoute.startsWith('/video')) {
      PageUtils.enterPip(width: width, height: height);
    }
  }

  /// 弹幕权重
  int danmakuWeight = 0;
  late RuleFilter filters;
  // 关联弹幕控制器
  DanmakuController? danmakuController;
  bool showDanmaku = true;
  Set<int> dmState = <int>{};
  late final mergeDanmaku = GStorage.mergeDanmaku;
  // 弹幕相关配置
  late Set<int> blockTypes;
  late double showArea;
  late double opacity;
  late double fontSize;
  late double fontSizeFS;
  late double strokeWidth;
  late int fontWeight;
  late bool massiveMode;
  late double danmakuDuration;
  late double danmakuStaticDuration;
  late List<double> speedList;
  late bool enableAutoLongPressSpeed = false;
  late bool enableLongShowControl;
  double subtitleFontScale = 1.0;
  double subtitleFontScaleFS = 1.5;
  late double danmakuLineHeight = GStorage.danmakuLineHeight;
  late int subtitlePaddingH = GStorage.subtitlePaddingH;
  late int subtitlePaddingB = GStorage.subtitlePaddingB;
  late double subtitleBgOpaticy = GStorage.subtitleBgOpaticy;
  late bool showVipDanmaku = GStorage.showVipDanmaku;
  late bool showSpecialDanmaku = GStorage.showSpecialDanmaku;
  late double subtitleStrokeWidth = GStorage.subtitleStrokeWidth;
  late int subtitleFontWeight = GStorage.subtitleFontWeight;

  // sponsor block
  late final bool enableSponsorBlock =
      setting.get(SettingBoxKey.enableSponsorBlock, defaultValue: false);
  late final double blockLimit = GStorage.blockLimit;
  late final List<Pair<SegmentType, SkipType>> blockSettings =
      GStorage.blockSettings;
  late final List<Color> blockColor = GStorage.blockColor;
  late final List<String> segmentTypes =
      SegmentType.values.map((item) => item.name).toList();
  late final List<String> enableList = blockSettings
      .where((item) => item.second != SkipType.disable)
      .map((item) => item.first.name)
      .toList();
  late final blockServer = GStorage.blockServer;

  // settings
  late final showFSActionItem = GStorage.showFSActionItem;
  late final enableShrinkVideoSize = GStorage.enableShrinkVideoSize;
  late final darkVideoPage = GStorage.darkVideoPage;
  late final enableSlideVolumeBrightness = GStorage.enableSlideVolumeBrightness;
  late final enableSlideFS = GStorage.enableSlideFS;
  late final enableDragSubtitle = GStorage.enableDragSubtitle;
  late final fastForBackwardDuration = GStorage.fastForBackwardDuration;

  late final horizontalSeasonPanel = GStorage.horizontalSeasonPanel;
  late final preInitPlayer = GStorage.preInitPlayer;
  late final showRelatedVideo = GStorage.showRelatedVideo;
  late final showVideoReply = GStorage.showVideoReply;
  late final showBangumiReply = GStorage.showBangumiReply;
  late final reverseFromFirst = GStorage.reverseFromFirst;
  late final horizontalPreview = GStorage.horizontalPreview;
  late final showDmChart = GStorage.showDmChart;

  int? cacheVideoQa;
  late int cacheAudioQa;
  bool enableHeart = true;

  bool enableHA =
      GStorage.setting.get(SettingBoxKey.enableHA, defaultValue: true);
  String hwdec = GStorage.hardwareDecoding;

  // 播放顺序相关
  PlayRepeat playRepeat = PlayRepeat.pause;

  TextStyle get subTitleStyle => TextStyle(
        height: 1.5,
        fontSize:
            16 * (isFullScreen.value ? subtitleFontScaleFS : subtitleFontScale),
        letterSpacing: 0.1,
        wordSpacing: 0.1,
        color: Colors.white,
        fontWeight: FontWeight.values[subtitleFontWeight],
        backgroundColor: subtitleBgOpaticy == 0
            ? null
            : Colors.black.withValues(alpha: subtitleBgOpaticy),
      );

  SubtitleViewConfiguration get subtitleViewConfiguration =>
      SubtitleViewConfiguration(
        style: subTitleStyle,
        padding: EdgeInsets.only(
          left: subtitlePaddingH.toDouble(),
          right: subtitlePaddingH.toDouble(),
          bottom: subtitlePaddingB.toDouble(),
        ),
        textScaleFactor: 1,
        strokeWidth: subtitleBgOpaticy == 0 ? subtitleStrokeWidth : null,
      );

  GlobalKey<VideoState> Function()? getPlayerKey;

  void updateSubtitleStyle() {
    getPlayerKey?.call().currentState?.update(
          subtitleViewConfiguration: subtitleViewConfiguration,
        );
  }

  void onUpdatePadding(EdgeInsets padding) {
    subtitlePaddingB = padding.bottom.round().clamp(0, 200);
    putSubtitleSettings();
  }

  void updateSliderPositionSecond() {
    int newSecond = _sliderPosition.value.inSeconds;
    if (sliderPositionSeconds.value != newSecond) {
      sliderPositionSeconds.value = newSecond;
    }
  }

  void updatePositionSecond() {
    int newSecond = _position.value.inSeconds;
    if (positionSeconds.value != newSecond) {
      positionSeconds.value = newSecond;
    }
  }

  void updateDurationSecond() {
    if (durationSeconds.value != _duration.value) {
      durationSeconds.value = _duration.value;
    }
  }

  void updateBufferedSecond() {
    int newSecond = _buffered.value.inSeconds;
    if (bufferedSeconds.value != newSecond) {
      bufferedSeconds.value = newSecond;
    }
  }

  static bool instanceExists() {
    return _instance != null;
  }

  static void setPlayCallBack(Function? playCallBack) {
    _playCallBack = playCallBack;
  }

  bool? backToHome;

  static Function? _playCallBack;

  static void playIfExists({bool repeat = false, bool hideControls = true}) {
    // await _instance?.play(repeat: repeat, hideControls: hideControls);
    _playCallBack?.call();
  }

  // try to get PlayerStatus
  static PlayerStatus? getPlayerStatusIfExists() {
    return _instance?.playerStatus.status.value;
  }

  static Future<void> pauseIfExists(
      {bool notify = true, bool isInterrupt = false}) async {
    if (_instance?.playerStatus.status.value == PlayerStatus.playing) {
      await _instance?.pause(notify: notify, isInterrupt: isInterrupt);
    }
  }

  static Future<void> seekToIfExists(Duration position, {type = 'seek'}) async {
    await _instance?.seekTo(position, type: type);
  }

  static double? getVolumeIfExists() {
    return _instance?.volume.value;
  }

  static Future<void> setVolumeIfExists(double volumeNew,
      {bool videoPlayerVolume = false}) async {
    await _instance?.setVolume(volumeNew, videoPlayerVolume: videoPlayerVolume);
  }

  Box get video => GStorage.video;

  // 添加一个私有构造函数
  PlPlayerController._() {
    _videoType = videoType;
    isOpenDanmu.value =
        setting.get(SettingBoxKey.enableShowDanmaku, defaultValue: true);
    danmakuWeight = setting.get(SettingBoxKey.danmakuWeight, defaultValue: 0);
    filters = GStorage.danmakuFilterRule;
    blockTypes =
        (setting.get(SettingBoxKey.danmakuBlockType, defaultValue: <int>[])
                as Iterable)
            .cast<int>()
            .toSet();
    showArea = setting.get(SettingBoxKey.danmakuShowArea, defaultValue: 0.5);
    // 不透明度
    opacity = setting.get(SettingBoxKey.danmakuOpacity, defaultValue: 1.0);
    // 字体大小
    fontSize = setting.get(SettingBoxKey.danmakuFontScale, defaultValue: 1.0);
    // 全屏字体大小
    fontSizeFS = GStorage.danmakuFontScaleFS;
    subtitleFontScale = GStorage.subtitleFontScale;
    subtitleFontScaleFS = GStorage.subtitleFontScaleFS;
    massiveMode = GStorage.danmakuMassiveMode;
    // 弹幕时间
    danmakuDuration =
        setting.get(SettingBoxKey.danmakuDuration, defaultValue: 7.0);
    danmakuStaticDuration =
        setting.get(SettingBoxKey.danmakuStaticDuration, defaultValue: 4.0);
    // 描边粗细
    strokeWidth = setting.get(SettingBoxKey.strokeWidth, defaultValue: 1.5);
    // 弹幕字体粗细
    fontWeight = setting.get(SettingBoxKey.fontWeight, defaultValue: 5);
    playRepeat = PlayRepeat.values.toList().firstWhere(
          (e) =>
              e.value ==
              video.get(VideoBoxKey.playRepeat,
                  defaultValue: PlayRepeat.pause.value),
        );
    _playbackSpeed.value =
        video.get(VideoBoxKey.playSpeedDefault, defaultValue: 1.0);
    enableAutoLongPressSpeed = setting
        .get(SettingBoxKey.enableAutoLongPressSpeed, defaultValue: false);
    // 后台播放
    _continuePlayInBackground.value = setting
        .get(SettingBoxKey.continuePlayInBackground, defaultValue: false);
    if (!enableAutoLongPressSpeed) {
      _longPressSpeed.value =
          video.get(VideoBoxKey.longPressSpeedDefault, defaultValue: 3.0);
    }
    enableLongShowControl =
        setting.get(SettingBoxKey.enableLongShowControl, defaultValue: false);
    speedList = GStorage.speedList;

    if (!Accounts.get(AccountType.heartbeat).isLogin ||
        GStorage.localCache.get(LocalCacheKey.historyPause) == true) {
      enableHeart = false;
    }

    if (Platform.isAndroid) {
      Utils.channel.setMethodCallHandler((call) async {
        if (call.method == 'onUserLeaveHint') {
          if (autoPiP && playerStatus.status.value == PlayerStatus.playing) {
            enterPip();
          }
        }
      });
    }

    // _playerEventSubs = onPlayerStatusChanged.listen((PlayerStatus status) {
    //   if (status == PlayerStatus.playing) {
    //     WakelockPlus.enable();
    //   } else {
    //     WakelockPlus.disable();
    //   }
    // });
  }

  // 获取实例 传参
  static PlPlayerController getInstance({
    String videoType = 'archive',
  }) {
    // 如果实例尚未创建，则创建一个新实例
    _instance ??= PlPlayerController._();
    _instance!._playerCount.value += 1;
    _videoType.value = videoType;
    return _instance!;
  }

  // 初始化资源
  Future<void> setDataSource(
    DataSource dataSource, {
    List<Segment>? segmentList,
    List<Segment>? viewPointList,
    bool? showVP,
    List<double>? dmTrend,
    bool autoplay = true,
    // 默认不循环
    PlaylistMode looping = PlaylistMode.none,
    // 初始化播放位置
    Duration? seekTo,
    // 初始化播放速度
    double speed = 1.0,
    int? width,
    int? height,
    Duration? duration,
    // 方向
    String? direction,
    // 记录历史记录
    String bvid = '',
    int cid = 0,
    dynamic epid,
    dynamic seasonId,
    dynamic subType,
    VoidCallback? callback,
  }) async {
    try {
      this.width = width;
      this.height = height;
      this.dataSource = dataSource;
      this.segmentList.value = segmentList ?? <Segment>[];
      this.viewPointList.value = viewPointList ?? <Segment>[];
      this.showVP.value = showVP ?? true;
      this.dmTrend.value = dmTrend ?? <double>[];
      _autoPlay = autoplay;
      _looping = looping;
      // 初始化视频倍速
      // _playbackSpeed.value = speed;
      // 初始化数据加载状态
      dataStatus.status.value = DataStatus.loading;
      // 初始化全屏方向
      _direction.value = direction ?? 'horizontal';
      _bvid = bvid;
      _cid = cid;
      _epid = epid;
      _seasonId = seasonId;
      _subType = subType;

      if (showSeekPreview) {
        videoShot = null;
        showPreview.value = false;
        previewDx.value = 0;
      }

      if (_videoPlayerController != null &&
          _videoPlayerController!.state.playing) {
        await pause(notify: false);
      }

      if (_playerCount.value == 0) {
        return;
      }
      // 配置Player 音轨、字幕等等
      _videoPlayerController =
          await _createVideoController(dataSource, _looping, seekTo);
      callback?.call();
      // 获取视频时长 00:00
      _duration.value = duration ?? _videoPlayerController!.state.duration;
      _position.value =
          _buffered.value = _sliderPosition.value = seekTo ?? Duration.zero;
      updateDurationSecond();
      updatePositionSecond();
      updateSliderPositionSecond();
      updateBufferedSecond();
      // 数据加载完成
      dataStatus.status.value = DataStatus.loaded;

      // listen the video player events
      if (!_listenersInitialized) {
        startListeners();
      }
      await _initializePlayer();
    } catch (err, stackTrace) {
      dataStatus.status.value = DataStatus.error;
      debugPrint(stackTrace.toString());
      debugPrint('plPlayer err:  $err');
    }
  }

  Directory? shadersDirectory;
  Future<Directory?> copyShadersToExternalDirectory() async {
    if (shadersDirectory != null) {
      return shadersDirectory;
    }
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final directory = await getApplicationSupportDirectory();
    shadersDirectory = Directory(path.join(directory.path, 'anime_shaders'));

    if (!shadersDirectory!.existsSync()) {
      await shadersDirectory!.create(recursive: true);
    }

    final shaderFiles = manifestMap.keys.where((String key) =>
        key.startsWith('assets/shaders/') && key.endsWith('.glsl'));

    // int copiedFilesCount = 0;

    for (var filePath in shaderFiles) {
      final fileName = filePath.split('/').last;
      final targetFile = File(path.join(shadersDirectory!.path, fileName));
      if (targetFile.existsSync()) {
        continue;
      }

      try {
        final data = await rootBundle.load(filePath);
        final List<int> bytes = data.buffer.asUint8List();
        await targetFile.writeAsBytes(bytes);
        // copiedFilesCount++;
      } catch (e) {
        debugPrint('$e');
      }
    }
    return shadersDirectory;
  }

  bool get _isBangumi =>
      Get.parameters['type'] == '1' || Get.parameters['type'] == '4';
  late int superResolutionType = _isBangumi ? GStorage.superResolutionType : 0;
  Future<void> setShader([int? type, NativePlayer? pp]) async {
    if (type == null) {
      type ??= superResolutionType;
    } else {
      superResolutionType = type;
      if (_isBangumi) {
        GStorage.setting.put(SettingBoxKey.superResolutionType, type);
      }
    }
    pp ??= _videoPlayerController?.platform as NativePlayer;
    await pp.waitForPlayerInitialization;
    await pp.waitForVideoControllerInitializationIfAttached;
    if (type == 1) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(
          (await copyShadersToExternalDirectory())?.path ?? '',
          Constants.mpvAnime4KShadersLite,
        ),
      ]);
    } else if (type == 2) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(
          (await copyShadersToExternalDirectory())?.path ?? '',
          Constants.mpvAnime4KShaders,
        ),
      ]);
    } else {
      await pp.command(['change-list', 'glsl-shaders', 'clr', '']);
    }
  }

  // 配置播放器
  Future<Player> _createVideoController(
    DataSource dataSource,
    PlaylistMode looping,
    Duration? seekTo,
  ) async {
    // 每次配置时先移除监听
    removeListeners();
    isBuffering.value = false;
    buffered.value = Duration.zero;
    _heartDuration = 0;
    _position.value = Duration.zero;
    // 初始化时清空弹幕，防止上次重叠
    if (danmakuController != null) {
      danmakuController!.clear();
    }
    int bufferSize =
        setting.get(SettingBoxKey.expandBuffer, defaultValue: false)
            ? (videoType.value == 'live' ? 64 * 1024 * 1024 : 32 * 1024 * 1024)
            : (videoType.value == 'live' ? 16 * 1024 * 1024 : 4 * 1024 * 1024);
    Player player = _videoPlayerController ??
        Player(
          configuration: PlayerConfiguration(
            // 默认缓冲 4M 大小
            bufferSize: bufferSize,
          ),
        );
    var pp = player.platform as NativePlayer;
    // 解除倍速限制
    if (_isBangumi) {
      setShader(superResolutionType, pp);
    }
    if (_videoPlayerController == null) {
      String audioNormalization = GStorage.audioNormalization;
      audioNormalization = switch (audioNormalization) {
        '0' => '',
        '1' => ',${AudioNormalization.dynaudnorm.param}',
        '2' => ',${AudioNormalization.loudnorm.param}',
        _ => ',$audioNormalization',
      };
      await pp.setProperty(
        "af",
        "scaletempo2=max-speed=8$audioNormalization",
      );
    }
    //  音量不一致
    if (Platform.isAndroid) {
      await pp.setProperty("volume-max", "100");
      String ao = setting.get(SettingBoxKey.useOpenSLES, defaultValue: true)
          ? "opensles,audiotrack"
          : "audiotrack,opensles";
      await pp.setProperty("ao", ao);
    }
    // video-sync=display-resample
    await pp.setProperty("video-sync",
        setting.get(SettingBoxKey.videoSync, defaultValue: 'display-resample'));
    // // vo=gpu-next & gpu-context=android & gpu-api=opengl
    // await pp.setProperty("vo", "gpu-next");
    // await pp.setProperty("gpu-context", "android");
    // await pp.setProperty("gpu-api", "opengl");
    await player.setAudioTrack(
      AudioTrack.auto(),
    );
    // 音轨
    if (dataSource.audioSource?.isNotEmpty == true) {
      await pp.setProperty(
        'audio-files',
        UniversalPlatform.isWindows
            ? dataSource.audioSource!.replaceAll(';', '\\;')
            : dataSource.audioSource!.replaceAll(':', '\\:'),
      );
    } else {
      await pp.setProperty('audio-files', '');
    }

    // 字幕
    if (dataSource.subFiles != '' && dataSource.subFiles != null) {
      await pp.setProperty(
        'sub-files',
        UniversalPlatform.isWindows
            ? dataSource.subFiles!.replaceAll(';', '\\;')
            : dataSource.subFiles!.replaceAll(':', '\\:'),
      );
      await pp.setProperty("subs-with-matching-audio", "no");
      await pp.setProperty("sub-forced-only", "yes");
      await pp.setProperty("blend-subtitles", "video");
    }

    _videoController ??= VideoController(
      player,
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: enableHA,
        androidAttachSurfaceAfterVideoParameters: false,
        hwdec: enableHA ? hwdec : null,
      ),
    );

    player.setPlaylistMode(looping);
    if (dataSource.type == DataSourceType.asset) {
      final assetUrl = dataSource.videoSource!.startsWith("asset://")
          ? dataSource.videoSource!
          : "asset://${dataSource.videoSource!}";
      await player.open(
        Media(assetUrl, httpHeaders: dataSource.httpHeaders, start: seekTo),
        play: false,
      );
    } else {
      await player.open(
        Media(dataSource.videoSource!,
            httpHeaders: dataSource.httpHeaders, start: seekTo),
        play: false,
      );
    }
    // 音轨
    // player.setAudioTrack(
    //   AudioTrack.uri(dataSource.audioSource!),
    // );

    return player;
  }

  Future<bool> refreshPlayer() async {
    if (_videoPlayerController == null) {
      SmartDialog.showToast('视频播放器为空，请重新进入本页面');
      return false;
    }
    if (dataSource.videoSource.isNullOrEmpty) {
      SmartDialog.showToast('视频源为空，请重新进入本页面');
      return false;
    }
    if (dataSource.audioSource.isNullOrEmpty) {
      SmartDialog.showToast('音频源为空');
    } else {
      await (_videoPlayerController!.platform as NativePlayer).setProperty(
        'audio-files',
        UniversalPlatform.isWindows
            ? dataSource.audioSource!.replaceAll(';', '\\;')
            : dataSource.audioSource!.replaceAll(':', '\\:'),
      );
    }
    await _videoPlayerController!.open(
      Media(
        dataSource.videoSource!,
        httpHeaders: dataSource.httpHeaders,
        start: _position.value,
      ),
      play: true,
    );
    return true;
    // seekTo(currentPos);
  }

  // 开始播放
  Future<void> _initializePlayer() async {
    if (_instance == null) return;
    // 设置倍速
    if (videoType.value == 'live') {
      await setPlaybackSpeed(1.0);
    } else {
      if (_videoPlayerController?.state.rate != _playbackSpeed.value) {
        await setPlaybackSpeed(_playbackSpeed.value);
      }
    }
    getVideoFit();
    // if (_looping) {
    //   await setLooping(_looping);
    // }

    // 跳转播放
    // if (seekTo != Duration.zero) {
    //   await this.seekTo(seekTo);
    // }

    // 自动播放
    if (_autoPlay) {
      playIfExists();
      // await play(duration: duration);
    }
  }

  Future<void> autoEnterFullscreen() async {
    bool autoEnterFullscreen = GStorage.setting
        .get(SettingBoxKey.enableAutoEnter, defaultValue: false);
    if (autoEnterFullscreen) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (dataStatus.status.value != DataStatus.loaded) {
          _dataListenerForEnterFullscreen = dataStatus.status.listen((status) {
            if (status == DataStatus.loaded) {
              _dataListenerForEnterFullscreen.cancel();
              triggerFullScreen(status: true);
            }
          });
        } else {
          triggerFullScreen(status: true);
        }
      });
    }
  }

  Set<StreamSubscription> subscriptions = {};
  final Set<Function(Duration position)> _positionListeners = {};
  final Set<Function(PlayerStatus status)> _statusListeners = {};

  /// 播放事件监听
  void startListeners() {
    subscriptions = {
      videoPlayerController!.stream.playing.listen((event) {
        if (event) {
          playerStatus.status.value = PlayerStatus.playing;
        } else {
          playerStatus.status.value = PlayerStatus.paused;
        }
        videoPlayerServiceHandler.onStatusChange(
          playerStatus.status.value,
          isBuffering.value,
          videoType.value == 'live',
        );

        /// 触发回调事件
        for (var element in _statusListeners) {
          element(event ? PlayerStatus.playing : PlayerStatus.paused);
        }
        if (videoPlayerController!.state.position.inSeconds != 0) {
          makeHeartBeat(positionSeconds.value, type: 'status');
        }
      }),
      videoPlayerController!.stream.completed.listen((event) {
        if (event) {
          playerStatus.status.value = PlayerStatus.completed;

          /// 触发回调事件
          for (var element in _statusListeners) {
            element(PlayerStatus.completed);
          }
        } else {
          // playerStatus.status.value = PlayerStatus.playing;
        }
        makeHeartBeat(positionSeconds.value, type: 'completed');
      }),
      videoPlayerController!.stream.position.listen((event) {
        _position.value = event;
        updatePositionSecond();
        if (!isSliderMoving.value) {
          _sliderPosition.value = event;
          updateSliderPositionSecond();
        }

        /// 触发回调事件
        for (var element in _positionListeners) {
          element(event);
        }
        makeHeartBeat(event.inSeconds);
      }),
      videoPlayerController!.stream.duration.listen((Duration event) {
        duration.value = event;
      }),
      videoPlayerController!.stream.buffer.listen((Duration event) {
        _buffered.value = event;
        updateBufferedSecond();
      }),
      videoPlayerController!.stream.buffering.listen((bool event) {
        isBuffering.value = event;
        videoPlayerServiceHandler.onStatusChange(
          playerStatus.status.value,
          event,
          videoType.value == 'live',
        );
      }),
      // videoPlayerController!.stream.log.listen((event) {
      //   debugPrint('videoPlayerController!.stream.log.listen');
      //   debugPrint(event);
      //   SmartDialog.showToast('视频加载日志： $event');
      // }),
      videoPlayerController!.stream.error.listen((String event) {
        // 直播的错误提示没有参考价值，均不予显示
        if (videoType.value == 'live') return;
        if (event.startsWith("Failed to open https://") ||
            event.startsWith("Can not open external file https://") ||
            //tcp: ffurl_read returned 0xdfb9b0bb
            //tcp: ffurl_read returned 0xffffff99
            event.startsWith('tcp: ffurl_read returned ')) {
          EasyThrottle.throttle('videoPlayerController!.stream.error.listen',
              const Duration(milliseconds: 10000), () {
            Future.delayed(const Duration(milliseconds: 3000), () async {
              debugPrint("isBuffering.value: ${isBuffering.value}");
              debugPrint("_buffered.value: ${_buffered.value}");
              if (isBuffering.value && _buffered.value == Duration.zero) {
                SmartDialog.showToast('视频链接打开失败，重试中',
                    displayTime: const Duration(milliseconds: 500));
                if (!await refreshPlayer()) {
                  debugPrint("failed");
                }
              }
            });
          });
        } else if (event.startsWith('Could not open codec')) {
          SmartDialog.showToast('无法加载解码器, $event，可能会切换至软解');
        } else {
          if (!onlyPlayAudio.value) {
            if (event.startsWith("Failed to open .") ||
                event.startsWith("Cannot open") ||
                event.startsWith("Can not open")) {
              List list = [
                if (dataSource.videoSource.isNullOrEmpty) '视频',
                if (dataSource.audioSource.isNullOrEmpty) '音频',
              ];
              if (list.isNotEmpty) {
                SmartDialog.showToast('${list.join('、')}源为空');
                return;
              }
            }
            SmartDialog.showToast('视频加载错误, $event');
            debugPrint('视频加载错误, $event');
          }
        }
      }),
      // videoPlayerController!.stream.volume.listen((event) {
      //   if (!mute.value && _volumeBeforeMute != event) {
      //     _volumeBeforeMute = event / 100;
      //   }
      // }),
      // 媒体通知监听
      onPlayerStatusChanged.listen((PlayerStatus event) {
        videoPlayerServiceHandler.onStatusChange(
          event,
          isBuffering.value,
          videoType.value == 'live',
        );
      }),
      onPositionChanged.listen((Duration event) {
        EasyThrottle.throttle(
            'mediaServicePosition',
            const Duration(seconds: 1),
            () => videoPlayerServiceHandler.onPositionChange(event));
      }),
    };
  }

  /// 移除事件监听
  void removeListeners() {
    for (final s in subscriptions) {
      s.cancel();
    }
  }

  /// 跳转至指定位置
  Future<void> seekTo(Duration position, {type = 'seek'}) async {
    // if (position >= duration.value) {
    //   position = duration.value - const Duration(milliseconds: 100);
    // }
    if (_playerCount.value == 0) {
      return;
    }
    if (position < Duration.zero) {
      position = Duration.zero;
    }
    _position.value = position;
    updatePositionSecond();
    _heartDuration = position.inSeconds;
    if (duration.value.inSeconds != 0) {
      if (type != 'slider') {
        /// 拖动进度条调节时，不等待第一帧，防止抖动
        await _videoPlayerController?.stream.buffer.first;
      }
      danmakuController?.clear();
      try {
        await _videoPlayerController?.seek(position);
      } catch (e) {
        debugPrint('seek failed: $e');
      }
      // if (playerStatus.stopped) {
      //   play();
      // }
    } else {
      debugPrint('seek duration else');
      _timerForSeek?.cancel();
      _timerForSeek =
          Timer.periodic(const Duration(milliseconds: 200), (Timer t) async {
        //_timerForSeek = null;
        if (_playerCount.value == 0) {
          _timerForSeek?.cancel();
          _timerForSeek = null;
        } else if (duration.value.inSeconds != 0) {
          try {
            await _videoPlayerController?.stream.buffer.first;
            danmakuController?.clear();
            await _videoPlayerController?.seek(position);
          } catch (e) {
            debugPrint('seek failed: $e');
          }
          // if (playerStatus.status.value == PlayerStatus.paused) {
          //   play();
          // }
          t.cancel();
          _timerForSeek = null;
        }
      });
    }
  }

  /// 设置倍速
  Future<void> setPlaybackSpeed(double speed) async {
    lastPlaybackSpeed = playbackSpeed;

    if (speed == _videoPlayerController?.state.rate) {
      return;
    }

    await _videoPlayerController?.setRate(speed);
    if (danmakuController != null) {
      DanmakuOption currentOption = danmakuController!.option;
      double defaultDuration = currentOption.duration * lastPlaybackSpeed;
      double defaultStaticDuration =
          currentOption.staticDuration * lastPlaybackSpeed;
      DanmakuOption updatedOption = currentOption.copyWith(
        duration: defaultDuration / speed,
        staticDuration: defaultStaticDuration / speed,
      );
      danmakuController!.updateOption(updatedOption);
    }
    _playbackSpeed.value = speed;
  }

  // 还原默认速度
  Future<void> setDefaultSpeed() async {
    double speed = video.get(VideoBoxKey.playSpeedDefault, defaultValue: 1.0);
    await _videoPlayerController?.setRate(speed);
    _playbackSpeed.value = speed;
  }

  /// 播放视频
  Future<void> play({bool repeat = false, bool hideControls = true}) async {
    if (_playerCount.value == 0) return;
    // 播放时自动隐藏控制条
    controls = !hideControls;
    // repeat为true，将从头播放
    if (repeat) {
      // await seekTo(Duration.zero);
      await seekTo(Duration.zero, type: "slider");
    }

    await _videoPlayerController?.play();

    playerStatus.status.value = PlayerStatus.playing;
    // screenManager.setOverlays(false);

    audioSessionHandler.setActive(true);
  }

  /// 暂停播放
  Future<void> pause({bool notify = true, bool isInterrupt = false}) async {
    await _videoPlayerController?.pause();
    playerStatus.status.value = PlayerStatus.paused;

    // 主动暂停时让出音频焦点
    if (!isInterrupt) {
      audioSessionHandler.setActive(false);
    }
  }

  /// 更改播放状态
  Future<void> togglePlay() async {
    feedBack();
    if (playerStatus.playing) {
      pause();
    } else {
      play();
    }
  }

  bool? isTriple;

  /// 隐藏控制条
  void hideTaskControls() {
    if (_timer != null) {
      _timer!.cancel();
    }
    Duration waitingTime = Duration(seconds: enableLongShowControl ? 30 : 3);
    _timer = Timer(waitingTime, () {
      if (!isSliderMoving.value && isTriple != true) {
        controls = false;
      }
      _timer = null;
    });
  }

  /// 调整播放时间
  void onChangedSlider(double v) {
    _sliderPosition.value = Duration(seconds: v.floor());
    updateSliderPositionSecond();
  }

  void onChangedSliderStart() {
    _isSliderMoving.value = true;
  }

  bool? cancelSeek;
  bool? hasToast;

  void onUpdatedSliderProgress(Duration value) {
    _sliderTempPosition.value = value;
    _sliderPosition.value = value;
    updateSliderPositionSecond();
  }

  void onChangedSliderEnd() {
    if (cancelSeek != true) {
      feedBack();
    }
    cancelSeek = null;
    hasToast = null;
    _isSliderMoving.value = false;
    hideTaskControls();
  }

  /// 音量
  Future<void> getCurrentVolume() async {
    // mac try...catch
    try {
      _currentVolume.value = (await FlutterVolumeController.getVolume())!;
    } catch (_) {}
  }

  Future<void> setVolume(double volumeNew,
      {bool videoPlayerVolume = false}) async {
    if (volumeNew < 0.0) {
      volumeNew = 0.0;
    } else if (volumeNew > 1.0) {
      volumeNew = 1.0;
    }
    if (volume.value == volumeNew) {
      return;
    }
    volume.value = volumeNew;

    try {
      FlutterVolumeController.updateShowSystemUI(false);
      await FlutterVolumeController.setVolume(volumeNew);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  void volumeUpdated() {
    showVolumeStatus.value = true;
    _timerForShowingVolume?.cancel();
    _timerForShowingVolume = Timer(const Duration(seconds: 1), () {
      showVolumeStatus.value = false;
    });
  }

  /// 亮度
  Future<void> getCurrentBrightness() async {
    try {
      _currentBrightness.value = await ScreenBrightness().application;
    } catch (e) {
      throw 'Failed to get current brightness';
      //return 0;
    }
  }

  void setCurrBrightness(double brightness) {
    _currentBrightness.value = brightness;
  }

  Future<void> setBrightness(double brightness) async {
    try {
      this.brightness.value = brightness;
      ScreenBrightness().setApplicationScreenBrightness(brightness);
      // setVideoBrightness();
    } catch (e) {
      throw 'Failed to set brightness';
    }
  }

  /// Toggle Change the videofit accordingly
  void toggleVideoFit(BoxFit value) {
    _videoFit.value = value;
    setVideoFit();
    getPlayerKey?.call().currentState?.update(fit: value);
  }

  /// 缓存fit
  Future<void> setVideoFit() async {
    SmartDialog.showToast(_videoFit.value.toast,
        displayTime: const Duration(seconds: 1));
    video.put(VideoBoxKey.cacheVideoFit, _videoFit.value.index);
  }

  /// 读取fit
  Future<void> getVideoFit() async {
    int fitValue = video.get(VideoBoxKey.cacheVideoFit, defaultValue: 1);
    var attr = BoxFit.values[fitValue];
    // 由于none与scaleDown涉及视频原始尺寸，需要等待视频加载后再设置，否则尺寸会变为0，出现错误;
    if (attr == BoxFit.none || attr == BoxFit.scaleDown) {
      if (buffered.value == Duration.zero) {
        attr = BoxFit.contain;
        _dataListenerForVideoFit = dataStatus.status.listen((status) {
          if (status == DataStatus.loaded) {
            _dataListenerForVideoFit.cancel();
            int fitValue =
                video.get(VideoBoxKey.cacheVideoFit, defaultValue: 1);
            var attr = BoxFit.values[fitValue];
            if (attr == BoxFit.none || attr == BoxFit.scaleDown) {
              _videoFit.value = attr;
            }
          }
        });
      }
      // fill不应该在竖屏视频生效
    } else if (attr == BoxFit.fill && direction.value == 'vertical') {
      attr = BoxFit.contain;
    }
    _videoFit.value = attr;
  }

  /// 设置后台播放
  Future<void> setBackgroundPlay(bool val) async {
    setting.put(SettingBoxKey.enableBackgroundPlay, val);
    videoPlayerServiceHandler.revalidateSetting();
  }

  /// 读取亮度
  // Future<void> getVideoBrightness() async {
  //   double brightnessValue =
  //       video.get(VideoBoxKey.videoBrightness, defaultValue: 0.5);
  //   setBrightness(brightnessValue);
  // }

  set controls(bool visible) {
    _showControls.value = visible;
    _timer?.cancel();
    if (visible) {
      hideTaskControls();
    }
  }

  void hiddenControls(bool val) {
    showControls.value = val;
  }

  /// 设置长按倍速状态 live模式下禁用
  Future<void> setLongPressStatus(bool val) async {
    if (videoType.value == 'live') {
      return;
    }
    if (controlsLock.value) {
      return;
    }
    if (_longPressStatus.value == val) {
      return;
    }
    if (val) {
      if (playerStatus.status.value == PlayerStatus.playing) {
        _longPressStatus.value = val;
        HapticFeedback.lightImpact();
        await setPlaybackSpeed(
            enableAutoLongPressSpeed ? playbackSpeed * 2 : longPressSpeed);
      }
    } else {
      // debugPrint('$playbackSpeed');
      _longPressStatus.value = val;
      await setPlaybackSpeed(lastPlaybackSpeed);
    }
  }

  /// 关闭控制栏
  void onLockControl(bool val) {
    feedBack();
    _controlsLock.value = val;
    showControls.value = !val;
  }

  void toggleFullScreen(bool val) {
    _isFullScreen.value = val;
    updateSubtitleStyle();
  }

  late final FullScreenMode mode = FullScreenModeCode.fromCode(
      setting.get(SettingBoxKey.fullScreenMode, defaultValue: 0));
  late final horizontalScreen = GStorage.horizontalScreen;

  // 全屏
  void triggerFullScreen({bool status = true, int duration = 500}) {
    EasyThrottle.throttle('fullScreen', Duration(milliseconds: duration),
        () async {
      stopScreenTimer();

      if (!isFullScreen.value && status) {
        hideStatusBar();

        /// 按照视频宽高比决定全屏方向
        toggleFullScreen(true);

        /// 进入全屏
        if (mode == FullScreenMode.none) {
          return;
        }
        if (mode == FullScreenMode.gravity) {
          fullAutoModeForceSensor();
          return;
        }
        if (mode == FullScreenMode.vertical ||
            (mode == FullScreenMode.auto && direction.value == 'vertical') ||
            (mode == FullScreenMode.ratio &&
                (Get.height / Get.width < 1.25 ||
                    direction.value == 'vertical'))) {
          await verticalScreenForTwoSeconds();
        } else {
          await landScape();
        }
      } else if (isFullScreen.value && !status) {
        late bool removeSafeArea = setting
            .get(SettingBoxKey.videoPlayerRemoveSafeArea, defaultValue: false);
        if (Get.currentRoute.startsWith('/liveRoom') || !removeSafeArea) {
          showStatusBar();
        }
        toggleFullScreen(false);
        if (mode == FullScreenMode.none) {
          return;
        }
        if (!horizontalScreen) {
          await verticalScreenForTwoSeconds();
        } else {
          await autoScreen();
        }
      }
    });
  }

  void addPositionListener(Function(Duration position) listener) =>
      _positionListeners.add(listener);
  void removePositionListener(Function(Duration position) listener) =>
      _positionListeners.remove(listener);
  void addStatusLister(Function(PlayerStatus status) listener) =>
      _statusListeners.add(listener);
  void removeStatusLister(Function(PlayerStatus status) listener) =>
      _statusListeners.remove(listener);

  /// 截屏
  Future<Uint8List?> screenshot() async {
    final Uint8List? screenshot =
        await _videoPlayerController!.screenshot(format: 'image/png');
    return screenshot;
  }

  Future<void> videoPlayerClosed() async {
    _timer?.cancel();
    _timerForVolume?.cancel();
    _timerForGettingVolume?.cancel();
    timerForTrackingMouse?.cancel();
    _timerForSeek?.cancel();
  }

  // 记录播放记录
  Future<void> makeHeartBeat(
    int progress, {
    type = 'playing',
    bool isManual = false,
    dynamic bvid,
    dynamic cid,
    dynamic epid,
    dynamic seasonId,
    dynamic subType,
  }) async {
    if (!enableHeart || MineController.anonymity.value || progress == 0) {
      return;
    } else if (playerStatus.status.value == PlayerStatus.paused) {
      if (!isManual) {
        return;
      }
    }
    if (videoType.value == 'live') {
      return;
    }
    bool isComplete = playerStatus.status.value == PlayerStatus.completed ||
        type == 'completed';
    if ((durationSeconds.value - position.value).inMilliseconds > 1000) {
      isComplete = false;
    }
    // 播放状态变化时，更新

    if (type == 'status' || type == 'completed') {
      await VideoHttp.heartBeat(
        bvid: bvid ?? _bvid,
        cid: cid ?? _cid,
        progress: isComplete ? -1 : progress,
        epid: epid ?? _epid,
        seasonId: seasonId ?? _seasonId,
        subType: subType ?? _subType,
      );
      return;
    }
    // 正常播放时，间隔5秒更新一次
    else if (progress - _heartDuration >= 5) {
      _heartDuration = progress;
      await VideoHttp.heartBeat(
        bvid: bvid ?? _bvid,
        cid: cid ?? _cid,
        progress: progress,
        epid: epid ?? _epid,
        seasonId: seasonId ?? _seasonId,
        subType: subType ?? _subType,
      );
    }
  }

  void setPlayRepeat(PlayRepeat type) {
    playRepeat = type;
    video.put(VideoBoxKey.playRepeat, type.value);
  }

  void putDanmakuSettings() {
    setting
      ..put(SettingBoxKey.danmakuWeight, danmakuWeight)
      ..put(SettingBoxKey.danmakuBlockType, blockTypes.toList())
      ..put(SettingBoxKey.danmakuShowArea, showArea)
      ..put(SettingBoxKey.danmakuOpacity, opacity)
      ..put(SettingBoxKey.danmakuFontScale, fontSize)
      ..put(SettingBoxKey.danmakuFontScaleFS, fontSizeFS)
      ..put(SettingBoxKey.danmakuDuration, danmakuDuration)
      ..put(SettingBoxKey.danmakuStaticDuration, danmakuStaticDuration)
      ..put(SettingBoxKey.strokeWidth, strokeWidth)
      ..put(SettingBoxKey.fontWeight, fontWeight)
      ..put(SettingBoxKey.danmakuLineHeight, danmakuLineHeight);
  }

  void putSubtitleSettings() {
    setting
      ..put(SettingBoxKey.subtitleFontScale, subtitleFontScale)
      ..put(SettingBoxKey.subtitleFontScaleFS, subtitleFontScaleFS)
      ..put(SettingBoxKey.subtitlePaddingH, subtitlePaddingH)
      ..put(SettingBoxKey.subtitlePaddingB, subtitlePaddingB)
      ..put(SettingBoxKey.subtitleBgOpaticy, subtitleBgOpaticy)
      ..put(SettingBoxKey.subtitleStrokeWidth, subtitleStrokeWidth)
      ..put(SettingBoxKey.subtitleFontWeight, subtitleFontWeight);
  }

  Future<void> dispose({String type = 'single'}) async {
    // 每次减1，最后销毁
    if (type == 'single' && playerCount.value > 1) {
      _playerCount.value -= 1;
      _heartDuration = 0;
      if (!Get.previousRoute.startsWith('/video')) {
        pause();
      }
      return;
    }
    dmState.clear();
    _playerCount.value = 0;
    Utils.channel.setMethodCallHandler(null);
    pause();
    try {
      _timer?.cancel();
      _timerForVolume?.cancel();
      _timerForGettingVolume?.cancel();
      timerForTrackingMouse?.cancel();
      _timerForSeek?.cancel();
      // _position.close();
      _playerEventSubs?.cancel();
      // _sliderPosition.close();
      // _sliderTempPosition.close();
      // _isSliderMoving.close();
      // _duration.close();
      // _buffered.close();
      // _showControls.close();
      // _controlsLock.close();

      // playerStatus.status.close();
      // dataStatus.status.close();

      if (_videoPlayerController != null) {
        var pp = _videoPlayerController!.platform as NativePlayer;
        await pp.setProperty('audio-files', '');
        removeListeners();
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    _instance = null;
    videoPlayerServiceHandler.clear();
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  static void updatePlayCount() {
    if (_instance?._playerCount.value == 1) {
      _instance?.dispose();
    } else {
      _instance?._playerCount.value -= 1;
    }
  }

  void setContinuePlayInBackground() {
    _continuePlayInBackground.value = !_continuePlayInBackground.value;
    setting.put(SettingBoxKey.continuePlayInBackground,
        _continuePlayInBackground.value);
  }

  void setOnlyPlayAudio() {
    onlyPlayAudio.value = !onlyPlayAudio.value;
    videoPlayerController?.setVideoTrack(
        onlyPlayAudio.value ? VideoTrack.no() : VideoTrack.auto());
  }

  late final showSeekPreview = GStorage.showSeekPreview;
  late bool _isQueryingVideoShot = false;
  Map? videoShot;
  late final RxBool showPreview = false.obs;
  late final RxDouble previewDx = 0.0.obs;

  Future<void> getVideoShot() async {
    if (_isQueryingVideoShot) {
      return;
    }
    _isQueryingVideoShot = true;
    try {
      var res = await Request().get(
        '/x/player/videoshot',
        queryParameters: {
          // 'aid': IdUtils.bv2av(_bvid),
          'bvid': _bvid,
          'cid': _cid,
          'index': 1,
        },
      );
      if (res.data['code'] == 0) {
        videoShot = {
          'status': true,
          'data': VideoShotData.fromJson(res.data['data']),
        };
      } else {
        videoShot = {'status': false};
      }
    } catch (e) {
      videoShot = {'status': false};
      debugPrint('getVideoShot: $e');
    }
    _isQueryingVideoShot = false;
  }

  late final RxList<double> dmTrend = <double>[].obs;
  late final RxBool showDmTreandChart = true.obs;

  // 双击检测变量
  DateTime? _lastSelectKeyPressTime;
  static const Duration _doubleTapThreshold = Duration(milliseconds: 300);
  Timer? singleTapTimer;

  // 添加双击检测方法
  bool isDoubleTap() {
    final now = DateTime.now();
    if (_lastSelectKeyPressTime != null &&
        now.difference(_lastSelectKeyPressTime!) <= _doubleTapThreshold) {
      _lastSelectKeyPressTime = null; // 重置
      return true;
    }
    _lastSelectKeyPressTime = now;
    return false;
  }
}

extension BoxFitExt on BoxFit {
  String get desc => const ['拉伸', '自动', '裁剪', '等宽', '等高', '原始', '限制'][index];

  String get toast => const [
        '拉伸至播放器尺寸，将产生变形（竖屏改为自动）',
        '缩放至播放器尺寸，保留黑边',
        '缩放至填满播放器，裁剪超出部分',
        '缩放至撑满播放器宽度',
        '缩放至撑满播放器高度',
        '不缩放，以视频原始尺寸显示',
        '仅超出时缩小至播放器尺寸',
      ][index];
}
