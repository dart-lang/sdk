// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.ffi_use_sites;

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageFfiExceptionalReturnNull,
        messageFfiExpectedConstant,
        templateFfiDartTypeMismatch,
        templateFfiEmptyStruct,
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
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_environment.dart';

import 'ffi.dart'
    show FfiTransformerData, NativeType, FfiTransformer, optimizedTypes;

/// Checks and replaces calls to dart:ffi struct fields and methods.
void transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    FfiTransformerData ffiTransformerData,
    ReferenceFromIndex referenceFromIndex) {
  final index = new LibraryIndex(
      component, ["dart:ffi", "dart:_internal", "dart:typed_data"]);
  if (!index.containsLibrary("dart:ffi")) {
    // TODO: This check doesn't make sense: "dart:ffi" is always loaded/created
    // for the VM target.
    // If dart:ffi is not loaded, do not do the transformation.
    return;
  }
  if (index.tryGetClass('dart:ffi', 'NativeFunction') == null) {
    // If dart:ffi is not loaded (for real): do not do the transformation.
    return;
  }
  final transformer = new _FfiUseSiteTransformer(
      index,
      coreTypes,
      hierarchy,
      diagnosticReporter,
      referenceFromIndex,
      ffiTransformerData.replacedGetters,
      ffiTransformerData.replacedSetters,
      ffiTransformerData.emptyStructs);
  libraries.forEach(transformer.visitLibrary);
}

/// Checks and replaces calls to dart:ffi struct fields and methods.
class _FfiUseSiteTransformer extends FfiTransformer {
  final Map<Field, Procedure> replacedGetters;
  final Map<Field, Procedure> replacedSetters;
  final Set<Class> emptyStructs;
  StaticTypeContext _staticTypeContext;

  Library currentLibrary;
  bool get isFfiLibrary => currentLibrary == ffiLibrary;
  IndexedLibrary currentLibraryIndex;

  // Used to create private top-level fields with unique names for each
  // callback.
  int callbackCount = 0;

  _FfiUseSiteTransformer(
      LibraryIndex index,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex referenceFromIndex,
      this.replacedGetters,
      this.replacedSetters,
      this.emptyStructs)
      : super(index, coreTypes, hierarchy, diagnosticReporter,
            referenceFromIndex) {}

  @override
  TreeNode visitLibrary(Library node) {
    currentLibrary = node;
    currentLibraryIndex = referenceFromIndex?.lookupLibrary(node);
    callbackCount = 0;
    return super.visitLibrary(node);
  }

