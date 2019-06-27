// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.ffi_use_sites;

import 'package:front_end/src/api_unstable/vm.dart'
    show
        templateFfiTypeInvalid,
        templateFfiTypeMismatch,
        templateFfiDartTypeMismatch,
        templateFfiTypeUnsized,
        templateFfiNotStatic;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;

import 'ffi.dart'
    show
        ReplacedMembers,
        NativeType,
        kNativeTypeIntStart,
        kNativeTypeIntEnd,
        FfiTransformer;

/// Checks and replaces calls to dart:ffi struct fields and methods.
void transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReplacedMembers replacedFields) {
  final index = new LibraryIndex(component, ["dart:ffi"]);
  if (!index.containsLibrary("dart:ffi")) {
    // if dart:ffi is not loaded, do not do the transformation
    return;
  }
  final transformer = new _FfiUseSiteTransformer(
      index,
      coreTypes,
      hierarchy,
      diagnosticReporter,
      replacedFields.replacedGetters,
      replacedFields.replacedSetters);
  libraries.forEach(transformer.visitLibrary);
}

/// Checks and replaces calls to dart:ffi struct fields and methods.
class _FfiUseSiteTransformer extends FfiTransformer {
  final Map<Field, Procedure> replacedGetters;
  final Map<Field, Procedure> replacedSetters;

  bool isFfiLibrary;

  _FfiUseSiteTransformer(
      LibraryIndex index,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      DiagnosticReporter diagnosticReporter,
      this.replacedGetters,
      this.replacedSetters)
      : super(index, coreTypes, hierarchy, diagnosticReporter) {}

  @override
  TreeNode visitLibrary(Library node) {
    isFfiLibrary = node == ffiLibrary;
    return super.visitLibrary(node);
  }

  @override
  visitClass(Class node) {
    env.thisType = InterfaceType(node);
    try {
      return super.visitClass(node);
    } finally {
      env.thisType = null;
    }
  }

  @override
  visitPropertyGet(PropertyGet node) {
    super.visitPropertyGet(node);

    Procedure replacedWith = replacedGetters[node.interfaceTarget];
    if (replacedWith != null) {
      node = PropertyGet(node.receiver, replacedWith.name, replacedWith);
    }

    return node;
  }

  @override
  visitPropertySet(PropertySet node) {
    super.visitPropertySet(node);

    Procedure replacedWith = replacedSetters[node.interfaceTarget];
    if (replacedWith != null) {
      node = PropertySet(
          node.receiver, replacedWith.name, node.value, replacedWith);
    }

    return node;
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);

