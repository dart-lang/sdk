///
//  Generated code. Do not modify.
//  source: foo.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FooKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FooKeep',
      createEmptyInstance: create)
    ..aOM<BarKeep>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'barKeep',
        protoName: 'barKeep', subBuilder: BarKeep.create)
    ..aOM<BarKeep>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'barDrop',
        protoName: 'barDrop', subBuilder: BarKeep.create)
    ..m<$core.String, BarKeep>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mapKeep',
        protoName: 'mapKeep',
        entryClassName: 'FooKeep.MapKeepEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: BarKeep.create)
    ..m<$core.String, ZopDrop>(
        4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mapDrop',
        protoName: 'mapDrop',
        entryClassName: 'FooKeep.MapDropEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: ZopDrop.create)
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'aKeep', $pb.PbFieldType.O3,
        protoName: 'aKeep')
    ..aOM<HasKeep>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hasKeep',
        protoName: 'hasKeep', subBuilder: HasKeep.create)
    ..aOM<ClearKeep>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'clearKeep',
        protoName: 'clearKeep', subBuilder: ClearKeep.create)
    ..hasRequiredFields = false;

  FooKeep._() : super();
  factory FooKeep() => create();
  factory FooKeep.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FooKeep.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FooKeep clone() => FooKeep()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FooKeep copyWith(void Function(FooKeep) updates) =>
      super.copyWith((message) => updates(message as FooKeep))
          as FooKeep; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FooKeep create() => FooKeep._();
  FooKeep createEmptyInstance() => create();
  static $pb.PbList<FooKeep> createRepeated() => $pb.PbList<FooKeep>();
  @$core.pragma('dart2js:noInline')
  static FooKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FooKeep>(create);
  static FooKeep? _defaultInstance;

  @$pb.TagNumber(1)
  BarKeep get barKeep => $_getN(0);
  @$pb.TagNumber(1)
  set barKeep(BarKeep v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBarKeep() => $_has(0);
  @$pb.TagNumber(1)
  void clearBarKeep() => clearField(1);
  @$pb.TagNumber(1)
  BarKeep ensureBarKeep() => $_ensure(0);

  @$pb.TagNumber(2)
  BarKeep get barDrop => $_getN(1);
  @$pb.TagNumber(2)
  set barDrop(BarKeep v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBarDrop() => $_has(1);
  @$pb.TagNumber(2)
  void clearBarDrop() => clearField(2);
  @$pb.TagNumber(2)
  BarKeep ensureBarDrop() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.Map<$core.String, BarKeep> get mapKeep => $_getMap(2);

  @$pb.TagNumber(4)
  $core.Map<$core.String, ZopDrop> get mapDrop => $_getMap(3);

  @$pb.TagNumber(5)
  $core.int get aKeep => $_getIZ(4);
  @$pb.TagNumber(5)
  set aKeep($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAKeep() => $_has(4);
  @$pb.TagNumber(5)
  void clearAKeep() => clearField(5);

  @$pb.TagNumber(6)
  HasKeep get hasKeep => $_getN(5);
  @$pb.TagNumber(6)
  set hasKeep(HasKeep v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasHasKeep() => $_has(5);
  @$pb.TagNumber(6)
  void clearHasKeep() => clearField(6);
  @$pb.TagNumber(6)
  HasKeep ensureHasKeep() => $_ensure(5);

  @$pb.TagNumber(7)
  ClearKeep get clearKeep => $_getN(6);
  @$pb.TagNumber(7)
  set clearKeep(ClearKeep v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasClearKeep() => $_has(6);
  @$pb.TagNumber(7)
  void clearClearKeep() => clearField(7);
  @$pb.TagNumber(7)
  ClearKeep ensureClearKeep() => $_ensure(6);
}

class BarKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'BarKeep',
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'aKeep',
        $pb.PbFieldType.O3,
        protoName: 'aKeep')
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'bDrop',
        $pb.PbFieldType.O3,
        protoName: 'bDrop')
    ..hasRequiredFields = false;

  BarKeep._() : super();
  factory BarKeep() => create();
  factory BarKeep.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BarKeep.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BarKeep clone() => BarKeep()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BarKeep copyWith(void Function(BarKeep) updates) =>
      super.copyWith((message) => updates(message as BarKeep))
          as BarKeep; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BarKeep create() => BarKeep._();
  BarKeep createEmptyInstance() => create();
  static $pb.PbList<BarKeep> createRepeated() => $pb.PbList<BarKeep>();
  @$core.pragma('dart2js:noInline')
  static BarKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BarKeep>(create);
  static BarKeep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aKeep => $_getIZ(0);
  @$pb.TagNumber(1)
  set aKeep($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasAKeep() => $_has(0);
  @$pb.TagNumber(1)
  void clearAKeep() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get bDrop => $_getIZ(1);
  @$pb.TagNumber(2)
  set bDrop($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBDrop() => $_has(1);
  @$pb.TagNumber(2)
  void clearBDrop() => clearField(2);
}

class HasKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'HasKeep',
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'aDrop',
        $pb.PbFieldType.O3,
        protoName: 'aDrop')
    ..hasRequiredFields = false;

  HasKeep._() : super();
  factory HasKeep() => create();
  factory HasKeep.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory HasKeep.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  HasKeep clone() => HasKeep()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  HasKeep copyWith(void Function(HasKeep) updates) =>
      super.copyWith((message) => updates(message as HasKeep))
          as HasKeep; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static HasKeep create() => HasKeep._();
  HasKeep createEmptyInstance() => create();
  static $pb.PbList<HasKeep> createRepeated() => $pb.PbList<HasKeep>();
  @$core.pragma('dart2js:noInline')
  static HasKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HasKeep>(create);
  static HasKeep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aDrop => $_getIZ(0);
  @$pb.TagNumber(1)
  set aDrop($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasADrop() => $_has(0);
  @$pb.TagNumber(1)
  void clearADrop() => clearField(1);
}

class ClearKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ClearKeep',
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'aDrop',
        $pb.PbFieldType.O3,
        protoName: 'aDrop')
    ..hasRequiredFields = false;

  ClearKeep._() : super();
  factory ClearKeep() => create();
  factory ClearKeep.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClearKeep.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClearKeep clone() => ClearKeep()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClearKeep copyWith(void Function(ClearKeep) updates) =>
      super.copyWith((message) => updates(message as ClearKeep))
          as ClearKeep; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ClearKeep create() => ClearKeep._();
  ClearKeep createEmptyInstance() => create();
  static $pb.PbList<ClearKeep> createRepeated() => $pb.PbList<ClearKeep>();
  @$core.pragma('dart2js:noInline')
  static ClearKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClearKeep>(create);
  static ClearKeep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aDrop => $_getIZ(0);
  @$pb.TagNumber(1)
  set aDrop($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasADrop() => $_has(0);
  @$pb.TagNumber(1)
  void clearADrop() => clearField(1);
}

class ZopDrop extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ZopDrop',
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'aDrop',
        $pb.PbFieldType.O3,
        protoName: 'aDrop')
    ..hasRequiredFields = false;

  ZopDrop._() : super();
  factory ZopDrop() => create();
  factory ZopDrop.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ZopDrop.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ZopDrop clone() => ZopDrop()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ZopDrop copyWith(void Function(ZopDrop) updates) =>
      super.copyWith((message) => updates(message as ZopDrop))
          as ZopDrop; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ZopDrop create() => ZopDrop._();
  ZopDrop createEmptyInstance() => create();
  static $pb.PbList<ZopDrop> createRepeated() => $pb.PbList<ZopDrop>();
  @$core.pragma('dart2js:noInline')
  static ZopDrop getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ZopDrop>(create);
  static ZopDrop? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aDrop => $_getIZ(0);
  @$pb.TagNumber(1)
  set aDrop($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasADrop() => $_has(0);
  @$pb.TagNumber(1)
  void clearADrop() => clearField(1);
}

class MobDrop extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'MobDrop',
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'aDrop',
        $pb.PbFieldType.O3,
        protoName: 'aDrop')
    ..hasRequiredFields = false;

  MobDrop._() : super();
  factory MobDrop() => create();
  factory MobDrop.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MobDrop.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MobDrop clone() => MobDrop()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MobDrop copyWith(void Function(MobDrop) updates) =>
      super.copyWith((message) => updates(message as MobDrop))
          as MobDrop; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MobDrop create() => MobDrop._();
  MobDrop createEmptyInstance() => create();
  static $pb.PbList<MobDrop> createRepeated() => $pb.PbList<MobDrop>();
  @$core.pragma('dart2js:noInline')
  static MobDrop getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MobDrop>(create);
  static MobDrop? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aDrop => $_getIZ(0);
  @$pb.TagNumber(1)
  set aDrop($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasADrop() => $_has(0);
  @$pb.TagNumber(1)
  void clearADrop() => clearField(1);
}
