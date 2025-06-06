import 'package:PiliPlus/http/follow.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/models/common/follow_order_type.dart';
import 'package:PiliPlus/models/follow/result.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/pages/follow/controller.dart';
import 'package:get/get.dart';

class FollowChildController
    extends CommonListController<FollowDataModel, FollowItemModel> {
  FollowChildController(this.controller, this.mid, this.tagid);
  final FollowController? controller;
  final int? tagid;
  final int mid;

  late final Rx<FollowOrderType> orderType = FollowOrderType.def.obs;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<FollowItemModel>? getDataList(FollowDataModel response) {
    return response.list;
  }

  @override
  bool customHandleResponse(bool isRefresh, Success<FollowDataModel> response) {
    if (controller != null) {
      try {
        if (controller!.isOwner &&
            tagid == null &&
            isRefresh &&
            controller!.followState.value.isSuccess) {
          controller!.tabs
            ..[0].count = response.response.total
            ..refresh();
        }
      } catch (_) {}
    }
    return false;
  }

  @override
  Future<LoadingState<FollowDataModel>> customGetData() {
    if (tagid != null) {
      return MemberHttp.followUpGroup(mid, tagid, page, 20);
    }

    return FollowHttp.followingsNew(
      vmid: mid,
      pn: page,
      ps: 20,
      orderType: orderType.value.type,
    );
  }
}
