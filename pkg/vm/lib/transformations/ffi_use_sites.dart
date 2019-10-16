// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.ffi_use_sites;

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageFfiExceptionalReturnNull,
        messageFfiExpectedConstant,
        templateFfiDartTypeMismatch,
        templateFfiExpectedExceptionalReturn,
        templateFfiExpectedNoExceptionalReturn,
        templateFfiExtendsOrImplementsSealedClass,
        templateFfiNotStatic,
        templateFfiTypeInvalid,
        templateFfiTypeMismatch;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_environment.dart';

import 'ffi.dart'
    show ReplacedMembers, NativeType, FfiTransformer, optimizedTypes;

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

  Library currentLibrary;
  bool get isFfiLibrary => currentLibrary == ffiLibrary;

  // Used to create private top-level fields with unique names for each
  // callback.
  int callbackCount = 0;

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
    currentLibrary = node;
    callbackCount = 0;
    return super.visitLibrary(node);
  }

  @override
  visitClass(Class node) {
    env.thisType = InterfaceType(node);
    try {
      _ensureNotExtendsOrImplementsSealedClass(node);
      return super.visitClass(node);
    } on _FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
      return super.visitClass(node);
    } finally {
      env.thisType = null;
    }
  }

  @override
  visitPropertyGet(PropertyGet node) {
    super.visitPropertyGet(node);

    final Procedure replacedWith = replacedGetters[node.interfaceTarget];
    if (replacedWith != null) {
      node = PropertyGet(node.receiver, replacedWith.name, replacedWith);
    }

    return node;
  }

  @override
  visitPropertySet(PropertySet node) {
    super.visitPropertySet(node);

    final Procedure replacedWith = replacedSetters[node.interfaceTarget];
    if (replacedWith != null) {
      node = PropertySet(
          node.receiver, replacedWith.name, node.value, replacedWith);
    }

    return node;
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);

    final Member target = node.target;
    try {
      if (target == fromFunctionMethod) {
        final DartType nativeType =
            InterfaceType(nativeFunctionClass, [node.arguments.types[0]]);
        final Expression func = node.arguments.positional[0];
        final DartType dartType = func.getStaticType(env);

        _ensureIsStaticFunction(func);

        // TODO(36730): Allow passing/returning structs by value.
        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);

        // Check `exceptionalReturn`'s type.
        final FunctionType funcType = dartType;
        final NativeType expectedReturn = getType(
            ((node.arguments.types[0] as FunctionType).returnType
                    as InterfaceType)
                .classNode);

        if (expectedReturn == NativeType.kVoid ||
            expectedReturn == NativeType.kPointer) {
          if (node.arguments.positional.length > 1) {
            diagnosticReporter.report(
                templateFfiExpectedNoExceptionalReturn
                    .withArguments(funcType.returnType),
                node.fileOffset,
                1,
                node.location.file);
            return node;
          }
          node.arguments.positional.add(NullLiteral()..parent = node);
        } else {
          // The exceptional return value is not optional for other return
          // types.
          if (node.arguments.positional.length < 2) {
            diagnosticReporter.report(
                templateFfiExpectedExceptionalReturn
                    .withArguments(funcType.returnType),
                node.fileOffset,
                1,
                node.location.file);
            return node;
          }

          final Expression exceptionalReturn = node.arguments.positional[1];

          // The exceptional return value must be a constant so that it be
          // referenced by precompiled trampoline's object pool.
          if (exceptionalReturn is! BasicLiteral &&
              !(exceptionalReturn is ConstantExpression &&
                  exceptionalReturn.constant is PrimitiveConstant)) {
            diagnosticReporter.report(messageFfiExpectedConstant,
                node.fileOffset, 1, node.location.file);
            return node;
          }

          // Moreover it may not be null.
          if (exceptionalReturn is NullLiteral ||
              (exceptionalReturn is ConstantExpression &&
                  exceptionalReturn.constant is NullConstant)) {
            diagnosticReporter.report(messageFfiExceptionalReturnNull,
                node.fileOffset, 1, node.location.file);
            return node;
          }

          final DartType returnType = exceptionalReturn.getStaticType(env);

          if (!env.isSubtypeOf(returnType, funcType.returnType,
              SubtypeCheckMode.ignoringNullabilities)) {
            diagnosticReporter.report(
                templateFfiDartTypeMismatch.withArguments(
                    returnType, funcType.returnType),
                exceptionalReturn.fileOffset,
                1,
                exceptionalReturn.location.file);
            return node;
          }
        }
        return _replaceFromFunction(node);
      }
    } on _FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
    }

    return node;
  }

  // We need to replace calls to 'DynamicLibrary.lookupFunction' with explicit
  // Kernel, because we cannot have a generic call to 'asFunction' in its body.
  //
  // Below, in 'visitMethodInvocation', we ensure that the type arguments to
  // 'lookupFunction' are constants, so by inlining the call to 'asFunction' at
  // the call-site, we ensure that there are no generic calls to 'asFunction'.
  //
  // We will not detect dynamic invocations of 'asFunction' and
  // 'lookupFunction': these are handled by the stubs in 'ffi_patch.dart' and
  // 'dynamic_library_patch.dart'. Dynamic invocations of 'lookupFunction' (and
  // 'asFunction') are not legal and throw a runtime exception.
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

  // We need to rewrite calls to 'fromFunction' into two calls, representing the
  // compile-time and run-time aspects of creating the closure:
  //
  // final dynamic _#ffiCallback0 = Pointer.fromFunction<T>(f, e) =>
  //   _pointerFromFunction<NativeFunction<T>>(
  //     _nativeCallbackFunction<T>(f, e));
  //
  //  ... _#ffiCallback0 ...
  //
  // We must implement this as a Kernel rewrite because <T> must be a
  // compile-time constant to any invocation of '_nativeCallbackFunction'.
  //
  // Creating this closure requires a runtime call, so we save the result in a
  // synthetic top-level field to avoid recomputing it.
  Expression _replaceFromFunction(StaticInvocation node) {
    final nativeFunctionType =
        InterfaceType(nativeFunctionClass, node.arguments.types);
    final Field field = Field(
        Name("_#ffiCallback${callbackCount++}", currentLibrary),
        type: InterfaceType(pointerClass, [nativeFunctionType]),
        initializer: StaticInvocation(
            pointerFromFunctionProcedure,
            Arguments([
              StaticInvocation(nativeCallbackFunctionProcedure, node.arguments)
            ], types: [
              nativeFunctionType
            ])),
        isStatic: true,
        isFinal: true);
    currentLibrary.addMember(field);
    return StaticGet(field);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    final Member target = node.interfaceTarget;
    try {
      // We will not detect dynamic invocations of 'asFunction' and
      // 'lookupFunction' -- these are handled by the 'asFunctionInternal' stub
      // in 'dynamic_library_patch.dart'. Dynamic invocations of 'asFunction'
      // and 'lookupFunction' are not legal and throw a runtime exception.
      if (target == lookupFunctionMethod) {
        final DartType nativeType =
            InterfaceType(nativeFunctionClass, [node.arguments.types[0]]);
        final DartType dartType = node.arguments.types[1];

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        return _replaceLookupFunction(node);
      } else if (target == asFunctionMethod) {
        final DartType dartType = node.arguments.types[0];
        final DartType pointerType = node.receiver.getStaticType(env);
        final DartType nativeType = _pointerTypeGetTypeArg(pointerType);

        _ensureNativeTypeValid(pointerType, node);
        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);

        final DartType nativeSignature =
            (nativeType as InterfaceType).typeArguments[0];
        return StaticInvocation(asFunctionInternal,
            Arguments([node.receiver], types: [dartType, nativeSignature]));
      } else if (target == elementAtMethod) {
        // TODO(37773): When moving to extension methods we can get rid of
        // this rewiring.
        final DartType pointerType = node.receiver.getStaticType(env);
        final DartType nativeType = _pointerTypeGetTypeArg(pointerType);
        if (nativeType is TypeParameterType) {
          // Do not rewire generic invocations.
          return node;
        }
        final Class nativeClass = (nativeType as InterfaceType).classNode;
        final NativeType nt = getType(nativeClass);
        if (optimizedTypes.contains(nt)) {
          final typeArguments = [
            if (nt == NativeType.kPointer) _pointerTypeGetTypeArg(nativeType)
          ];
          return StaticInvocation(
              elementAtMethods[nt],
              Arguments([node.receiver, node.arguments.positional[0]],
                  types: typeArguments));
        }
      }
    } on _FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
    }

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
    // We disable implicit downcasts, they will go away when NNBD lands.
    if (env.isSubtypeOf(elementType, shouldBeElementType,
        SubtypeCheckMode.ignoringNullabilities)) return;
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

  void _ensureIsStaticFunction(Expression node) {
    if ((node is StaticGet && node.target is Procedure) ||
        (node is ConstantExpression && node.constant is TearOffConstant)) {
      return;
    }
    diagnosticReporter.report(
        templateFfiNotStatic.withArguments(fromFunctionMethod.name.name),
        node.fileOffset,
        1,
        node.location.file);
    throw _FfiStaticTypeError();
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
    final Class extended = _extendsOrImplementsSealedClass(klass);
    if (extended != null) {
      diagnosticReporter.report(
          templateFfiExtendsOrImplementsSealedClass
              .withArguments(extended.name),
          klass.fileOffset,
          1,
          klass.location.file);
      throw _FfiStaticTypeError();
    }
  }
}

/// Used internally for abnormal control flow to prevent cascading error
/// messages.
class _FfiStaticTypeError implements Exception {}
