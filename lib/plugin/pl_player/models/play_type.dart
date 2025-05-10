enum PlayType { video, live }

extension PlayTypeExt on PlayType {
  bool get isLive => this == PlayType.live;
}
