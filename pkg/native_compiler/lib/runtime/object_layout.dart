// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:native_compiler/runtime/vm_defs.dart';

/// Memory access order for fields accessed concurrently.
enum MemoryOrder {
  /// No ordering constraints.
  relaxed,

  /// Load performs acquire and store performs release.
  acquireRelease,
}

/// Computes layout of Dart objects (field offsets and instance size).
class ObjectLayout {
  final VMOffsets vmOffsets;
  final int wordSize;
  final int compressedWordSize;

  /// Instance size before rounding.
  final Map<ast.Class, int> _instanceSize = {};

  /// Name of the implicit type arguments field.
  late final ast.Name _typeArgumentsFieldName = ast.Name('#typeArguments');

  /// Implicit type arguments field for a class.
  final Map<ast.Class, CField> _typeArgumentsField = {};

  /// Field offsets.
  final Map<CField, int> _fieldOffset = {};

  /// Fields stored as unboxed values.
  final Set<CField> _unboxedFields = {};

  /// Field memory order (if not relaxed).
  final Map<CField, MemoryOrder> _fieldMemoryOrder = {};

  ObjectLayout(
    this.vmOffsets, {
    required this.wordSize,
    required this.compressedWordSize,
  });

  /// Return true if [value] can be represented as a Smi (small integer).
  bool isSmi(int value) {
    final shiftedOut = value >> smiBits(compressedWordSize);
    return shiftedOut == 0 || shiftedOut == -1;
  }

  int getUnalignedInstanceSize(ast.Class cls) {
    _ensureComputed(cls);
    return _instanceSize[cls]!;
  }

  int getInstanceSize(ast.Class cls) {
    return roundUp(getUnalignedInstanceSize(cls), objectAlignment(wordSize));
  }

  int getFieldOffset(CField field) {
    assert(!field.isStatic);
    if (field.isSynthetic) {
      return switch (field.asSynthetic) {
        ContextField(:var index) => vmOffsets.Context_elementOffset(index),
        ClosureField(:var index) => vmOffsets.Closure_elementOffset(index),
        RecordField(:var index) => vmOffsets.Record_elementOffset(index),
      };
    }
    _ensureComputed(field.enclosingClass);
    return _fieldOffset[field]!;
  }

  bool isUnboxedField(CField field) {
    // TODO: support unboxed Dart fields.
    return _unboxedFields.contains(field);
  }

  MemoryOrder getFieldMemoryOrder(CField field) {
    return _fieldMemoryOrder[field] ?? MemoryOrder.relaxed;
  }

  CField? getTypeArgumentsField(ast.Class cls) {
    _ensureComputed(cls);
    return _typeArgumentsField[cls];
  }

  bool _isComputed(ast.Class cls) => _instanceSize.containsKey(cls);

  void _ensureComputed(ast.Class cls) {
    if (!_isComputed(cls)) {
      _computeLayout(cls);
    }
  }

  void _computeLayout(ast.Class cls) {
    if (_computeLayoutOfBuiltinClass(cls)) {
      return;
    }

    final superclass = cls.superclass;
    if (superclass != null) {
      _ensureComputed(superclass);
    }

    int nextOffset = _instanceSize[superclass]!;

    final superTypeArgs = superclass != null
        ? _typeArgumentsField[superclass]
        : null;
    if (superTypeArgs != null) {
      // Inherit type arguments field from generic superclass.
      _typeArgumentsField[cls] = superTypeArgs;
    } else if (cls.typeParameters.isNotEmpty) {
      // This class is generic but superclass is not, so
      // introduce a new implicit type arguments field.
      final typeArgs = _createTypeArgumentsField(cls);
      _fieldOffset[typeArgs] = nextOffset;
      nextOffset += compressedWordSize;
    }

    for (final field in cls.fields) {
      if (!field.isStatic) {
        _fieldOffset[CField(field)] = nextOffset;
        nextOffset += compressedWordSize;
      }
    }

    _instanceSize[cls] = nextOffset;
  }

  CField _createTypeArgumentsField(ast.Class cls) {
    final field = CField(
      ast.Field.immutable(
        _typeArgumentsFieldName,
        isFinal: true,
        isStatic: false,
        fileUri: ast.dummyUri,
      )..parent = cls,
    );
    _typeArgumentsField[cls] = field;
    return field;
  }

