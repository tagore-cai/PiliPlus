import 'package:PiliPlus/models/video/pugv_info/episode.dart';

class PugvInfoData {
  int? seasonId;
  List<Episode>? episodes;

  PugvInfoData({
    this.seasonId,
    this.episodes,
  });

  factory PugvInfoData.fromJson(Map<String, dynamic> json) => PugvInfoData(
        seasonId: json['season_id'],
        episodes: (json['episodes'] as List<dynamic>?)
            ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
