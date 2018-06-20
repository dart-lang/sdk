///
//  Generated code. Do not modify.
///
// ignore_for_file: non_constant_identifier_names,library_prefixes

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

class DependencyInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('DependencyInfoPB')
    ..aOS(1, 'targetId')
    ..aOS(2, 'mask')
    ..hasRequiredFields = false;

  DependencyInfoPB() : super();
  DependencyInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  DependencyInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  DependencyInfoPB clone() => new DependencyInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static DependencyInfoPB create() => new DependencyInfoPB();
  static PbList<DependencyInfoPB> createRepeated() =>
      new PbList<DependencyInfoPB>();
  static DependencyInfoPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyDependencyInfoPB();
    return _defaultInstance;
  }

  static DependencyInfoPB _defaultInstance;
  static void $checkItem(DependencyInfoPB v) {
    if (v is! DependencyInfoPB) checkItemFailed(v, 'DependencyInfoPB');
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

class _ReadonlyDependencyInfoPB extends DependencyInfoPB
    with ReadonlyMessageMixin {}

class AllInfoPB_AllInfosEntry extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('AllInfoPB_AllInfosEntry')
    ..aOS(1, 'key')
    ..a<InfoPB>(2, 'value', PbFieldType.OM, InfoPB.getDefault, InfoPB.create)
    ..hasRequiredFields = false;

  AllInfoPB_AllInfosEntry() : super();
  AllInfoPB_AllInfosEntry.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  AllInfoPB_AllInfosEntry.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  AllInfoPB_AllInfosEntry clone() =>
      new AllInfoPB_AllInfosEntry()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static AllInfoPB_AllInfosEntry create() => new AllInfoPB_AllInfosEntry();
  static PbList<AllInfoPB_AllInfosEntry> createRepeated() =>
      new PbList<AllInfoPB_AllInfosEntry>();
  static AllInfoPB_AllInfosEntry getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyAllInfoPB_AllInfosEntry();
    return _defaultInstance;
  }

  static AllInfoPB_AllInfosEntry _defaultInstance;
  static void $checkItem(AllInfoPB_AllInfosEntry v) {
    if (v is! AllInfoPB_AllInfosEntry)
      checkItemFailed(v, 'AllInfoPB_AllInfosEntry');
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

class _ReadonlyAllInfoPB_AllInfosEntry extends AllInfoPB_AllInfosEntry
    with ReadonlyMessageMixin {}

class AllInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('AllInfoPB')
    ..a<ProgramInfoPB>(1, 'program', PbFieldType.OM, ProgramInfoPB.getDefault,
        ProgramInfoPB.create)
    ..pp<AllInfoPB_AllInfosEntry>(2, 'allInfos', PbFieldType.PM,
        AllInfoPB_AllInfosEntry.$checkItem, AllInfoPB_AllInfosEntry.create)
    ..hasRequiredFields = false;

  AllInfoPB() : super();
  AllInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  AllInfoPB.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  AllInfoPB clone() => new AllInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static AllInfoPB create() => new AllInfoPB();
  static PbList<AllInfoPB> createRepeated() => new PbList<AllInfoPB>();
  static AllInfoPB getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyAllInfoPB();
    return _defaultInstance;
  }

  static AllInfoPB _defaultInstance;
  static void $checkItem(AllInfoPB v) {
    if (v is! AllInfoPB) checkItemFailed(v, 'AllInfoPB');
  }

  ProgramInfoPB get program => $_getN(0);
  set program(ProgramInfoPB v) {
    setField(1, v);
  }

  bool hasProgram() => $_has(0);
  void clearProgram() => clearField(1);

  List<AllInfoPB_AllInfosEntry> get allInfos => $_getList(1);
}

class _ReadonlyAllInfoPB extends AllInfoPB with ReadonlyMessageMixin {}

class InfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('InfoPB')
    ..aOS(1, 'name')
    ..a<int>(2, 'id', PbFieldType.O3)
    ..aOS(3, 'serializedId')
    ..aOS(4, 'coverageId')
    ..a<int>(5, 'size', PbFieldType.O3)
    ..aOS(6, 'parentId')
    ..pp<DependencyInfoPB>(7, 'uses', PbFieldType.PM,
        DependencyInfoPB.$checkItem, DependencyInfoPB.create)
    ..a<LibraryInfoPB>(100, 'libraryInfo', PbFieldType.OM,
        LibraryInfoPB.getDefault, LibraryInfoPB.create)
    ..a<ClassInfoPB>(101, 'classInfo', PbFieldType.OM, ClassInfoPB.getDefault,
        ClassInfoPB.create)
    ..a<FunctionInfoPB>(102, 'functionInfo', PbFieldType.OM,
        FunctionInfoPB.getDefault, FunctionInfoPB.create)
    ..a<FieldInfoPB>(103, 'fieldInfo', PbFieldType.OM, FieldInfoPB.getDefault,
        FieldInfoPB.create)
    ..a<ConstantInfoPB>(104, 'constantInfo', PbFieldType.OM,
        ConstantInfoPB.getDefault, ConstantInfoPB.create)
    ..a<OutputUnitInfoPB>(105, 'outputUnitInfo', PbFieldType.OM,
        OutputUnitInfoPB.getDefault, OutputUnitInfoPB.create)
    ..a<TypedefInfoPB>(106, 'typedefInfo', PbFieldType.OM,
        TypedefInfoPB.getDefault, TypedefInfoPB.create)
    ..a<ClosureInfoPB>(107, 'closureInfo', PbFieldType.OM,
        ClosureInfoPB.getDefault, ClosureInfoPB.create)
    ..hasRequiredFields = false;

  InfoPB() : super();
  InfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  InfoPB.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  InfoPB clone() => new InfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static InfoPB create() => new InfoPB();
  static PbList<InfoPB> createRepeated() => new PbList<InfoPB>();
  static InfoPB getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyInfoPB();
    return _defaultInstance;
  }

  static InfoPB _defaultInstance;
  static void $checkItem(InfoPB v) {
    if (v is! InfoPB) checkItemFailed(v, 'InfoPB');
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

  LibraryInfoPB get libraryInfo => $_getN(7);
  set libraryInfo(LibraryInfoPB v) {
    setField(100, v);
  }

  bool hasLibraryInfo() => $_has(7);
  void clearLibraryInfo() => clearField(100);

  ClassInfoPB get classInfo => $_getN(8);
  set classInfo(ClassInfoPB v) {
    setField(101, v);
  }

  bool hasClassInfo() => $_has(8);
  void clearClassInfo() => clearField(101);

  FunctionInfoPB get functionInfo => $_getN(9);
  set functionInfo(FunctionInfoPB v) {
    setField(102, v);
  }

  bool hasFunctionInfo() => $_has(9);
  void clearFunctionInfo() => clearField(102);

  FieldInfoPB get fieldInfo => $_getN(10);
  set fieldInfo(FieldInfoPB v) {
    setField(103, v);
  }

  bool hasFieldInfo() => $_has(10);
  void clearFieldInfo() => clearField(103);

  ConstantInfoPB get constantInfo => $_getN(11);
  set constantInfo(ConstantInfoPB v) {
    setField(104, v);
  }

  bool hasConstantInfo() => $_has(11);
  void clearConstantInfo() => clearField(104);

  OutputUnitInfoPB get outputUnitInfo => $_getN(12);
  set outputUnitInfo(OutputUnitInfoPB v) {
    setField(105, v);
  }

  bool hasOutputUnitInfo() => $_has(12);
  void clearOutputUnitInfo() => clearField(105);

  TypedefInfoPB get typedefInfo => $_getN(13);
  set typedefInfo(TypedefInfoPB v) {
    setField(106, v);
  }

  bool hasTypedefInfo() => $_has(13);
  void clearTypedefInfo() => clearField(106);

  ClosureInfoPB get closureInfo => $_getN(14);
  set closureInfo(ClosureInfoPB v) {
    setField(107, v);
  }

  bool hasClosureInfo() => $_has(14);
  void clearClosureInfo() => clearField(107);
}