  CField _createBuiltinField(
    ast.Class cls,
    String name,
    ast.DartType type,
    int? offset, {
    bool isFinal = false,
    bool isUnboxed = false,
    MemoryOrder memoryOrder = .relaxed,
  }) {
    final fieldNode = isFinal
        ? ast.Field.immutable(ast.Name(name), type: type, fileUri: ast.dummyUri)
        : ast.Field.mutable(ast.Name(name), type: type, fileUri: ast.dummyUri);
    fieldNode.parent = cls;
    final field = CField(fieldNode);
    if (offset != null) {
      _fieldOffset[field] = offset;
    }
    if (isUnboxed) {
      _unboxedFields.add(field);
    }
    if (memoryOrder != .relaxed) {
      _fieldMemoryOrder[field] = memoryOrder;
    }
    return field;
  }

  late final CoreTypes _coreTypes = GlobalContext.instance.coreTypes;
  late final LibraryIndex _libraryIndex = GlobalContext.instance.coreLibraries;

  late final ast.Class _stringBaseClass = _libraryIndex.getClass(
    'dart:core',
    '_StringBase',
  );
  late final ast.Class _arrayClass = _libraryIndex.getClass(
    'dart:core',
    '_Array',
  );
  late final ast.Class _growableListClass = _libraryIndex.getClass(
    'dart:core',
    '_GrowableList',
  );
  late final ast.Class _closureClass = _libraryIndex.getClass(
    'dart:core',
    '_Closure',
  );
  late final ast.Class _abstractTypeClass = _libraryIndex.getClass(
    'dart:core',
    '_AbstractType',
  );
  late final ast.Class _weakPropertyClass = _libraryIndex.getClass(
    'dart:core',
    '_WeakProperty',
  );
  late final ast.Class _weakReferenceClass = _libraryIndex.getClass(
    'dart:core',
    '_WeakReference',
  );
  late final ast.Class _finalizerImplClass = _libraryIndex.getClass(
    'dart:core',
    '_FinalizerImpl',
  );
  late final ast.Class _linkedHashBaseClass = _libraryIndex.getClass(
    'dart:_compact_hash',
    '_LinkedHashBase',
  );
  late final ast.Class _linkedHashImmutableBaseClass = _libraryIndex.getClass(
    'dart:_compact_hash',
    '_LinkedHashImmutableBase',
  );
  late final ast.Class _finalizerBaseClass = _libraryIndex.getClass(
    'dart:_internal',
    'FinalizerBase',
  );
  late final ast.Class _finalizerEntryClass = _libraryIndex.getClass(
    'dart:_internal',
    'FinalizerEntry',
  );
  late final ast.Class _suspendStateClass = _libraryIndex.getClass(
    'dart:async',
    '_SuspendState',
  );
  late final ast.Class _rawReceivePortClass = _libraryIndex.getClass(
    'dart:isolate',
    '_RawReceivePort',
  );
  late final ast.Class _sendPortClass = _libraryIndex.getClass(
    'dart:isolate',
    'SendPort',
  );
  // Synthetic common base class for all typed data lists and ffi Pointer.
  late final ast.Class _pointerBaseClass = ast.Class(
    name: '#PointerBase',
    supertype: ast.Supertype(_coreTypes.objectClass, ast.DartTypeList.empty),
    fileUri: ast.dummyUri,
  )..parent = _coreTypes.coreLibrary;
  late final ast.Class _typedListBaseClass = _libraryIndex.getClass(
    'dart:typed_data',
    '_TypedListBase',
  );
  late final ast.Class _typedListClass = _libraryIndex.getClass(
    'dart:typed_data',
    '_TypedList',
  );
  late final ast.Class _typedListViewClass = _libraryIndex.getClass(
    'dart:typed_data',
    '_TypedListView',
  );
  late final ast.Class _uint32ListClass = _libraryIndex.getClass(
    'dart:typed_data',
    'Uint32List',
  );

