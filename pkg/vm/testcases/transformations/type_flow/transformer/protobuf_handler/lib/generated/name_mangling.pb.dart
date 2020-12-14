///
//  Generated code. Do not modify.
//  source: name_mangling.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AKeep',
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  AKeep._() : super();
  factory AKeep() => create();
  factory AKeep.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AKeep.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AKeep clone() => AKeep()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AKeep copyWith(void Function(AKeep) updates) =>
      super.copyWith((message) => updates(message as AKeep))
          as AKeep; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AKeep create() => AKeep._();
  AKeep createEmptyInstance() => create();
  static $pb.PbList<AKeep> createRepeated() => $pb.PbList<AKeep>();
  @$core.pragma('dart2js:noInline')
  static AKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AKeep>(create);
  static AKeep? _defaultInstance;
}

class NameManglingKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'NameManglingKeep',
      createEmptyInstance: create)
    ..aOM<AKeep>(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'clone',
        subBuilder: AKeep.create)
    ..hasRequiredFields = false;

  NameManglingKeep._() : super();
  factory NameManglingKeep() => create();
  factory NameManglingKeep.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory NameManglingKeep.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  NameManglingKeep clone() => NameManglingKeep()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  NameManglingKeep copyWith(void Function(NameManglingKeep) updates) =>
      super.copyWith((message) => updates(message as NameManglingKeep))
          as NameManglingKeep; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NameManglingKeep create() => NameManglingKeep._();
  NameManglingKeep createEmptyInstance() => create();
  static $pb.PbList<NameManglingKeep> createRepeated() =>
      $pb.PbList<NameManglingKeep>();
  @$core.pragma('dart2js:noInline')
  static NameManglingKeep getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NameManglingKeep>(create);
  static NameManglingKeep? _defaultInstance;

  @$pb.TagNumber(10)
  AKeep get clone_10 => $_getN(0);
  @$pb.TagNumber(10)
  set clone_10(AKeep v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasClone_10() => $_has(0);
  @$pb.TagNumber(10)
  void clearClone_10() => clearField(10);
  @$pb.TagNumber(10)
  AKeep ensureClone_10() => $_ensure(0);
}
