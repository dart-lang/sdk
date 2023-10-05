//  Generated code. Do not modify.
//  source: info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use dependencyInfoPBDescriptor instead')
const DependencyInfoPB$json = const {
  '1': 'DependencyInfoPB',
  '2': const [
    const {'1': 'target_id', '3': 1, '4': 1, '5': 9, '10': 'targetId'},
    const {'1': 'mask', '3': 2, '4': 1, '5': 9, '10': 'mask'},
  ],
};

/// Descriptor for `DependencyInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dependencyInfoPBDescriptor = $convert.base64Decode(
    'ChBEZXBlbmRlbmN5SW5mb1BCEhsKCXRhcmdldF9pZBgBIAEoCVIIdGFyZ2V0SWQSEgoEbWFzaxgCIAEoCVIEbWFzaw==');
@$core.Deprecated('Use allInfoPBDescriptor instead')
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

@$core.Deprecated('Use allInfoPBDescriptor instead')
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

/// Descriptor for `AllInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List allInfoPBDescriptor = $convert.base64Decode(
    'CglBbGxJbmZvUEISOwoHcHJvZ3JhbRgBIAEoCzIhLmRhcnQyanNfaW5mby5wcm90by5Qcm9ncmFtSW5mb1BCUgdwcm9ncmFtEkgKCWFsbF9pbmZvcxgCIAMoCzIrLmRhcnQyanNfaW5mby5wcm90by5BbGxJbmZvUEIuQWxsSW5mb3NFbnRyeVIIYWxsSW5mb3MSVwoQZGVmZXJyZWRfaW1wb3J0cxgDIAMoCzIsLmRhcnQyanNfaW5mby5wcm90by5MaWJyYXJ5RGVmZXJyZWRJbXBvcnRzUEJSD2RlZmVycmVkSW1wb3J0cxpXCg1BbGxJbmZvc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjAKBXZhbHVlGAIgASgLMhouZGFydDJqc19pbmZvLnByb3RvLkluZm9QQlIFdmFsdWU6AjgB');
@$core.Deprecated('Use infoPBDescriptor instead')
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
    const {
      '1': 'class_type_info',
      '3': 108,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ClassTypeInfoPB',
      '9': 0,
      '10': 'classTypeInfo'
    },
  ],
  '8': const [
    const {'1': 'concrete'},
  ],
  '9': const [
    const {'1': 9, '2': 100},
  ],
};

/// Descriptor for `InfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List infoPBDescriptor = $convert.base64Decode(
    'CgZJbmZvUEISEgoEbmFtZRgBIAEoCVIEbmFtZRIOCgJpZBgCIAEoBVICaWQSIwoNc2VyaWFsaXplZF9pZBgDIAEoCVIMc2VyaWFsaXplZElkEh8KC2NvdmVyYWdlX2lkGAQgASgJUgpjb3ZlcmFnZUlkEhIKBHNpemUYBSABKAVSBHNpemUSGwoJcGFyZW50X2lkGAYgASgJUghwYXJlbnRJZBI4CgR1c2VzGAcgAygLMiQuZGFydDJqc19pbmZvLnByb3RvLkRlcGVuZGVuY3lJbmZvUEJSBHVzZXMSJAoOb3V0cHV0X3VuaXRfaWQYCCABKAlSDG91dHB1dFVuaXRJZBJGCgxsaWJyYXJ5X2luZm8YZCABKAsyIS5kYXJ0MmpzX2luZm8ucHJvdG8uTGlicmFyeUluZm9QQkgAUgtsaWJyYXJ5SW5mbxJACgpjbGFzc19pbmZvGGUgASgLMh8uZGFydDJqc19pbmZvLnByb3RvLkNsYXNzSW5mb1BCSABSCWNsYXNzSW5mbxJJCg1mdW5jdGlvbl9pbmZvGGYgASgLMiIuZGFydDJqc19pbmZvLnByb3RvLkZ1bmN0aW9uSW5mb1BCSABSDGZ1bmN0aW9uSW5mbxJACgpmaWVsZF9pbmZvGGcgASgLMh8uZGFydDJqc19pbmZvLnByb3RvLkZpZWxkSW5mb1BCSABSCWZpZWxkSW5mbxJJCg1jb25zdGFudF9pbmZvGGggASgLMiIuZGFydDJqc19pbmZvLnByb3RvLkNvbnN0YW50SW5mb1BCSABSDGNvbnN0YW50SW5mbxJQChBvdXRwdXRfdW5pdF9pbmZvGGkgASgLMiQuZGFydDJqc19pbmZvLnByb3RvLk91dHB1dFVuaXRJbmZvUEJIAFIOb3V0cHV0VW5pdEluZm8SRgoMdHlwZWRlZl9pbmZvGGogASgLMiEuZGFydDJqc19pbmZvLnByb3RvLlR5cGVkZWZJbmZvUEJIAFILdHlwZWRlZkluZm8SRgoMY2xvc3VyZV9pbmZvGGsgASgLMiEuZGFydDJqc19pbmZvLnByb3RvLkNsb3N1cmVJbmZvUEJIAFILY2xvc3VyZUluZm8STQoPY2xhc3NfdHlwZV9pbmZvGGwgASgLMiMuZGFydDJqc19pbmZvLnByb3RvLkNsYXNzVHlwZUluZm9QQkgAUg1jbGFzc1R5cGVJbmZvQgoKCGNvbmNyZXRlSgQICRBk');
