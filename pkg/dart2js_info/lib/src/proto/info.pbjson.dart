//
//  Generated code. Do not modify.
//  source: info.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use dependencyInfoPBDescriptor instead')
const DependencyInfoPB$json = {
  '1': 'DependencyInfoPB',
  '2': [
    {'1': 'target_id', '3': 1, '4': 1, '5': 9, '10': 'targetId'},
    {'1': 'mask', '3': 2, '4': 1, '5': 9, '10': 'mask'},
  ],
};

/// Descriptor for `DependencyInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dependencyInfoPBDescriptor = $convert.base64Decode(
    'ChBEZXBlbmRlbmN5SW5mb1BCEhsKCXRhcmdldF9pZBgBIAEoCVIIdGFyZ2V0SWQSEgoEbWFzax'
    'gCIAEoCVIEbWFzaw==');

@$core.Deprecated('Use allInfoPBDescriptor instead')
const AllInfoPB$json = {
  '1': 'AllInfoPB',
  '2': [
    {
      '1': 'program',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ProgramInfoPB',
      '10': 'program'
    },
    {
      '1': 'all_infos',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.dart2js_info.proto.AllInfoPB.AllInfosEntry',
      '10': 'allInfos'
    },
    {
      '1': 'deferred_imports',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.dart2js_info.proto.LibraryDeferredImportsPB',
      '10': 'deferredImports'
    },
  ],
  '3': [AllInfoPB_AllInfosEntry$json],
};

