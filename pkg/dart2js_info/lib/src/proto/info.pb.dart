//
//  Generated code. Do not modify.
//  source: info.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class DependencyInfoPB extends $pb.GeneratedMessage {
  factory DependencyInfoPB({
    $core.String? targetId,
    $core.String? mask,
  }) {
    final $result = create();
    if (targetId != null) {
      $result.targetId = targetId;
    }
    if (mask != null) {
      $result.mask = mask;
    }
    return $result;
  }
  DependencyInfoPB._() : super();
  factory DependencyInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DependencyInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DependencyInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'targetId')
    ..aOS(2, _omitFieldNames ? '' : 'mask')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DependencyInfoPB clone() => DependencyInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DependencyInfoPB copyWith(void Function(DependencyInfoPB) updates) =>
      super.copyWith((message) => updates(message as DependencyInfoPB))
          as DependencyInfoPB;

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

  /// * The dependency element's serialized_id, references as FunctionInfo or FieldInfo.
  @$pb.TagNumber(1)
  $core.String get targetId => $_getSZ(0);
  @$pb.TagNumber(1)
  set targetId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTargetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTargetId() => $_clearField(1);

  /// * Either a selector mask indicating how this is used, or 'inlined'.
  @$pb.TagNumber(2)
  $core.String get mask => $_getSZ(1);
  @$pb.TagNumber(2)
  set mask($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMask() => $_has(1);
  @$pb.TagNumber(2)
  void clearMask() => $_clearField(2);
}