@$core.Deprecated('Use programInfoPBDescriptor instead')
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

/// Descriptor for `ProgramInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List programInfoPBDescriptor = $convert.base64Decode(
    'Cg1Qcm9ncmFtSW5mb1BCEiMKDWVudHJ5cG9pbnRfaWQYASABKAlSDGVudHJ5cG9pbnRJZBISCgRzaXplGAIgASgFUgRzaXplEicKD2RhcnQyanNfdmVyc2lvbhgDIAEoCVIOZGFydDJqc1ZlcnNpb24SLQoSY29tcGlsYXRpb25fbW9tZW50GAQgASgDUhFjb21waWxhdGlvbk1vbWVudBIxChRjb21waWxhdGlvbl9kdXJhdGlvbhgFIAEoA1ITY29tcGlsYXRpb25EdXJhdGlvbhIqChF0b19wcm90b19kdXJhdGlvbhgGIAEoA1IPdG9Qcm90b0R1cmF0aW9uEiwKEmR1bXBfaW5mb19kdXJhdGlvbhgHIAEoA1IQZHVtcEluZm9EdXJhdGlvbhIzChZub19zdWNoX21ldGhvZF9lbmFibGVkGAggASgIUhNub1N1Y2hNZXRob2RFbmFibGVkEi8KFGlzX3J1bnRpbWVfdHlwZV91c2VkGAkgASgIUhFpc1J1bnRpbWVUeXBlVXNlZBImCg9pc19pc29sYXRlX3VzZWQYCiABKAhSDWlzSXNvbGF0ZVVzZWQSMwoWaXNfZnVuY3Rpb25fYXBwbHlfdXNlZBgLIAEoCFITaXNGdW5jdGlvbkFwcGx5VXNlZBImCg9pc19taXJyb3JzX3VzZWQYDCABKAhSDWlzTWlycm9yc1VzZWQSGgoIbWluaWZpZWQYDSABKAhSCG1pbmlmaWVk');
@$core.Deprecated('Use libraryInfoPBDescriptor instead')
const LibraryInfoPB$json = const {
  '1': 'LibraryInfoPB',
  '2': const [
    const {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    const {'1': 'children_ids', '3': 2, '4': 3, '5': 9, '10': 'childrenIds'},
  ],
};

/// Descriptor for `LibraryInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List libraryInfoPBDescriptor = $convert.base64Decode(
    'Cg1MaWJyYXJ5SW5mb1BCEhAKA3VyaRgBIAEoCVIDdXJpEiEKDGNoaWxkcmVuX2lkcxgCIAMoCVILY2hpbGRyZW5JZHM=');
@$core.Deprecated('Use outputUnitInfoPBDescriptor instead')
const OutputUnitInfoPB$json = const {
  '1': 'OutputUnitInfoPB',
  '2': const [
    const {'1': 'imports', '3': 1, '4': 3, '5': 9, '10': 'imports'},
  ],
};

