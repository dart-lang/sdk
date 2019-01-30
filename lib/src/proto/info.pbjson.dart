///
//  Generated code. Do not modify.
//  source: info.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

const DependencyInfoPB$json = const {
  '1': 'DependencyInfoPB',
  '2': const [
    const {'1': 'target_id', '3': 1, '4': 1, '5': 9, '10': 'targetId'},
    const {'1': 'mask', '3': 2, '4': 1, '5': 9, '10': 'mask'},
  ],
};

const AllInfoPB$json = const {
  '1': 'AllInfoPB',
  '2': const [
    const {
      '1': 'program',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ProgramInfoPB',
      '10': 'program'
    },
    const {
      '1': 'all_infos',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.dart2js_info.proto.AllInfoPB.AllInfosEntry',
      '10': 'allInfos'
    },
    const {
      '1': 'deferred_imports',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.dart2js_info.proto.LibraryDeferredImportsPB',
      '10': 'deferredImports'
    },
  ],
  '3': const [AllInfoPB_AllInfosEntry$json],
};

const AllInfoPB_AllInfosEntry$json = const {
  '1': 'AllInfosEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.InfoPB',
      '10': 'value'
    },
  ],
  '7': const {'7': true},
};

const InfoPB$json = const {
  '1': 'InfoPB',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'id', '3': 2, '4': 1, '5': 5, '10': 'id'},
    const {'1': 'serialized_id', '3': 3, '4': 1, '5': 9, '10': 'serializedId'},
    const {'1': 'coverage_id', '3': 4, '4': 1, '5': 9, '10': 'coverageId'},
    const {'1': 'size', '3': 5, '4': 1, '5': 5, '10': 'size'},
    const {'1': 'parent_id', '3': 6, '4': 1, '5': 9, '10': 'parentId'},
    const {
      '1': 'uses',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.dart2js_info.proto.DependencyInfoPB',
      '10': 'uses'
    },
    const {'1': 'output_unit_id', '3': 8, '4': 1, '5': 9, '10': 'outputUnitId'},
    const {
      '1': 'library_info',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.LibraryInfoPB',
      '9': 0,
      '10': 'libraryInfo'
    },
    const {
      '1': 'class_info',
      '3': 101,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ClassInfoPB',
      '9': 0,
      '10': 'classInfo'
    },
    const {
      '1': 'function_info',
      '3': 102,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.FunctionInfoPB',
      '9': 0,
      '10': 'functionInfo'
    },
    const {
      '1': 'field_info',
      '3': 103,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.FieldInfoPB',
      '9': 0,
      '10': 'fieldInfo'
    },
    const {
      '1': 'constant_info',
      '3': 104,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ConstantInfoPB',
      '9': 0,
      '10': 'constantInfo'
    },
    const {
      '1': 'output_unit_info',
      '3': 105,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.OutputUnitInfoPB',
      '9': 0,
      '10': 'outputUnitInfo'
    },
    const {
      '1': 'typedef_info',
      '3': 106,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.TypedefInfoPB',
      '9': 0,
      '10': 'typedefInfo'
    },
    const {
      '1': 'closure_info',
      '3': 107,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ClosureInfoPB',
      '9': 0,
      '10': 'closureInfo'
    },
  ],
  '8': const [
    const {'1': 'concrete'},
  ],
  '9': const [
    const {'1': 9, '2': 100},
  ],
};

const ProgramInfoPB$json = const {
  '1': 'ProgramInfoPB',
  '2': const [
    const {'1': 'entrypoint_id', '3': 1, '4': 1, '5': 9, '10': 'entrypointId'},
    const {'1': 'size', '3': 2, '4': 1, '5': 5, '10': 'size'},
    const {
      '1': 'dart2js_version',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'dart2jsVersion'
    },
    const {
      '1': 'compilation_moment',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'compilationMoment'
    },
    const {
      '1': 'compilation_duration',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'compilationDuration'
    },
    const {
      '1': 'to_proto_duration',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'toProtoDuration'
    },
    const {
      '1': 'dump_info_duration',
      '3': 7,
      '4': 1,
      '5': 3,
      '10': 'dumpInfoDuration'
    },
    const {
      '1': 'no_such_method_enabled',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'noSuchMethodEnabled'
    },
    const {
      '1': 'is_runtime_type_used',
      '3': 9,
      '4': 1,
      '5': 8,
      '10': 'isRuntimeTypeUsed'
    },
    const {
      '1': 'is_isolate_used',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'isIsolateUsed'
    },
    const {
      '1': 'is_function_apply_used',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'isFunctionApplyUsed'
    },
    const {
      '1': 'is_mirrors_used',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'isMirrorsUsed'
    },
    const {'1': 'minified', '3': 13, '4': 1, '5': 8, '10': 'minified'},
  ],
};