    Member target = node.target;
    try {
      if (target == fromFunctionMethod) {
        DartType nativeType =
            InterfaceType(nativeFunctionClass, [node.arguments.types[0]]);
        Expression func = node.arguments.positional[0];
        DartType dartType = func.getStaticType(env);

        _ensureIsStatic(func);
        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);

        // Check `exceptionalReturn`'s type.
        final FunctionType funcType = dartType;
        final Expression exceptionalReturn = node.arguments.positional[1];
        final DartType returnType = exceptionalReturn.getStaticType(env);

        if (!env.isSubtypeOf(returnType, funcType.returnType)) {
          diagnosticReporter.report(
              templateFfiDartTypeMismatch.withArguments(
                  returnType, funcType.returnType),
              exceptionalReturn.fileOffset,
              1,
              exceptionalReturn.location.file);
        }
      }
    } catch (_FfiStaticTypeError) {}

    return node;
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    Member target = node.interfaceTarget;
    try {
      if (target == lookupFunctionMethod) {
        DartType nativeType =
            InterfaceType(nativeFunctionClass, [node.arguments.types[0]]);
        DartType dartType = node.arguments.types[1];

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
      } else if (target == asFunctionMethod) {
        if (isFfiLibrary) {
          // Library code of dart:ffi uses asFunction to implement
          // lookupFunction. Since we treat lookupFunction as well, this call
          // can be generic and still support AOT.
          return node;
        }

        DartType dartType = node.arguments.types[0];
        DartType pointerType = node.receiver.getStaticType(env);
        DartType nativeType = _pointerTypeGetTypeArg(pointerType);

        _ensureNativeTypeValid(pointerType, node);
        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
      } else if (target == loadMethod) {
        // TODO(dacoharkes): should load and store permitted to be generic?
        // https://github.com/dart-lang/sdk/issues/35902
        DartType dartType = node.arguments.types[0];
        DartType pointerType = node.receiver.getStaticType(env);
        DartType nativeType = _pointerTypeGetTypeArg(pointerType);

        _ensureNativeTypeValid(pointerType, node);
        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeSized(nativeType, node, target.name);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
      } else if (target == storeMethod) {
        // TODO(dacoharkes): should load and store permitted to be generic?
        // https://github.com/dart-lang/sdk/issues/35902
        DartType dartType = node.arguments.positional[0].getStaticType(env);
        DartType pointerType = node.receiver.getStaticType(env);
        DartType nativeType = _pointerTypeGetTypeArg(pointerType);

        _ensureNativeTypeValid(pointerType, node);
        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeSized(nativeType, node, target.name);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
      }
    } catch (_FfiStaticTypeError) {}

    return node;
  }

  DartType _pointerTypeGetTypeArg(DartType pointerType) {
    if (pointerType is InterfaceType) {
      InterfaceType superType =
          hierarchy.getTypeAsInstanceOf(pointerType, pointerClass);
      return superType?.typeArguments[0];
    }
    return null;
  }

  void _ensureNativeTypeToDartType(
      DartType containerTypeArg, DartType elementType, Expression node) {
    final DartType shouldBeElementType =
        convertNativeTypeToDartType(containerTypeArg);
    if (elementType == shouldBeElementType) return;
    // Both subtypes and implicit downcasts are allowed statically.
    if (env.isSubtypeOf(shouldBeElementType, elementType)) return;
    if (env.isSubtypeOf(elementType, shouldBeElementType)) return;
    diagnosticReporter.report(
        templateFfiTypeMismatch.withArguments(
            elementType, shouldBeElementType, containerTypeArg),
        node.fileOffset,
        1,
        node.location.file);
    throw _FfiStaticTypeError();
  }

  void _ensureNativeTypeValid(DartType nativeType, Expression node) {
    if (!_nativeTypeValid(nativeType)) {
      diagnosticReporter.report(
          templateFfiTypeInvalid.withArguments(nativeType),
          node.fileOffset,
          1,
          node.location.file);
      throw _FfiStaticTypeError();
    }
  }

  /// The Dart type system does not enforce that NativeFunction return and
  /// parameter types are only NativeTypes, so we need to check this.
  bool _nativeTypeValid(DartType nativeType) {
    return convertNativeTypeToDartType(nativeType) != null;
  }

  void _ensureNativeTypeSized(
      DartType nativeType, Expression node, Name targetName) {
    if (!_nativeTypeSized(nativeType)) {
      diagnosticReporter.report(
          templateFfiTypeUnsized.withArguments(targetName.name, nativeType),
          node.fileOffset,
          1,
          node.location.file);
      throw _FfiStaticTypeError();
    }
  }

  /// Unsized NativeTypes do not support [sizeOf] because their size is unknown.
  /// Consequently, [allocate], [Pointer.load], [Pointer.store], and
  /// [Pointer.elementAt] are not available.
  bool _nativeTypeSized(DartType nativeType) {
    if (!(nativeType is InterfaceType)) {
      return false;
    }
    Class nativeClass = (nativeType as InterfaceType).classNode;
    if (env.isSubtypeOf(
        InterfaceType(nativeClass), InterfaceType(pointerClass))) {
      return true;
    }
    NativeType nativeType_ = getType(nativeClass);
    if (nativeType_ == null) {
      return false;
    }
    if (kNativeTypeIntStart.index <= nativeType_.index &&
        nativeType_.index <= kNativeTypeIntEnd.index) {
      return true;
    }
    if (nativeType_ == NativeType.kFloat || nativeType_ == NativeType.kDouble) {
      return true;
    }
    if (nativeType_ == NativeType.kPointer) {
      return true;
    }
    return false;
  }

  void _ensureIsStatic(Expression node) {
    if (!_isStatic(node)) {
      diagnosticReporter.report(
          templateFfiNotStatic.withArguments(fromFunctionMethod.name.name),
          node.fileOffset,
          1,
          node.location.file);
      throw _FfiStaticTypeError();
    }
  }

  bool _isStatic(Expression node) {
    if (node is StaticGet) {
      return node.target is Procedure;
    }
    return node is ConstantExpression;
  }
}

/// Used internally for abnormal control flow to prevent cascading error
/// messages.
class _FfiStaticTypeError implements Exception {}
