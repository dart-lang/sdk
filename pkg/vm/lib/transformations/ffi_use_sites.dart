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
        templateFfiNotStatic,
        templateFfiExtendsOrImplementsSealedClass;

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
    // If dart:ffi is not loaded, do not do the transformation.
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
      _ensureNotExtendsOrImplementsSealedClass(node);
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
        // TODO(36730): Allow passing/returning structs by value.
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
    } on _FfiStaticTypeError {}

    return node;
  }

  // We need to replace calls to 'DynamicLibrary.lookupFunction' with explicit
  // Kernel, because we cannot have a generic call to 'asFunction' in its body.
  //
  // Below, in 'visitMethodInvocation', we ensure that the type arguments to
  // 'lookupFunction' are constants, so by inlining the call to 'asFunction' at
  // the call-site, we ensure that there are no generic calls to 'asFunction'.
  //
  // We will not detect dynamic invocations of 'asFunction' -- these are handled
  // by the stub in 'dynamic_library_patch.dart'. Dynamic invocations of
  // 'lookupFunction' (and 'asFunction') are not legal and throw a runtime
  // exception.
  Expression _replaceLookupFunction(MethodInvocation node) {
    // The generated code looks like:
    //
    // _asFunctionInternal<DS, NS>(lookup<NativeFunction<NS>>(symbolName))

    final DartType nativeSignature = node.arguments.types[0];
    final DartType dartSignature = node.arguments.types[1];

    final Arguments args = Arguments([
      node.arguments.positional.single
    ], types: [
      InterfaceType(nativeFunctionClass, [nativeSignature])
    ]);

    final Expression lookupResult = MethodInvocation(
        node.receiver, Name("lookup"), args, libraryLookupMethod);

    return StaticInvocation(asFunctionInternal,
        Arguments([lookupResult], types: [dartSignature, nativeSignature]));
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    Member target = node.interfaceTarget;
    try {
      // We will not detect dynamic invocations of 'asFunction' and
      // 'lookupFunction' -- these are handled by the 'asFunctionInternal' stub
      // in 'dynamic_library_patch.dart'. Dynamic invocations of 'asFunction'
      // and 'lookupFunction' are not legal and throw a runtime exception.
      if (target == lookupFunctionMethod) {
        DartType nativeType =
            InterfaceType(nativeFunctionClass, [node.arguments.types[0]]);
        DartType dartType = node.arguments.types[1];

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        return _replaceLookupFunction(node);
      } else if (target == asFunctionMethod) {
        DartType dartType = node.arguments.types[0];
        DartType pointerType = node.receiver.getStaticType(env);
        DartType nativeType = _pointerTypeGetTypeArg(pointerType);

        _ensureNativeTypeValid(pointerType, node);
        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);

        final DartType nativeSignature =
            (nativeType as InterfaceType).typeArguments[0];
        return StaticInvocation(asFunctionInternal,
            Arguments([node.receiver], types: [dartType, nativeSignature]));
      } else if (target == loadMethod) {
        // TODO(dacoharkes): should load and store be generic?
        // https://github.com/dart-lang/sdk/issues/35902
        DartType dartType = node.arguments.types[0];
        DartType pointerType = node.receiver.getStaticType(env);
        DartType nativeType = _pointerTypeGetTypeArg(pointerType);

        _ensureNativeTypeValid(pointerType, node);
        _ensureNativeTypeValid(nativeType, node, allowStructs: true);
        _ensureNativeTypeSized(nativeType, node, target.name);
        _ensureNativeTypeToDartType(nativeType, dartType, node,
            allowStructs: true);
      } else if (target == storeMethod) {
        // TODO(dacoharkes): should load and store permitted to be generic?
        // https://github.com/dart-lang/sdk/issues/35902
        DartType dartType = node.arguments.positional[0].getStaticType(env);
        DartType pointerType = node.receiver.getStaticType(env);
        DartType nativeType = _pointerTypeGetTypeArg(pointerType);

        // TODO(36730): Allow storing an entire struct to memory.
        // TODO(36780): Emit a better error message for the struct case.
        _ensureNativeTypeValid(pointerType, node);
        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeSized(nativeType, node, target.name);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
      }
    } on _FfiStaticTypeError {}

    return node;
  }

  DartType _pointerTypeGetTypeArg(DartType pointerType) {
    return pointerType is InterfaceType ? pointerType.typeArguments[0] : null;
  }

  void _ensureNativeTypeToDartType(
      DartType containerTypeArg, DartType elementType, Expression node,
      {bool allowStructs: false}) {
    final DartType shouldBeElementType =
        convertNativeTypeToDartType(containerTypeArg, allowStructs);
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

  void _ensureNativeTypeValid(DartType nativeType, Expression node,
      {bool allowStructs: false}) {
    if (!_nativeTypeValid(nativeType, allowStructs: allowStructs)) {
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
  bool _nativeTypeValid(DartType nativeType, {bool allowStructs: false}) {
    return convertNativeTypeToDartType(nativeType, allowStructs) != null;
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
    if (nativeType is! InterfaceType) {
      return false;
    }
    Class nativeClass = (nativeType as InterfaceType).classNode;
    if (env.isSubtypeOf(
        InterfaceType(nativeClass), InterfaceType(pointerClass))) {
      return true;
    }
    if (hierarchy.isSubclassOf(nativeClass, structClass)) {
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

  Class _extendsOrImplementsSealedClass(Class klass) {
    final Class superClass = klass.supertype?.classNode;

    // The Struct class can be extended, but subclasses of Struct cannot be (nor
    // implemented).
    if (klass != structClass && hierarchy.isSubtypeOf(klass, structClass)) {
      return superClass != structClass ? superClass : null;
    }

    if (!nativeTypesClasses.contains(klass)) {
      for (final parent in nativeTypesClasses) {
        if (hierarchy.isSubtypeOf(klass, parent)) {
          return parent;
        }
      }
    }
    return null;
  }

  void _ensureNotExtendsOrImplementsSealedClass(Class klass) {
    Class extended = _extendsOrImplementsSealedClass(klass);
    if (extended != null) {
      diagnosticReporter.report(
          templateFfiExtendsOrImplementsSealedClass
              .withArguments(extended.name),
          klass.fileOffset,
          1,
          klass.location.file);
    }
  }
}

/// Used internally for abnormal control flow to prevent cascading error
/// messages.
class _FfiStaticTypeError implements Exception {}
