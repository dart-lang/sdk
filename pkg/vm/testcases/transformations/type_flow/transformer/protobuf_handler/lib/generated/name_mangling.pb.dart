///
//  Generated code. Do not modify.
//  source: name_mangling.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i =
      $pb.BuilderInfo('AKeep', createEmptyInstance: create)
        ..hasRequiredFields = false;

  AKeep._() : super();
  factory AKeep() => create();
  factory AKeep.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AKeep.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  AKeep clone() => AKeep()..mergeFromMessage(this);
  AKeep copyWith(void Function(AKeep) updates) =>
      super.copyWith((message) => updates(message as AKeep));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AKeep create() => AKeep._();
  AKeep createEmptyInstance() => create();
  static $pb.PbList<AKeep> createRepeated() => $pb.PbList<AKeep>();
  @$core.pragma('dart2js:noInline')
  static AKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AKeep>(create);
  static AKeep _defaultInstance;
}

class NameManglingKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i =
      $pb.BuilderInfo('NameManglingKeep', createEmptyInstance: create)
        ..aOM<AKeep>(10, 'clone', subBuilder: AKeep.create)
        ..hasRequiredFields = false;

  NameManglingKeep._() : super();
  factory NameManglingKeep() => create();
  factory NameManglingKeep.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory NameManglingKeep.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  NameManglingKeep clone() => NameManglingKeep()..mergeFromMessage(this);
  NameManglingKeep copyWith(void Function(NameManglingKeep) updates) =>
      super.copyWith((message) => updates(message as NameManglingKeep));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NameManglingKeep create() => NameManglingKeep._();
  NameManglingKeep createEmptyInstance() => create();
  static $pb.PbList<NameManglingKeep> createRepeated() =>
      $pb.PbList<NameManglingKeep>();
  @$core.pragma('dart2js:noInline')
  static NameManglingKeep getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NameManglingKeep>(create);
  static NameManglingKeep _defaultInstance;

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