/// Descriptor for `OutputUnitInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputUnitInfoPBDescriptor = $convert.base64Decode(
    'ChBPdXRwdXRVbml0SW5mb1BCEhgKB2ltcG9ydHMYASADKAlSB2ltcG9ydHM=');
@$core.Deprecated('Use classInfoPBDescriptor instead')
const ClassInfoPB$json = const {
  '1': 'ClassInfoPB',
  '2': const [
    const {'1': 'is_abstract', '3': 1, '4': 1, '5': 8, '10': 'isAbstract'},
    const {'1': 'children_ids', '3': 2, '4': 3, '5': 9, '10': 'childrenIds'},
  ],
};

/// Descriptor for `ClassInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List classInfoPBDescriptor = $convert.base64Decode(
    'CgtDbGFzc0luZm9QQhIfCgtpc19hYnN0cmFjdBgBIAEoCFIKaXNBYnN0cmFjdBIhCgxjaGlsZHJlbl9pZHMYAiADKAlSC2NoaWxkcmVuSWRz');
@$core.Deprecated('Use classTypeInfoPBDescriptor instead')
const ClassTypeInfoPB$json = const {
  '1': 'ClassTypeInfoPB',
};

/// Descriptor for `ClassTypeInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List classTypeInfoPBDescriptor =
    $convert.base64Decode('Cg9DbGFzc1R5cGVJbmZvUEI=');
@$core.Deprecated('Use constantInfoPBDescriptor instead')
const ConstantInfoPB$json = const {
  '1': 'ConstantInfoPB',
  '2': const [
    const {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `ConstantInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List constantInfoPBDescriptor =
    $convert.base64Decode('Cg5Db25zdGFudEluZm9QQhISCgRjb2RlGAEgASgJUgRjb2Rl');
@$core.Deprecated('Use fieldInfoPBDescriptor instead')
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

/// Descriptor for `FieldInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldInfoPBDescriptor = $convert.base64Decode(
    'CgtGaWVsZEluZm9QQhISCgR0eXBlGAEgASgJUgR0eXBlEiMKDWluZmVycmVkX3R5cGUYAiABKAlSDGluZmVycmVkVHlwZRIhCgxjaGlsZHJlbl9pZHMYAyADKAlSC2NoaWxkcmVuSWRzEhIKBGNvZGUYBCABKAlSBGNvZGUSGQoIaXNfY29uc3QYBSABKAhSB2lzQ29uc3QSJQoOaW5pdGlhbGl6ZXJfaWQYBiABKAlSDWluaXRpYWxpemVySWQ=');
@$core.Deprecated('Use typedefInfoPBDescriptor instead')
const TypedefInfoPB$json = const {
  '1': 'TypedefInfoPB',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
  ],
};

/// Descriptor for `TypedefInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typedefInfoPBDescriptor =
    $convert.base64Decode('Cg1UeXBlZGVmSW5mb1BCEhIKBHR5cGUYASABKAlSBHR5cGU=');
@$core.Deprecated('Use functionModifiersPBDescriptor instead')
const FunctionModifiersPB$json = const {
  '1': 'FunctionModifiersPB',
  '2': const [
    const {'1': 'is_static', '3': 1, '4': 1, '5': 8, '10': 'isStatic'},
    const {'1': 'is_const', '3': 2, '4': 1, '5': 8, '10': 'isConst'},
    const {'1': 'is_factory', '3': 3, '4': 1, '5': 8, '10': 'isFactory'},
    const {'1': 'is_external', '3': 4, '4': 1, '5': 8, '10': 'isExternal'},
  ],
};

/// Descriptor for `FunctionModifiersPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List functionModifiersPBDescriptor = $convert.base64Decode(
    'ChNGdW5jdGlvbk1vZGlmaWVyc1BCEhsKCWlzX3N0YXRpYxgBIAEoCFIIaXNTdGF0aWMSGQoIaXNfY29uc3QYAiABKAhSB2lzQ29uc3QSHQoKaXNfZmFjdG9yeRgDIAEoCFIJaXNGYWN0b3J5Eh8KC2lzX2V4dGVybmFsGAQgASgIUgppc0V4dGVybmFs');
@$core.Deprecated('Use parameterInfoPBDescriptor instead')
const ParameterInfoPB$json = const {
  '1': 'ParameterInfoPB',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'declared_type', '3': 3, '4': 1, '5': 9, '10': 'declaredType'},
  ],
};