const LibraryInfoPB$json = const {
  '1': 'LibraryInfoPB',
  '2': const [
    const {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    const {'1': 'children_ids', '3': 2, '4': 3, '5': 9, '10': 'childrenIds'},
  ],
};

const OutputUnitInfoPB$json = const {
  '1': 'OutputUnitInfoPB',
  '2': const [
    const {'1': 'imports', '3': 1, '4': 3, '5': 9, '10': 'imports'},
  ],
};

const ClassInfoPB$json = const {
  '1': 'ClassInfoPB',
  '2': const [
    const {'1': 'is_abstract', '3': 1, '4': 1, '5': 8, '10': 'isAbstract'},
    const {'1': 'children_ids', '3': 2, '4': 3, '5': 9, '10': 'childrenIds'},
  ],
};

const ConstantInfoPB$json = const {
  '1': 'ConstantInfoPB',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

const FieldInfoPB$json = const {
  '1': 'FieldInfoPB',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'inferred_type', '3': 2, '4': 1, '5': 9, '10': 'inferredType'},
    const {'1': 'children_ids', '3': 3, '4': 3, '5': 9, '10': 'childrenIds'},
    const {'1': 'code', '3': 4, '4': 1, '5': 9, '10': 'code'},
    const {'1': 'is_const', '3': 5, '4': 1, '5': 8, '10': 'isConst'},
    const {
      '1': 'initializer_id',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'initializerId'
    },
  ],
};

const TypedefInfoPB$json = const {
  '1': 'TypedefInfoPB',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
  ],
};

const FunctionModifiersPB$json = const {
  '1': 'FunctionModifiersPB',
  '2': const [
    const {'1': 'is_static', '3': 1, '4': 1, '5': 8, '10': 'isStatic'},
    const {'1': 'is_const', '3': 2, '4': 1, '5': 8, '10': 'isConst'},
    const {'1': 'is_factory', '3': 3, '4': 1, '5': 8, '10': 'isFactory'},
    const {'1': 'is_external', '3': 4, '4': 1, '5': 8, '10': 'isExternal'},
  ],
};

const ParameterInfoPB$json = const {
  '1': 'ParameterInfoPB',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'declared_type', '3': 3, '4': 1, '5': 9, '10': 'declaredType'},
  ],
};

const FunctionInfoPB$json = const {
  '1': 'FunctionInfoPB',
  '2': const [
    const {
      '1': 'function_modifiers',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.FunctionModifiersPB',
      '10': 'functionModifiers'
    },
    const {'1': 'children_ids', '3': 2, '4': 3, '5': 9, '10': 'childrenIds'},
    const {'1': 'return_type', '3': 3, '4': 1, '5': 9, '10': 'returnType'},
    const {
      '1': 'inferred_return_type',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'inferredReturnType'
    },
    const {
      '1': 'parameters',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.dart2js_info.proto.ParameterInfoPB',
      '10': 'parameters'
    },
    const {'1': 'side_effects', '3': 6, '4': 1, '5': 9, '10': 'sideEffects'},
    const {'1': 'inlined_count', '3': 7, '4': 1, '5': 5, '10': 'inlinedCount'},
    const {'1': 'code', '3': 8, '4': 1, '5': 9, '10': 'code'},
  ],
  '9': const [
    const {'1': 9, '2': 10},
  ],
};

const ClosureInfoPB$json = const {
  '1': 'ClosureInfoPB',
  '2': const [
    const {'1': 'function_id', '3': 1, '4': 1, '5': 9, '10': 'functionId'},
  ],
};

const DeferredImportPB$json = const {
  '1': 'DeferredImportPB',
  '2': const [
    const {'1': 'prefix', '3': 1, '4': 1, '5': 9, '10': 'prefix'},
    const {'1': 'files', '3': 2, '4': 3, '5': 9, '10': 'files'},
  ],
};

const LibraryDeferredImportsPB$json = const {
  '1': 'LibraryDeferredImportsPB',
  '2': const [
    const {'1': 'library_uri', '3': 1, '4': 1, '5': 9, '10': 'libraryUri'},
    const {'1': 'library_name', '3': 2, '4': 1, '5': 9, '10': 'libraryName'},
    const {
      '1': 'imports',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.dart2js_info.proto.DeferredImportPB',
      '10': 'imports'
    },
  ],
};