class _ReadonlyInfoPB extends InfoPB with ReadonlyMessageMixin {}

class ProgramInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('ProgramInfoPB')
    ..aOS(1, 'entrypointId')
    ..a<int>(2, 'size', PbFieldType.O3)
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
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ProgramInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ProgramInfoPB clone() => new ProgramInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static ProgramInfoPB create() => new ProgramInfoPB();
  static PbList<ProgramInfoPB> createRepeated() => new PbList<ProgramInfoPB>();
  static ProgramInfoPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyProgramInfoPB();
    return _defaultInstance;
  }

  static ProgramInfoPB _defaultInstance;
  static void $checkItem(ProgramInfoPB v) {
    if (v is! ProgramInfoPB) checkItemFailed(v, 'ProgramInfoPB');
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

class _ReadonlyProgramInfoPB extends ProgramInfoPB with ReadonlyMessageMixin {}

class LibraryInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('LibraryInfoPB')
    ..aOS(1, 'uri')
    ..pPS(2, 'childrenIds')
    ..hasRequiredFields = false;

  LibraryInfoPB() : super();
  LibraryInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  LibraryInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  LibraryInfoPB clone() => new LibraryInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static LibraryInfoPB create() => new LibraryInfoPB();
  static PbList<LibraryInfoPB> createRepeated() => new PbList<LibraryInfoPB>();
  static LibraryInfoPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyLibraryInfoPB();
    return _defaultInstance;
  }

  static LibraryInfoPB _defaultInstance;
  static void $checkItem(LibraryInfoPB v) {
    if (v is! LibraryInfoPB) checkItemFailed(v, 'LibraryInfoPB');
  }

  String get uri => $_getS(0, '');
  set uri(String v) {
    $_setString(0, v);
  }

  bool hasUri() => $_has(0);
  void clearUri() => clearField(1);

  List<String> get childrenIds => $_getList(1);
}

class _ReadonlyLibraryInfoPB extends LibraryInfoPB with ReadonlyMessageMixin {}

class OutputUnitInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('OutputUnitInfoPB')
    ..pPS(1, 'imports')
    ..hasRequiredFields = false;

  OutputUnitInfoPB() : super();
  OutputUnitInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  OutputUnitInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  OutputUnitInfoPB clone() => new OutputUnitInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static OutputUnitInfoPB create() => new OutputUnitInfoPB();
  static PbList<OutputUnitInfoPB> createRepeated() =>
      new PbList<OutputUnitInfoPB>();
  static OutputUnitInfoPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyOutputUnitInfoPB();
    return _defaultInstance;
  }

  static OutputUnitInfoPB _defaultInstance;
  static void $checkItem(OutputUnitInfoPB v) {
    if (v is! OutputUnitInfoPB) checkItemFailed(v, 'OutputUnitInfoPB');
  }

  List<String> get imports => $_getList(0);
}

class _ReadonlyOutputUnitInfoPB extends OutputUnitInfoPB
    with ReadonlyMessageMixin {}

class ClassInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('ClassInfoPB')
    ..aOB(1, 'isAbstract')
    ..pPS(2, 'childrenIds')
    ..hasRequiredFields = false;

  ClassInfoPB() : super();
  ClassInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ClassInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ClassInfoPB clone() => new ClassInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static ClassInfoPB create() => new ClassInfoPB();
  static PbList<ClassInfoPB> createRepeated() => new PbList<ClassInfoPB>();
  static ClassInfoPB getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyClassInfoPB();
    return _defaultInstance;
  }

  static ClassInfoPB _defaultInstance;
  static void $checkItem(ClassInfoPB v) {
    if (v is! ClassInfoPB) checkItemFailed(v, 'ClassInfoPB');
  }

  bool get isAbstract => $_get(0, false);
  set isAbstract(bool v) {
    $_setBool(0, v);
  }

  bool hasIsAbstract() => $_has(0);
  void clearIsAbstract() => clearField(1);

  List<String> get childrenIds => $_getList(1);
}

