// This is a generated file - do not edit.
//
// Generated from foo.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../mixins.lib.dart' as $mixin;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class FooKeep extends $pb.GeneratedMessage {
  factory FooKeep() => create();

  FooKeep._();

  factory FooKeep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FooKeep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FooKeep',
      createEmptyInstance: create)
    ..aOM<BarKeep>(1, _omitFieldNames ? '' : 'barKeep',
        protoName: 'barKeep', subBuilder: BarKeep.create)
    ..aOM<BarKeep>(2, _omitFieldNames ? '' : 'barDrop',
        protoName: 'barDrop', subBuilder: BarKeep.create)
    ..m<$core.String, BarKeep>(3, _omitFieldNames ? '' : 'mapKeep',
        protoName: 'mapKeep',
        entryClassName: 'FooKeep.MapKeepEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: BarKeep.create,
        valueDefaultOrMaker: BarKeep.getDefault)
    ..m<$core.String, ZopDrop>(4, _omitFieldNames ? '' : 'mapDrop',
        protoName: 'mapDrop',
        entryClassName: 'FooKeep.MapDropEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: ZopDrop.create,
        valueDefaultOrMaker: ZopDrop.getDefault)
    ..aI(5, _omitFieldNames ? '' : 'aKeep', protoName: 'aKeep')
    ..aOM<HasKeep>(6, _omitFieldNames ? '' : 'hasKeep',
        protoName: 'hasKeep', subBuilder: HasKeep.create)
    ..aOM<ClearKeep>(7, _omitFieldNames ? '' : 'clearKeep',
        protoName: 'clearKeep', subBuilder: ClearKeep.create)
    ..aOM<MixinKeep>(8, _omitFieldNames ? '' : 'mixinKeep',
        protoName: 'mixinKeep', subBuilder: MixinKeep.create)
    ..aOM<MixinDrop>(9, _omitFieldNames ? '' : 'mixinDrop',
        protoName: 'mixinDrop', subBuilder: MixinDrop.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FooKeep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FooKeep copyWith(void Function(FooKeep) updates) =>
      super.copyWith((message) => updates(message as FooKeep)) as FooKeep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FooKeep create() => FooKeep._();
  @$core.override
  FooKeep createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FooKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FooKeep>(create);
  static FooKeep? _defaultInstance;

  @$pb.TagNumber(1)
  BarKeep get barKeep => $_getN(0);
  @$pb.TagNumber(1)
  set barKeep(BarKeep value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBarKeep() => $_has(0);
  @$pb.TagNumber(1)
  void clearBarKeep() => $_clearField(1);
  @$pb.TagNumber(1)
  BarKeep ensureBarKeep() => $_ensure(0);

  @$pb.TagNumber(2)
  BarKeep get barDrop => $_getN(1);
  @$pb.TagNumber(2)
  set barDrop(BarKeep value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBarDrop() => $_has(1);
  @$pb.TagNumber(2)
  void clearBarDrop() => $_clearField(2);
  @$pb.TagNumber(2)
  BarKeep ensureBarDrop() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, BarKeep> get mapKeep => $_getMap(2);

  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, ZopDrop> get mapDrop => $_getMap(3);

  @$pb.TagNumber(5)
  $core.int get aKeep => $_getIZ(4);
  @$pb.TagNumber(5)
  set aKeep($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAKeep() => $_has(4);
  @$pb.TagNumber(5)
  void clearAKeep() => $_clearField(5);

  @$pb.TagNumber(6)
  HasKeep get hasKeep => $_getN(5);
  @$pb.TagNumber(6)
  set hasKeep(HasKeep value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasHasKeep() => $_has(5);
  @$pb.TagNumber(6)
  void clearHasKeep() => $_clearField(6);
  @$pb.TagNumber(6)
  HasKeep ensureHasKeep() => $_ensure(5);

  @$pb.TagNumber(7)
  ClearKeep get clearKeep => $_getN(6);
  @$pb.TagNumber(7)
  set clearKeep(ClearKeep value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasClearKeep() => $_has(6);
  @$pb.TagNumber(7)
  void clearClearKeep() => $_clearField(7);
  @$pb.TagNumber(7)
  ClearKeep ensureClearKeep() => $_ensure(6);

  @$pb.TagNumber(8)
  MixinKeep get mixinKeep => $_getN(7);
  @$pb.TagNumber(8)
  set mixinKeep(MixinKeep value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMixinKeep() => $_has(7);
  @$pb.TagNumber(8)
  void clearMixinKeep() => $_clearField(8);
  @$pb.TagNumber(8)
  MixinKeep ensureMixinKeep() => $_ensure(7);

  @$pb.TagNumber(9)
  MixinDrop get mixinDrop => $_getN(8);
  @$pb.TagNumber(9)
  set mixinDrop(MixinDrop value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasMixinDrop() => $_has(8);
  @$pb.TagNumber(9)
  void clearMixinDrop() => $_clearField(9);
  @$pb.TagNumber(9)
  MixinDrop ensureMixinDrop() => $_ensure(8);
}

class BarKeep extends $pb.GeneratedMessage {
  factory BarKeep() => create();

  BarKeep._();

  factory BarKeep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BarKeep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BarKeep',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'aKeep', protoName: 'aKeep')
    ..aI(2, _omitFieldNames ? '' : 'bDrop', protoName: 'bDrop')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BarKeep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BarKeep copyWith(void Function(BarKeep) updates) =>
      super.copyWith((message) => updates(message as BarKeep)) as BarKeep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BarKeep create() => BarKeep._();
  @$core.override
  BarKeep createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BarKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BarKeep>(create);
  static BarKeep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aKeep => $_getIZ(0);
  @$pb.TagNumber(1)
  set aKeep($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAKeep() => $_has(0);
  @$pb.TagNumber(1)
  void clearAKeep() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get bDrop => $_getIZ(1);
  @$pb.TagNumber(2)
  set bDrop($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBDrop() => $_has(1);
  @$pb.TagNumber(2)
  void clearBDrop() => $_clearField(2);
}

class HasKeep extends $pb.GeneratedMessage {
  factory HasKeep() => create();

  HasKeep._();

  factory HasKeep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HasKeep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HasKeep',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'aDrop', protoName: 'aDrop')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HasKeep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HasKeep copyWith(void Function(HasKeep) updates) =>
      super.copyWith((message) => updates(message as HasKeep)) as HasKeep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HasKeep create() => HasKeep._();
  @$core.override
  HasKeep createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HasKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HasKeep>(create);
  static HasKeep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aDrop => $_getIZ(0);
  @$pb.TagNumber(1)
  set aDrop($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasADrop() => $_has(0);
  @$pb.TagNumber(1)
  void clearADrop() => $_clearField(1);
}

class ClearKeep extends $pb.GeneratedMessage {
  factory ClearKeep() => create();

  ClearKeep._();

  factory ClearKeep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClearKeep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClearKeep',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'aDrop', protoName: 'aDrop')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearKeep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearKeep copyWith(void Function(ClearKeep) updates) =>
      super.copyWith((message) => updates(message as ClearKeep)) as ClearKeep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClearKeep create() => ClearKeep._();
  @$core.override
  ClearKeep createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClearKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClearKeep>(create);
  static ClearKeep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aDrop => $_getIZ(0);
  @$pb.TagNumber(1)
  set aDrop($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasADrop() => $_has(0);
  @$pb.TagNumber(1)
  void clearADrop() => $_clearField(1);
}

class ZopDrop extends $pb.GeneratedMessage {
  factory ZopDrop() => create();

  ZopDrop._();

  factory ZopDrop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ZopDrop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ZopDrop',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'aDrop', protoName: 'aDrop')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZopDrop clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ZopDrop copyWith(void Function(ZopDrop) updates) =>
      super.copyWith((message) => updates(message as ZopDrop)) as ZopDrop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ZopDrop create() => ZopDrop._();
  @$core.override
  ZopDrop createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ZopDrop getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ZopDrop>(create);
  static ZopDrop? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aDrop => $_getIZ(0);
  @$pb.TagNumber(1)
  set aDrop($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasADrop() => $_has(0);
  @$pb.TagNumber(1)
  void clearADrop() => $_clearField(1);
}

class MobDrop extends $pb.GeneratedMessage {
  factory MobDrop() => create();

  MobDrop._();

  factory MobDrop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MobDrop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MobDrop',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'aDrop', protoName: 'aDrop')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MobDrop clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MobDrop copyWith(void Function(MobDrop) updates) =>
      super.copyWith((message) => updates(message as MobDrop)) as MobDrop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MobDrop create() => MobDrop._();
  @$core.override
  MobDrop createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MobDrop getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MobDrop>(create);
  static MobDrop? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aDrop => $_getIZ(0);
  @$pb.TagNumber(1)
  set aDrop($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasADrop() => $_has(0);
  @$pb.TagNumber(1)
  void clearADrop() => $_clearField(1);
}

class MixinKeep extends $pb.GeneratedMessage with $mixin.MyMixin {
  factory MixinKeep() => create();

  MixinKeep._();

  factory MixinKeep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MixinKeep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MixinKeep',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'aKeep', protoName: 'aKeep')
    ..aI(2, _omitFieldNames ? '' : 'bDrop', protoName: 'bDrop')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MixinKeep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MixinKeep copyWith(void Function(MixinKeep) updates) =>
      super.copyWith((message) => updates(message as MixinKeep)) as MixinKeep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MixinKeep create() => MixinKeep._();
  @$core.override
  MixinKeep createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MixinKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MixinKeep>(create);
  static MixinKeep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aKeep => $_getIZ(0);
  @$pb.TagNumber(1)
  set aKeep($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAKeep() => $_has(0);
  @$pb.TagNumber(1)
  void clearAKeep() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get bDrop => $_getIZ(1);
  @$pb.TagNumber(2)
  set bDrop($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBDrop() => $_has(1);
  @$pb.TagNumber(2)
  void clearBDrop() => $_clearField(2);
}

class MixinDrop extends $pb.GeneratedMessage with $mixin.MyMixin {
  factory MixinDrop() => create();

  MixinDrop._();

  factory MixinDrop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MixinDrop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MixinDrop',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'aDrop', protoName: 'aDrop')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MixinDrop clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MixinDrop copyWith(void Function(MixinDrop) updates) =>
      super.copyWith((message) => updates(message as MixinDrop)) as MixinDrop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MixinDrop create() => MixinDrop._();
  @$core.override
  MixinDrop createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MixinDrop getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MixinDrop>(create);
  static MixinDrop? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get aDrop => $_getIZ(0);
  @$pb.TagNumber(1)
  set aDrop($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasADrop() => $_has(0);
  @$pb.TagNumber(1)
  void clearADrop() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