@$core.Deprecated('Use allInfoPBDescriptor instead')
const AllInfoPB_AllInfosEntry$json = {
  '1': 'AllInfosEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.InfoPB',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `AllInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List allInfoPBDescriptor = $convert.base64Decode(
    'CglBbGxJbmZvUEISOwoHcHJvZ3JhbRgBIAEoCzIhLmRhcnQyanNfaW5mby5wcm90by5Qcm9ncm'
    'FtSW5mb1BCUgdwcm9ncmFtEkgKCWFsbF9pbmZvcxgCIAMoCzIrLmRhcnQyanNfaW5mby5wcm90'
    'by5BbGxJbmZvUEIuQWxsSW5mb3NFbnRyeVIIYWxsSW5mb3MSVwoQZGVmZXJyZWRfaW1wb3J0cx'
    'gDIAMoCzIsLmRhcnQyanNfaW5mby5wcm90by5MaWJyYXJ5RGVmZXJyZWRJbXBvcnRzUEJSD2Rl'
    'ZmVycmVkSW1wb3J0cxpXCg1BbGxJbmZvc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjAKBXZhbH'
    'VlGAIgASgLMhouZGFydDJqc19pbmZvLnByb3RvLkluZm9QQlIFdmFsdWU6AjgB');

@$core.Deprecated('Use infoPBDescriptor instead')
const InfoPB$json = {
  '1': 'InfoPB',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'id', '3': 2, '4': 1, '5': 5, '10': 'id'},
    {'1': 'serialized_id', '3': 3, '4': 1, '5': 9, '10': 'serializedId'},
    {'1': 'coverage_id', '3': 4, '4': 1, '5': 9, '10': 'coverageId'},
    {'1': 'size', '3': 5, '4': 1, '5': 5, '10': 'size'},
    {'1': 'parent_id', '3': 6, '4': 1, '5': 9, '10': 'parentId'},
    {
      '1': 'uses',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.dart2js_info.proto.DependencyInfoPB',
      '10': 'uses'
    },
    {'1': 'output_unit_id', '3': 8, '4': 1, '5': 9, '10': 'outputUnitId'},
    {
      '1': 'library_info',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.LibraryInfoPB',
      '9': 0,
      '10': 'libraryInfo'
    },
    {
      '1': 'class_info',
      '3': 101,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ClassInfoPB',
      '9': 0,
      '10': 'classInfo'
    },
    {
      '1': 'function_info',
      '3': 102,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.FunctionInfoPB',
      '9': 0,
      '10': 'functionInfo'
    },
    {
      '1': 'field_info',
      '3': 103,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.FieldInfoPB',
      '9': 0,
      '10': 'fieldInfo'
    },
    {
      '1': 'constant_info',
      '3': 104,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ConstantInfoPB',
      '9': 0,
      '10': 'constantInfo'
    },
    {
      '1': 'output_unit_info',
      '3': 105,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.OutputUnitInfoPB',
      '9': 0,
      '10': 'outputUnitInfo'
    },
    {
      '1': 'typedef_info',
      '3': 106,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.TypedefInfoPB',
      '9': 0,
      '10': 'typedefInfo'
    },
    {
      '1': 'closure_info',
      '3': 107,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ClosureInfoPB',
      '9': 0,
      '10': 'closureInfo'
    },
    {
      '1': 'class_type_info',
      '3': 108,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.ClassTypeInfoPB',
      '9': 0,
      '10': 'classTypeInfo'
    },
  ],
  '8': [
    {'1': 'concrete'},
  ],
  '9': [
    {'1': 9, '2': 100},
  ],
};

/// Descriptor for `InfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List infoPBDescriptor = $convert.base64Decode(
    'CgZJbmZvUEISEgoEbmFtZRgBIAEoCVIEbmFtZRIOCgJpZBgCIAEoBVICaWQSIwoNc2VyaWFsaX'
    'plZF9pZBgDIAEoCVIMc2VyaWFsaXplZElkEh8KC2NvdmVyYWdlX2lkGAQgASgJUgpjb3ZlcmFn'
    'ZUlkEhIKBHNpemUYBSABKAVSBHNpemUSGwoJcGFyZW50X2lkGAYgASgJUghwYXJlbnRJZBI4Cg'
    'R1c2VzGAcgAygLMiQuZGFydDJqc19pbmZvLnByb3RvLkRlcGVuZGVuY3lJbmZvUEJSBHVzZXMS'
    'JAoOb3V0cHV0X3VuaXRfaWQYCCABKAlSDG91dHB1dFVuaXRJZBJGCgxsaWJyYXJ5X2luZm8YZC'
    'ABKAsyIS5kYXJ0MmpzX2luZm8ucHJvdG8uTGlicmFyeUluZm9QQkgAUgtsaWJyYXJ5SW5mbxJA'
    'CgpjbGFzc19pbmZvGGUgASgLMh8uZGFydDJqc19pbmZvLnByb3RvLkNsYXNzSW5mb1BCSABSCW'
    'NsYXNzSW5mbxJJCg1mdW5jdGlvbl9pbmZvGGYgASgLMiIuZGFydDJqc19pbmZvLnByb3RvLkZ1'
    'bmN0aW9uSW5mb1BCSABSDGZ1bmN0aW9uSW5mbxJACgpmaWVsZF9pbmZvGGcgASgLMh8uZGFydD'
    'Jqc19pbmZvLnByb3RvLkZpZWxkSW5mb1BCSABSCWZpZWxkSW5mbxJJCg1jb25zdGFudF9pbmZv'
    'GGggASgLMiIuZGFydDJqc19pbmZvLnByb3RvLkNvbnN0YW50SW5mb1BCSABSDGNvbnN0YW50SW'
    '5mbxJQChBvdXRwdXRfdW5pdF9pbmZvGGkgASgLMiQuZGFydDJqc19pbmZvLnByb3RvLk91dHB1'
    'dFVuaXRJbmZvUEJIAFIOb3V0cHV0VW5pdEluZm8SRgoMdHlwZWRlZl9pbmZvGGogASgLMiEuZG'
    'FydDJqc19pbmZvLnByb3RvLlR5cGVkZWZJbmZvUEJIAFILdHlwZWRlZkluZm8SRgoMY2xvc3Vy'
    'ZV9pbmZvGGsgASgLMiEuZGFydDJqc19pbmZvLnByb3RvLkNsb3N1cmVJbmZvUEJIAFILY2xvc3'
    'VyZUluZm8STQoPY2xhc3NfdHlwZV9pbmZvGGwgASgLMiMuZGFydDJqc19pbmZvLnByb3RvLkNs'
    'YXNzVHlwZUluZm9QQkgAUg1jbGFzc1R5cGVJbmZvQgoKCGNvbmNyZXRlSgQICRBk');

@$core.Deprecated('Use programInfoPBDescriptor instead')
const ProgramInfoPB$json = {
  '1': 'ProgramInfoPB',
  '2': [
    {'1': 'entrypoint_id', '3': 1, '4': 1, '5': 9, '10': 'entrypointId'},
    {'1': 'size', '3': 2, '4': 1, '5': 5, '10': 'size'},
    {'1': 'dart2js_version', '3': 3, '4': 1, '5': 9, '10': 'dart2jsVersion'},
    {
      '1': 'compilation_moment',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'compilationMoment'
    },
    {
      '1': 'compilation_duration',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'compilationDuration'
    },
    {'1': 'to_proto_duration', '3': 6, '4': 1, '5': 3, '10': 'toProtoDuration'},
    {
      '1': 'dump_info_duration',
      '3': 7,
      '4': 1,
      '5': 3,
      '10': 'dumpInfoDuration'
    },
    {
      '1': 'no_such_method_enabled',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'noSuchMethodEnabled'
    },
    {
      '1': 'is_runtime_type_used',
      '3': 9,
      '4': 1,
      '5': 8,
      '10': 'isRuntimeTypeUsed'
    },
    {'1': 'is_isolate_used', '3': 10, '4': 1, '5': 8, '10': 'isIsolateUsed'},
    {
      '1': 'is_function_apply_used',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'isFunctionApplyUsed'
    },
    {'1': 'is_mirrors_used', '3': 12, '4': 1, '5': 8, '10': 'isMirrorsUsed'},
    {'1': 'minified', '3': 13, '4': 1, '5': 8, '10': 'minified'},
  ],
};

/// Descriptor for `ProgramInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List programInfoPBDescriptor = $convert.base64Decode(
    'Cg1Qcm9ncmFtSW5mb1BCEiMKDWVudHJ5cG9pbnRfaWQYASABKAlSDGVudHJ5cG9pbnRJZBISCg'
    'RzaXplGAIgASgFUgRzaXplEicKD2RhcnQyanNfdmVyc2lvbhgDIAEoCVIOZGFydDJqc1ZlcnNp'
    'b24SLQoSY29tcGlsYXRpb25fbW9tZW50GAQgASgDUhFjb21waWxhdGlvbk1vbWVudBIxChRjb2'
    '1waWxhdGlvbl9kdXJhdGlvbhgFIAEoA1ITY29tcGlsYXRpb25EdXJhdGlvbhIqChF0b19wcm90'
    'b19kdXJhdGlvbhgGIAEoA1IPdG9Qcm90b0R1cmF0aW9uEiwKEmR1bXBfaW5mb19kdXJhdGlvbh'
    'gHIAEoA1IQZHVtcEluZm9EdXJhdGlvbhIzChZub19zdWNoX21ldGhvZF9lbmFibGVkGAggASgI'
    'UhNub1N1Y2hNZXRob2RFbmFibGVkEi8KFGlzX3J1bnRpbWVfdHlwZV91c2VkGAkgASgIUhFpc1'
    'J1bnRpbWVUeXBlVXNlZBImCg9pc19pc29sYXRlX3VzZWQYCiABKAhSDWlzSXNvbGF0ZVVzZWQS'
    'MwoWaXNfZnVuY3Rpb25fYXBwbHlfdXNlZBgLIAEoCFITaXNGdW5jdGlvbkFwcGx5VXNlZBImCg'
    '9pc19taXJyb3JzX3VzZWQYDCABKAhSDWlzTWlycm9yc1VzZWQSGgoIbWluaWZpZWQYDSABKAhS'
    'CG1pbmlmaWVk');

