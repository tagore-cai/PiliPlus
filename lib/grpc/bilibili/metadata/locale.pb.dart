//
//  Generated code. Do not modify.
//  source: bilibili/metadata/locale.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Locale extends $pb.GeneratedMessage {
  factory Locale({
    LocaleIds? cLocale,
    LocaleIds? sLocale,
    $core.String? simCode,
    $core.String? timezone,
    $core.String? utcOffset,
    $core.bool? isDaylightTime,
    $core.bool? alwaysTranslate,
  }) {
    final $result = create();
    if (cLocale != null) {
      $result.cLocale = cLocale;
    }
    if (sLocale != null) {
      $result.sLocale = sLocale;
    }
    if (simCode != null) {
      $result.simCode = simCode;
    }
    if (timezone != null) {
      $result.timezone = timezone;
    }
    if (utcOffset != null) {
      $result.utcOffset = utcOffset;
    }
    if (isDaylightTime != null) {
      $result.isDaylightTime = isDaylightTime;
    }
    if (alwaysTranslate != null) {
      $result.alwaysTranslate = alwaysTranslate;
    }
    return $result;
  }
  Locale._() : super();
  factory Locale.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Locale.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Locale', package: const $pb.PackageName(_omitMessageNames ? '' : 'bilibili.metadata.locale'), createEmptyInstance: create)
    ..aOM<LocaleIds>(1, _omitFieldNames ? '' : 'cLocale', subBuilder: LocaleIds.create)
    ..aOM<LocaleIds>(2, _omitFieldNames ? '' : 'sLocale', subBuilder: LocaleIds.create)
    ..aOS(3, _omitFieldNames ? '' : 'simCode')
    ..aOS(4, _omitFieldNames ? '' : 'timezone')
    ..aOS(5, _omitFieldNames ? '' : 'utcOffset')
    ..aOB(6, _omitFieldNames ? '' : 'isDaylightTime')
    ..aOB(7, _omitFieldNames ? '' : 'alwaysTranslate')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Locale clone() => Locale()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Locale copyWith(void Function(Locale) updates) => super.copyWith((message) => updates(message as Locale)) as Locale;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Locale create() => Locale._();
  Locale createEmptyInstance() => create();
  static $pb.PbList<Locale> createRepeated() => $pb.PbList<Locale>();
  @$core.pragma('dart2js:noInline')
  static Locale getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Locale>(create);
  static Locale? _defaultInstance;

  @$pb.TagNumber(1)
  LocaleIds get cLocale => $_getN(0);
  @$pb.TagNumber(1)
  set cLocale(LocaleIds v) { $_setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCLocale() => $_has(0);
  @$pb.TagNumber(1)
  void clearCLocale() => $_clearField(1);
  @$pb.TagNumber(1)
  LocaleIds ensureCLocale() => $_ensure(0);

  @$pb.TagNumber(2)
  LocaleIds get sLocale => $_getN(1);
  @$pb.TagNumber(2)
  set sLocale(LocaleIds v) { $_setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasSLocale() => $_has(1);
  @$pb.TagNumber(2)
  void clearSLocale() => $_clearField(2);
  @$pb.TagNumber(2)
  LocaleIds ensureSLocale() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get simCode => $_getSZ(2);
  @$pb.TagNumber(3)
  set simCode($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSimCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearSimCode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get timezone => $_getSZ(3);
  @$pb.TagNumber(4)
  set timezone($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTimezone() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimezone() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get utcOffset => $_getSZ(4);
  @$pb.TagNumber(5)
  set utcOffset($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasUtcOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearUtcOffset() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isDaylightTime => $_getBF(5);
  @$pb.TagNumber(6)
  set isDaylightTime($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasIsDaylightTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsDaylightTime() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get alwaysTranslate => $_getBF(6);
  @$pb.TagNumber(7)
  set alwaysTranslate($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasAlwaysTranslate() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlwaysTranslate() => $_clearField(7);
}

class LocaleIds extends $pb.GeneratedMessage {
  factory LocaleIds({
    $core.String? language,
    $core.String? script,
    $core.String? region,
  }) {
    final $result = create();
    if (language != null) {
      $result.language = language;
    }
    if (script != null) {
      $result.script = script;
    }
    if (region != null) {
      $result.region = region;
    }
    return $result;
  }
  LocaleIds._() : super();
  factory LocaleIds.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LocaleIds.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LocaleIds', package: const $pb.PackageName(_omitMessageNames ? '' : 'bilibili.metadata.locale'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'language')
    ..aOS(2, _omitFieldNames ? '' : 'script')
    ..aOS(3, _omitFieldNames ? '' : 'region')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LocaleIds clone() => LocaleIds()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LocaleIds copyWith(void Function(LocaleIds) updates) => super.copyWith((message) => updates(message as LocaleIds)) as LocaleIds;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocaleIds create() => LocaleIds._();
  LocaleIds createEmptyInstance() => create();
  static $pb.PbList<LocaleIds> createRepeated() => $pb.PbList<LocaleIds>();
  @$core.pragma('dart2js:noInline')
  static LocaleIds getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocaleIds>(create);
  static LocaleIds? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get language => $_getSZ(0);
  @$pb.TagNumber(1)
  set language($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLanguage() => $_has(0);
  @$pb.TagNumber(1)
  void clearLanguage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get script => $_getSZ(1);
  @$pb.TagNumber(2)
  set script($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasScript() => $_has(1);
  @$pb.TagNumber(2)
  void clearScript() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get region => $_getSZ(2);
  @$pb.TagNumber(3)
  set region($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRegion() => $_has(2);
  @$pb.TagNumber(3)
  void clearRegion() => $_clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