  // dart:core
  late final CField Object_classId = _createBuiltinField(
    _coreTypes.objectClass,
    '#classId',
    _coreTypes.intNonNullableRawType,
    null, // Bit field of tags field, implemented in code generator.
    isFinal: true,
    isUnboxed: true,
  );
  late final CField StringBase_length = _createBuiltinField(
    _stringBaseClass,
    'length',
    _coreTypes.intNonNullableRawType,
    vmOffsets.String_length_offset,
    isFinal: true,
  );
  late final CField Array_length = _createBuiltinField(
    _arrayClass,
    'length',
    _coreTypes.intNonNullableRawType,
    vmOffsets.Array_length_offset,
    isFinal: true,
  );
  late final CField GrowableList_length = _createBuiltinField(
    _growableListClass,
    'length',
    _coreTypes.intNonNullableRawType,
    vmOffsets.GrowableObjectArray_length_offset,
  );
  late final CField GrowableList_data = _createBuiltinField(
    _growableListClass,
    'data',
    _coreTypes.nonNullableRawType(_arrayClass),
    vmOffsets.GrowableObjectArray_data_offset,
  );
  late final CField WeakProperty_key = _createBuiltinField(
    _weakPropertyClass,
    'key',
    const ast.DynamicType(),
    vmOffsets.WeakProperty_key_offset,
  );
  late final CField WeakProperty_value = _createBuiltinField(
    _weakPropertyClass,
    'value',
    const ast.DynamicType(),
    vmOffsets.WeakProperty_value_offset,
  );
  late final CField WeakReference_target = _createBuiltinField(
    _weakReferenceClass,
    'target',
    ast.TypeParameterType(_weakReferenceClass.typeParameters.single, .nullable),
    vmOffsets.WeakReference_target_offset,
  );
  late final CField Closure_hash = _createBuiltinField(
    _closureClass,
    'hash',
    _coreTypes.intNonNullableRawType,
    vmOffsets.Closure_hash_offset,
  );
  late final CField AbstractType_hash = _createBuiltinField(
    _abstractTypeClass,
    'hash',
    _coreTypes.intNonNullableRawType,
    vmOffsets.AbstractType_hash_offset,
  );
  late final CField FinalizerImpl_callback = _createBuiltinField(
    _finalizerImplClass,
    'callback',
    ast.FunctionType(
      ast.DartTypeList(
        ast.TypeParameterType.withDefaultNullability(
          _finalizerImplClass.typeParameters.single,
        ),
      ),
      const ast.VoidType(),
      .nonNullable,
    ),
    vmOffsets.Finalizer_callback_offset,
  );

  // dart:_compact_hash
  late final CField LinkedHashBase_index = _createBuiltinField(
    _linkedHashBaseClass,
    'index',
    _coreTypes.nonNullableRawType(_uint32ListClass),
    vmOffsets.LinkedHashBase_index_offset,
  );
  late final CField LinkedHashBase_hashMask = _createBuiltinField(
    _linkedHashBaseClass,
    'hashMask',
    _coreTypes.intNonNullableRawType,
    vmOffsets.LinkedHashBase_hash_mask_offset,
  );
  late final CField LinkedHashBase_data = _createBuiltinField(
    _linkedHashBaseClass,
    'data',
    _coreTypes.listNonNullableRawType,
    vmOffsets.LinkedHashBase_data_offset,
  );
  late final CField LinkedHashBase_usedData = _createBuiltinField(
    _linkedHashBaseClass,
    'usedData',
    _coreTypes.intNonNullableRawType,
    vmOffsets.LinkedHashBase_used_data_offset,
  );
  late final CField LinkedHashBase_deletedKeys = _createBuiltinField(
    _linkedHashBaseClass,
    'deletedKeys',
    _coreTypes.intNonNullableRawType,
    vmOffsets.LinkedHashBase_deleted_keys_offset,
  );
  late final CField LinkedHashImmutableBase_index = _createBuiltinField(
    _linkedHashImmutableBaseClass,
    'index',
    _coreTypes.nullableRawType(_uint32ListClass),
    vmOffsets.LinkedHashBase_index_offset,
    memoryOrder: .acquireRelease,
  );

