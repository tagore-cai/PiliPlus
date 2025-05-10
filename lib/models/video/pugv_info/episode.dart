class Episode {
  int? aid;
  num? catalogueIndex;
  num? cid;
  String? cover;
  num? duration;
  num? epStatus;
  bool? episodeCanView;
  String? from;
  num? id;
  num? index;
  String? label;
  num? page;
  num? play;
  num? playWay;
  bool? playable;
  num? releaseDate;
  bool? showVt;
  num? status;
  String? subtitle;
  String? title;
  bool? watched;
  num? watchedHistory;

  Episode({
    this.aid,
    this.catalogueIndex,
    this.cid,
    this.cover,
    this.duration,
    this.epStatus,
    this.episodeCanView,
    this.from,
    this.id,
    this.index,
    this.label,
    this.page,
    this.play,
    this.playWay,
    this.playable,
    this.releaseDate,
    this.showVt,
    this.status,
    this.subtitle,
    this.title,
    this.watched,
    this.watchedHistory,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        aid: json['aid'] as int?,
        catalogueIndex: json['catalogue_index'] as num?,
        cid: json['cid'] as num?,
        cover: json['cover'] as String?,
        duration: json['duration'] as num?,
        epStatus: json['ep_status'] as num?,
        episodeCanView: json['episode_can_view'] as bool?,
        from: json['from'] as String?,
        id: json['id'] as num?,
        index: json['index'] as num?,
        label: json['label'] as String?,
        page: json['page'] as num?,
        play: json['play'] as num?,
        playWay: json['play_way'] as num?,
        playable: json['playable'] as bool?,
        releaseDate: json['release_date'] as num?,
        showVt: json['show_vt'] as bool?,
        status: json['status'] as num?,
        subtitle: json['subtitle'] as String?,
        title: json['title'] as String?,
        watched: json['watched'] as bool?,
        watchedHistory: json['watchedHistory'] as num?,
      );

  Map<String, dynamic> toJson() => {
        'aid': aid,
        'catalogue_index': catalogueIndex,
        'cid': cid,
        'cover': cover,
        'duration': duration,
        'ep_status': epStatus,
        'episode_can_view': episodeCanView,
        'from': from,
        'id': id,
        'index': index,
        'label': label,
        'page': page,
        'play': play,
        'play_way': playWay,
        'playable': playable,
        'release_date': releaseDate,
        'show_vt': showVt,
        'status': status,
        'subtitle': subtitle,
        'title': title,
        'watched': watched,
        'watchedHistory': watchedHistory,
      };
}