  @override
  visitClass(Class node) {
    try {
      _ensureNotExtendsOrImplementsSealedClass(node);
      return super.visitClass(node);
    } on _FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
      return super.visitClass(node);
    }
  }

  @override
  visitField(Field node) {
    _staticTypeContext = new StaticTypeContext(node, env);
    var result = super.visitField(node);
    _staticTypeContext = null;
    return result;
  }

  @override
  visitConstructor(Constructor node) {
    _staticTypeContext = new StaticTypeContext(node, env);
    var result = super.visitConstructor(node);
    _staticTypeContext = null;
    return result;
  }

  @override
  visitProcedure(Procedure node) {
    if (isFfiLibrary && node.isExtensionMember) {
      if (node == asFunctionTearoff || node == lookupFunctionTearoff) {
        // Skip static checks and transformation for the tearoffs.
        return node;
      }
    }

    _staticTypeContext = new StaticTypeContext(node, env);
    final result = super.visitProcedure(node);
    _staticTypeContext = null;
    return result;
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
      if (target == lookupFunctionMethod) {
        final DartType nativeType = InterfaceType(
            nativeFunctionClass, Nullability.legacy, [node.arguments.types[0]]);
        final DartType dartType = node.arguments.types[1];

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureNoEmptyStructs(dartType, node);
        return _replaceLookupFunction(node);
      } else if (target == asFunctionMethod) {
        final DartType dartType = node.arguments.types[1];
        final DartType nativeType = InterfaceType(
            nativeFunctionClass, Nullability.legacy, [node.arguments.types[0]]);

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureNoEmptyStructs(dartType, node);

        final DartType nativeSignature =
            (nativeType as InterfaceType).typeArguments[0];
        // Inline function body to make all type arguments instatiated.
        return StaticInvocation(
            asFunctionInternal,
            Arguments([node.arguments.positional[0]],
                types: [dartType, nativeSignature]));
      } else if (target == fromFunctionMethod) {
        final DartType nativeType = InterfaceType(
            nativeFunctionClass, Nullability.legacy, [node.arguments.types[0]]);
        final Expression func = node.arguments.positional[0];
        final DartType dartType = func.getStaticType(_staticTypeContext);

        _ensureIsStaticFunction(func);

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureNoEmptyStructs(dartType, node);

        // Check `exceptionalReturn`'s type.
        final FunctionType funcType = dartType;
        final Class expectedReturnClass =
            ((node.arguments.types[0] as FunctionType).returnType
                    as InterfaceType)
                .classNode;
        final NativeType expectedReturn = getType(expectedReturnClass);

        if (expectedReturn == NativeType.kVoid ||
            expectedReturn == NativeType.kPointer ||
            expectedReturn == NativeType.kHandle ||
            expectedReturnClass.superclass == structClass) {
          if (node.arguments.positional.length > 1) {
            diagnosticReporter.report(
                templateFfiExpectedNoExceptionalReturn.withArguments(
                    funcType.returnType, currentLibrary.isNonNullableByDefault),
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
                templateFfiExpectedExceptionalReturn.withArguments(
                    funcType.returnType, currentLibrary.isNonNullableByDefault),
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

          final DartType returnType =
              exceptionalReturn.getStaticType(_staticTypeContext);

          if (!env.isSubtypeOf(returnType, funcType.returnType,
              SubtypeCheckMode.ignoringNullabilities)) {
            diagnosticReporter.report(
                templateFfiDartTypeMismatch.withArguments(returnType,
                    funcType.returnType, currentLibrary.isNonNullableByDefault),
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
  // Above, in 'visitStaticInvocation', we ensure that the type arguments to
  // 'lookupFunction' are constants, so by inlining the call to 'asFunction' at
  // the call-site, we ensure that there are no generic calls to 'asFunction'.
  Expression _replaceLookupFunction(StaticInvocation node) {
    // The generated code looks like:
    //
    // _asFunctionInternal<DS, NS>(lookup<NativeFunction<NS>>(symbolName))

    final DartType nativeSignature = node.arguments.types[0];
    final DartType dartSignature = node.arguments.types[1];

    final Arguments args = Arguments([
      node.arguments.positional[1]
    ], types: [
      InterfaceType(nativeFunctionClass, Nullability.legacy, [nativeSignature])
    ]);

    final Expression lookupResult = MethodInvocation(
        node.arguments.positional[0],
        Name("lookup"),
        args,
        libraryLookupMethod);

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
    final nativeFunctionType = InterfaceType(
        nativeFunctionClass, Nullability.legacy, node.arguments.types);
    var name = Name("_#ffiCallback${callbackCount++}", currentLibrary);
    var lookupField = currentLibraryIndex?.lookupField(name.text);
    final Field field = Field(name,
        type: InterfaceType(
            pointerClass, Nullability.legacy, [nativeFunctionType]),
        initializer: StaticInvocation(
            pointerFromFunctionProcedure,
            Arguments([
              StaticInvocation(nativeCallbackFunctionProcedure, node.arguments)
            ], types: [
              nativeFunctionType
            ])),
        isStatic: true,
        isFinal: true,
        fileUri: currentLibrary.fileUri,
        getterReference: lookupField?.getterReference,
        setterReference: lookupField?.setterReference)
      ..fileOffset = node.fileOffset;
    currentLibrary.addField(field);
    return StaticGet(field);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    final Member target = node.interfaceTarget;
    try {
      if (target == elementAtMethod) {
        final DartType pointerType =
            node.receiver.getStaticType(_staticTypeContext);
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
      DartType nativeType, DartType dartType, Expression node,
      {bool allowHandle: false}) {
    final DartType correspondingDartType = convertNativeTypeToDartType(
        nativeType,
        allowStructs: true,
        allowHandle: allowHandle);
    if (dartType == correspondingDartType) return;
    if (env.isSubtypeOf(correspondingDartType, dartType,
        SubtypeCheckMode.ignoringNullabilities)) {
      return;
    }
    diagnosticReporter.report(
        templateFfiTypeMismatch.withArguments(dartType, correspondingDartType,
            nativeType, currentLibrary.isNonNullableByDefault),
        node.fileOffset,
        1,
        node.location.file);
    throw _FfiStaticTypeError();
  }

  void _ensureNativeTypeValid(DartType nativeType, Expression node,
      {bool allowHandle: false}) {
    if (!_nativeTypeValid(nativeType,
        allowStructs: true, allowHandle: allowHandle)) {
      diagnosticReporter.report(
          templateFfiTypeInvalid.withArguments(
              nativeType, currentLibrary.isNonNullableByDefault),
          node.fileOffset,
          1,
          node.location.file);
      throw _FfiStaticTypeError();
    }
  }

  void _ensureNoEmptyStructs(DartType nativeType, Expression node) {
    // Error on structs with no fields.
    if (nativeType is InterfaceType) {
      final Class nativeClass = nativeType.classNode;
      if (hierarchy.isSubclassOf(nativeClass, structClass)) {
        if (emptyStructs.contains(nativeClass)) {
          diagnosticReporter.report(
              templateFfiEmptyStruct.withArguments(nativeClass.name),
              node.fileOffset,
              1,
              node.location.file);
        }
      }
    }

    // Recurse when seeing a function type.
    if (nativeType is FunctionType) {
      nativeType.positionalParameters
          .forEach((e) => _ensureNoEmptyStructs(e, node));
      _ensureNoEmptyStructs(nativeType.returnType, node);
    }
  }

  /// The Dart type system does not enforce that NativeFunction return and
  /// parameter types are only NativeTypes, so we need to check this.
  bool _nativeTypeValid(DartType nativeType,
      {bool allowStructs: false, allowHandle: false}) {
    return convertNativeTypeToDartType(nativeType,
            allowStructs: allowStructs, allowHandle: allowHandle) !=
        null;
  }

  void _ensureIsStaticFunction(Expression node) {
    if ((node is StaticGet && node.target is Procedure) ||
        (node is ConstantExpression && node.constant is TearOffConstant)) {
      return;
    }
    diagnosticReporter.report(
        templateFfiNotStatic.withArguments(fromFunctionMethod.name.text),
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