  // dart:_internal
  late final CField FinalizerBase_isolate = _createBuiltinField(
    _finalizerBaseClass,
    'isolate',
    _coreTypes.intNonNullableRawType, // Address
    vmOffsets.FinalizerBase_isolate_offset,
    isUnboxed: true,
  );
  late final CField FinalizerBase_allEntries = _createBuiltinField(
    _finalizerBaseClass,
    'allEntries',
    ast.InterfaceType(
      _coreTypes.setClass,
      .nonNullable,
      ast.DartTypeList(_coreTypes.nonNullableRawType(_finalizerEntryClass)),
    ),
    vmOffsets.FinalizerBase_all_entries_offset,
  );
  late final CField FinalizerEntry_value = _createBuiltinField(
    _finalizerEntryClass,
    'value',
    _coreTypes.objectNullableRawType,
    vmOffsets.FinalizerEntry_value_offset,
  );
  late final CField FinalizerEntry_detach = _createBuiltinField(
    _finalizerEntryClass,
    'detach',
    _coreTypes.objectNullableRawType,
    vmOffsets.FinalizerEntry_detach_offset,
  );
  late final CField FinalizerEntry_token = _createBuiltinField(
    _finalizerEntryClass,
    'token',
    _coreTypes.objectNullableRawType,
    vmOffsets.FinalizerEntry_token_offset,
  );
  late final CField FinalizerEntry_finalizer = _createBuiltinField(
    _finalizerEntryClass,
    'finalizer',
    _coreTypes.nonNullableRawType(_finalizerBaseClass),
    vmOffsets.FinalizerEntry_finalizer_offset,
  );
  late final CField FinalizerEntry_externalSize = _createBuiltinField(
    _finalizerEntryClass,
    'externalSize',
    _coreTypes.intNonNullableRawType, // intptr_t
    vmOffsets.FinalizerEntry_external_size_offset,
  );

  // dart:async
  late final CField SuspendState_functionData = _createBuiltinField(
    _suspendStateClass,
    'functionData',
    _coreTypes.objectNonNullableRawType,
    vmOffsets.SuspendState_function_data_offset,
  );
  late final CField SuspendState_thenCallback = _createBuiltinField(
    _suspendStateClass,
    'thenCallback',
    ast.FunctionType(
      ast.DartTypeList.dynamic1,
      const ast.VoidType(),
      .nullable,
    ),
    vmOffsets.SuspendState_then_callback_offset,
  );
  late final CField SuspendState_errorCallback = _createBuiltinField(
    _suspendStateClass,
    'errorCallback',
    ast.FunctionType(
      ast.DartTypeList(
        _coreTypes.objectNonNullableRawType,
        _coreTypes.stackTraceNonNullableRawType,
      ),
      const ast.DynamicType(),
      .nullable,
    ),
    vmOffsets.SuspendState_error_callback_offset,
  );

  // dart:isolate
  late final CField RawReceivePort_handler = _createBuiltinField(
    _rawReceivePortClass,
    'handler',
    _coreTypes.functionNullableRawType,
    vmOffsets.ReceivePort_handler_offset,
  );
  late final CField RawReceivePort_sendPort = _createBuiltinField(
    _rawReceivePortClass,
    'sendPort',
    _coreTypes.nonNullableRawType(_sendPortClass),
    vmOffsets.ReceivePort_send_port_offset,
    isFinal: true,
  );

  // dart:typed_data
  late final CField PointerBase_data = _createBuiltinField(
    _pointerBaseClass,
    'data',
    _coreTypes.intNonNullableRawType,
    vmOffsets.PointerBase_data_offset,
    isFinal: true,
    isUnboxed: true,
  );
  late final CField TypedListBase_length = _createBuiltinField(
    _typedListBaseClass,
    'length',
    _coreTypes.intNonNullableRawType,
    vmOffsets.TypedDataBase_length_offset,
    isFinal: true,
  );
  late final CField TypedListView_typedData = _createBuiltinField(
    _typedListViewClass,
    'typedData',
    _coreTypes.nonNullableRawType(_typedListClass),
    vmOffsets.TypedDataView_typed_data_offset,
    isFinal: true,
  );
  late final CField TypedListView_offsetInBytes = _createBuiltinField(
    _typedListViewClass,
    'offsetInBytes',
    _coreTypes.intNonNullableRawType,
    vmOffsets.TypedDataView_offset_in_bytes_offset,
    isFinal: true,
  );