@$core.Deprecated('Use libraryInfoPBDescriptor instead')
const LibraryInfoPB$json = {
  '1': 'LibraryInfoPB',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'children_ids', '3': 2, '4': 3, '5': 9, '10': 'childrenIds'},
  ],
};

/// Descriptor for `LibraryInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List libraryInfoPBDescriptor = $convert.base64Decode(
    'Cg1MaWJyYXJ5SW5mb1BCEhAKA3VyaRgBIAEoCVIDdXJpEiEKDGNoaWxkcmVuX2lkcxgCIAMoCV'
    'ILY2hpbGRyZW5JZHM=');

@$core.Deprecated('Use outputUnitInfoPBDescriptor instead')
const OutputUnitInfoPB$json = {
  '1': 'OutputUnitInfoPB',
  '2': [
    {'1': 'imports', '3': 1, '4': 3, '5': 9, '10': 'imports'},
  ],
};

/// Descriptor for `OutputUnitInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputUnitInfoPBDescriptor = $convert.base64Decode(
    'ChBPdXRwdXRVbml0SW5mb1BCEhgKB2ltcG9ydHMYASADKAlSB2ltcG9ydHM=');

@$core.Deprecated('Use classInfoPBDescriptor instead')
const ClassInfoPB$json = {
  '1': 'ClassInfoPB',
  '2': [
    {'1': 'is_abstract', '3': 1, '4': 1, '5': 8, '10': 'isAbstract'},
    {'1': 'children_ids', '3': 2, '4': 3, '5': 9, '10': 'childrenIds'},
  ],
};

/// Descriptor for `ClassInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List classInfoPBDescriptor = $convert.base64Decode(
    'CgtDbGFzc0luZm9QQhIfCgtpc19hYnN0cmFjdBgBIAEoCFIKaXNBYnN0cmFjdBIhCgxjaGlsZH'
    'Jlbl9pZHMYAiADKAlSC2NoaWxkcmVuSWRz');