/// * The entire information produced when compiling a program.
class AllInfoPB extends $pb.GeneratedMessage {
  factory AllInfoPB({
    ProgramInfoPB? program,
    $pb.PbMap<$core.String, InfoPB>? allInfos,
    $core.Iterable<LibraryDeferredImportsPB>? deferredImports,
  }) {
    final $result = create();
    if (program != null) {
      $result.program = program;
    }
    if (allInfos != null) {
      $result.allInfos.addAll(allInfos);
    }
    if (deferredImports != null) {
      $result.deferredImports.addAll(deferredImports);
    }
    return $result;
  }
  AllInfoPB._() : super();
  factory AllInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AllInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AllInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOM<ProgramInfoPB>(1, _omitFieldNames ? '' : 'program',
        subBuilder: ProgramInfoPB.create)
    ..m<$core.String, InfoPB>(2, _omitFieldNames ? '' : 'allInfos',
        entryClassName: 'AllInfoPB.AllInfosEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: InfoPB.create,
        valueDefaultOrMaker: InfoPB.getDefault,
        packageName: const $pb.PackageName('dart2js_info.proto'))
    ..pc<LibraryDeferredImportsPB>(
        3, _omitFieldNames ? '' : 'deferredImports', $pb.PbFieldType.PM,
        subBuilder: LibraryDeferredImportsPB.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AllInfoPB clone() => AllInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AllInfoPB copyWith(void Function(AllInfoPB) updates) =>
      super.copyWith((message) => updates(message as AllInfoPB)) as AllInfoPB;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AllInfoPB create() => AllInfoPB._();
  AllInfoPB createEmptyInstance() => create();
  static $pb.PbList<AllInfoPB> createRepeated() => $pb.PbList<AllInfoPB>();
  @$core.pragma('dart2js:noInline')
  static AllInfoPB getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AllInfoPB>(create);
  static AllInfoPB? _defaultInstance;

  /// * Summary information about the program.
  @$pb.TagNumber(1)
  ProgramInfoPB get program => $_getN(0);
  @$pb.TagNumber(1)
  set program(ProgramInfoPB v) {
    $_setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasProgram() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgram() => $_clearField(1);
  @$pb.TagNumber(1)
  ProgramInfoPB ensureProgram() => $_ensure(0);

  /// * All the recorded information about elements processed by the compiler.
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, InfoPB> get allInfos => $_getMap(1);

  /// * Details about all deferred imports and what files would be loaded when the import is resolved.
  @$pb.TagNumber(3)
  $pb.PbList<LibraryDeferredImportsPB> get deferredImports => $_getList(2);
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

///
///  Common interface to many pieces of information generated by the dart2js
///  compiler that are directly associated with an element (compilation unit,
///  library, class, function, or field).
class InfoPB extends $pb.GeneratedMessage {
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
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (id != null) {
      $result.id = id;
    }
    if (serializedId != null) {
      $result.serializedId = serializedId;
    }
    if (coverageId != null) {
      $result.coverageId = coverageId;
    }
    if (size != null) {
      $result.size = size;
    }
    if (parentId != null) {
      $result.parentId = parentId;
    }
    if (uses != null) {
      $result.uses.addAll(uses);
    }
    if (outputUnitId != null) {
      $result.outputUnitId = outputUnitId;
    }
    if (libraryInfo != null) {
      $result.libraryInfo = libraryInfo;
    }
    if (classInfo != null) {
      $result.classInfo = classInfo;
    }
    if (functionInfo != null) {
      $result.functionInfo = functionInfo;
    }
    if (fieldInfo != null) {
      $result.fieldInfo = fieldInfo;
    }
    if (constantInfo != null) {
      $result.constantInfo = constantInfo;
    }
    if (outputUnitInfo != null) {
      $result.outputUnitInfo = outputUnitInfo;
    }
    if (typedefInfo != null) {
      $result.typedefInfo = typedefInfo;
    }
    if (closureInfo != null) {
      $result.closureInfo = closureInfo;
    }
    if (classTypeInfo != null) {
      $result.classTypeInfo = classTypeInfo;
    }
    return $result;
  }
  InfoPB._() : super();
  factory InfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

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
      _omitMessageNames ? '' : 'InfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..oo(0, [100, 101, 102, 103, 104, 105, 106, 107, 108])
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'id', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'serializedId')
    ..aOS(4, _omitFieldNames ? '' : 'coverageId')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'size', $pb.PbFieldType.O3)
    ..aOS(6, _omitFieldNames ? '' : 'parentId')
    ..pc<DependencyInfoPB>(7, _omitFieldNames ? '' : 'uses', $pb.PbFieldType.PM,
        subBuilder: DependencyInfoPB.create)
    ..aOS(8, _omitFieldNames ? '' : 'outputUnitId')
    ..aOM<LibraryInfoPB>(100, _omitFieldNames ? '' : 'libraryInfo',
        subBuilder: LibraryInfoPB.create)
    ..aOM<ClassInfoPB>(101, _omitFieldNames ? '' : 'classInfo',
        subBuilder: ClassInfoPB.create)
    ..aOM<FunctionInfoPB>(102, _omitFieldNames ? '' : 'functionInfo',
        subBuilder: FunctionInfoPB.create)
    ..aOM<FieldInfoPB>(103, _omitFieldNames ? '' : 'fieldInfo',
        subBuilder: FieldInfoPB.create)
    ..aOM<ConstantInfoPB>(104, _omitFieldNames ? '' : 'constantInfo',
        subBuilder: ConstantInfoPB.create)
    ..aOM<OutputUnitInfoPB>(105, _omitFieldNames ? '' : 'outputUnitInfo',
        subBuilder: OutputUnitInfoPB.create)
    ..aOM<TypedefInfoPB>(106, _omitFieldNames ? '' : 'typedefInfo',
        subBuilder: TypedefInfoPB.create)
    ..aOM<ClosureInfoPB>(107, _omitFieldNames ? '' : 'closureInfo',
        subBuilder: ClosureInfoPB.create)
    ..aOM<ClassTypeInfoPB>(108, _omitFieldNames ? '' : 'classTypeInfo',
        subBuilder: ClassTypeInfoPB.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InfoPB clone() => InfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InfoPB copyWith(void Function(InfoPB) updates) =>
      super.copyWith((message) => updates(message as InfoPB)) as InfoPB;

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
  void clearConcrete() => $_clearField($_whichOneof(0));

  /// * Name of the element associated with this info.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// * An id to uniquely identify this info among infos of the same kind.
  @$pb.TagNumber(2)
  $core.int get id => $_getIZ(1);
  @$pb.TagNumber(2)
  set id($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  /// * A globally unique id which combines kind and id together.
  @$pb.TagNumber(3)
  $core.String get serializedId => $_getSZ(2);
  @$pb.TagNumber(3)
  set serializedId($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSerializedId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSerializedId() => $_clearField(3);

  /// * Id used by the compiler when instrumenting code for code coverage.
  @$pb.TagNumber(4)
  $core.String get coverageId => $_getSZ(3);
  @$pb.TagNumber(4)
  set coverageId($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCoverageId() => $_has(3);
  @$pb.TagNumber(4)
  void clearCoverageId() => $_clearField(4);

  /// * Bytes used in the generated code for the corresponding element.
  @$pb.TagNumber(5)
  $core.int get size => $_getIZ(4);
  @$pb.TagNumber(5)
  set size($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearSize() => $_clearField(5);

  /// * The serialized_id of the enclosing element.
  @$pb.TagNumber(6)
  $core.String get parentId => $_getSZ(5);
  @$pb.TagNumber(6)
  set parentId($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasParentId() => $_has(5);
  @$pb.TagNumber(6)
  void clearParentId() => $_clearField(6);

  /// * How does this function or field depend on others.
  @$pb.TagNumber(7)
  $pb.PbList<DependencyInfoPB> get uses => $_getList(6);

  /// * The serialized_id of the output unit the element is generated into.
  @$pb.TagNumber(8)
  $core.String get outputUnitId => $_getSZ(7);
  @$pb.TagNumber(8)
  set outputUnitId($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasOutputUnitId() => $_has(7);
  @$pb.TagNumber(8)
  void clearOutputUnitId() => $_clearField(8);

  /// * Information about a library element.
  @$pb.TagNumber(100)
  LibraryInfoPB get libraryInfo => $_getN(8);
  @$pb.TagNumber(100)
  set libraryInfo(LibraryInfoPB v) {
    $_setField(100, v);
  }

  @$pb.TagNumber(100)
  $core.bool hasLibraryInfo() => $_has(8);
  @$pb.TagNumber(100)
  void clearLibraryInfo() => $_clearField(100);
  @$pb.TagNumber(100)
  LibraryInfoPB ensureLibraryInfo() => $_ensure(8);

  /// * Information about a class element.
  @$pb.TagNumber(101)
  ClassInfoPB get classInfo => $_getN(9);
  @$pb.TagNumber(101)
  set classInfo(ClassInfoPB v) {
    $_setField(101, v);
  }

  @$pb.TagNumber(101)
  $core.bool hasClassInfo() => $_has(9);
  @$pb.TagNumber(101)
  void clearClassInfo() => $_clearField(101);
  @$pb.TagNumber(101)
  ClassInfoPB ensureClassInfo() => $_ensure(9);

  /// * Information about a function element.
  @$pb.TagNumber(102)
  FunctionInfoPB get functionInfo => $_getN(10);
  @$pb.TagNumber(102)
  set functionInfo(FunctionInfoPB v) {
    $_setField(102, v);
  }

  @$pb.TagNumber(102)
  $core.bool hasFunctionInfo() => $_has(10);
  @$pb.TagNumber(102)
  void clearFunctionInfo() => $_clearField(102);
  @$pb.TagNumber(102)
  FunctionInfoPB ensureFunctionInfo() => $_ensure(10);

  /// * Information about a field element.
  @$pb.TagNumber(103)
  FieldInfoPB get fieldInfo => $_getN(11);
  @$pb.TagNumber(103)
  set fieldInfo(FieldInfoPB v) {
    $_setField(103, v);
  }

  @$pb.TagNumber(103)
  $core.bool hasFieldInfo() => $_has(11);
  @$pb.TagNumber(103)
  void clearFieldInfo() => $_clearField(103);
  @$pb.TagNumber(103)
  FieldInfoPB ensureFieldInfo() => $_ensure(11);

  /// * Information about a constant element.
  @$pb.TagNumber(104)
  ConstantInfoPB get constantInfo => $_getN(12);
  @$pb.TagNumber(104)
  set constantInfo(ConstantInfoPB v) {
    $_setField(104, v);
  }

  @$pb.TagNumber(104)
  $core.bool hasConstantInfo() => $_has(12);
  @$pb.TagNumber(104)
  void clearConstantInfo() => $_clearField(104);
  @$pb.TagNumber(104)
  ConstantInfoPB ensureConstantInfo() => $_ensure(12);

  /// * Information about an output unit element.
  @$pb.TagNumber(105)
  OutputUnitInfoPB get outputUnitInfo => $_getN(13);
  @$pb.TagNumber(105)
  set outputUnitInfo(OutputUnitInfoPB v) {
    $_setField(105, v);
  }

  @$pb.TagNumber(105)
  $core.bool hasOutputUnitInfo() => $_has(13);
  @$pb.TagNumber(105)
  void clearOutputUnitInfo() => $_clearField(105);
  @$pb.TagNumber(105)
  OutputUnitInfoPB ensureOutputUnitInfo() => $_ensure(13);

  /// * Information about a typedef element.
  @$pb.TagNumber(106)
  TypedefInfoPB get typedefInfo => $_getN(14);
  @$pb.TagNumber(106)
  set typedefInfo(TypedefInfoPB v) {
    $_setField(106, v);
  }

  @$pb.TagNumber(106)
  $core.bool hasTypedefInfo() => $_has(14);
  @$pb.TagNumber(106)
  void clearTypedefInfo() => $_clearField(106);
  @$pb.TagNumber(106)
  TypedefInfoPB ensureTypedefInfo() => $_ensure(14);

  /// * Information about a closure element.
  @$pb.TagNumber(107)
  ClosureInfoPB get closureInfo => $_getN(15);
  @$pb.TagNumber(107)
  set closureInfo(ClosureInfoPB v) {
    $_setField(107, v);
  }

  @$pb.TagNumber(107)
  $core.bool hasClosureInfo() => $_has(15);
  @$pb.TagNumber(107)
  void clearClosureInfo() => $_clearField(107);
  @$pb.TagNumber(107)
  ClosureInfoPB ensureClosureInfo() => $_ensure(15);

  /// * Information about a class type element.
  @$pb.TagNumber(108)
  ClassTypeInfoPB get classTypeInfo => $_getN(16);
  @$pb.TagNumber(108)
  set classTypeInfo(ClassTypeInfoPB v) {
    $_setField(108, v);
  }

  @$pb.TagNumber(108)
  $core.bool hasClassTypeInfo() => $_has(16);
  @$pb.TagNumber(108)
  void clearClassTypeInfo() => $_clearField(108);
  @$pb.TagNumber(108)
  ClassTypeInfoPB ensureClassTypeInfo() => $_ensure(16);
}

/// * General metadata about the dart2js invocation.
class ProgramInfoPB extends $pb.GeneratedMessage {
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
    final $result = create();
    if (entrypointId != null) {
      $result.entrypointId = entrypointId;
    }
    if (size != null) {
      $result.size = size;
    }
    if (dart2jsVersion != null) {
      $result.dart2jsVersion = dart2jsVersion;
    }
    if (compilationMoment != null) {
      $result.compilationMoment = compilationMoment;
    }
    if (compilationDuration != null) {
      $result.compilationDuration = compilationDuration;
    }
    if (toProtoDuration != null) {
      $result.toProtoDuration = toProtoDuration;
    }
    if (dumpInfoDuration != null) {
      $result.dumpInfoDuration = dumpInfoDuration;
    }
    if (noSuchMethodEnabled != null) {
      $result.noSuchMethodEnabled = noSuchMethodEnabled;
    }
    if (isRuntimeTypeUsed != null) {
      $result.isRuntimeTypeUsed = isRuntimeTypeUsed;
    }
    if (isIsolateUsed != null) {
      $result.isIsolateUsed = isIsolateUsed;
    }
    if (isFunctionApplyUsed != null) {
      $result.isFunctionApplyUsed = isFunctionApplyUsed;
    }
    if (isMirrorsUsed != null) {
      $result.isMirrorsUsed = isMirrorsUsed;
    }
    if (minified != null) {
      $result.minified = minified;
    }
    return $result;
  }
  ProgramInfoPB._() : super();
  factory ProgramInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ProgramInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProgramInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'entrypointId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'size', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'dart2jsVersion')
    ..aInt64(4, _omitFieldNames ? '' : 'compilationMoment')
    ..aInt64(5, _omitFieldNames ? '' : 'compilationDuration')
    ..aInt64(6, _omitFieldNames ? '' : 'toProtoDuration')
    ..aInt64(7, _omitFieldNames ? '' : 'dumpInfoDuration')
    ..aOB(8, _omitFieldNames ? '' : 'noSuchMethodEnabled')
    ..aOB(9, _omitFieldNames ? '' : 'isRuntimeTypeUsed')
    ..aOB(10, _omitFieldNames ? '' : 'isIsolateUsed')
    ..aOB(11, _omitFieldNames ? '' : 'isFunctionApplyUsed')
    ..aOB(12, _omitFieldNames ? '' : 'isMirrorsUsed')
    ..aOB(13, _omitFieldNames ? '' : 'minified')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ProgramInfoPB clone() => ProgramInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ProgramInfoPB copyWith(void Function(ProgramInfoPB) updates) =>
      super.copyWith((message) => updates(message as ProgramInfoPB))
          as ProgramInfoPB;

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

  /// * serialized_id for the entrypoint FunctionInfo.
  @$pb.TagNumber(1)
  $core.String get entrypointId => $_getSZ(0);
  @$pb.TagNumber(1)
  set entrypointId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEntrypointId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntrypointId() => $_clearField(1);

  /// * The overall size of the dart2js binary.
  @$pb.TagNumber(2)
  $core.int get size => $_getIZ(1);
  @$pb.TagNumber(2)
  set size($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearSize() => $_clearField(2);

  /// * The version of dart2js used to compile the program.
  @$pb.TagNumber(3)
  $core.String get dart2jsVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set dart2jsVersion($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDart2jsVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearDart2jsVersion() => $_clearField(3);

  /// * The time at which the compilation was performed in microseconds since epoch.
  @$pb.TagNumber(4)
  $fixnum.Int64 get compilationMoment => $_getI64(3);
  @$pb.TagNumber(4)
  set compilationMoment($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCompilationMoment() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompilationMoment() => $_clearField(4);

  /// * The amount of time spent compiling the program in microseconds.
  @$pb.TagNumber(5)
  $fixnum.Int64 get compilationDuration => $_getI64(4);
  @$pb.TagNumber(5)
  set compilationDuration($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCompilationDuration() => $_has(4);
  @$pb.TagNumber(5)
  void clearCompilationDuration() => $_clearField(5);

  /// * The amount of time spent converting the info to protobuf in microseconds.
  @$pb.TagNumber(6)
  $fixnum.Int64 get toProtoDuration => $_getI64(5);
  @$pb.TagNumber(6)
  set toProtoDuration($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasToProtoDuration() => $_has(5);
  @$pb.TagNumber(6)
  void clearToProtoDuration() => $_clearField(6);

  /// * The amount of time spent writing out the serialized info in microseconds.
  @$pb.TagNumber(7)
  $fixnum.Int64 get dumpInfoDuration => $_getI64(6);
  @$pb.TagNumber(7)
  set dumpInfoDuration($fixnum.Int64 v) {
    $_setInt64(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDumpInfoDuration() => $_has(6);
  @$pb.TagNumber(7)
  void clearDumpInfoDuration() => $_clearField(7);

  /// * true if noSuchMethod is used.
  @$pb.TagNumber(8)
  $core.bool get noSuchMethodEnabled => $_getBF(7);
  @$pb.TagNumber(8)
  set noSuchMethodEnabled($core.bool v) {
    $_setBool(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasNoSuchMethodEnabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearNoSuchMethodEnabled() => $_clearField(8);

  /// * True if Object.runtimeType is used.
  @$pb.TagNumber(9)
  $core.bool get isRuntimeTypeUsed => $_getBF(8);
  @$pb.TagNumber(9)
  set isRuntimeTypeUsed($core.bool v) {
    $_setBool(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasIsRuntimeTypeUsed() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsRuntimeTypeUsed() => $_clearField(9);

  /// * True if dart:isolate library is used.
  @$pb.TagNumber(10)
  $core.bool get isIsolateUsed => $_getBF(9);
  @$pb.TagNumber(10)
  set isIsolateUsed($core.bool v) {
    $_setBool(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasIsIsolateUsed() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsIsolateUsed() => $_clearField(10);

  /// * True if Function.apply is used.
  @$pb.TagNumber(11)
  $core.bool get isFunctionApplyUsed => $_getBF(10);
  @$pb.TagNumber(11)
  set isFunctionApplyUsed($core.bool v) {
    $_setBool(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasIsFunctionApplyUsed() => $_has(10);
  @$pb.TagNumber(11)
  void clearIsFunctionApplyUsed() => $_clearField(11);

  /// * True if dart:mirrors features are used.
  @$pb.TagNumber(12)
  $core.bool get isMirrorsUsed => $_getBF(11);
  @$pb.TagNumber(12)
  set isMirrorsUsed($core.bool v) {
    $_setBool(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasIsMirrorsUsed() => $_has(11);
  @$pb.TagNumber(12)
  void clearIsMirrorsUsed() => $_clearField(12);

  /// * Whether the resulting dart2js binary is minified.
  @$pb.TagNumber(13)
  $core.bool get minified => $_getBF(12);
  @$pb.TagNumber(13)
  set minified($core.bool v) {
    $_setBool(12, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasMinified() => $_has(12);
  @$pb.TagNumber(13)
  void clearMinified() => $_clearField(13);
}

/// * Info associated with a library element.
class LibraryInfoPB extends $pb.GeneratedMessage {
  factory LibraryInfoPB({
    $core.String? uri,
    $core.Iterable<$core.String>? childrenIds,
  }) {
    final $result = create();
    if (uri != null) {
      $result.uri = uri;
    }
    if (childrenIds != null) {
      $result.childrenIds.addAll(childrenIds);
    }
    return $result;
  }
  LibraryInfoPB._() : super();
  factory LibraryInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LibraryInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LibraryInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..pPS(2, _omitFieldNames ? '' : 'childrenIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LibraryInfoPB clone() => LibraryInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LibraryInfoPB copyWith(void Function(LibraryInfoPB) updates) =>
      super.copyWith((message) => updates(message as LibraryInfoPB))
          as LibraryInfoPB;

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

  /// * The canonical uri that identifies the library.
  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);

  /// * The serialized_ids of all FunctionInfo, FieldInfo, ClassInfo and TypedefInfo elements that are defined in the library.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get childrenIds => $_getList(1);
}

/// *
///  Information about an output unit. Normally there is just one for the entire
///  program unless the application uses deferred imports, in which case there
///  would be an additional output unit per deferred chunk.
class OutputUnitInfoPB extends $pb.GeneratedMessage {
  factory OutputUnitInfoPB({
    $core.Iterable<$core.String>? imports,
  }) {
    final $result = create();
    if (imports != null) {
      $result.imports.addAll(imports);
    }
    return $result;
  }
  OutputUnitInfoPB._() : super();
  factory OutputUnitInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory OutputUnitInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputUnitInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'imports')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  OutputUnitInfoPB clone() => OutputUnitInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  OutputUnitInfoPB copyWith(void Function(OutputUnitInfoPB) updates) =>
      super.copyWith((message) => updates(message as OutputUnitInfoPB))
          as OutputUnitInfoPB;

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

  /// * The deferred imports that will load this output unit.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get imports => $_getList(0);
}

/// * Information about a class element.
class ClassInfoPB extends $pb.GeneratedMessage {
  factory ClassInfoPB({
    $core.bool? isAbstract,
    $core.Iterable<$core.String>? childrenIds,
  }) {
    final $result = create();
    if (isAbstract != null) {
      $result.isAbstract = isAbstract;
    }
    if (childrenIds != null) {
      $result.childrenIds.addAll(childrenIds);
    }
    return $result;
  }
  ClassInfoPB._() : super();
  factory ClassInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClassInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClassInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isAbstract')
    ..pPS(2, _omitFieldNames ? '' : 'childrenIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClassInfoPB clone() => ClassInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClassInfoPB copyWith(void Function(ClassInfoPB) updates) =>
      super.copyWith((message) => updates(message as ClassInfoPB))
          as ClassInfoPB;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClassInfoPB create() => ClassInfoPB._();
  ClassInfoPB createEmptyInstance() => create();
  static $pb.PbList<ClassInfoPB> createRepeated() => $pb.PbList<ClassInfoPB>();
  @$core.pragma('dart2js:noInline')
  static ClassInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClassInfoPB>(create);
  static ClassInfoPB? _defaultInstance;

  /// * Whether the class is abstract.
  @$pb.TagNumber(1)
  $core.bool get isAbstract => $_getBF(0);
  @$pb.TagNumber(1)
  set isAbstract($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIsAbstract() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsAbstract() => $_clearField(1);

  /// * The serialized_ids of all FunctionInfo and FieldInfo elements defined in the class.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get childrenIds => $_getList(1);
}

/// * Information about a class type element.
class ClassTypeInfoPB extends $pb.GeneratedMessage {
  factory ClassTypeInfoPB() => create();
  ClassTypeInfoPB._() : super();
  factory ClassTypeInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClassTypeInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClassTypeInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClassTypeInfoPB clone() => ClassTypeInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClassTypeInfoPB copyWith(void Function(ClassTypeInfoPB) updates) =>
      super.copyWith((message) => updates(message as ClassTypeInfoPB))
          as ClassTypeInfoPB;

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

/// * Information about a constant value.
class ConstantInfoPB extends $pb.GeneratedMessage {
  factory ConstantInfoPB({
    $core.String? code,
  }) {
    final $result = create();
    if (code != null) {
      $result.code = code;
    }
    return $result;
  }
  ConstantInfoPB._() : super();
  factory ConstantInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ConstantInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConstantInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConstantInfoPB clone() => ConstantInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConstantInfoPB copyWith(void Function(ConstantInfoPB) updates) =>
      super.copyWith((message) => updates(message as ConstantInfoPB))
          as ConstantInfoPB;

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

  /// * The actual generated code for the constant.
  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

/// * Information about a field element.
class FieldInfoPB extends $pb.GeneratedMessage {
  factory FieldInfoPB({
    $core.String? type,
    $core.String? inferredType,
    $core.Iterable<$core.String>? childrenIds,
    $core.String? code,
    $core.bool? isConst,
    $core.String? initializerId,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (inferredType != null) {
      $result.inferredType = inferredType;
    }
    if (childrenIds != null) {
      $result.childrenIds.addAll(childrenIds);
    }
    if (code != null) {
      $result.code = code;
    }
    if (isConst != null) {
      $result.isConst = isConst;
    }
    if (initializerId != null) {
      $result.initializerId = initializerId;
    }
    return $result;
  }
  FieldInfoPB._() : super();
  factory FieldInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FieldInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FieldInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'inferredType')
    ..pPS(3, _omitFieldNames ? '' : 'childrenIds')
    ..aOS(4, _omitFieldNames ? '' : 'code')
    ..aOB(5, _omitFieldNames ? '' : 'isConst')
    ..aOS(6, _omitFieldNames ? '' : 'initializerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FieldInfoPB clone() => FieldInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FieldInfoPB copyWith(void Function(FieldInfoPB) updates) =>
      super.copyWith((message) => updates(message as FieldInfoPB))
          as FieldInfoPB;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FieldInfoPB create() => FieldInfoPB._();
  FieldInfoPB createEmptyInstance() => create();
  static $pb.PbList<FieldInfoPB> createRepeated() => $pb.PbList<FieldInfoPB>();
  @$core.pragma('dart2js:noInline')
  static FieldInfoPB getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FieldInfoPB>(create);
  static FieldInfoPB? _defaultInstance;

  /// * The type of the field.
  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// * The type inferred by dart2js's whole program analysis.
  @$pb.TagNumber(2)
  $core.String get inferredType => $_getSZ(1);
  @$pb.TagNumber(2)
  set inferredType($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasInferredType() => $_has(1);
  @$pb.TagNumber(2)
  void clearInferredType() => $_clearField(2);

  /// * The serialized_ids of all ClosureInfo elements nested in the field initializer.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get childrenIds => $_getList(2);

  /// * The actual generated code for the field.
  @$pb.TagNumber(4)
  $core.String get code => $_getSZ(3);
  @$pb.TagNumber(4)
  set code($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearCode() => $_clearField(4);

  /// * Whether the field is a const declaration.
  @$pb.TagNumber(5)
  $core.bool get isConst => $_getBF(4);
  @$pb.TagNumber(5)
  set isConst($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasIsConst() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsConst() => $_clearField(5);

  /// * When isConst is true, the serialized_id of the ConstantInfo initializer expression.
  @$pb.TagNumber(6)
  $core.String get initializerId => $_getSZ(5);
  @$pb.TagNumber(6)
  set initializerId($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasInitializerId() => $_has(5);
  @$pb.TagNumber(6)
  void clearInitializerId() => $_clearField(6);
}

/// * Information about a typedef declaration.
class TypedefInfoPB extends $pb.GeneratedMessage {
  factory TypedefInfoPB({
    $core.String? type,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    return $result;
  }
  TypedefInfoPB._() : super();
  factory TypedefInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TypedefInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TypedefInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TypedefInfoPB clone() => TypedefInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TypedefInfoPB copyWith(void Function(TypedefInfoPB) updates) =>
      super.copyWith((message) => updates(message as TypedefInfoPB))
          as TypedefInfoPB;

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

  /// * The declared type.
  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

/// * Available function modifiers.
class FunctionModifiersPB extends $pb.GeneratedMessage {
  factory FunctionModifiersPB({
    $core.bool? isStatic,
    $core.bool? isConst,
    $core.bool? isFactory,
    $core.bool? isExternal,
  }) {
    final $result = create();
    if (isStatic != null) {
      $result.isStatic = isStatic;
    }
    if (isConst != null) {
      $result.isConst = isConst;
    }
    if (isFactory != null) {
      $result.isFactory = isFactory;
    }
    if (isExternal != null) {
      $result.isExternal = isExternal;
    }
    return $result;
  }
  FunctionModifiersPB._() : super();
  factory FunctionModifiersPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FunctionModifiersPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FunctionModifiersPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isStatic')
    ..aOB(2, _omitFieldNames ? '' : 'isConst')
    ..aOB(3, _omitFieldNames ? '' : 'isFactory')
    ..aOB(4, _omitFieldNames ? '' : 'isExternal')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FunctionModifiersPB clone() => FunctionModifiersPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FunctionModifiersPB copyWith(void Function(FunctionModifiersPB) updates) =>
      super.copyWith((message) => updates(message as FunctionModifiersPB))
          as FunctionModifiersPB;

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

  /// * Whether the function is declared as static.
  @$pb.TagNumber(1)
  $core.bool get isStatic => $_getBF(0);
  @$pb.TagNumber(1)
  set isStatic($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIsStatic() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsStatic() => $_clearField(1);

  /// * Whether the function is declared as const.
  @$pb.TagNumber(2)
  $core.bool get isConst => $_getBF(1);
  @$pb.TagNumber(2)
  set isConst($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasIsConst() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsConst() => $_clearField(2);

  /// * Whether the function is a factory constructor.
  @$pb.TagNumber(3)
  $core.bool get isFactory => $_getBF(2);
  @$pb.TagNumber(3)
  set isFactory($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasIsFactory() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsFactory() => $_clearField(3);

  /// * Whether the function is declared as extern.
  @$pb.TagNumber(4)
  $core.bool get isExternal => $_getBF(3);
  @$pb.TagNumber(4)
  set isExternal($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasIsExternal() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsExternal() => $_clearField(4);
}

/// * Information about a function parameter.
class ParameterInfoPB extends $pb.GeneratedMessage {
  factory ParameterInfoPB({
    $core.String? name,
    $core.String? type,
    $core.String? declaredType,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (type != null) {
      $result.type = type;
    }
    if (declaredType != null) {
      $result.declaredType = declaredType;
    }
    return $result;
  }
  ParameterInfoPB._() : super();
  factory ParameterInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParameterInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParameterInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOS(3, _omitFieldNames ? '' : 'declaredType')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParameterInfoPB clone() => ParameterInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParameterInfoPB copyWith(void Function(ParameterInfoPB) updates) =>
      super.copyWith((message) => updates(message as ParameterInfoPB))
          as ParameterInfoPB;

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
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get declaredType => $_getSZ(2);
  @$pb.TagNumber(3)
  set declaredType($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDeclaredType() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeclaredType() => $_clearField(3);
}

/// * Information about a function or method.
class FunctionInfoPB extends $pb.GeneratedMessage {
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
    final $result = create();
    if (functionModifiers != null) {
      $result.functionModifiers = functionModifiers;
    }
    if (childrenIds != null) {
      $result.childrenIds.addAll(childrenIds);
    }
    if (returnType != null) {
      $result.returnType = returnType;
    }
    if (inferredReturnType != null) {
      $result.inferredReturnType = inferredReturnType;
    }
    if (parameters != null) {
      $result.parameters.addAll(parameters);
    }
    if (sideEffects != null) {
      $result.sideEffects = sideEffects;
    }
    if (inlinedCount != null) {
      $result.inlinedCount = inlinedCount;
    }
    if (code != null) {
      $result.code = code;
    }
    return $result;
  }
  FunctionInfoPB._() : super();
  factory FunctionInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FunctionInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FunctionInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOM<FunctionModifiersPB>(1, _omitFieldNames ? '' : 'functionModifiers',
        subBuilder: FunctionModifiersPB.create)
    ..pPS(2, _omitFieldNames ? '' : 'childrenIds')
    ..aOS(3, _omitFieldNames ? '' : 'returnType')
    ..aOS(4, _omitFieldNames ? '' : 'inferredReturnType')
    ..pc<ParameterInfoPB>(
        5, _omitFieldNames ? '' : 'parameters', $pb.PbFieldType.PM,
        subBuilder: ParameterInfoPB.create)
    ..aOS(6, _omitFieldNames ? '' : 'sideEffects')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'inlinedCount', $pb.PbFieldType.O3)
    ..aOS(8, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FunctionInfoPB clone() => FunctionInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FunctionInfoPB copyWith(void Function(FunctionInfoPB) updates) =>
      super.copyWith((message) => updates(message as FunctionInfoPB))
          as FunctionInfoPB;

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

  /// * Modifiers applied to the function.
  @$pb.TagNumber(1)
  FunctionModifiersPB get functionModifiers => $_getN(0);
  @$pb.TagNumber(1)
  set functionModifiers(FunctionModifiersPB v) {
    $_setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFunctionModifiers() => $_has(0);
  @$pb.TagNumber(1)
  void clearFunctionModifiers() => $_clearField(1);
  @$pb.TagNumber(1)
  FunctionModifiersPB ensureFunctionModifiers() => $_ensure(0);

  /// * serialized_ids of any ClosureInfo elements declared in the function.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get childrenIds => $_getList(1);

  /// * The declared return type.
  @$pb.TagNumber(3)
  $core.String get returnType => $_getSZ(2);
  @$pb.TagNumber(3)
  set returnType($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasReturnType() => $_has(2);
  @$pb.TagNumber(3)
  void clearReturnType() => $_clearField(3);

  /// * The inferred return type.
  @$pb.TagNumber(4)
  $core.String get inferredReturnType => $_getSZ(3);
  @$pb.TagNumber(4)
  set inferredReturnType($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasInferredReturnType() => $_has(3);
  @$pb.TagNumber(4)
  void clearInferredReturnType() => $_clearField(4);

  /// * Name and type information for each parameter.
  @$pb.TagNumber(5)
  $pb.PbList<ParameterInfoPB> get parameters => $_getList(4);

  /// * Side-effects of the function.
  @$pb.TagNumber(6)
  $core.String get sideEffects => $_getSZ(5);
  @$pb.TagNumber(6)
  set sideEffects($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasSideEffects() => $_has(5);
  @$pb.TagNumber(6)
  void clearSideEffects() => $_clearField(6);

  /// * How many function calls were inlined into the function.
  @$pb.TagNumber(7)
  $core.int get inlinedCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set inlinedCount($core.int v) {
    $_setSignedInt32(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasInlinedCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearInlinedCount() => $_clearField(7);

  /// * The actual generated code.
  @$pb.TagNumber(8)
  $core.String get code => $_getSZ(7);
  @$pb.TagNumber(8)
  set code($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasCode() => $_has(7);
  @$pb.TagNumber(8)
  void clearCode() => $_clearField(8);
}

/// * Information about a closure, also known as a local function.
class ClosureInfoPB extends $pb.GeneratedMessage {
  factory ClosureInfoPB({
    $core.String? functionId,
  }) {
    final $result = create();
    if (functionId != null) {
      $result.functionId = functionId;
    }
    return $result;
  }
  ClosureInfoPB._() : super();
  factory ClosureInfoPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClosureInfoPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClosureInfoPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'functionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClosureInfoPB clone() => ClosureInfoPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClosureInfoPB copyWith(void Function(ClosureInfoPB) updates) =>
      super.copyWith((message) => updates(message as ClosureInfoPB))
          as ClosureInfoPB;

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

  /// * serialized_id of the FunctionInfo wrapped by this closure.
  @$pb.TagNumber(1)
  $core.String get functionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set functionId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFunctionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFunctionId() => $_clearField(1);
}

class DeferredImportPB extends $pb.GeneratedMessage {
  factory DeferredImportPB({
    $core.String? prefix,
    $core.Iterable<$core.String>? files,
  }) {
    final $result = create();
    if (prefix != null) {
      $result.prefix = prefix;
    }
    if (files != null) {
      $result.files.addAll(files);
    }
    return $result;
  }
  DeferredImportPB._() : super();
  factory DeferredImportPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DeferredImportPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeferredImportPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'prefix')
    ..pPS(2, _omitFieldNames ? '' : 'files')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DeferredImportPB clone() => DeferredImportPB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DeferredImportPB copyWith(void Function(DeferredImportPB) updates) =>
      super.copyWith((message) => updates(message as DeferredImportPB))
          as DeferredImportPB;

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

  /// * The prefix assigned to the deferred import.
  @$pb.TagNumber(1)
  $core.String get prefix => $_getSZ(0);
  @$pb.TagNumber(1)
  set prefix($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPrefix() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefix() => $_clearField(1);

  /// * The list of filenames loaded by the import.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get files => $_getList(1);
}

/// * Information about deferred imports within a dart library.
class LibraryDeferredImportsPB extends $pb.GeneratedMessage {
  factory LibraryDeferredImportsPB({
    $core.String? libraryUri,
    $core.String? libraryName,
    $core.Iterable<DeferredImportPB>? imports,
  }) {
    final $result = create();
    if (libraryUri != null) {
      $result.libraryUri = libraryUri;
    }
    if (libraryName != null) {
      $result.libraryName = libraryName;
    }
    if (imports != null) {
      $result.imports.addAll(imports);
    }
    return $result;
  }
  LibraryDeferredImportsPB._() : super();
  factory LibraryDeferredImportsPB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LibraryDeferredImportsPB.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LibraryDeferredImportsPB',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'dart2js_info.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'libraryUri')
    ..aOS(2, _omitFieldNames ? '' : 'libraryName')
    ..pc<DeferredImportPB>(
        3, _omitFieldNames ? '' : 'imports', $pb.PbFieldType.PM,
        subBuilder: DeferredImportPB.create)
    ..hasRequiredFields = false;

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
          as LibraryDeferredImportsPB;

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

  /// * The uri of the library which makes the deferred import.
  @$pb.TagNumber(1)
  $core.String get libraryUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set libraryUri($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasLibraryUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearLibraryUri() => $_clearField(1);

  /// * The name of the library, or "<unnamed>" if it is unnamed.
  @$pb.TagNumber(2)
  $core.String get libraryName => $_getSZ(1);
  @$pb.TagNumber(2)
  set libraryName($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLibraryName() => $_has(1);
  @$pb.TagNumber(2)
  void clearLibraryName() => $_clearField(2);

  /// * The individual deferred imports within the library.
  @$pb.TagNumber(3)
  $pb.PbList<DeferredImportPB> get imports => $_getList(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