class _ReadonlyClassInfoPB extends ClassInfoPB with ReadonlyMessageMixin {}

class ConstantInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('ConstantInfoPB')
    ..aOS(1, 'code')
    ..hasRequiredFields = false;

  ConstantInfoPB() : super();
  ConstantInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ConstantInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ConstantInfoPB clone() => new ConstantInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static ConstantInfoPB create() => new ConstantInfoPB();
  static PbList<ConstantInfoPB> createRepeated() =>
      new PbList<ConstantInfoPB>();
  static ConstantInfoPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyConstantInfoPB();
    return _defaultInstance;
  }

  static ConstantInfoPB _defaultInstance;
  static void $checkItem(ConstantInfoPB v) {
    if (v is! ConstantInfoPB) checkItemFailed(v, 'ConstantInfoPB');
  }

  String get code => $_getS(0, '');
  set code(String v) {
    $_setString(0, v);
  }

  bool hasCode() => $_has(0);
  void clearCode() => clearField(1);
}

class _ReadonlyConstantInfoPB extends ConstantInfoPB with ReadonlyMessageMixin {
}

class FieldInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('FieldInfoPB')
    ..aOS(1, 'type')
    ..aOS(2, 'inferredType')
    ..pPS(3, 'childrenIds')
    ..aOS(4, 'code')
    ..aOB(5, 'isConst')
    ..aOS(6, 'initializerId')
    ..hasRequiredFields = false;

  FieldInfoPB() : super();
  FieldInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  FieldInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  FieldInfoPB clone() => new FieldInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static FieldInfoPB create() => new FieldInfoPB();
  static PbList<FieldInfoPB> createRepeated() => new PbList<FieldInfoPB>();
  static FieldInfoPB getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyFieldInfoPB();
    return _defaultInstance;
  }

  static FieldInfoPB _defaultInstance;
  static void $checkItem(FieldInfoPB v) {
    if (v is! FieldInfoPB) checkItemFailed(v, 'FieldInfoPB');
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

class _ReadonlyFieldInfoPB extends FieldInfoPB with ReadonlyMessageMixin {}

class TypedefInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('TypedefInfoPB')
    ..aOS(1, 'type')
    ..hasRequiredFields = false;

  TypedefInfoPB() : super();
  TypedefInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  TypedefInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  TypedefInfoPB clone() => new TypedefInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static TypedefInfoPB create() => new TypedefInfoPB();
  static PbList<TypedefInfoPB> createRepeated() => new PbList<TypedefInfoPB>();
  static TypedefInfoPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyTypedefInfoPB();
    return _defaultInstance;
  }

  static TypedefInfoPB _defaultInstance;
  static void $checkItem(TypedefInfoPB v) {
    if (v is! TypedefInfoPB) checkItemFailed(v, 'TypedefInfoPB');
  }

  String get type => $_getS(0, '');
  set type(String v) {
    $_setString(0, v);
  }

  bool hasType() => $_has(0);
  void clearType() => clearField(1);
}

class _ReadonlyTypedefInfoPB extends TypedefInfoPB with ReadonlyMessageMixin {}

class FunctionModifiersPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('FunctionModifiersPB')
    ..aOB(1, 'isStatic')
    ..aOB(2, 'isConst')
    ..aOB(3, 'isFactory')
    ..aOB(4, 'isExternal')
    ..hasRequiredFields = false;

  FunctionModifiersPB() : super();
  FunctionModifiersPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  FunctionModifiersPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  FunctionModifiersPB clone() =>
      new FunctionModifiersPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static FunctionModifiersPB create() => new FunctionModifiersPB();
  static PbList<FunctionModifiersPB> createRepeated() =>
      new PbList<FunctionModifiersPB>();
  static FunctionModifiersPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyFunctionModifiersPB();
    return _defaultInstance;
  }

  static FunctionModifiersPB _defaultInstance;
  static void $checkItem(FunctionModifiersPB v) {
    if (v is! FunctionModifiersPB) checkItemFailed(v, 'FunctionModifiersPB');
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

class _ReadonlyFunctionModifiersPB extends FunctionModifiersPB
    with ReadonlyMessageMixin {}

class ParameterInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('ParameterInfoPB')
    ..aOS(1, 'name')
    ..aOS(2, 'type')
    ..aOS(3, 'declaredType')
    ..hasRequiredFields = false;

  ParameterInfoPB() : super();
  ParameterInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ParameterInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ParameterInfoPB clone() => new ParameterInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static ParameterInfoPB create() => new ParameterInfoPB();
  static PbList<ParameterInfoPB> createRepeated() =>
      new PbList<ParameterInfoPB>();
  static ParameterInfoPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyParameterInfoPB();
    return _defaultInstance;
  }

  static ParameterInfoPB _defaultInstance;
  static void $checkItem(ParameterInfoPB v) {
    if (v is! ParameterInfoPB) checkItemFailed(v, 'ParameterInfoPB');
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

class _ReadonlyParameterInfoPB extends ParameterInfoPB
    with ReadonlyMessageMixin {}

class MeasurementEntryPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('MeasurementEntryPB')
    ..aOS(1, 'name')
    ..p<int>(2, 'values', PbFieldType.P3)
    ..hasRequiredFields = false;

  MeasurementEntryPB() : super();
  MeasurementEntryPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MeasurementEntryPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MeasurementEntryPB clone() =>
      new MeasurementEntryPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static MeasurementEntryPB create() => new MeasurementEntryPB();
  static PbList<MeasurementEntryPB> createRepeated() =>
      new PbList<MeasurementEntryPB>();
  static MeasurementEntryPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyMeasurementEntryPB();
    return _defaultInstance;
  }

  static MeasurementEntryPB _defaultInstance;
  static void $checkItem(MeasurementEntryPB v) {
    if (v is! MeasurementEntryPB) checkItemFailed(v, 'MeasurementEntryPB');
  }

  String get name => $_getS(0, '');
  set name(String v) {
    $_setString(0, v);
  }

  bool hasName() => $_has(0);
  void clearName() => clearField(1);

  List<int> get values => $_getList(1);
}

class _ReadonlyMeasurementEntryPB extends MeasurementEntryPB
    with ReadonlyMessageMixin {}

class MeasurementCounterPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('MeasurementCounterPB')
    ..aOS(1, 'name')
    ..a<int>(2, 'value', PbFieldType.O3)
    ..hasRequiredFields = false;

  MeasurementCounterPB() : super();
  MeasurementCounterPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MeasurementCounterPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MeasurementCounterPB clone() =>
      new MeasurementCounterPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static MeasurementCounterPB create() => new MeasurementCounterPB();
  static PbList<MeasurementCounterPB> createRepeated() =>
      new PbList<MeasurementCounterPB>();
  static MeasurementCounterPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyMeasurementCounterPB();
    return _defaultInstance;
  }

  static MeasurementCounterPB _defaultInstance;
  static void $checkItem(MeasurementCounterPB v) {
    if (v is! MeasurementCounterPB) checkItemFailed(v, 'MeasurementCounterPB');
  }

  String get name => $_getS(0, '');
  set name(String v) {
    $_setString(0, v);
  }

  bool hasName() => $_has(0);
  void clearName() => clearField(1);

  int get value => $_get(1, 0);
  set value(int v) {
    $_setSignedInt32(1, v);
  }

  bool hasValue() => $_has(1);
  void clearValue() => clearField(2);
}

class _ReadonlyMeasurementCounterPB extends MeasurementCounterPB
    with ReadonlyMessageMixin {}

class MeasurementsPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('MeasurementsPB')
    ..aOS(1, 'sourceFile')
    ..pp<MeasurementEntryPB>(2, 'entries', PbFieldType.PM,
        MeasurementEntryPB.$checkItem, MeasurementEntryPB.create)
    ..pp<MeasurementCounterPB>(3, 'counters', PbFieldType.PM,
        MeasurementCounterPB.$checkItem, MeasurementCounterPB.create)
    ..hasRequiredFields = false;

  MeasurementsPB() : super();
  MeasurementsPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MeasurementsPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MeasurementsPB clone() => new MeasurementsPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static MeasurementsPB create() => new MeasurementsPB();
  static PbList<MeasurementsPB> createRepeated() =>
      new PbList<MeasurementsPB>();
  static MeasurementsPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyMeasurementsPB();
    return _defaultInstance;
  }

  static MeasurementsPB _defaultInstance;
  static void $checkItem(MeasurementsPB v) {
    if (v is! MeasurementsPB) checkItemFailed(v, 'MeasurementsPB');
  }

  String get sourceFile => $_getS(0, '');
  set sourceFile(String v) {
    $_setString(0, v);
  }

  bool hasSourceFile() => $_has(0);
  void clearSourceFile() => clearField(1);

  List<MeasurementEntryPB> get entries => $_getList(1);

  List<MeasurementCounterPB> get counters => $_getList(2);
}

class _ReadonlyMeasurementsPB extends MeasurementsPB with ReadonlyMessageMixin {
}

class FunctionInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('FunctionInfoPB')
    ..a<FunctionModifiersPB>(1, 'functionModifiers', PbFieldType.OM,
        FunctionModifiersPB.getDefault, FunctionModifiersPB.create)
    ..pPS(2, 'childrenIds')
    ..aOS(3, 'returnType')
    ..aOS(4, 'inferredReturnType')
    ..pp<ParameterInfoPB>(5, 'parameters', PbFieldType.PM,
        ParameterInfoPB.$checkItem, ParameterInfoPB.create)
    ..aOS(6, 'sideEffects')
    ..a<int>(7, 'inlinedCount', PbFieldType.O3)
    ..aOS(8, 'code')
    ..a<MeasurementsPB>(9, 'measurements', PbFieldType.OM,
        MeasurementsPB.getDefault, MeasurementsPB.create)
    ..hasRequiredFields = false;

  FunctionInfoPB() : super();
  FunctionInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  FunctionInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  FunctionInfoPB clone() => new FunctionInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static FunctionInfoPB create() => new FunctionInfoPB();
  static PbList<FunctionInfoPB> createRepeated() =>
      new PbList<FunctionInfoPB>();
  static FunctionInfoPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyFunctionInfoPB();
    return _defaultInstance;
  }

  static FunctionInfoPB _defaultInstance;
  static void $checkItem(FunctionInfoPB v) {
    if (v is! FunctionInfoPB) checkItemFailed(v, 'FunctionInfoPB');
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

  MeasurementsPB get measurements => $_getN(8);
  set measurements(MeasurementsPB v) {
    setField(9, v);
  }

  bool hasMeasurements() => $_has(8);
  void clearMeasurements() => clearField(9);
}

class _ReadonlyFunctionInfoPB extends FunctionInfoPB with ReadonlyMessageMixin {
}

class ClosureInfoPB extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('ClosureInfoPB')
    ..aOS(1, 'functionId')
    ..hasRequiredFields = false;

  ClosureInfoPB() : super();
  ClosureInfoPB.fromBuffer(List<int> i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ClosureInfoPB.fromJson(String i,
      [ExtensionRegistry r = ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ClosureInfoPB clone() => new ClosureInfoPB()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static ClosureInfoPB create() => new ClosureInfoPB();
  static PbList<ClosureInfoPB> createRepeated() => new PbList<ClosureInfoPB>();
  static ClosureInfoPB getDefault() {
    if (_defaultInstance == null)
      _defaultInstance = new _ReadonlyClosureInfoPB();
    return _defaultInstance;
  }

  static ClosureInfoPB _defaultInstance;
  static void $checkItem(ClosureInfoPB v) {
    if (v is! ClosureInfoPB) checkItemFailed(v, 'ClosureInfoPB');
  }

  String get functionId => $_getS(0, '');
  set functionId(String v) {
    $_setString(0, v);
  }

  bool hasFunctionId() => $_has(0);
  void clearFunctionId() => clearField(1);
}

class _ReadonlyClosureInfoPB extends ClosureInfoPB with ReadonlyMessageMixin {}