  // External non-Dart fields.
  late final ast.Class _threadClass = ast.Class(
    name: '#Thread',
    supertype: ast.Supertype(_coreTypes.objectClass, ast.DartTypeList.empty),
    fileUri: ast.dummyUri,
  )..parent = _vmLibrary;
  late final CField Thread_isolate = _createBuiltinField(
    _threadClass,
    'isolate',
    _coreTypes.intNonNullableRawType, // Address.
    vmOffsets.Thread_isolate_offset,
    isUnboxed: true,
  );
  late final CField Thread_isolateGroup = _createBuiltinField(
    _threadClass,
    'isolateGroup',
    _coreTypes.intNonNullableRawType, // Address.
    vmOffsets.Thread_isolate_group_offset,
    isUnboxed: true,
  );
  late final CField Thread_threadLocals = _createBuiltinField(
    _threadClass,
    'threadLocals',
    _coreTypes.listNonNullableRawType,
    vmOffsets.Thread_thread_locals_offset,
  );
  late final CField Thread_nextTaskId = _createBuiltinField(
    _threadClass,
    'nextTaskId',
    _coreTypes.intNonNullableRawType,
    vmOffsets.Thread_next_task_id_offset,
    isUnboxed: true,
  );
  late final CField Thread_dartStream = _createBuiltinField(
    _threadClass,
    'dartStream',
    _coreTypes.intNonNullableRawType, // Address.
    vmOffsets.Thread_dart_stream_offset,
    isUnboxed: true,
  );
  late final CField Thread_serviceExtensionStream = _createBuiltinField(
    _threadClass,
    'serviceExtensionStream',
    _coreTypes.intNonNullableRawType, // Address.
    vmOffsets.Thread_service_extension_stream_offset,
    isUnboxed: true,
  );
  late final CField Thread_predefined_symbols_address = _createBuiltinField(
    _threadClass,
    'predefinedSymbolsAddress',
    _coreTypes.intNonNullableRawType, // Address.
    vmOffsets.Thread_predefined_symbols_address_offset,
    isUnboxed: true,
  );
  late final ast.Class _isolateClass = ast.Class(
    name: '#Isolate',
    supertype: ast.Supertype(_coreTypes.objectClass, ast.DartTypeList.empty),
    fileUri: ast.dummyUri,
  )..parent = _vmLibrary;
  late final CField Isolate_finalizers = _createBuiltinField(
    _isolateClass,
    'finalizers',
    _coreTypes.listNullableRawType,
    vmOffsets.Isolate_finalizers_offset,
  );
  late final ast.Class _timelineStreamClass = ast.Class(
    name: '#TimelineStream',
    supertype: ast.Supertype(_coreTypes.objectClass, ast.DartTypeList.empty),
    fileUri: ast.dummyUri,
  )..parent = _vmLibrary;
  late final CField TimelineStream_enabled = _createBuiltinField(
    _timelineStreamClass,
    'enabled',
    _coreTypes.intNonNullableRawType, // uintptr_t
    vmOffsets.TimelineStream_enabled_offset,
    isUnboxed: true,
  );
  late final ast.Class _streamInfoClass = ast.Class(
    name: '#StreamInfo',
    supertype: ast.Supertype(_coreTypes.objectClass, ast.DartTypeList.empty),
    fileUri: ast.dummyUri,
  )..parent = _vmLibrary;
  late final CField StreamInfo_enabled = _createBuiltinField(
    _streamInfoClass,
    'enabled',
    _coreTypes.intNonNullableRawType, // intptr_t
    vmOffsets.StreamInfo_enabled_offset,
    isUnboxed: true,
  );

  // Layout of built-in instances is specified either as
  // 'int size' or '(int size, int typeArgsOffset)' if class is generic.

