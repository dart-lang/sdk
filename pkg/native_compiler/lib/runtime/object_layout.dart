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
    if (_computeLayoutOfBuiltInClass(cls)) {
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

  CField _createBuiltInField(
    ast.Class cls,
    String name,
    ast.DartType type,
    int? offset, {
    bool isFinal = false,
    bool isUnboxed = false,
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
  late final ast.Class _linkedHashBaseClass = _libraryIndex.getClass(
    'dart:_compact_hash',
    '_LinkedHashBase',
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
  late final ast.Class _typedListBaseClass = _libraryIndex.getClass(
    'dart:typed_data',
    '_TypedListBase',
  );
  late final ast.Class _uint32ListClass = _libraryIndex.getClass(
    'dart:typed_data',
    'Uint32List',
  );

  // dart:core
  late final CField Object_classId = _createBuiltInField(
    _coreTypes.objectClass,
    '#classId',
    _coreTypes.intNonNullableRawType,
    null, // Bit field of tags field, implemented in code generator.
    isFinal: true,
    isUnboxed: true,
  );
  late final CField StringBase_length = _createBuiltInField(
    _stringBaseClass,
    'length',
    _coreTypes.intNonNullableRawType,
    vmOffsets.String_length_offset,
    isFinal: true,
  );
  late final CField Array_length = _createBuiltInField(
    _arrayClass,
    'length',
    _coreTypes.intNonNullableRawType,
    vmOffsets.Array_length_offset,
    isFinal: true,
  );
  late final CField GrowableList_length = _createBuiltInField(
    _growableListClass,
    'length',
    _coreTypes.intNonNullableRawType,
    vmOffsets.GrowableObjectArray_length_offset,
  );
  late final CField GrowableList_data = _createBuiltInField(
    _growableListClass,
    'data',
    _coreTypes.nonNullableRawType(_arrayClass),
    vmOffsets.GrowableObjectArray_data_offset,
  );

  // dart:_compact_hash
  late final CField LinkedHashBase_index = _createBuiltInField(
    _linkedHashBaseClass,
    'index',
    _coreTypes.nonNullableRawType(_uint32ListClass),
    vmOffsets.LinkedHashBase_index_offset,
  );
  late final CField LinkedHashBase_hashMask = _createBuiltInField(
    _linkedHashBaseClass,
    'hashMask',
    _coreTypes.intNonNullableRawType,
    vmOffsets.LinkedHashBase_hash_mask_offset,
  );
  late final CField LinkedHashBase_data = _createBuiltInField(
    _linkedHashBaseClass,
    'data',
    _coreTypes.listNonNullableRawType,
    vmOffsets.LinkedHashBase_data_offset,
  );
  late final CField LinkedHashBase_usedData = _createBuiltInField(
    _linkedHashBaseClass,
    'usedData',
    _coreTypes.intNonNullableRawType,
    vmOffsets.LinkedHashBase_used_data_offset,
  );
  late final CField LinkedHashBase_deletedKeys = _createBuiltInField(
    _linkedHashBaseClass,
    'deletedKeys',
    _coreTypes.intNonNullableRawType,
    vmOffsets.LinkedHashBase_deleted_keys_offset,
  );

  // dart:async
  late final CField SuspendState_functionData = _createBuiltInField(
    _suspendStateClass,
    'functionData',
    _coreTypes.objectNonNullableRawType,
    vmOffsets.SuspendState_function_data_offset,
  );
  late final CField SuspendState_thenCallback = _createBuiltInField(
    _suspendStateClass,
    'thenCallback',
    ast.FunctionType(
      [const ast.DynamicType()],
      const ast.VoidType(),
      .nullable,
    ),
    vmOffsets.SuspendState_then_callback_offset,
  );
  late final CField SuspendState_errorCallback = _createBuiltInField(
    _suspendStateClass,
    'errorCallback',
    ast.FunctionType(
      [
        _coreTypes.objectNonNullableRawType,
        _coreTypes.stackTraceNonNullableRawType,
      ],
      const ast.DynamicType(),
      .nullable,
    ),
    vmOffsets.SuspendState_error_callback_offset,
  );

  // dart:isolate
  late final CField RawReceivePort_handler = _createBuiltInField(
    _rawReceivePortClass,
    'handler',
    _coreTypes.functionNullableRawType,
    vmOffsets.ReceivePort_handler_offset,
  );
  late final CField RawReceivePort_sendPort = _createBuiltInField(
    _rawReceivePortClass,
    'sendPort',
    _coreTypes.nonNullableRawType(_sendPortClass),
    vmOffsets.ReceivePort_send_port_offset,
    isFinal: true,
  );

  // dart:typed_data
  late final CField TypedListBase_length = _createBuiltInField(
    _typedListBaseClass,
    'length',
    _coreTypes.intNonNullableRawType,
    vmOffsets.TypedDataBase_length_offset,
    isFinal: true,
  );

  // External non-Dart fields.
  late final ast.Class _threadClass = ast.Class(
    name: '#Thread',
    supertype: ast.Supertype(_coreTypes.objectClass, const []),
    fileUri: ast.dummyUri,
  )..parent = _vmLibrary;
  late final CField Thread_threadLocals = _createBuiltInField(
    _threadClass,
    'threadLocals',
    _coreTypes.listNonNullableRawType,
    vmOffsets.Thread_thread_locals_offset,
  );
  late final CField Thread_predefined_symbols_address = _createBuiltInField(
    _threadClass,
    'predefinedSymbolsAddress',
    _coreTypes.intNonNullableRawType, // Address.
    vmOffsets.Thread_predefined_symbols_address_offset,
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
    'Object': vmOffsets.Instance_InstanceSize,
  };

  late final Map<String, Object> _dartTypedDataInstanceLayout = {
    '_Int32x4': vmOffsets.Int32x4_InstanceSize,
    '_Float32x4': vmOffsets.Float32x4_InstanceSize,
    '_Float64x2': vmOffsets.Float64x2_InstanceSize,
    // TODO: add other built-in classes from dart:typed_data
  };

  late final Map<String, Object> _dartCompactHashInstanceLayout = {
    '_LinkedHashBase': (
      vmOffsets.LinkedHashBase_InstanceSize,
      vmOffsets.LinkedHashBase_type_arguments_offset,
    ),
  };

  late final Map<String, Object> _dartVmInstanceLayout = {'#Thread': 0};

  late final ast.Library _typedDataLibrary = _libraryIndex.getLibrary(
    'dart:typed_data',
  );
  late final ast.Library _compactHashLibrary = _libraryIndex.getLibrary(
    'dart:_compact_hash',
  );
  late final ast.Library _vmLibrary = _libraryIndex.getLibrary('dart:_vm');

  bool _computeLayoutOfBuiltInClass(ast.Class cls) {
    final library = cls.enclosingLibrary;
    if (!library.importUri.isScheme('dart')) {
      return false;
    }
    Object? layout;
    if (library == GlobalContext.instance.coreTypes.coreLibrary) {
      layout = _dartCoreInstanceLayout[cls.name];
    } else if (library == _typedDataLibrary) {
      layout = _dartTypedDataInstanceLayout[cls.name];
    } else if (library == _compactHashLibrary) {
      layout = _dartCompactHashInstanceLayout[cls.name];
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
