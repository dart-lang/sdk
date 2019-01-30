///
//  Generated code. Do not modify.
//  source: info.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

class DependencyInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('DependencyInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'targetId')
    ..aOS(2, 'mask')
    ..hasRequiredFields = false;

  DependencyInfoPB() : super();
  DependencyInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  DependencyInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  DependencyInfoPB clone() => new DependencyInfoPB()..mergeFromMessage(this);
  DependencyInfoPB copyWith(void Function(DependencyInfoPB) updates) =>
      super.copyWith((message) => updates(message as DependencyInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static DependencyInfoPB create() => new DependencyInfoPB();
  static $pb.PbList<DependencyInfoPB> createRepeated() =>
      new $pb.PbList<DependencyInfoPB>();
  static DependencyInfoPB getDefault() =>
      _defaultInstance ??= create()..freeze();
  static DependencyInfoPB _defaultInstance;
  static void $checkItem(DependencyInfoPB v) {
    if (v is! DependencyInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get targetId => $_getS(0, '');
  set targetId(String v) {
    $_setString(0, v);
  }

  bool hasTargetId() => $_has(0);
  void clearTargetId() => clearField(1);

  String get mask => $_getS(1, '');
  set mask(String v) {
    $_setString(1, v);
  }

  bool hasMask() => $_has(1);
  void clearMask() => clearField(2);
}

class AllInfoPB_AllInfosEntry extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'AllInfoPB.AllInfosEntry',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'key')
    ..a<InfoPB>(
        2, 'value', $pb.PbFieldType.OM, InfoPB.getDefault, InfoPB.create)
    ..hasRequiredFields = false;

  AllInfoPB_AllInfosEntry() : super();
  AllInfoPB_AllInfosEntry.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  AllInfoPB_AllInfosEntry.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  AllInfoPB_AllInfosEntry clone() =>
      new AllInfoPB_AllInfosEntry()..mergeFromMessage(this);
  AllInfoPB_AllInfosEntry copyWith(
          void Function(AllInfoPB_AllInfosEntry) updates) =>
      super.copyWith((message) => updates(message as AllInfoPB_AllInfosEntry));
  $pb.BuilderInfo get info_ => _i;
  static AllInfoPB_AllInfosEntry create() => new AllInfoPB_AllInfosEntry();
  static $pb.PbList<AllInfoPB_AllInfosEntry> createRepeated() =>
      new $pb.PbList<AllInfoPB_AllInfosEntry>();
  static AllInfoPB_AllInfosEntry getDefault() =>
      _defaultInstance ??= create()..freeze();
  static AllInfoPB_AllInfosEntry _defaultInstance;
  static void $checkItem(AllInfoPB_AllInfosEntry v) {
    if (v is! AllInfoPB_AllInfosEntry)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get key => $_getS(0, '');
  set key(String v) {
    $_setString(0, v);
  }

  bool hasKey() => $_has(0);
  void clearKey() => clearField(1);

  InfoPB get value => $_getN(1);
  set value(InfoPB v) {
    setField(2, v);
  }

  bool hasValue() => $_has(1);
  void clearValue() => clearField(2);
}

class AllInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('AllInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..a<ProgramInfoPB>(1, 'program', $pb.PbFieldType.OM,
        ProgramInfoPB.getDefault, ProgramInfoPB.create)
    ..pp<AllInfoPB_AllInfosEntry>(2, 'allInfos', $pb.PbFieldType.PM,
        AllInfoPB_AllInfosEntry.$checkItem, AllInfoPB_AllInfosEntry.create)
    ..pp<LibraryDeferredImportsPB>(3, 'deferredImports', $pb.PbFieldType.PM,
        LibraryDeferredImportsPB.$checkItem, LibraryDeferredImportsPB.create)
    ..hasRequiredFields = false;

  AllInfoPB() : super();
  AllInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  AllInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  AllInfoPB clone() => new AllInfoPB()..mergeFromMessage(this);
  AllInfoPB copyWith(void Function(AllInfoPB) updates) =>
      super.copyWith((message) => updates(message as AllInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static AllInfoPB create() => new AllInfoPB();
  static $pb.PbList<AllInfoPB> createRepeated() => new $pb.PbList<AllInfoPB>();
  static AllInfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static AllInfoPB _defaultInstance;
  static void $checkItem(AllInfoPB v) {
    if (v is! AllInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  ProgramInfoPB get program => $_getN(0);
  set program(ProgramInfoPB v) {
    setField(1, v);
  }

  bool hasProgram() => $_has(0);
  void clearProgram() => clearField(1);

  List<AllInfoPB_AllInfosEntry> get allInfos => $_getList(1);

  List<LibraryDeferredImportsPB> get deferredImports => $_getList(2);
}

class InfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('InfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'name')
    ..a<int>(2, 'id', $pb.PbFieldType.O3)
    ..aOS(3, 'serializedId')
    ..aOS(4, 'coverageId')
    ..a<int>(5, 'size', $pb.PbFieldType.O3)
    ..aOS(6, 'parentId')
    ..pp<DependencyInfoPB>(7, 'uses', $pb.PbFieldType.PM,
        DependencyInfoPB.$checkItem, DependencyInfoPB.create)
    ..aOS(8, 'outputUnitId')
    ..a<LibraryInfoPB>(100, 'libraryInfo', $pb.PbFieldType.OM,
        LibraryInfoPB.getDefault, LibraryInfoPB.create)
    ..a<ClassInfoPB>(101, 'classInfo', $pb.PbFieldType.OM,
        ClassInfoPB.getDefault, ClassInfoPB.create)
    ..a<FunctionInfoPB>(102, 'functionInfo', $pb.PbFieldType.OM,
        FunctionInfoPB.getDefault, FunctionInfoPB.create)
    ..a<FieldInfoPB>(103, 'fieldInfo', $pb.PbFieldType.OM,
        FieldInfoPB.getDefault, FieldInfoPB.create)
    ..a<ConstantInfoPB>(104, 'constantInfo', $pb.PbFieldType.OM,
        ConstantInfoPB.getDefault, ConstantInfoPB.create)
    ..a<OutputUnitInfoPB>(105, 'outputUnitInfo', $pb.PbFieldType.OM,
        OutputUnitInfoPB.getDefault, OutputUnitInfoPB.create)
    ..a<TypedefInfoPB>(106, 'typedefInfo', $pb.PbFieldType.OM,
        TypedefInfoPB.getDefault, TypedefInfoPB.create)
    ..a<ClosureInfoPB>(107, 'closureInfo', $pb.PbFieldType.OM,
        ClosureInfoPB.getDefault, ClosureInfoPB.create)
    ..hasRequiredFields = false;

  InfoPB() : super();
  InfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  InfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  InfoPB clone() => new InfoPB()..mergeFromMessage(this);
  InfoPB copyWith(void Function(InfoPB) updates) =>
      super.copyWith((message) => updates(message as InfoPB));
  $pb.BuilderInfo get info_ => _i;
  static InfoPB create() => new InfoPB();
  static $pb.PbList<InfoPB> createRepeated() => new $pb.PbList<InfoPB>();
  static InfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static InfoPB _defaultInstance;
  static void $checkItem(InfoPB v) {
    if (v is! InfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get name => $_getS(0, '');
  set name(String v) {
    $_setString(0, v);
  }

  bool hasName() => $_has(0);
  void clearName() => clearField(1);

  int get id => $_get(1, 0);
  set id(int v) {
    $_setSignedInt32(1, v);
  }

  bool hasId() => $_has(1);
  void clearId() => clearField(2);

  String get serializedId => $_getS(2, '');
  set serializedId(String v) {
    $_setString(2, v);
  }

  bool hasSerializedId() => $_has(2);
  void clearSerializedId() => clearField(3);

  String get coverageId => $_getS(3, '');
  set coverageId(String v) {
    $_setString(3, v);
  }

  bool hasCoverageId() => $_has(3);
  void clearCoverageId() => clearField(4);

  int get size => $_get(4, 0);
  set size(int v) {
    $_setSignedInt32(4, v);
  }

  bool hasSize() => $_has(4);
  void clearSize() => clearField(5);

  String get parentId => $_getS(5, '');
  set parentId(String v) {
    $_setString(5, v);
  }

  bool hasParentId() => $_has(5);
  void clearParentId() => clearField(6);

  List<DependencyInfoPB> get uses => $_getList(6);

  String get outputUnitId => $_getS(7, '');
  set outputUnitId(String v) {
    $_setString(7, v);
  }

  bool hasOutputUnitId() => $_has(7);
  void clearOutputUnitId() => clearField(8);

  LibraryInfoPB get libraryInfo => $_getN(8);
  set libraryInfo(LibraryInfoPB v) {
    setField(100, v);
  }

  bool hasLibraryInfo() => $_has(8);
  void clearLibraryInfo() => clearField(100);

  ClassInfoPB get classInfo => $_getN(9);
  set classInfo(ClassInfoPB v) {
    setField(101, v);
  }

  bool hasClassInfo() => $_has(9);
  void clearClassInfo() => clearField(101);

  FunctionInfoPB get functionInfo => $_getN(10);
  set functionInfo(FunctionInfoPB v) {
    setField(102, v);
  }

  bool hasFunctionInfo() => $_has(10);
  void clearFunctionInfo() => clearField(102);

  FieldInfoPB get fieldInfo => $_getN(11);
  set fieldInfo(FieldInfoPB v) {
    setField(103, v);
  }

  bool hasFieldInfo() => $_has(11);
  void clearFieldInfo() => clearField(103);

  ConstantInfoPB get constantInfo => $_getN(12);
  set constantInfo(ConstantInfoPB v) {
    setField(104, v);
  }

  bool hasConstantInfo() => $_has(12);
  void clearConstantInfo() => clearField(104);

  OutputUnitInfoPB get outputUnitInfo => $_getN(13);
  set outputUnitInfo(OutputUnitInfoPB v) {
    setField(105, v);
  }

  bool hasOutputUnitInfo() => $_has(13);
  void clearOutputUnitInfo() => clearField(105);

  TypedefInfoPB get typedefInfo => $_getN(14);
  set typedefInfo(TypedefInfoPB v) {
    setField(106, v);
  }

  bool hasTypedefInfo() => $_has(14);
  void clearTypedefInfo() => clearField(106);

  ClosureInfoPB get closureInfo => $_getN(15);
  set closureInfo(ClosureInfoPB v) {
    setField(107, v);
  }

  bool hasClosureInfo() => $_has(15);
  void clearClosureInfo() => clearField(107);
}

class ProgramInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ProgramInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'entrypointId')
    ..a<int>(2, 'size', $pb.PbFieldType.O3)
    ..aOS(3, 'dart2jsVersion')
    ..aInt64(4, 'compilationMoment')
    ..aInt64(5, 'compilationDuration')
    ..aInt64(6, 'toProtoDuration')
    ..aInt64(7, 'dumpInfoDuration')
    ..aOB(8, 'noSuchMethodEnabled')
    ..aOB(9, 'isRuntimeTypeUsed')
    ..aOB(10, 'isIsolateUsed')
    ..aOB(11, 'isFunctionApplyUsed')
    ..aOB(12, 'isMirrorsUsed')
    ..aOB(13, 'minified')
    ..hasRequiredFields = false;

  ProgramInfoPB() : super();
  ProgramInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ProgramInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ProgramInfoPB clone() => new ProgramInfoPB()..mergeFromMessage(this);
  ProgramInfoPB copyWith(void Function(ProgramInfoPB) updates) =>
      super.copyWith((message) => updates(message as ProgramInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static ProgramInfoPB create() => new ProgramInfoPB();
  static $pb.PbList<ProgramInfoPB> createRepeated() =>
      new $pb.PbList<ProgramInfoPB>();
  static ProgramInfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static ProgramInfoPB _defaultInstance;
  static void $checkItem(ProgramInfoPB v) {
    if (v is! ProgramInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get entrypointId => $_getS(0, '');
  set entrypointId(String v) {
    $_setString(0, v);
  }

  bool hasEntrypointId() => $_has(0);
  void clearEntrypointId() => clearField(1);

  int get size => $_get(1, 0);
  set size(int v) {
    $_setSignedInt32(1, v);
  }

  bool hasSize() => $_has(1);
  void clearSize() => clearField(2);

  String get dart2jsVersion => $_getS(2, '');
  set dart2jsVersion(String v) {
    $_setString(2, v);
  }

  bool hasDart2jsVersion() => $_has(2);
  void clearDart2jsVersion() => clearField(3);

  Int64 get compilationMoment => $_getI64(3);
  set compilationMoment(Int64 v) {
    $_setInt64(3, v);
  }

  bool hasCompilationMoment() => $_has(3);
  void clearCompilationMoment() => clearField(4);

  Int64 get compilationDuration => $_getI64(4);
  set compilationDuration(Int64 v) {
    $_setInt64(4, v);
  }

  bool hasCompilationDuration() => $_has(4);
  void clearCompilationDuration() => clearField(5);

  Int64 get toProtoDuration => $_getI64(5);
  set toProtoDuration(Int64 v) {
    $_setInt64(5, v);
  }

  bool hasToProtoDuration() => $_has(5);
  void clearToProtoDuration() => clearField(6);

  Int64 get dumpInfoDuration => $_getI64(6);
  set dumpInfoDuration(Int64 v) {
    $_setInt64(6, v);
  }

  bool hasDumpInfoDuration() => $_has(6);
  void clearDumpInfoDuration() => clearField(7);

  bool get noSuchMethodEnabled => $_get(7, false);
  set noSuchMethodEnabled(bool v) {
    $_setBool(7, v);
  }

  bool hasNoSuchMethodEnabled() => $_has(7);
  void clearNoSuchMethodEnabled() => clearField(8);

  bool get isRuntimeTypeUsed => $_get(8, false);
  set isRuntimeTypeUsed(bool v) {
    $_setBool(8, v);
  }

  bool hasIsRuntimeTypeUsed() => $_has(8);
  void clearIsRuntimeTypeUsed() => clearField(9);

  bool get isIsolateUsed => $_get(9, false);
  set isIsolateUsed(bool v) {
    $_setBool(9, v);
  }

  bool hasIsIsolateUsed() => $_has(9);
  void clearIsIsolateUsed() => clearField(10);

  bool get isFunctionApplyUsed => $_get(10, false);
  set isFunctionApplyUsed(bool v) {
    $_setBool(10, v);
  }

  bool hasIsFunctionApplyUsed() => $_has(10);
  void clearIsFunctionApplyUsed() => clearField(11);

  bool get isMirrorsUsed => $_get(11, false);
  set isMirrorsUsed(bool v) {
    $_setBool(11, v);
  }

  bool hasIsMirrorsUsed() => $_has(11);
  void clearIsMirrorsUsed() => clearField(12);

  bool get minified => $_get(12, false);
  set minified(bool v) {
    $_setBool(12, v);
  }

  bool hasMinified() => $_has(12);
  void clearMinified() => clearField(13);
}

class LibraryInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('LibraryInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'uri')
    ..pPS(2, 'childrenIds')
    ..hasRequiredFields = false;

  LibraryInfoPB() : super();
  LibraryInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  LibraryInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  LibraryInfoPB clone() => new LibraryInfoPB()..mergeFromMessage(this);
  LibraryInfoPB copyWith(void Function(LibraryInfoPB) updates) =>
      super.copyWith((message) => updates(message as LibraryInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static LibraryInfoPB create() => new LibraryInfoPB();
  static $pb.PbList<LibraryInfoPB> createRepeated() =>
      new $pb.PbList<LibraryInfoPB>();
  static LibraryInfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static LibraryInfoPB _defaultInstance;
  static void $checkItem(LibraryInfoPB v) {
    if (v is! LibraryInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get uri => $_getS(0, '');
  set uri(String v) {
    $_setString(0, v);
  }

  bool hasUri() => $_has(0);
  void clearUri() => clearField(1);

  List<String> get childrenIds => $_getList(1);
}

class OutputUnitInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('OutputUnitInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..pPS(1, 'imports')
    ..hasRequiredFields = false;

  OutputUnitInfoPB() : super();
  OutputUnitInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  OutputUnitInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  OutputUnitInfoPB clone() => new OutputUnitInfoPB()..mergeFromMessage(this);
  OutputUnitInfoPB copyWith(void Function(OutputUnitInfoPB) updates) =>
      super.copyWith((message) => updates(message as OutputUnitInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static OutputUnitInfoPB create() => new OutputUnitInfoPB();
  static $pb.PbList<OutputUnitInfoPB> createRepeated() =>
      new $pb.PbList<OutputUnitInfoPB>();
  static OutputUnitInfoPB getDefault() =>
      _defaultInstance ??= create()..freeze();
  static OutputUnitInfoPB _defaultInstance;
  static void $checkItem(OutputUnitInfoPB v) {
    if (v is! OutputUnitInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<String> get imports => $_getList(0);
}

class ClassInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ClassInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOB(1, 'isAbstract')
    ..pPS(2, 'childrenIds')
    ..hasRequiredFields = false;

  ClassInfoPB() : super();
  ClassInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ClassInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ClassInfoPB clone() => new ClassInfoPB()..mergeFromMessage(this);
  ClassInfoPB copyWith(void Function(ClassInfoPB) updates) =>
      super.copyWith((message) => updates(message as ClassInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static ClassInfoPB create() => new ClassInfoPB();
  static $pb.PbList<ClassInfoPB> createRepeated() =>
      new $pb.PbList<ClassInfoPB>();
  static ClassInfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static ClassInfoPB _defaultInstance;
  static void $checkItem(ClassInfoPB v) {
    if (v is! ClassInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  bool get isAbstract => $_get(0, false);
  set isAbstract(bool v) {
    $_setBool(0, v);
  }

  bool hasIsAbstract() => $_has(0);
  void clearIsAbstract() => clearField(1);

  List<String> get childrenIds => $_getList(1);
}

class ConstantInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ConstantInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'code')
    ..hasRequiredFields = false;

  ConstantInfoPB() : super();
  ConstantInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ConstantInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ConstantInfoPB clone() => new ConstantInfoPB()..mergeFromMessage(this);
  ConstantInfoPB copyWith(void Function(ConstantInfoPB) updates) =>
      super.copyWith((message) => updates(message as ConstantInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static ConstantInfoPB create() => new ConstantInfoPB();
  static $pb.PbList<ConstantInfoPB> createRepeated() =>
      new $pb.PbList<ConstantInfoPB>();
  static ConstantInfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static ConstantInfoPB _defaultInstance;
  static void $checkItem(ConstantInfoPB v) {
    if (v is! ConstantInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get code => $_getS(0, '');
  set code(String v) {
    $_setString(0, v);
  }

  bool hasCode() => $_has(0);
  void clearCode() => clearField(1);
}

class FieldInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('FieldInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'type')
    ..aOS(2, 'inferredType')
    ..pPS(3, 'childrenIds')
    ..aOS(4, 'code')
    ..aOB(5, 'isConst')
    ..aOS(6, 'initializerId')
    ..hasRequiredFields = false;

  FieldInfoPB() : super();
  FieldInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  FieldInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  FieldInfoPB clone() => new FieldInfoPB()..mergeFromMessage(this);
  FieldInfoPB copyWith(void Function(FieldInfoPB) updates) =>
      super.copyWith((message) => updates(message as FieldInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static FieldInfoPB create() => new FieldInfoPB();
  static $pb.PbList<FieldInfoPB> createRepeated() =>
      new $pb.PbList<FieldInfoPB>();
  static FieldInfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static FieldInfoPB _defaultInstance;
  static void $checkItem(FieldInfoPB v) {
    if (v is! FieldInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get type => $_getS(0, '');
  set type(String v) {
    $_setString(0, v);
  }

  bool hasType() => $_has(0);
  void clearType() => clearField(1);

  String get inferredType => $_getS(1, '');
  set inferredType(String v) {
    $_setString(1, v);
  }

  bool hasInferredType() => $_has(1);
  void clearInferredType() => clearField(2);

  List<String> get childrenIds => $_getList(2);

  String get code => $_getS(3, '');
  set code(String v) {
    $_setString(3, v);
  }

  bool hasCode() => $_has(3);
  void clearCode() => clearField(4);

  bool get isConst => $_get(4, false);
  set isConst(bool v) {
    $_setBool(4, v);
  }

  bool hasIsConst() => $_has(4);
  void clearIsConst() => clearField(5);

  String get initializerId => $_getS(5, '');
  set initializerId(String v) {
    $_setString(5, v);
  }

  bool hasInitializerId() => $_has(5);
  void clearInitializerId() => clearField(6);
}

class TypedefInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('TypedefInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'type')
    ..hasRequiredFields = false;

  TypedefInfoPB() : super();
  TypedefInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  TypedefInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  TypedefInfoPB clone() => new TypedefInfoPB()..mergeFromMessage(this);
  TypedefInfoPB copyWith(void Function(TypedefInfoPB) updates) =>
      super.copyWith((message) => updates(message as TypedefInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static TypedefInfoPB create() => new TypedefInfoPB();
  static $pb.PbList<TypedefInfoPB> createRepeated() =>
      new $pb.PbList<TypedefInfoPB>();
  static TypedefInfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static TypedefInfoPB _defaultInstance;
  static void $checkItem(TypedefInfoPB v) {
    if (v is! TypedefInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get type => $_getS(0, '');
  set type(String v) {
    $_setString(0, v);
  }

  bool hasType() => $_has(0);
  void clearType() => clearField(1);
}

class FunctionModifiersPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('FunctionModifiersPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOB(1, 'isStatic')
    ..aOB(2, 'isConst')
    ..aOB(3, 'isFactory')
    ..aOB(4, 'isExternal')
    ..hasRequiredFields = false;

  FunctionModifiersPB() : super();
  FunctionModifiersPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  FunctionModifiersPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  FunctionModifiersPB clone() =>
      new FunctionModifiersPB()..mergeFromMessage(this);
  FunctionModifiersPB copyWith(void Function(FunctionModifiersPB) updates) =>
      super.copyWith((message) => updates(message as FunctionModifiersPB));
  $pb.BuilderInfo get info_ => _i;
  static FunctionModifiersPB create() => new FunctionModifiersPB();
  static $pb.PbList<FunctionModifiersPB> createRepeated() =>
      new $pb.PbList<FunctionModifiersPB>();
  static FunctionModifiersPB getDefault() =>
      _defaultInstance ??= create()..freeze();
  static FunctionModifiersPB _defaultInstance;
  static void $checkItem(FunctionModifiersPB v) {
    if (v is! FunctionModifiersPB)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  bool get isStatic => $_get(0, false);
  set isStatic(bool v) {
    $_setBool(0, v);
  }

  bool hasIsStatic() => $_has(0);
  void clearIsStatic() => clearField(1);

  bool get isConst => $_get(1, false);
  set isConst(bool v) {
    $_setBool(1, v);
  }

  bool hasIsConst() => $_has(1);
  void clearIsConst() => clearField(2);

  bool get isFactory => $_get(2, false);
  set isFactory(bool v) {
    $_setBool(2, v);
  }

  bool hasIsFactory() => $_has(2);
  void clearIsFactory() => clearField(3);

  bool get isExternal => $_get(3, false);
  set isExternal(bool v) {
    $_setBool(3, v);
  }

  bool hasIsExternal() => $_has(3);
  void clearIsExternal() => clearField(4);
}

class ParameterInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ParameterInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'name')
    ..aOS(2, 'type')
    ..aOS(3, 'declaredType')
    ..hasRequiredFields = false;

  ParameterInfoPB() : super();
  ParameterInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ParameterInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ParameterInfoPB clone() => new ParameterInfoPB()..mergeFromMessage(this);
  ParameterInfoPB copyWith(void Function(ParameterInfoPB) updates) =>
      super.copyWith((message) => updates(message as ParameterInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static ParameterInfoPB create() => new ParameterInfoPB();
  static $pb.PbList<ParameterInfoPB> createRepeated() =>
      new $pb.PbList<ParameterInfoPB>();
  static ParameterInfoPB getDefault() =>
      _defaultInstance ??= create()..freeze();
  static ParameterInfoPB _defaultInstance;
  static void $checkItem(ParameterInfoPB v) {
    if (v is! ParameterInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get name => $_getS(0, '');
  set name(String v) {
    $_setString(0, v);
  }

  bool hasName() => $_has(0);
  void clearName() => clearField(1);

  String get type => $_getS(1, '');
  set type(String v) {
    $_setString(1, v);
  }

  bool hasType() => $_has(1);
  void clearType() => clearField(2);

  String get declaredType => $_getS(2, '');
  set declaredType(String v) {
    $_setString(2, v);
  }

  bool hasDeclaredType() => $_has(2);
  void clearDeclaredType() => clearField(3);
}

class FunctionInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('FunctionInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..a<FunctionModifiersPB>(1, 'functionModifiers', $pb.PbFieldType.OM,
        FunctionModifiersPB.getDefault, FunctionModifiersPB.create)
    ..pPS(2, 'childrenIds')
    ..aOS(3, 'returnType')
    ..aOS(4, 'inferredReturnType')
    ..pp<ParameterInfoPB>(5, 'parameters', $pb.PbFieldType.PM,
        ParameterInfoPB.$checkItem, ParameterInfoPB.create)
    ..aOS(6, 'sideEffects')
    ..a<int>(7, 'inlinedCount', $pb.PbFieldType.O3)
    ..aOS(8, 'code')
    ..hasRequiredFields = false;

  FunctionInfoPB() : super();
  FunctionInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  FunctionInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  FunctionInfoPB clone() => new FunctionInfoPB()..mergeFromMessage(this);
  FunctionInfoPB copyWith(void Function(FunctionInfoPB) updates) =>
      super.copyWith((message) => updates(message as FunctionInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static FunctionInfoPB create() => new FunctionInfoPB();
  static $pb.PbList<FunctionInfoPB> createRepeated() =>
      new $pb.PbList<FunctionInfoPB>();
  static FunctionInfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static FunctionInfoPB _defaultInstance;
  static void $checkItem(FunctionInfoPB v) {
    if (v is! FunctionInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  FunctionModifiersPB get functionModifiers => $_getN(0);
  set functionModifiers(FunctionModifiersPB v) {
    setField(1, v);
  }

  bool hasFunctionModifiers() => $_has(0);
  void clearFunctionModifiers() => clearField(1);

  List<String> get childrenIds => $_getList(1);

  String get returnType => $_getS(2, '');
  set returnType(String v) {
    $_setString(2, v);
  }

  bool hasReturnType() => $_has(2);
  void clearReturnType() => clearField(3);

  String get inferredReturnType => $_getS(3, '');
  set inferredReturnType(String v) {
    $_setString(3, v);
  }

  bool hasInferredReturnType() => $_has(3);
  void clearInferredReturnType() => clearField(4);

  List<ParameterInfoPB> get parameters => $_getList(4);

  String get sideEffects => $_getS(5, '');
  set sideEffects(String v) {
    $_setString(5, v);
  }

  bool hasSideEffects() => $_has(5);
  void clearSideEffects() => clearField(6);

  int get inlinedCount => $_get(6, 0);
  set inlinedCount(int v) {
    $_setSignedInt32(6, v);
  }

  bool hasInlinedCount() => $_has(6);
  void clearInlinedCount() => clearField(7);

  String get code => $_getS(7, '');
  set code(String v) {
    $_setString(7, v);
  }

  bool hasCode() => $_has(7);
  void clearCode() => clearField(8);
}

class ClosureInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ClosureInfoPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'functionId')
    ..hasRequiredFields = false;

  ClosureInfoPB() : super();
  ClosureInfoPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ClosureInfoPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ClosureInfoPB clone() => new ClosureInfoPB()..mergeFromMessage(this);
  ClosureInfoPB copyWith(void Function(ClosureInfoPB) updates) =>
      super.copyWith((message) => updates(message as ClosureInfoPB));
  $pb.BuilderInfo get info_ => _i;
  static ClosureInfoPB create() => new ClosureInfoPB();
  static $pb.PbList<ClosureInfoPB> createRepeated() =>
      new $pb.PbList<ClosureInfoPB>();
  static ClosureInfoPB getDefault() => _defaultInstance ??= create()..freeze();
  static ClosureInfoPB _defaultInstance;
  static void $checkItem(ClosureInfoPB v) {
    if (v is! ClosureInfoPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get functionId => $_getS(0, '');
  set functionId(String v) {
    $_setString(0, v);
  }

  bool hasFunctionId() => $_has(0);
  void clearFunctionId() => clearField(1);
}

class DeferredImportPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('DeferredImportPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'prefix')
    ..pPS(2, 'files')
    ..hasRequiredFields = false;

  DeferredImportPB() : super();
  DeferredImportPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  DeferredImportPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  DeferredImportPB clone() => new DeferredImportPB()..mergeFromMessage(this);
  DeferredImportPB copyWith(void Function(DeferredImportPB) updates) =>
      super.copyWith((message) => updates(message as DeferredImportPB));
  $pb.BuilderInfo get info_ => _i;
  static DeferredImportPB create() => new DeferredImportPB();
  static $pb.PbList<DeferredImportPB> createRepeated() =>
      new $pb.PbList<DeferredImportPB>();
  static DeferredImportPB getDefault() =>
      _defaultInstance ??= create()..freeze();
  static DeferredImportPB _defaultInstance;
  static void $checkItem(DeferredImportPB v) {
    if (v is! DeferredImportPB) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get prefix => $_getS(0, '');
  set prefix(String v) {
    $_setString(0, v);
  }

  bool hasPrefix() => $_has(0);
  void clearPrefix() => clearField(1);

  List<String> get files => $_getList(1);
}

class LibraryDeferredImportsPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'LibraryDeferredImportsPB',
      package: const $pb.PackageName('dart2js_info.proto'))
    ..aOS(1, 'libraryUri')
    ..aOS(2, 'libraryName')
    ..pp<DeferredImportPB>(3, 'imports', $pb.PbFieldType.PM,
        DeferredImportPB.$checkItem, DeferredImportPB.create)
    ..hasRequiredFields = false;

  LibraryDeferredImportsPB() : super();
  LibraryDeferredImportsPB.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  LibraryDeferredImportsPB.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  LibraryDeferredImportsPB clone() =>
      new LibraryDeferredImportsPB()..mergeFromMessage(this);
  LibraryDeferredImportsPB copyWith(
          void Function(LibraryDeferredImportsPB) updates) =>
      super.copyWith((message) => updates(message as LibraryDeferredImportsPB));
  $pb.BuilderInfo get info_ => _i;
  static LibraryDeferredImportsPB create() => new LibraryDeferredImportsPB();
  static $pb.PbList<LibraryDeferredImportsPB> createRepeated() =>
      new $pb.PbList<LibraryDeferredImportsPB>();
  static LibraryDeferredImportsPB getDefault() =>
      _defaultInstance ??= create()..freeze();
  static LibraryDeferredImportsPB _defaultInstance;
  static void $checkItem(LibraryDeferredImportsPB v) {
    if (v is! LibraryDeferredImportsPB)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get libraryUri => $_getS(0, '');
  set libraryUri(String v) {
    $_setString(0, v);
  }

  bool hasLibraryUri() => $_has(0);
  void clearLibraryUri() => clearField(1);

  String get libraryName => $_getS(1, '');
  set libraryName(String v) {
    $_setString(1, v);
  }

  bool hasLibraryName() => $_has(1);
  void clearLibraryName() => clearField(2);

  List<DeferredImportPB> get imports => $_getList(2);
}
