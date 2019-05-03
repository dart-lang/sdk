///
//  Generated code. Do not modify.
//  source: foo.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, Map, override;

import 'package:protobuf/protobuf.dart' as $pb;

class FooKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('FooKeep')
    ..a<BarKeep>(
        1, 'barKeep', $pb.PbFieldType.OM, BarKeep.getDefault, BarKeep.create)
    ..a<BarKeep>(
        2, 'barDrop', $pb.PbFieldType.OM, BarKeep.getDefault, BarKeep.create)
    ..m<String, BarKeep>(3, 'mapKeep', 'FooKeep.MapKeepEntry',
        $pb.PbFieldType.OS, $pb.PbFieldType.OM, BarKeep.create, null, null)
    ..m<String, ZopDrop>(4, 'mapDrop', 'FooKeep.MapDropEntry',
        $pb.PbFieldType.OS, $pb.PbFieldType.OM, ZopDrop.create, null, null)
    ..a<int>(5, 'aKeep', $pb.PbFieldType.O3)
    ..a<HasKeep>(
        6, 'hasKeep', $pb.PbFieldType.OM, HasKeep.getDefault, HasKeep.create)
    ..a<ClearKeep>(7, 'clearKeep', $pb.PbFieldType.OM, ClearKeep.getDefault,
        ClearKeep.create)
    ..hasRequiredFields = false;

  FooKeep() : super();
  FooKeep.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  FooKeep.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  FooKeep clone() => new FooKeep()..mergeFromMessage(this);
  FooKeep copyWith(void Function(FooKeep) updates) =>
      super.copyWith((message) => updates(message as FooKeep));
  $pb.BuilderInfo get info_ => _i;
  static FooKeep create() => new FooKeep();
  FooKeep createEmptyInstance() => create();
  static $pb.PbList<FooKeep> createRepeated() => new $pb.PbList<FooKeep>();
  static FooKeep getDefault() => _defaultInstance ??= create()..freeze();
  static FooKeep _defaultInstance;

  BarKeep get barKeep => $_getN(0);
  set barKeep(BarKeep v) {
    setField(1, v);
  }

  bool hasBarKeep() => $_has(0);
  void clearBarKeep() => clearField(1);

  BarKeep get barDrop => $_getN(1);
  set barDrop(BarKeep v) {
    setField(2, v);
  }

  bool hasBarDrop() => $_has(1);
  void clearBarDrop() => clearField(2);

  Map<String, BarKeep> get mapKeep => $_getMap(2);

  Map<String, ZopDrop> get mapDrop => $_getMap(3);

  int get aKeep => $_get(4, 0);
  set aKeep(int v) {
    $_setSignedInt32(4, v);
  }

  bool hasAKeep() => $_has(4);
  void clearAKeep() => clearField(5);

  HasKeep get hasKeep => $_getN(5);
  set hasKeep(HasKeep v) {
    setField(6, v);
  }

  bool hasHasKeep() => $_has(5);
  void clearHasKeep() => clearField(6);

  ClearKeep get clearKeep => $_getN(6);
  set clearKeep(ClearKeep v) {
    setField(7, v);
  }

  bool hasClearKeep() => $_has(6);
  void clearClearKeep() => clearField(7);
}

class BarKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('BarKeep')
    ..a<int>(1, 'aKeep', $pb.PbFieldType.O3)
    ..a<int>(2, 'bDrop', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  BarKeep() : super();
  BarKeep.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  BarKeep.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  BarKeep clone() => new BarKeep()..mergeFromMessage(this);
  BarKeep copyWith(void Function(BarKeep) updates) =>
      super.copyWith((message) => updates(message as BarKeep));
  $pb.BuilderInfo get info_ => _i;
  static BarKeep create() => new BarKeep();
  BarKeep createEmptyInstance() => create();
  static $pb.PbList<BarKeep> createRepeated() => new $pb.PbList<BarKeep>();
  static BarKeep getDefault() => _defaultInstance ??= create()..freeze();
  static BarKeep _defaultInstance;

  int get aKeep => $_get(0, 0);
  set aKeep(int v) {
    $_setSignedInt32(0, v);
  }

  bool hasAKeep() => $_has(0);
  void clearAKeep() => clearField(1);

  int get bDrop => $_get(1, 0);
  set bDrop(int v) {
    $_setSignedInt32(1, v);
  }

  bool hasBDrop() => $_has(1);
  void clearBDrop() => clearField(2);
}

class HasKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('HasKeep')
    ..a<int>(1, 'aDrop', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  HasKeep() : super();
  HasKeep.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  HasKeep.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  HasKeep clone() => new HasKeep()..mergeFromMessage(this);
  HasKeep copyWith(void Function(HasKeep) updates) =>
      super.copyWith((message) => updates(message as HasKeep));
  $pb.BuilderInfo get info_ => _i;
  static HasKeep create() => new HasKeep();
  HasKeep createEmptyInstance() => create();
  static $pb.PbList<HasKeep> createRepeated() => new $pb.PbList<HasKeep>();
  static HasKeep getDefault() => _defaultInstance ??= create()..freeze();
  static HasKeep _defaultInstance;

  int get aDrop => $_get(0, 0);
  set aDrop(int v) {
    $_setSignedInt32(0, v);
  }

  bool hasADrop() => $_has(0);
  void clearADrop() => clearField(1);
}

class ClearKeep extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ClearKeep')
    ..a<int>(1, 'aDrop', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  ClearKeep() : super();
  ClearKeep.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ClearKeep.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ClearKeep clone() => new ClearKeep()..mergeFromMessage(this);
  ClearKeep copyWith(void Function(ClearKeep) updates) =>
      super.copyWith((message) => updates(message as ClearKeep));
  $pb.BuilderInfo get info_ => _i;
  static ClearKeep create() => new ClearKeep();
  ClearKeep createEmptyInstance() => create();
  static $pb.PbList<ClearKeep> createRepeated() => new $pb.PbList<ClearKeep>();
  static ClearKeep getDefault() => _defaultInstance ??= create()..freeze();
  static ClearKeep _defaultInstance;

  int get aDrop => $_get(0, 0);
  set aDrop(int v) {
    $_setSignedInt32(0, v);
  }

  bool hasADrop() => $_has(0);
  void clearADrop() => clearField(1);
}

class ZopDrop extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ZopDrop')
    ..a<int>(1, 'aDrop', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  ZopDrop() : super();
  ZopDrop.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ZopDrop.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ZopDrop clone() => new ZopDrop()..mergeFromMessage(this);
  ZopDrop copyWith(void Function(ZopDrop) updates) =>
      super.copyWith((message) => updates(message as ZopDrop));
  $pb.BuilderInfo get info_ => _i;
  static ZopDrop create() => new ZopDrop();
  ZopDrop createEmptyInstance() => create();
  static $pb.PbList<ZopDrop> createRepeated() => new $pb.PbList<ZopDrop>();
  static ZopDrop getDefault() => _defaultInstance ??= create()..freeze();
  static ZopDrop _defaultInstance;

  int get aDrop => $_get(0, 0);
  set aDrop(int v) {
    $_setSignedInt32(0, v);
  }

  bool hasADrop() => $_has(0);
  void clearADrop() => clearField(1);
}

class MobDrop extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('MobDrop')
    ..a<int>(1, 'aDrop', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  MobDrop() : super();
  MobDrop.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MobDrop.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MobDrop clone() => new MobDrop()..mergeFromMessage(this);
  MobDrop copyWith(void Function(MobDrop) updates) =>
      super.copyWith((message) => updates(message as MobDrop));
  $pb.BuilderInfo get info_ => _i;
  static MobDrop create() => new MobDrop();
  MobDrop createEmptyInstance() => create();
  static $pb.PbList<MobDrop> createRepeated() => new $pb.PbList<MobDrop>();
  static MobDrop getDefault() => _defaultInstance ??= create()..freeze();
  static MobDrop _defaultInstance;

  int get aDrop => $_get(0, 0);
  set aDrop(int v) {
    $_setSignedInt32(0, v);
  }

  bool hasADrop() => $_has(0);
  void clearADrop() => clearField(1);
}