  late final Map<String, Object> _dartCoreInstanceLayout = {
    '_Double': vmOffsets.Double_InstanceSize,
    '_GrowableList': (
      vmOffsets.GrowableObjectArray_InstanceSize,
      vmOffsets.GrowableObjectArray_type_arguments_offset,
    ),
    '_Mint': vmOffsets.Mint_InstanceSize,
    '_WeakProperty': vmOffsets.WeakProperty_InstanceSize,
    '_WeakReference': (
      vmOffsets.WeakReference_InstanceSize,
      vmOffsets.WeakReference_type_arguments_offset,
    ),
    '_FinalizerImpl': (
      vmOffsets.Finalizer_InstanceSize,
      vmOffsets.Finalizer_type_arguments_offset,
    ),
    'Object': vmOffsets.Instance_InstanceSize,
  };

  late final Map<String, Object> _dartTypedDataInstanceLayout = {
    '_Int32x4': vmOffsets.Int32x4_InstanceSize,
    '_Float32x4': vmOffsets.Float32x4_InstanceSize,
    '_Float64x2': vmOffsets.Float64x2_InstanceSize,
    '_TypedListView': vmOffsets.TypedDataView_InstanceSize,
    '_ByteDataView': vmOffsets.TypedDataView_InstanceSize,
    // TODO: add other built-in classes from dart:typed_data
  };

  late final Map<String, Object> _dartCompactHashInstanceLayout = {
    '_LinkedHashBase': (
      vmOffsets.LinkedHashBase_InstanceSize,
      vmOffsets.LinkedHashBase_type_arguments_offset,
    ),
  };

  late final Map<String, Object> _dartInternalInstanceLayout = {
    'FinalizerEntry': vmOffsets.FinalizerEntry_InstanceSize,
  };

  late final Map<String, Object> _dartNativewrappersInstanceLayout = {
    'NativeFieldWrapperClass1':
        vmOffsets.Instance_InstanceSize + compressedWordSize,
    'NativeFieldWrapperClass2':
        vmOffsets.Instance_InstanceSize + compressedWordSize,
    'NativeFieldWrapperClass3':
        vmOffsets.Instance_InstanceSize + compressedWordSize,
    'NativeFieldWrapperClass4':
        vmOffsets.Instance_InstanceSize + compressedWordSize,
  };

  late final Map<String, Object> _dartVmInstanceLayout = {'#Thread': 0};

  late final ast.Library _typedDataLibrary = _libraryIndex.getLibrary(
    'dart:typed_data',
  );
  late final ast.Library _compactHashLibrary = _libraryIndex.getLibrary(
    'dart:_compact_hash',
  );
  late final ast.Library _internalLibrary = _libraryIndex.getLibrary(
    'dart:_internal',
  );
  late final ast.Library _nativewrappersLibrary = _libraryIndex.getLibrary(
    'dart:nativewrappers',
  );
  late final ast.Library _vmLibrary = _libraryIndex.getLibrary('dart:_vm');

  bool _computeLayoutOfBuiltinClass(ast.Class cls) {
    final library = cls.enclosingLibrary;
    if (!library.importUri.isScheme('dart')) {
      return false;
    }
    Object? layout;
    if (library == _coreTypes.coreLibrary) {
      layout = _dartCoreInstanceLayout[cls.name];
    } else if (library == _typedDataLibrary) {
      layout = _dartTypedDataInstanceLayout[cls.name];
    } else if (library == _compactHashLibrary) {
      layout = _dartCompactHashInstanceLayout[cls.name];
    } else if (library == _internalLibrary) {
      layout = _dartInternalInstanceLayout[cls.name];
    } else if (library == _nativewrappersLibrary) {
      layout = _dartNativewrappersInstanceLayout[cls.name];
    } else if (library == _vmLibrary) {
      layout = _dartVmInstanceLayout[cls.name];
    }
    // TODO: add built-in classes from dart:ffi
    if (layout != null) {
      switch (layout) {
        case int():
          _instanceSize[cls] = layout;
          break;
        case (int size, int typeArgsOffset):
          _instanceSize[cls] = size;
          _fieldOffset[_createTypeArgumentsField(cls)] = typeArgsOffset;
          break;
        default:
          throw 'Unexpected built-in class layout ${layout.runtimeType} $layout';
      }
      return true;
    }
    return false;
  }
}