@$core.Deprecated('Use classTypeInfoPBDescriptor instead')
const ClassTypeInfoPB$json = {
  '1': 'ClassTypeInfoPB',
};

/// Descriptor for `ClassTypeInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List classTypeInfoPBDescriptor =
    $convert.base64Decode('Cg9DbGFzc1R5cGVJbmZvUEI=');

@$core.Deprecated('Use constantInfoPBDescriptor instead')
const ConstantInfoPB$json = {
  '1': 'ConstantInfoPB',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `ConstantInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List constantInfoPBDescriptor =
    $convert.base64Decode('Cg5Db25zdGFudEluZm9QQhISCgRjb2RlGAEgASgJUgRjb2Rl');

@$core.Deprecated('Use fieldInfoPBDescriptor instead')
const FieldInfoPB$json = {
  '1': 'FieldInfoPB',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'inferred_type', '3': 2, '4': 1, '5': 9, '10': 'inferredType'},
    {'1': 'children_ids', '3': 3, '4': 3, '5': 9, '10': 'childrenIds'},
    {'1': 'code', '3': 4, '4': 1, '5': 9, '10': 'code'},
    {'1': 'is_const', '3': 5, '4': 1, '5': 8, '10': 'isConst'},
    {'1': 'initializer_id', '3': 6, '4': 1, '5': 9, '10': 'initializerId'},
  ],
};

/// Descriptor for `FieldInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldInfoPBDescriptor = $convert.base64Decode(
    'CgtGaWVsZEluZm9QQhISCgR0eXBlGAEgASgJUgR0eXBlEiMKDWluZmVycmVkX3R5cGUYAiABKA'
    'lSDGluZmVycmVkVHlwZRIhCgxjaGlsZHJlbl9pZHMYAyADKAlSC2NoaWxkcmVuSWRzEhIKBGNv'
    'ZGUYBCABKAlSBGNvZGUSGQoIaXNfY29uc3QYBSABKAhSB2lzQ29uc3QSJQoOaW5pdGlhbGl6ZX'
    'JfaWQYBiABKAlSDWluaXRpYWxpemVySWQ=');

@$core.Deprecated('Use typedefInfoPBDescriptor instead')
const TypedefInfoPB$json = {
  '1': 'TypedefInfoPB',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
  ],
};

/// Descriptor for `TypedefInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typedefInfoPBDescriptor =
    $convert.base64Decode('Cg1UeXBlZGVmSW5mb1BCEhIKBHR5cGUYASABKAlSBHR5cGU=');

@$core.Deprecated('Use functionModifiersPBDescriptor instead')
const FunctionModifiersPB$json = {
  '1': 'FunctionModifiersPB',
  '2': [
    {'1': 'is_static', '3': 1, '4': 1, '5': 8, '10': 'isStatic'},
    {'1': 'is_const', '3': 2, '4': 1, '5': 8, '10': 'isConst'},
    {'1': 'is_factory', '3': 3, '4': 1, '5': 8, '10': 'isFactory'},
    {'1': 'is_external', '3': 4, '4': 1, '5': 8, '10': 'isExternal'},
  ],
};

/// Descriptor for `FunctionModifiersPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List functionModifiersPBDescriptor = $convert.base64Decode(
    'ChNGdW5jdGlvbk1vZGlmaWVyc1BCEhsKCWlzX3N0YXRpYxgBIAEoCFIIaXNTdGF0aWMSGQoIaX'
    'NfY29uc3QYAiABKAhSB2lzQ29uc3QSHQoKaXNfZmFjdG9yeRgDIAEoCFIJaXNGYWN0b3J5Eh8K'
    'C2lzX2V4dGVybmFsGAQgASgIUgppc0V4dGVybmFs');

@$core.Deprecated('Use parameterInfoPBDescriptor instead')
const ParameterInfoPB$json = {
  '1': 'ParameterInfoPB',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'declared_type', '3': 3, '4': 1, '5': 9, '10': 'declaredType'},
  ],
};

/// Descriptor for `ParameterInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parameterInfoPBDescriptor = $convert.base64Decode(
    'Cg9QYXJhbWV0ZXJJbmZvUEISEgoEbmFtZRgBIAEoCVIEbmFtZRISCgR0eXBlGAIgASgJUgR0eX'
    'BlEiMKDWRlY2xhcmVkX3R5cGUYAyABKAlSDGRlY2xhcmVkVHlwZQ==');

