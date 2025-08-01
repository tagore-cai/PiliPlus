import 'dart:async';

import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/follow.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/dynamics/up.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:PiliPlus/pages/dynamics_tab/controller.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class DynamicsController extends GetxController
    with GetSingleTickerProviderStateMixin, ScrollOrRefreshMixin {
  @override
  final ScrollController scrollController = ScrollController();
  String? offset = '';
  Rx<FollowUpModel> upData = FollowUpModel().obs;
  // 默认获取全部动态
  RxInt mid = (-1).obs;
  late TabController tabController;
  Set<int> tempBannedList = <int>{};
  List<UpItem> hasUpdatedUps = <UpItem>[];
  int allFollowedUpsPage = 1;
  int allFollowedUpsTotal = 0;

  late int currentMid = -1;
  late bool showLiveItems = Pref.expandDynLivePanel;

  final upPanelPosition = Pref.upPanelPosition;

  AccountService accountService = Get.find<AccountService>();

  DynamicsTabController? get controller {
    try {
      return Get.find<DynamicsTabController>(
        tag: DynamicsTabType.values[tabController.index].name,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(
      length: DynamicsTabType.values.length,
      vsync: this,
      initialIndex: Pref.defaultDynamicType,
    );

    queryFollowUp();
  }

  Future<void> queryFollowing2() async {
    if (upData.value.upList != null &&
        upData.value.upList!.length >= allFollowedUpsTotal) {
      return;
    }
    var res = await FollowHttp.followings(
      vmid: accountService.mid,
      pn: allFollowedUpsPage,
      orderType: 'attention',
      ps: 50,
    );
    if (res.isSuccess) {
      upData.value.upList ??= <UpItem>[];
      upData.value.upList!.addAll(
        res.data.list!
            .where((e) => hasUpdatedUps.every((e1) => e.mid != e1.mid))
            .map(
              (FollowItemModel e) => UpItem(
                face: e.face,
                mid: e.mid,
                uname: e.uname,
                hasUpdate: false,
              ),
            ),
      );
      allFollowedUpsPage += 1;
      allFollowedUpsTotal = res.data.total!;
      upData.refresh();
    } else {
      res.toast();
    }
  }

  late bool isQuerying = false;
  Future<void> queryFollowUp() async {
    if (isQuerying) return;
    isQuerying = true;
    if (!accountService.isLogin.value) {
      upData
        ..value.errMsg = '账号未登录'
        ..refresh();
    }
    upData.value.errMsg = null;
    if (Pref.dynamicsShowAllFollowedUp) {
      allFollowedUpsPage = 1;
      final f1 = DynamicsHttp.followUp();
      final f2 = FollowHttp.followings(
        vmid: accountService.mid,
        pn: allFollowedUpsPage,
        orderType: 'attention',
        ps: 50,
      );
      final res0 = await f1;
      if (!res0.isSuccess) {
        SmartDialog.showToast("获取关注动态失败：$res0");
        upData
          ..value.errMsg = (res0 as Error).errMsg
          ..refresh();
      } else {
        upData
          ..value.liveUsers = res0.data.liveUsers
          ..refresh();
        hasUpdatedUps = res0.data.upList!;
      }
      List<UpItem> allFollowedUps = <UpItem>[];
      final res1 = await f2;
      if (!res1.isSuccess) {
        SmartDialog.showToast("获取关注列表失败：$res1");
      } else {
        allFollowedUps = res1.data.list!
            .where((e) => hasUpdatedUps.every((e1) => e.mid != e1.mid))
            .map(
              (e) => UpItem(
                face: e.face,
                mid: e.mid,
                uname: e.uname,
                hasUpdate: false,
              ),
            )
            .toList();
        allFollowedUpsPage += 1;
        allFollowedUpsTotal = res1.data.total!;
      }
      upData
        ..value.upList = hasUpdatedUps + allFollowedUps
        ..refresh();
    } else {
      var res = await DynamicsHttp.followUp();
      if (res.isSuccess) {
        upData.value = res.data;
        if (upData.value.upList.isNullOrEmpty) {
          mid.value = -1;
        }
      } else {
        upData
          ..value.errMsg = (res as Error).errMsg
          ..refresh();
      }
    }
    isQuerying = false;
  }

  void onSelectUp(int mid) {
    if (this.mid.value == mid) {
      tabController.index = (mid == -1 ? 0 : 4);
      if (mid == -1) {
        queryFollowUp();
      }
      controller?.onReload();
      return;
    }

    this.mid.value = mid;
    tabController.index = (mid == -1 ? 0 : 4);
  }

  @override
  Future<void> onRefresh() async {
    queryFollowUp();
    await controller?.onRefresh();
  }

  @override
  void animateToTop() {
    controller?.animateToTop();
    scrollController.animToTop();
  }

  @override
  void toTopOrRefresh() {
    final ctr = controller;
    if (ctr?.scrollController.hasClients == true) {
      if (ctr!.scrollController.position.pixels == 0) {
        if (scrollController.hasClients &&
            scrollController.position.pixels != 0) {
          scrollController.animToTop();
        }
        EasyThrottle.throttle(
          'topOrRefresh',
          const Duration(milliseconds: 500),
          onRefresh,
        );
      } else {
        animateToTop();
      }
    } else {
      super.toTopOrRefresh();
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