/// Descriptor for `ParameterInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parameterInfoPBDescriptor = $convert.base64Decode(
    'Cg9QYXJhbWV0ZXJJbmZvUEISEgoEbmFtZRgBIAEoCVIEbmFtZRISCgR0eXBlGAIgASgJUgR0eXBlEiMKDWRlY2xhcmVkX3R5cGUYAyABKAlSDGRlY2xhcmVkVHlwZQ==');
@$core.Deprecated('Use functionInfoPBDescriptor instead')
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

/// Descriptor for `FunctionInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List functionInfoPBDescriptor = $convert.base64Decode(
    'Cg5GdW5jdGlvbkluZm9QQhJWChJmdW5jdGlvbl9tb2RpZmllcnMYASABKAsyJy5kYXJ0MmpzX2luZm8ucHJvdG8uRnVuY3Rpb25Nb2RpZmllcnNQQlIRZnVuY3Rpb25Nb2RpZmllcnMSIQoMY2hpbGRyZW5faWRzGAIgAygJUgtjaGlsZHJlbklkcxIfCgtyZXR1cm5fdHlwZRgDIAEoCVIKcmV0dXJuVHlwZRIwChRpbmZlcnJlZF9yZXR1cm5fdHlwZRgEIAEoCVISaW5mZXJyZWRSZXR1cm5UeXBlEkMKCnBhcmFtZXRlcnMYBSADKAsyIy5kYXJ0MmpzX2luZm8ucHJvdG8uUGFyYW1ldGVySW5mb1BCUgpwYXJhbWV0ZXJzEiEKDHNpZGVfZWZmZWN0cxgGIAEoCVILc2lkZUVmZmVjdHMSIwoNaW5saW5lZF9jb3VudBgHIAEoBVIMaW5saW5lZENvdW50EhIKBGNvZGUYCCABKAlSBGNvZGVKBAgJEAo=');
@$core.Deprecated('Use closureInfoPBDescriptor instead')
const ClosureInfoPB$json = const {
  '1': 'ClosureInfoPB',
  '2': const [
    const {'1': 'function_id', '3': 1, '4': 1, '5': 9, '10': 'functionId'},
  ],
};

/// Descriptor for `ClosureInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closureInfoPBDescriptor = $convert.base64Decode(
    'Cg1DbG9zdXJlSW5mb1BCEh8KC2Z1bmN0aW9uX2lkGAEgASgJUgpmdW5jdGlvbklk');
@$core.Deprecated('Use deferredImportPBDescriptor instead')
const DeferredImportPB$json = const {
  '1': 'DeferredImportPB',
  '2': const [
    const {'1': 'prefix', '3': 1, '4': 1, '5': 9, '10': 'prefix'},
    const {'1': 'files', '3': 2, '4': 3, '5': 9, '10': 'files'},
  ],
};

/// Descriptor for `DeferredImportPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deferredImportPBDescriptor = $convert.base64Decode(
    'ChBEZWZlcnJlZEltcG9ydFBCEhYKBnByZWZpeBgBIAEoCVIGcHJlZml4EhQKBWZpbGVzGAIgAygJUgVmaWxlcw==');
@$core.Deprecated('Use libraryDeferredImportsPBDescriptor instead')
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

/// Descriptor for `LibraryDeferredImportsPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List libraryDeferredImportsPBDescriptor =
    $convert.base64Decode(
        'ChhMaWJyYXJ5RGVmZXJyZWRJbXBvcnRzUEISHwoLbGlicmFyeV91cmkYASABKAlSCmxpYnJhcnlVcmkSIQoMbGlicmFyeV9uYW1lGAIgASgJUgtsaWJyYXJ5TmFtZRI+CgdpbXBvcnRzGAMgAygLMiQuZGFydDJqc19pbmZvLnByb3RvLkRlZmVycmVkSW1wb3J0UEJSB2ltcG9ydHM=');