@$core.Deprecated('Use functionInfoPBDescriptor instead')
const FunctionInfoPB$json = {
  '1': 'FunctionInfoPB',
  '2': [
    {
      '1': 'function_modifiers',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.dart2js_info.proto.FunctionModifiersPB',
      '10': 'functionModifiers'
    },
    {'1': 'children_ids', '3': 2, '4': 3, '5': 9, '10': 'childrenIds'},
    {'1': 'return_type', '3': 3, '4': 1, '5': 9, '10': 'returnType'},
    {
      '1': 'inferred_return_type',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'inferredReturnType'
    },
    {
      '1': 'parameters',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.dart2js_info.proto.ParameterInfoPB',
      '10': 'parameters'
    },
    {'1': 'side_effects', '3': 6, '4': 1, '5': 9, '10': 'sideEffects'},
    {'1': 'inlined_count', '3': 7, '4': 1, '5': 5, '10': 'inlinedCount'},
    {'1': 'code', '3': 8, '4': 1, '5': 9, '10': 'code'},
  ],
  '9': [
    {'1': 9, '2': 10},
  ],
};

/// Descriptor for `FunctionInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List functionInfoPBDescriptor = $convert.base64Decode(
    'Cg5GdW5jdGlvbkluZm9QQhJWChJmdW5jdGlvbl9tb2RpZmllcnMYASABKAsyJy5kYXJ0MmpzX2'
    'luZm8ucHJvdG8uRnVuY3Rpb25Nb2RpZmllcnNQQlIRZnVuY3Rpb25Nb2RpZmllcnMSIQoMY2hp'
    'bGRyZW5faWRzGAIgAygJUgtjaGlsZHJlbklkcxIfCgtyZXR1cm5fdHlwZRgDIAEoCVIKcmV0dX'
    'JuVHlwZRIwChRpbmZlcnJlZF9yZXR1cm5fdHlwZRgEIAEoCVISaW5mZXJyZWRSZXR1cm5UeXBl'
    'EkMKCnBhcmFtZXRlcnMYBSADKAsyIy5kYXJ0MmpzX2luZm8ucHJvdG8uUGFyYW1ldGVySW5mb1'
    'BCUgpwYXJhbWV0ZXJzEiEKDHNpZGVfZWZmZWN0cxgGIAEoCVILc2lkZUVmZmVjdHMSIwoNaW5s'
    'aW5lZF9jb3VudBgHIAEoBVIMaW5saW5lZENvdW50EhIKBGNvZGUYCCABKAlSBGNvZGVKBAgJEA'
    'o=');

@$core.Deprecated('Use closureInfoPBDescriptor instead')
const ClosureInfoPB$json = {
  '1': 'ClosureInfoPB',
  '2': [
    {'1': 'function_id', '3': 1, '4': 1, '5': 9, '10': 'functionId'},
  ],
};

/// Descriptor for `ClosureInfoPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closureInfoPBDescriptor = $convert.base64Decode(
    'Cg1DbG9zdXJlSW5mb1BCEh8KC2Z1bmN0aW9uX2lkGAEgASgJUgpmdW5jdGlvbklk');

@$core.Deprecated('Use deferredImportPBDescriptor instead')
const DeferredImportPB$json = {
  '1': 'DeferredImportPB',
  '2': [
    {'1': 'prefix', '3': 1, '4': 1, '5': 9, '10': 'prefix'},
    {'1': 'files', '3': 2, '4': 3, '5': 9, '10': 'files'},
  ],
};

/// Descriptor for `DeferredImportPB`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deferredImportPBDescriptor = $convert.base64Decode(
    'ChBEZWZlcnJlZEltcG9ydFBCEhYKBnByZWZpeBgBIAEoCVIGcHJlZml4EhQKBWZpbGVzGAIgAy'
    'gJUgVmaWxlcw==');

@$core.Deprecated('Use libraryDeferredImportsPBDescriptor instead')
const LibraryDeferredImportsPB$json = {
  '1': 'LibraryDeferredImportsPB',
  '2': [
    {'1': 'library_uri', '3': 1, '4': 1, '5': 9, '10': 'libraryUri'},
    {'1': 'library_name', '3': 2, '4': 1, '5': 9, '10': 'libraryName'},
    {
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
final $typed_data.Uint8List libraryDeferredImportsPBDescriptor = $convert.base64Decode(
    'ChhMaWJyYXJ5RGVmZXJyZWRJbXBvcnRzUEISHwoLbGlicmFyeV91cmkYASABKAlSCmxpYnJhcn'
    'lVcmkSIQoMbGlicmFyeV9uYW1lGAIgASgJUgtsaWJyYXJ5TmFtZRI+CgdpbXBvcnRzGAMgAygL'
    'MiQuZGFydDJqc19pbmZvLnByb3RvLkRlZmVycmVkSW1wb3J0UEJSB2ltcG9ydHM=');
