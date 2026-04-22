// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;
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
    _ensureComputed(field.enclosingClass);
    return _fieldOffset[field]!;
  }

  bool isUnboxedField(CField field) {
    // TODO: support unboxed fields.
    return false;
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

  late final ast.Library _typedDataLibrary = GlobalContext
      .instance
      .coreTypes
      .index
      .getLibrary('dart:typed_data');
  late final ast.Library _compactHashLibrary = GlobalContext
      .instance
      .coreTypes
      .index
      .getLibrary('dart:_compact_hash');

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
