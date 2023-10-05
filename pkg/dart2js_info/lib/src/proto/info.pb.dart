//  Generated code. Do not modify.
//  source: info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class DependencyInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DependencyInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'targetId')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'mask')
    ..hasRequiredFields = false;

  DependencyInfoPB._() : super();
  factory DependencyInfoPB({
    $core.String? targetId,
    $core.String? mask,
  }) {
    final result = create();
    if (targetId != null) {
      result.targetId = targetId;
    }
    if (mask != null) {
      result.mask = mask;
    }
    return result;
  }
  factory DependencyInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DependencyInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DependencyInfoPB clone() => DependencyInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DependencyInfoPB copyWith(void Function(DependencyInfoPB) updates) =>
      super.copyWith((message) => updates(message as DependencyInfoPB))
          as DependencyInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DependencyInfoPB create() => DependencyInfoPB._();
  DependencyInfoPB createEmptyInstance() => create();
  static $pb.PbList<DependencyInfoPB> createRepeated() =>
      $pb.PbList<DependencyInfoPB>();
  @$core.pragma('dart2js:noInline')
  static DependencyInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DependencyInfoPB>(create);
  static DependencyInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get targetId => $_getSZ(0);
  @$pb.TagNumber(1)
  set targetId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTargetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTargetId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get mask => $_getSZ(1);
  @$pb.TagNumber(2)
  set mask($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMask() => $_has(1);
  @$pb.TagNumber(2)
  void clearMask() => clearField(2);
}

class AllInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AllInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOM<ProgramInfoPB>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'program',
        subBuilder: ProgramInfoPB.create)
    ..m<$core.String, InfoPB>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'allInfos',
        entryClassName: 'AllInfoPB.AllInfosEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: InfoPB.create,
        packageName: const $pb.PackageName('dart2js_info.proto'))
    ..pc<LibraryDeferredImportsPB>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'deferredImports',
        $pb.PbFieldType.PM,
        subBuilder: LibraryDeferredImportsPB.create)
    ..hasRequiredFields = false;

  AllInfoPB._() : super();
  factory AllInfoPB({
    ProgramInfoPB? program,
    $core.Map<$core.String, InfoPB>? allInfos,
    $core.Iterable<LibraryDeferredImportsPB>? deferredImports,
  }) {
    final result = create();
    if (program != null) {
      result.program = program;
    }
    if (allInfos != null) {
      result.allInfos.addAll(allInfos);
    }
    if (deferredImports != null) {
      result.deferredImports.addAll(deferredImports);
    }
    return result;
  }
  factory AllInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AllInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AllInfoPB clone() => AllInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AllInfoPB copyWith(void Function(AllInfoPB) updates) =>
      super.copyWith((message) => updates(message as AllInfoPB))
          as AllInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AllInfoPB create() => AllInfoPB._();
  AllInfoPB createEmptyInstance() => create();
  static $pb.PbList<AllInfoPB> createRepeated() => $pb.PbList<AllInfoPB>();
  @$core.pragma('dart2js:noInline')
  static AllInfoPB getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AllInfoPB>(create);
  static AllInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  ProgramInfoPB get program => $_getN(0);
  @$pb.TagNumber(1)
  set program(ProgramInfoPB v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasProgram() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgram() => clearField(1);
  @$pb.TagNumber(1)
  ProgramInfoPB ensureProgram() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.Map<$core.String, InfoPB> get allInfos => $_getMap(1);

  @$pb.TagNumber(3)
  $core.List<LibraryDeferredImportsPB> get deferredImports => $_getList(2);
}

enum InfoPB_Concrete {
  libraryInfo,
  classInfo,
  functionInfo,
  fieldInfo,
  constantInfo,
  outputUnitInfo,
  typedefInfo,
  closureInfo,
  classTypeInfo,
  notSet
}

class InfoPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, InfoPB_Concrete> _InfoPB_ConcreteByTag = {
    100: InfoPB_Concrete.libraryInfo,
    101: InfoPB_Concrete.classInfo,
    102: InfoPB_Concrete.functionInfo,
    103: InfoPB_Concrete.fieldInfo,
    104: InfoPB_Concrete.constantInfo,
    105: InfoPB_Concrete.outputUnitInfo,
    106: InfoPB_Concrete.typedefInfo,
    107: InfoPB_Concrete.closureInfo,
    108: InfoPB_Concrete.classTypeInfo,
    0: InfoPB_Concrete.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'InfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..oo(0, [100, 101, 102, 103, 104, 105, 106, 107, 108])
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'id',
        $pb.PbFieldType.O3)
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'serializedId')
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'coverageId')
    ..a<$core.int>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'size',
        $pb.PbFieldType.O3)
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'parentId')
    ..pc<DependencyInfoPB>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uses',
        $pb.PbFieldType.PM,
        subBuilder: DependencyInfoPB.create)
    ..aOS(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'outputUnitId')
    ..aOM<LibraryInfoPB>(
        100,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'libraryInfo',
        subBuilder: LibraryInfoPB.create)
    ..aOM<ClassInfoPB>(
        101,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'classInfo',
        subBuilder: ClassInfoPB.create)
    ..aOM<FunctionInfoPB>(
        102,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'functionInfo',
        subBuilder: FunctionInfoPB.create)
    ..aOM<FieldInfoPB>(
        103,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'fieldInfo',
        subBuilder: FieldInfoPB.create)
    ..aOM<ConstantInfoPB>(
        104,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'constantInfo',
        subBuilder: ConstantInfoPB.create)
    ..aOM<OutputUnitInfoPB>(
        105,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'outputUnitInfo',
        subBuilder: OutputUnitInfoPB.create)
    ..aOM<TypedefInfoPB>(
        106,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'typedefInfo',
        subBuilder: TypedefInfoPB.create)
    ..aOM<ClosureInfoPB>(
        107,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'closureInfo',
        subBuilder: ClosureInfoPB.create)
    ..aOM<ClassTypeInfoPB>(
        108,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'classTypeInfo',
        subBuilder: ClassTypeInfoPB.create)
    ..hasRequiredFields = false;

  InfoPB._() : super();
  factory InfoPB({
    $core.String? name,
    $core.int? id,
    $core.String? serializedId,
    $core.String? coverageId,
    $core.int? size,
    $core.String? parentId,
    $core.Iterable<DependencyInfoPB>? uses,
    $core.String? outputUnitId,
    LibraryInfoPB? libraryInfo,
    ClassInfoPB? classInfo,
    FunctionInfoPB? functionInfo,
    FieldInfoPB? fieldInfo,
    ConstantInfoPB? constantInfo,
    OutputUnitInfoPB? outputUnitInfo,
    TypedefInfoPB? typedefInfo,
    ClosureInfoPB? closureInfo,
    ClassTypeInfoPB? classTypeInfo,
  }) {
    final result = create();
    if (name != null) {
      result.name = name;
    }
    if (id != null) {
      result.id = id;
    }
    if (serializedId != null) {
      result.serializedId = serializedId;
    }
    if (coverageId != null) {
      result.coverageId = coverageId;
    }
    if (size != null) {
      result.size = size;
    }
    if (parentId != null) {
      result.parentId = parentId;
    }
    if (uses != null) {
      result.uses.addAll(uses);
    }
    if (outputUnitId != null) {
      result.outputUnitId = outputUnitId;
    }
    if (libraryInfo != null) {
      result.libraryInfo = libraryInfo;
    }
    if (classInfo != null) {
      result.classInfo = classInfo;
    }
    if (functionInfo != null) {
      result.functionInfo = functionInfo;
    }
    if (fieldInfo != null) {
      result.fieldInfo = fieldInfo;
    }
    if (constantInfo != null) {
      result.constantInfo = constantInfo;
    }
    if (outputUnitInfo != null) {
      result.outputUnitInfo = outputUnitInfo;
    }
    if (typedefInfo != null) {
      result.typedefInfo = typedefInfo;
    }
    if (closureInfo != null) {
      result.closureInfo = closureInfo;
    }
    if (classTypeInfo != null) {
      result.classTypeInfo = classTypeInfo;
    }
    return result;
  }
  factory InfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InfoPB clone() => InfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InfoPB copyWith(void Function(InfoPB) updates) =>
      super.copyWith((message) => updates(message as InfoPB))
          as InfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InfoPB create() => InfoPB._();
  InfoPB createEmptyInstance() => create();
  static $pb.PbList<InfoPB> createRepeated() => $pb.PbList<InfoPB>();
  @$core.pragma('dart2js:noInline')
  static InfoPB getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InfoPB>(create);
  static InfoPB? _defaultInstance;

  InfoPB_Concrete whichConcrete() => _InfoPB_ConcreteByTag[$_whichOneof(0)]!;
  void clearConcrete() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get id => $_getIZ(1);
  @$pb.TagNumber(2)
  set id($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get serializedId => $_getSZ(2);
  @$pb.TagNumber(3)
  set serializedId($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSerializedId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSerializedId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get coverageId => $_getSZ(3);
  @$pb.TagNumber(4)
  set coverageId($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCoverageId() => $_has(3);
  @$pb.TagNumber(4)
  void clearCoverageId() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get size => $_getIZ(4);
  @$pb.TagNumber(5)
  set size($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearSize() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get parentId => $_getSZ(5);
  @$pb.TagNumber(6)
  set parentId($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasParentId() => $_has(5);
  @$pb.TagNumber(6)
  void clearParentId() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<DependencyInfoPB> get uses => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get outputUnitId => $_getSZ(7);
  @$pb.TagNumber(8)
  set outputUnitId($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasOutputUnitId() => $_has(7);
  @$pb.TagNumber(8)
  void clearOutputUnitId() => clearField(8);

  @$pb.TagNumber(100)
  LibraryInfoPB get libraryInfo => $_getN(8);
  @$pb.TagNumber(100)
  set libraryInfo(LibraryInfoPB v) {
    setField(100, v);
  }

  @$pb.TagNumber(100)
  $core.bool hasLibraryInfo() => $_has(8);
  @$pb.TagNumber(100)
  void clearLibraryInfo() => clearField(100);
  @$pb.TagNumber(100)
  LibraryInfoPB ensureLibraryInfo() => $_ensure(8);

  @$pb.TagNumber(101)
  ClassInfoPB get classInfo => $_getN(9);
  @$pb.TagNumber(101)
  set classInfo(ClassInfoPB v) {
    setField(101, v);
  }

  @$pb.TagNumber(101)
  $core.bool hasClassInfo() => $_has(9);
  @$pb.TagNumber(101)
  void clearClassInfo() => clearField(101);
  @$pb.TagNumber(101)
  ClassInfoPB ensureClassInfo() => $_ensure(9);

  @$pb.TagNumber(102)
  FunctionInfoPB get functionInfo => $_getN(10);
  @$pb.TagNumber(102)
  set functionInfo(FunctionInfoPB v) {
    setField(102, v);
  }

  @$pb.TagNumber(102)
  $core.bool hasFunctionInfo() => $_has(10);
  @$pb.TagNumber(102)
  void clearFunctionInfo() => clearField(102);
  @$pb.TagNumber(102)
  FunctionInfoPB ensureFunctionInfo() => $_ensure(10);

  @$pb.TagNumber(103)
  FieldInfoPB get fieldInfo => $_getN(11);
  @$pb.TagNumber(103)
  set fieldInfo(FieldInfoPB v) {
    setField(103, v);
  }

  @$pb.TagNumber(103)
  $core.bool hasFieldInfo() => $_has(11);
  @$pb.TagNumber(103)
  void clearFieldInfo() => clearField(103);
  @$pb.TagNumber(103)
  FieldInfoPB ensureFieldInfo() => $_ensure(11);

  @$pb.TagNumber(104)
  ConstantInfoPB get constantInfo => $_getN(12);
  @$pb.TagNumber(104)
  set constantInfo(ConstantInfoPB v) {
    setField(104, v);
  }

  @$pb.TagNumber(104)
  $core.bool hasConstantInfo() => $_has(12);
  @$pb.TagNumber(104)
  void clearConstantInfo() => clearField(104);
  @$pb.TagNumber(104)
  ConstantInfoPB ensureConstantInfo() => $_ensure(12);

  @$pb.TagNumber(105)
  OutputUnitInfoPB get outputUnitInfo => $_getN(13);
  @$pb.TagNumber(105)
  set outputUnitInfo(OutputUnitInfoPB v) {
    setField(105, v);
  }

  @$pb.TagNumber(105)
  $core.bool hasOutputUnitInfo() => $_has(13);
  @$pb.TagNumber(105)
  void clearOutputUnitInfo() => clearField(105);
  @$pb.TagNumber(105)
  OutputUnitInfoPB ensureOutputUnitInfo() => $_ensure(13);

  @$pb.TagNumber(106)
  TypedefInfoPB get typedefInfo => $_getN(14);
  @$pb.TagNumber(106)
  set typedefInfo(TypedefInfoPB v) {
    setField(106, v);
  }

  @$pb.TagNumber(106)
  $core.bool hasTypedefInfo() => $_has(14);
  @$pb.TagNumber(106)
  void clearTypedefInfo() => clearField(106);
  @$pb.TagNumber(106)
  TypedefInfoPB ensureTypedefInfo() => $_ensure(14);

  @$pb.TagNumber(107)
  ClosureInfoPB get closureInfo => $_getN(15);
  @$pb.TagNumber(107)
  set closureInfo(ClosureInfoPB v) {
    setField(107, v);
  }

  @$pb.TagNumber(107)
  $core.bool hasClosureInfo() => $_has(15);
  @$pb.TagNumber(107)
  void clearClosureInfo() => clearField(107);
  @$pb.TagNumber(107)
  ClosureInfoPB ensureClosureInfo() => $_ensure(15);

  @$pb.TagNumber(108)
  ClassTypeInfoPB get classTypeInfo => $_getN(16);
  @$pb.TagNumber(108)
  set classTypeInfo(ClassTypeInfoPB v) {
    setField(108, v);
  }

  @$pb.TagNumber(108)
  $core.bool hasClassTypeInfo() => $_has(16);
  @$pb.TagNumber(108)
  void clearClassTypeInfo() => clearField(108);
  @$pb.TagNumber(108)
  ClassTypeInfoPB ensureClassTypeInfo() => $_ensure(16);
}

class ProgramInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ProgramInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'entrypointId')
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'size',
        $pb.PbFieldType.O3)
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'dart2jsVersion')
    ..aInt64(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'compilationMoment')
    ..aInt64(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'compilationDuration')
    ..aInt64(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'toProtoDuration')
    ..aInt64(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'dumpInfoDuration')
    ..aOB(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'noSuchMethodEnabled')
    ..aOB(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isRuntimeTypeUsed')
    ..aOB(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isIsolateUsed')
    ..aOB(
        11,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isFunctionApplyUsed')
    ..aOB(
        12,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isMirrorsUsed')
    ..aOB(
        13,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'minified')
    ..hasRequiredFields = false;

  ProgramInfoPB._() : super();
  factory ProgramInfoPB({
    $core.String? entrypointId,
    $core.int? size,
    $core.String? dart2jsVersion,
    $fixnum.Int64? compilationMoment,
    $fixnum.Int64? compilationDuration,
    $fixnum.Int64? toProtoDuration,
    $fixnum.Int64? dumpInfoDuration,
    $core.bool? noSuchMethodEnabled,
    $core.bool? isRuntimeTypeUsed,
    $core.bool? isIsolateUsed,
    $core.bool? isFunctionApplyUsed,
    $core.bool? isMirrorsUsed,
    $core.bool? minified,
  }) {
    final result = create();
    if (entrypointId != null) {
      result.entrypointId = entrypointId;
    }
    if (size != null) {
      result.size = size;
    }
    if (dart2jsVersion != null) {
      result.dart2jsVersion = dart2jsVersion;
    }
    if (compilationMoment != null) {
      result.compilationMoment = compilationMoment;
    }
    if (compilationDuration != null) {
      result.compilationDuration = compilationDuration;
    }
    if (toProtoDuration != null) {
      result.toProtoDuration = toProtoDuration;
    }
    if (dumpInfoDuration != null) {
      result.dumpInfoDuration = dumpInfoDuration;
    }
    if (noSuchMethodEnabled != null) {
      result.noSuchMethodEnabled = noSuchMethodEnabled;
    }
    if (isRuntimeTypeUsed != null) {
      result.isRuntimeTypeUsed = isRuntimeTypeUsed;
    }
    if (isIsolateUsed != null) {
      result.isIsolateUsed = isIsolateUsed;
    }
    if (isFunctionApplyUsed != null) {
      result.isFunctionApplyUsed = isFunctionApplyUsed;
    }
    if (isMirrorsUsed != null) {
      result.isMirrorsUsed = isMirrorsUsed;
    }
    if (minified != null) {
      result.minified = minified;
    }
    return result;
  }
  factory ProgramInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ProgramInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ProgramInfoPB clone() => ProgramInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ProgramInfoPB copyWith(void Function(ProgramInfoPB) updates) =>
      super.copyWith((message) => updates(message as ProgramInfoPB))
          as ProgramInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ProgramInfoPB create() => ProgramInfoPB._();
  ProgramInfoPB createEmptyInstance() => create();
  static $pb.PbList<ProgramInfoPB> createRepeated() =>
      $pb.PbList<ProgramInfoPB>();
  @$core.pragma('dart2js:noInline')
  static ProgramInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProgramInfoPB>(create);
  static ProgramInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entrypointId => $_getSZ(0);
  @$pb.TagNumber(1)
  set entrypointId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEntrypointId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntrypointId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get size => $_getIZ(1);
  @$pb.TagNumber(2)
  set size($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearSize() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get dart2jsVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set dart2jsVersion($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDart2jsVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearDart2jsVersion() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get compilationMoment => $_getI64(3);
  @$pb.TagNumber(4)
  set compilationMoment($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCompilationMoment() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompilationMoment() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get compilationDuration => $_getI64(4);
  @$pb.TagNumber(5)
  set compilationDuration($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCompilationDuration() => $_has(4);
  @$pb.TagNumber(5)
  void clearCompilationDuration() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get toProtoDuration => $_getI64(5);
  @$pb.TagNumber(6)
  set toProtoDuration($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasToProtoDuration() => $_has(5);
  @$pb.TagNumber(6)
  void clearToProtoDuration() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get dumpInfoDuration => $_getI64(6);
  @$pb.TagNumber(7)
  set dumpInfoDuration($fixnum.Int64 v) {
    $_setInt64(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDumpInfoDuration() => $_has(6);
  @$pb.TagNumber(7)
  void clearDumpInfoDuration() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get noSuchMethodEnabled => $_getBF(7);
  @$pb.TagNumber(8)
  set noSuchMethodEnabled($core.bool v) {
    $_setBool(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasNoSuchMethodEnabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearNoSuchMethodEnabled() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isRuntimeTypeUsed => $_getBF(8);
  @$pb.TagNumber(9)
  set isRuntimeTypeUsed($core.bool v) {
    $_setBool(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasIsRuntimeTypeUsed() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsRuntimeTypeUsed() => clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isIsolateUsed => $_getBF(9);
  @$pb.TagNumber(10)
  set isIsolateUsed($core.bool v) {
    $_setBool(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasIsIsolateUsed() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsIsolateUsed() => clearField(10);

  @$pb.TagNumber(11)
  $core.bool get isFunctionApplyUsed => $_getBF(10);
  @$pb.TagNumber(11)
  set isFunctionApplyUsed($core.bool v) {
    $_setBool(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasIsFunctionApplyUsed() => $_has(10);
  @$pb.TagNumber(11)
  void clearIsFunctionApplyUsed() => clearField(11);

  @$pb.TagNumber(12)
  $core.bool get isMirrorsUsed => $_getBF(11);
  @$pb.TagNumber(12)
  set isMirrorsUsed($core.bool v) {
    $_setBool(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasIsMirrorsUsed() => $_has(11);
  @$pb.TagNumber(12)
  void clearIsMirrorsUsed() => clearField(12);

  @$pb.TagNumber(13)
  $core.bool get minified => $_getBF(12);
  @$pb.TagNumber(13)
  set minified($core.bool v) {
    $_setBool(12, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasMinified() => $_has(12);
  @$pb.TagNumber(13)
  void clearMinified() => clearField(13);
}

class LibraryInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'LibraryInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uri')
    ..pPS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'childrenIds')
    ..hasRequiredFields = false;

  LibraryInfoPB._() : super();
  factory LibraryInfoPB({
    $core.String? uri,
    $core.Iterable<$core.String>? childrenIds,
  }) {
    final result = create();
    if (uri != null) {
      result.uri = uri;
    }
    if (childrenIds != null) {
      result.childrenIds.addAll(childrenIds);
    }
    return result;
  }
  factory LibraryInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LibraryInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LibraryInfoPB clone() => LibraryInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LibraryInfoPB copyWith(void Function(LibraryInfoPB) updates) =>
      super.copyWith((message) => updates(message as LibraryInfoPB))
          as LibraryInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LibraryInfoPB create() => LibraryInfoPB._();
  LibraryInfoPB createEmptyInstance() => create();
  static $pb.PbList<LibraryInfoPB> createRepeated() =>
      $pb.PbList<LibraryInfoPB>();
  @$core.pragma('dart2js:noInline')
  static LibraryInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LibraryInfoPB>(create);
  static LibraryInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get childrenIds => $_getList(1);
}

class OutputUnitInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'OutputUnitInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..pPS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'imports')
    ..hasRequiredFields = false;

  OutputUnitInfoPB._() : super();
  factory OutputUnitInfoPB({
    $core.Iterable<$core.String>? imports,
  }) {
    final result = create();
    if (imports != null) {
      result.imports.addAll(imports);
    }
    return result;
  }
  factory OutputUnitInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory OutputUnitInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  OutputUnitInfoPB clone() => OutputUnitInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  OutputUnitInfoPB copyWith(void Function(OutputUnitInfoPB) updates) =>
      super.copyWith((message) => updates(message as OutputUnitInfoPB))
          as OutputUnitInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static OutputUnitInfoPB create() => OutputUnitInfoPB._();
  OutputUnitInfoPB createEmptyInstance() => create();
  static $pb.PbList<OutputUnitInfoPB> createRepeated() =>
      $pb.PbList<OutputUnitInfoPB>();
  @$core.pragma('dart2js:noInline')
  static OutputUnitInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputUnitInfoPB>(create);
  static OutputUnitInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get imports => $_getList(0);
}

class ClassInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ClassInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOB(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isAbstract')
    ..pPS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'childrenIds')
    ..hasRequiredFields = false;

  ClassInfoPB._() : super();
  factory ClassInfoPB({
    $core.bool? isAbstract,
    $core.Iterable<$core.String>? childrenIds,
  }) {
    final result = create();
    if (isAbstract != null) {
      result.isAbstract = isAbstract;
    }
    if (childrenIds != null) {
      result.childrenIds.addAll(childrenIds);
    }
    return result;
  }
  factory ClassInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClassInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClassInfoPB clone() => ClassInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClassInfoPB copyWith(void Function(ClassInfoPB) updates) =>
      super.copyWith((message) => updates(message as ClassInfoPB))
          as ClassInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ClassInfoPB create() => ClassInfoPB._();
  ClassInfoPB createEmptyInstance() => create();
  static $pb.PbList<ClassInfoPB> createRepeated() => $pb.PbList<ClassInfoPB>();
  @$core.pragma('dart2js:noInline')
  static ClassInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClassInfoPB>(create);
  static ClassInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isAbstract => $_getBF(0);
  @$pb.TagNumber(1)
  set isAbstract($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIsAbstract() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsAbstract() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get childrenIds => $_getList(1);
}

class ClassTypeInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ClassTypeInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  ClassTypeInfoPB._() : super();
  factory ClassTypeInfoPB() => create();
  factory ClassTypeInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClassTypeInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClassTypeInfoPB clone() => ClassTypeInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClassTypeInfoPB copyWith(void Function(ClassTypeInfoPB) updates) =>
      super.copyWith((message) => updates(message as ClassTypeInfoPB))
          as ClassTypeInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ClassTypeInfoPB create() => ClassTypeInfoPB._();
  ClassTypeInfoPB createEmptyInstance() => create();
  static $pb.PbList<ClassTypeInfoPB> createRepeated() =>
      $pb.PbList<ClassTypeInfoPB>();
  @$core.pragma('dart2js:noInline')
  static ClassTypeInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClassTypeInfoPB>(create);
  static ClassTypeInfoPB? _defaultInstance;
}

class ConstantInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ConstantInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'code')
    ..hasRequiredFields = false;

  ConstantInfoPB._() : super();
  factory ConstantInfoPB({
    $core.String? code,
  }) {
    final result = create();
    if (code != null) {
      result.code = code;
    }
    return result;
  }
  factory ConstantInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ConstantInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConstantInfoPB clone() => ConstantInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConstantInfoPB copyWith(void Function(ConstantInfoPB) updates) =>
      super.copyWith((message) => updates(message as ConstantInfoPB))
          as ConstantInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ConstantInfoPB create() => ConstantInfoPB._();
  ConstantInfoPB createEmptyInstance() => create();
  static $pb.PbList<ConstantInfoPB> createRepeated() =>
      $pb.PbList<ConstantInfoPB>();
  @$core.pragma('dart2js:noInline')
  static ConstantInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConstantInfoPB>(create);
  static ConstantInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);
}

class FieldInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FieldInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'inferredType')
    ..pPS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'childrenIds')
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'code')
    ..aOB(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isConst')
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'initializerId')
    ..hasRequiredFields = false;

  FieldInfoPB._() : super();
  factory FieldInfoPB({
    $core.String? type,
    $core.String? inferredType,
    $core.Iterable<$core.String>? childrenIds,
    $core.String? code,
    $core.bool? isConst,
    $core.String? initializerId,
  }) {
    final result = create();
    if (type != null) {
      result.type = type;
    }
    if (inferredType != null) {
      result.inferredType = inferredType;
    }
    if (childrenIds != null) {
      result.childrenIds.addAll(childrenIds);
    }
    if (code != null) {
      result.code = code;
    }
    if (isConst != null) {
      result.isConst = isConst;
    }
    if (initializerId != null) {
      result.initializerId = initializerId;
    }
    return result;
  }
  factory FieldInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FieldInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FieldInfoPB clone() => FieldInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FieldInfoPB copyWith(void Function(FieldInfoPB) updates) =>
      super.copyWith((message) => updates(message as FieldInfoPB))
          as FieldInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldInfoPB create() => FieldInfoPB._();
  FieldInfoPB createEmptyInstance() => create();
  static $pb.PbList<FieldInfoPB> createRepeated() => $pb.PbList<FieldInfoPB>();
  @$core.pragma('dart2js:noInline')
  static FieldInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FieldInfoPB>(create);
  static FieldInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get inferredType => $_getSZ(1);
  @$pb.TagNumber(2)
  set inferredType($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasInferredType() => $_has(1);
  @$pb.TagNumber(2)
  void clearInferredType() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get childrenIds => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get code => $_getSZ(3);
  @$pb.TagNumber(4)
  set code($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearCode() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isConst => $_getBF(4);
  @$pb.TagNumber(5)
  set isConst($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasIsConst() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsConst() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get initializerId => $_getSZ(5);
  @$pb.TagNumber(6)
  set initializerId($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasInitializerId() => $_has(5);
  @$pb.TagNumber(6)
  void clearInitializerId() => clearField(6);
}

class TypedefInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'TypedefInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..hasRequiredFields = false;

  TypedefInfoPB._() : super();
  factory TypedefInfoPB({
    $core.String? type,
  }) {
    final result = create();
    if (type != null) {
      result.type = type;
    }
    return result;
  }
  factory TypedefInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TypedefInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TypedefInfoPB clone() => TypedefInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TypedefInfoPB copyWith(void Function(TypedefInfoPB) updates) =>
      super.copyWith((message) => updates(message as TypedefInfoPB))
          as TypedefInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TypedefInfoPB create() => TypedefInfoPB._();
  TypedefInfoPB createEmptyInstance() => create();
  static $pb.PbList<TypedefInfoPB> createRepeated() =>
      $pb.PbList<TypedefInfoPB>();
  @$core.pragma('dart2js:noInline')
  static TypedefInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TypedefInfoPB>(create);
  static TypedefInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);
}

class FunctionModifiersPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FunctionModifiersPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOB(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isStatic')
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isConst')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isFactory')
    ..aOB(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'isExternal')
    ..hasRequiredFields = false;

  FunctionModifiersPB._() : super();
  factory FunctionModifiersPB({
    $core.bool? isStatic,
    $core.bool? isConst,
    $core.bool? isFactory,
    $core.bool? isExternal,
  }) {
    final result = create();
    if (isStatic != null) {
      result.isStatic = isStatic;
    }
    if (isConst != null) {
      result.isConst = isConst;
    }
    if (isFactory != null) {
      result.isFactory = isFactory;
    }
    if (isExternal != null) {
      result.isExternal = isExternal;
    }
    return result;
  }
  factory FunctionModifiersPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FunctionModifiersPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FunctionModifiersPB clone() => FunctionModifiersPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FunctionModifiersPB copyWith(void Function(FunctionModifiersPB) updates) =>
      super.copyWith((message) => updates(message as FunctionModifiersPB))
          as FunctionModifiersPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FunctionModifiersPB create() => FunctionModifiersPB._();
  FunctionModifiersPB createEmptyInstance() => create();
  static $pb.PbList<FunctionModifiersPB> createRepeated() =>
      $pb.PbList<FunctionModifiersPB>();
  @$core.pragma('dart2js:noInline')
  static FunctionModifiersPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FunctionModifiersPB>(create);
  static FunctionModifiersPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isStatic => $_getBF(0);
  @$pb.TagNumber(1)
  set isStatic($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIsStatic() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsStatic() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isConst => $_getBF(1);
  @$pb.TagNumber(2)
  set isConst($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasIsConst() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsConst() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isFactory => $_getBF(2);
  @$pb.TagNumber(3)
  set isFactory($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasIsFactory() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsFactory() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isExternal => $_getBF(3);
  @$pb.TagNumber(4)
  set isExternal($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasIsExternal() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsExternal() => clearField(4);
}

class ParameterInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ParameterInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'declaredType')
    ..hasRequiredFields = false;

  ParameterInfoPB._() : super();
  factory ParameterInfoPB({
    $core.String? name,
    $core.String? type,
    $core.String? declaredType,
  }) {
    final result = create();
    if (name != null) {
      result.name = name;
    }
    if (type != null) {
      result.type = type;
    }
    if (declaredType != null) {
      result.declaredType = declaredType;
    }
    return result;
  }
  factory ParameterInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParameterInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParameterInfoPB clone() => ParameterInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParameterInfoPB copyWith(void Function(ParameterInfoPB) updates) =>
      super.copyWith((message) => updates(message as ParameterInfoPB))
          as ParameterInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ParameterInfoPB create() => ParameterInfoPB._();
  ParameterInfoPB createEmptyInstance() => create();
  static $pb.PbList<ParameterInfoPB> createRepeated() =>
      $pb.PbList<ParameterInfoPB>();
  @$core.pragma('dart2js:noInline')
  static ParameterInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParameterInfoPB>(create);
  static ParameterInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get declaredType => $_getSZ(2);
  @$pb.TagNumber(3)
  set declaredType($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDeclaredType() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeclaredType() => clearField(3);
}

class FunctionInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FunctionInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOM<FunctionModifiersPB>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'functionModifiers',
        subBuilder: FunctionModifiersPB.create)
    ..pPS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'childrenIds')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'returnType')
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'inferredReturnType')
    ..pc<ParameterInfoPB>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'parameters',
        $pb.PbFieldType.PM,
        subBuilder: ParameterInfoPB.create)
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sideEffects')
    ..a<$core.int>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'inlinedCount',
        $pb.PbFieldType.O3)
    ..aOS(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'code')
    ..hasRequiredFields = false;

  FunctionInfoPB._() : super();
  factory FunctionInfoPB({
    FunctionModifiersPB? functionModifiers,
    $core.Iterable<$core.String>? childrenIds,
    $core.String? returnType,
    $core.String? inferredReturnType,
    $core.Iterable<ParameterInfoPB>? parameters,
    $core.String? sideEffects,
    $core.int? inlinedCount,
    $core.String? code,
  }) {
    final result = create();
    if (functionModifiers != null) {
      result.functionModifiers = functionModifiers;
    }
    if (childrenIds != null) {
      result.childrenIds.addAll(childrenIds);
    }
    if (returnType != null) {
      result.returnType = returnType;
    }
    if (inferredReturnType != null) {
      result.inferredReturnType = inferredReturnType;
    }
    if (parameters != null) {
      result.parameters.addAll(parameters);
    }
    if (sideEffects != null) {
      result.sideEffects = sideEffects;
    }
    if (inlinedCount != null) {
      result.inlinedCount = inlinedCount;
    }
    if (code != null) {
      result.code = code;
    }
    return result;
  }
  factory FunctionInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FunctionInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FunctionInfoPB clone() => FunctionInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FunctionInfoPB copyWith(void Function(FunctionInfoPB) updates) =>
      super.copyWith((message) => updates(message as FunctionInfoPB))
          as FunctionInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FunctionInfoPB create() => FunctionInfoPB._();
  FunctionInfoPB createEmptyInstance() => create();
  static $pb.PbList<FunctionInfoPB> createRepeated() =>
      $pb.PbList<FunctionInfoPB>();
  @$core.pragma('dart2js:noInline')
  static FunctionInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FunctionInfoPB>(create);
  static FunctionInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  FunctionModifiersPB get functionModifiers => $_getN(0);
  @$pb.TagNumber(1)
  set functionModifiers(FunctionModifiersPB v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFunctionModifiers() => $_has(0);
  @$pb.TagNumber(1)
  void clearFunctionModifiers() => clearField(1);
  @$pb.TagNumber(1)
  FunctionModifiersPB ensureFunctionModifiers() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get childrenIds => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get returnType => $_getSZ(2);
  @$pb.TagNumber(3)
  set returnType($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasReturnType() => $_has(2);
  @$pb.TagNumber(3)
  void clearReturnType() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get inferredReturnType => $_getSZ(3);
  @$pb.TagNumber(4)
  set inferredReturnType($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasInferredReturnType() => $_has(3);
  @$pb.TagNumber(4)
  void clearInferredReturnType() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<ParameterInfoPB> get parameters => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get sideEffects => $_getSZ(5);
  @$pb.TagNumber(6)
  set sideEffects($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasSideEffects() => $_has(5);
  @$pb.TagNumber(6)
  void clearSideEffects() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get inlinedCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set inlinedCount($core.int v) {
    $_setSignedInt32(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasInlinedCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearInlinedCount() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get code => $_getSZ(7);
  @$pb.TagNumber(8)
  set code($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasCode() => $_has(7);
  @$pb.TagNumber(8)
  void clearCode() => clearField(8);
}

class ClosureInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ClosureInfoPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'functionId')
    ..hasRequiredFields = false;

  ClosureInfoPB._() : super();
  factory ClosureInfoPB({
    $core.String? functionId,
  }) {
    final result = create();
    if (functionId != null) {
      result.functionId = functionId;
    }
    return result;
  }
  factory ClosureInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClosureInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClosureInfoPB clone() => ClosureInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClosureInfoPB copyWith(void Function(ClosureInfoPB) updates) =>
      super.copyWith((message) => updates(message as ClosureInfoPB))
          as ClosureInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ClosureInfoPB create() => ClosureInfoPB._();
  ClosureInfoPB createEmptyInstance() => create();
  static $pb.PbList<ClosureInfoPB> createRepeated() =>
      $pb.PbList<ClosureInfoPB>();
  @$core.pragma('dart2js:noInline')
  static ClosureInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClosureInfoPB>(create);
  static ClosureInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get functionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set functionId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFunctionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFunctionId() => clearField(1);
}

class DeferredImportPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DeferredImportPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'prefix')
    ..pPS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'files')
    ..hasRequiredFields = false;

  DeferredImportPB._() : super();
  factory DeferredImportPB({
    $core.String? prefix,
    $core.Iterable<$core.String>? files,
  }) {
    final result = create();
    if (prefix != null) {
      result.prefix = prefix;
    }
    if (files != null) {
      result.files.addAll(files);
    }
    return result;
  }
  factory DeferredImportPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DeferredImportPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DeferredImportPB clone() => DeferredImportPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DeferredImportPB copyWith(void Function(DeferredImportPB) updates) =>
      super.copyWith((message) => updates(message as DeferredImportPB))
          as DeferredImportPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeferredImportPB create() => DeferredImportPB._();
  DeferredImportPB createEmptyInstance() => create();
  static $pb.PbList<DeferredImportPB> createRepeated() =>
      $pb.PbList<DeferredImportPB>();
  @$core.pragma('dart2js:noInline')
  static DeferredImportPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeferredImportPB>(create);
  static DeferredImportPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get prefix => $_getSZ(0);
  @$pb.TagNumber(1)
  set prefix($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPrefix() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefix() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get files => $_getList(1);
}

class LibraryDeferredImportsPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'LibraryDeferredImportsPB',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'libraryUri')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'libraryName')
    ..pc<DeferredImportPB>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'imports',
        $pb.PbFieldType.PM,
        subBuilder: DeferredImportPB.create)
    ..hasRequiredFields = false;

  LibraryDeferredImportsPB._() : super();
  factory LibraryDeferredImportsPB({
    $core.String? libraryUri,
    $core.String? libraryName,
    $core.Iterable<DeferredImportPB>? imports,
  }) {
    final result = create();
    if (libraryUri != null) {
      result.libraryUri = libraryUri;
    }
    if (libraryName != null) {
      result.libraryName = libraryName;
    }
    if (imports != null) {
      result.imports.addAll(imports);
    }
    return result;
  }
  factory LibraryDeferredImportsPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LibraryDeferredImportsPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LibraryDeferredImportsPB clone() =>
      LibraryDeferredImportsPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LibraryDeferredImportsPB copyWith(
          void Function(LibraryDeferredImportsPB) updates) =>
      super.copyWith((message) => updates(message as LibraryDeferredImportsPB))
          as LibraryDeferredImportsPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LibraryDeferredImportsPB create() => LibraryDeferredImportsPB._();
  LibraryDeferredImportsPB createEmptyInstance() => create();
  static $pb.PbList<LibraryDeferredImportsPB> createRepeated() =>
      $pb.PbList<LibraryDeferredImportsPB>();
  @$core.pragma('dart2js:noInline')
  static LibraryDeferredImportsPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LibraryDeferredImportsPB>(create);
  static LibraryDeferredImportsPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get libraryUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set libraryUri($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasLibraryUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearLibraryUri() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get libraryName => $_getSZ(1);
  @$pb.TagNumber(2)
  set libraryName($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLibraryName() => $_has(1);
  @$pb.TagNumber(2)
  void clearLibraryName() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<DeferredImportPB> get imports => $_getList(2);
}
