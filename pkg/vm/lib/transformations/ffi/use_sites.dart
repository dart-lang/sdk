// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageFfiAddressOfMustBeNative,
        messageFfiCreateOfStructOrUnion,
        messageFfiExceptionalReturnNull,
        messageFfiExpectedConstant,
        templateFfiNativeCallableListenerReturnVoid,
        templateFfiDartTypeMismatch,
        templateFfiExpectedConstantArg,
        templateFfiExpectedExceptionalReturn,
        templateFfiExpectedNoExceptionalReturn,
        templateFfiExtendsOrImplementsSealedClass,
        templateFfiNotStatic;

import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:front_end/src/fasta/names.dart' show unaryMinusName;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_algebra.dart'
    show FunctionTypeInstantiator, Substitution;
import 'package:kernel/type_environment.dart';

import 'definitions.dart' as definitions;
import 'native_type_cfe.dart';
import 'native.dart' as native;
import 'common.dart' show FfiStaticTypeError, FfiTransformer, NativeType;
import 'finalizable.dart';

/// Checks and replaces calls to dart:ffi compound fields and methods.
///
/// To reliably lower calls to methods like `sizeOf` and `Native.addressOf`,
/// this requires that the [definitions] and the [native] transformer already
/// ran on the libraries to transform.
void transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex? referenceFromIndex) {
  final index = LibraryIndex(component, [
    "dart:ffi",
    "dart:_internal",
    "dart:typed_data",
    "dart:nativewrappers",
    "dart:isolate"
  ]);
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
  final transformer = new _FfiUseSiteTransformer2(
      index, coreTypes, hierarchy, diagnosticReporter, referenceFromIndex);
  libraries.forEach(transformer.visitLibrary);
}

/// Combines [_FfiUseSiteTransformer] and [FinalizableTransformer] into a single
/// traversal.
///
/// This transformation is not AST-node preserving. [Expression]s and
/// [Statement]s can be replaced by other [Expression]s and [Statement]s
/// respectively. This means one cannot do `visitX() { super.visitX() as X }`.
class _FfiUseSiteTransformer2 extends FfiTransformer
    with _FfiUseSiteTransformer, FinalizableTransformer {
  _FfiUseSiteTransformer2(
      LibraryIndex index,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex)
      : super(index, coreTypes, hierarchy, diagnosticReporter,
            referenceFromIndex);
}

/// Checks and replaces calls to dart:ffi compound fields and methods.
///
/// Designed to be mixed in. Calls super.visitXXX() to visit all nodes (except
/// the ones created by this transformation).
///
/// This transformation is not AST-node preserving. [Expression]s and
/// [Statement]s can be replaced by other [Expression]s and [Statement]s
/// respectively. This means one cannot do `visitX() { super.visitX() as X }`.
mixin _FfiUseSiteTransformer on FfiTransformer {
  StaticTypeContext? get staticTypeContext;

  bool _inFfiTearoff = false;

  bool get isFfiLibrary => currentLibrary == ffiLibrary;

  // Used to create private top-level fields with unique names for each
  // callback.
  int callbackCount = 0;

  // Used to create private top-level trampoline methods with unique names
  // for each call.
  int callCount = 0;

  @override
  TreeNode visitLibrary(Library node) {
    callbackCount = 0;
    callCount = 0;
    return super.visitLibrary(node);
  }

  @override
  visitClass(Class node) {
    try {
      _ensureNotExtendsOrImplementsSealedClass(node);
      return super.visitClass(node);
    } on FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
      return super.visitClass(node);
    }
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    if (_inFfiTearoff) {
      return node;
    }
    final target = node.target;
    if (hierarchy.isSubclassOf(target.enclosingClass, compoundClass) &&
        target.name != Name("#fromTypedDataBase")) {
      diagnosticReporter.report(messageFfiCreateOfStructOrUnion,
          node.fileOffset, 1, node.location?.file);
    }
    return super.visitConstructorInvocation(node);
  }

  @override
  visitProcedure(Procedure node) {
    assert(_inFfiTearoff == false);
    _inFfiTearoff = ((isFfiLibrary &&
            node.isExtensionMember &&
            (node == allocationTearoff ||
                node == asFunctionTearoff ||
                node == lookupFunctionTearoff ||
                node == abiSpecificIntegerPointerElementAtTearoff ||
                node == structPointerElementAtTearoff ||
                node == unionPointerElementAtTearoff))) ||
        // Dart2wasm uses enabledConstructorTearOffLowerings but these are not
        // users trying to call constructors.
        isConstructorTearOffLowering(node);
    final result = super.visitProcedure(node);
    _inFfiTearoff = false;
    return result;
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    final modifiedExpression = _visitStaticInvocation(node);
    if (node == modifiedExpression) {
      return super.visitStaticInvocation(node);
    }
    // We've just created this node. We're likely not going to need to transform
    // this node itself. Visit its sub expressions.
    return super.defaultExpression(modifiedExpression);
  }

  /// Replaces nodes if they match. Does not invoke any super visit.
  Expression _visitStaticInvocation(StaticInvocation node) {
    if (_inFfiTearoff) {
      return node;
    }
    final Member target = node.target;
    try {
      if (target == abiSpecificIntegerArrayElemAt ||
          target == abiSpecificIntegerArraySetElemAt) {
        final pointer = node.arguments.positional[0];
        final pointerType =
            pointer.getStaticType(staticTypeContext!) as InterfaceType;
        ensureNativeTypeValid(pointerType, pointer,
            allowCompounds: true, allowInlineArray: true);

        final typeArg = pointerType.typeArguments.single;
        final nativeTypeCfe =
            NativeTypeCfe(this, typeArg) as AbiSpecificNativeTypeCfe;

        final arrayVar = VariableDeclaration("#array",
            initializer: NullCheck(node.arguments.positional[0]),
            type: InterfaceType(arrayClass, Nullability.nonNullable),
            isSynthesized: true)
          ..fileOffset = node.fileOffset;
        final indexVar = VariableDeclaration("#index",
            initializer: NullCheck(node.arguments.positional[1]),
            type: coreTypes.intNonNullableRawType,
            isSynthesized: true)
          ..fileOffset = node.fileOffset;

        return BlockExpression(
          Block([
            arrayVar,
            indexVar,
            ExpressionStatement(InstanceInvocation(
              InstanceAccessKind.Instance,
              VariableGet(arrayVar),
              arrayCheckIndex.name,
              Arguments([VariableGet(indexVar)]),
              interfaceTarget: arrayCheckIndex,
              functionType: arrayCheckIndex.getterType as FunctionType,
            )),
          ]),
          abiSpecificLoadOrStoreExpression(
            nativeTypeCfe,
            typedDataBase: getArrayTypedDataBaseField(VariableGet(arrayVar)),
            index: VariableGet(indexVar),
            value: target == abiSpecificIntegerArraySetElemAt
                ? node.arguments.positional.last
                : null,
            fileOffset: node.fileOffset,
          ),
        );
      }
      if (target == abiSpecificIntegerPointerGetValue ||
          target == abiSpecificIntegerPointerSetValue ||
          target == abiSpecificIntegerPointerElemAt ||
          target == abiSpecificIntegerPointerSetElemAt) {
        final pointer = node.arguments.positional[0];
        final pointerType =
            pointer.getStaticType(staticTypeContext!) as InterfaceType;
        ensureNativeTypeValid(pointerType, pointer,
            allowCompounds: true, allowInlineArray: true);

        final typeArg = pointerType.typeArguments.single;
        final nativeTypeCfe =
            NativeTypeCfe(this, typeArg) as AbiSpecificNativeTypeCfe;

        return abiSpecificLoadOrStoreExpression(
          nativeTypeCfe,
          typedDataBase: node.arguments.positional[0],
          index: (target == abiSpecificIntegerPointerElemAt ||
                  target == abiSpecificIntegerPointerSetElemAt)
              ? node.arguments.positional[1]
              : null,
          value: (target == abiSpecificIntegerPointerSetValue ||
                  target == abiSpecificIntegerPointerSetElemAt)
              ? node.arguments.positional.last
              : null,
          fileOffset: node.fileOffset,
        );
      }
      if (target == structPointerGetRef ||
          target == structPointerGetElemAt ||
          target == unionPointerGetRef ||
          target == unionPointerGetElemAt) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        return _replaceGetRef(node);
      } else if (target == structPointerSetRef ||
          target == structPointerSetElemAt ||
          target == unionPointerSetRef ||
          target == unionPointerSetElemAt) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        return _replaceSetRef(node);
      } else if (target == abiSpecificIntegerPointerElementAt ||
          target == structPointerElementAt ||
          target == unionPointerElementAt ||
          target == abiSpecificIntegerPointerPlusOperator ||
          target == structPointerPlusOperator ||
          target == unionPointerPlusOperator ||
          target == abiSpecificIntegerPointerMinusOperator ||
          target == structPointerMinusOperator ||
          target == unionPointerMinusOperator) {
        final pointer = node.arguments.positional[0];
        final positiveOffset = node.arguments.positional[1];
        final Expression offset;
        if (target == abiSpecificIntegerPointerMinusOperator ||
            target == structPointerMinusOperator ||
            target == unionPointerMinusOperator) {
          offset = InstanceInvocation(InstanceAccessKind.Instance,
              positiveOffset, unaryMinusName, new Arguments([]),
              interfaceTarget: coreTypes.intUnaryMinus,
              functionType: coreTypes.intUnaryMinus.getterType as FunctionType);
        } else {
          offset = positiveOffset;
        }
        final pointerType =
            pointer.getStaticType(staticTypeContext!) as InterfaceType;
        ensureNativeTypeValid(pointerType, pointer,
            allowCompounds: true, allowInlineArray: true);
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        Expression? inlineSizeOf =
            this.inlineSizeOf(nativeType as InterfaceType);
        if (inlineSizeOf != null) {
          // Generates `receiver.offsetBy(inlineSizeOfExpression)`.
          return InstanceInvocation(InstanceAccessKind.Instance, pointer,
              offsetByMethod.name, Arguments([multiply(offset, inlineSizeOf)]),
              interfaceTarget: offsetByMethod,
              functionType: Substitution.fromInterfaceType(pointerType)
                  .substituteType(offsetByMethod.getterType) as FunctionType);
        }
      } else if (target == structArrayElemAt || target == unionArrayElemAt) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        return _replaceRefArray(node);
      } else if (target == arrayArrayElemAt) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node,
            allowInlineArray: true, allowCompounds: true);

        return _replaceArrayArrayElemAt(node);
      } else if (target == arrayArrayAssignAt) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node,
            allowInlineArray: true, allowCompounds: true);

        return _replaceArrayArrayElemAt(node, setter: true);
      } else if (target == sizeOfMethod) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node,
            allowCompounds: true, allowVoid: true);

        if (nativeType is InterfaceType) {
          Expression? inlineSizeOf = this.inlineSizeOf(nativeType);
          if (inlineSizeOf != null) {
            return inlineSizeOf;
          }
        }
      } else if (target == lookupFunctionMethod) {
        final nativeType = InterfaceType(nativeFunctionClass,
            currentLibrary.nonNullable, [node.arguments.types[0]]);
        final DartType dartType = node.arguments.types[1];

        _ensureIsLeafIsConst(node);
        final isLeaf = getIsLeafBoolean(node) ?? false;
        ensureNativeTypeValid(nativeType, node);
        ensureNativeTypeToDartType(
          nativeType,
          dartType,
          node,
          allowHandle: true, // Handle-specific errors emitted below.
          allowTypedData: true, // TypedData-specific errors emitted below.
        );
        ensureLeafCallDoesNotUseHandles(
          nativeType,
          isLeaf,
          reportErrorOn: node,
        );
        ensureOnlyLeafCallsUseTypedData(
          node.arguments.types[0],
          dartType,
          isLeaf: isLeaf,
          isCall: true,
          reportErrorOn: node,
        );
        return _replaceLookupFunction(node);
      } else if (target == asFunctionMethod) {
        final dartType = node.arguments.types[1];
        final InterfaceType nativeType = InterfaceType(nativeFunctionClass,
            Nullability.nonNullable, [node.arguments.types[0]]);

        _ensureIsLeafIsConst(node);
        final isLeaf = getIsLeafBoolean(node) ?? false;

        ensureNativeTypeValid(nativeType, node);
        ensureNativeTypeToDartType(
          nativeType,
          dartType,
          node,
          allowHandle: true, // Handle-specific errors emitted below.
          allowTypedData: true, // TypedData-specific errors emitted below.
        );
        ensureLeafCallDoesNotUseHandles(
          nativeType,
          isLeaf,
          reportErrorOn: node,
        );
        ensureOnlyLeafCallsUseTypedData(
          node.arguments.types[0],
          dartType,
          isLeaf: isLeaf,
          isCall: true,
          reportErrorOn: node,
        );
        final DartType nativeSignature = nativeType.typeArguments[0];

        return _replaceAsFunction(
          functionPointer: node.arguments.positional[0],
          pointerType: InterfaceType(
              pointerClass, Nullability.nonNullable, [nativeType]),
          nativeSignature: nativeSignature,
          dartSignature: dartType as FunctionType,
          isLeaf: isLeaf,
          fileOffset: node.fileOffset,
        );
      } else if (target == fromFunctionMethod) {
        return _verifyAndReplaceNativeCallableIsolateLocal(node,
            fromFunction: true);
      } else if (target == nativeCallableIsolateLocalConstructor) {
        return _verifyAndReplaceNativeCallableIsolateLocal(node);
      } else if (target == nativeCallableListenerConstructor) {
        final DartType nativeType = InterfaceType(nativeFunctionClass,
            currentLibrary.nonNullable, [node.arguments.types[0]]);
        final Expression func = node.arguments.positional[0];
        final DartType dartType = func.getStaticType(staticTypeContext!);

        ensureNativeTypeValid(nativeType, node);
        ensureNativeTypeToDartType(nativeType, dartType, node);

        final funcType = dartType as FunctionType;

        // Check return type.
        if (funcType.returnType != VoidType()) {
          diagnosticReporter.report(
              templateFfiNativeCallableListenerReturnVoid.withArguments(
                  funcType.returnType, currentLibrary.isNonNullableByDefault),
              func.fileOffset,
              1,
              func.location?.file);
          return node;
        }

        final replacement = _replaceNativeCallableListenerConstructor(node);

        final compoundClasses = funcType.positionalParameters
            .whereType<InterfaceType>()
            .map((t) => t.classNode)
            .where((c) =>
                c.superclass == structClass || c.superclass == unionClass)
            .toList();
        return invokeCompoundConstructors(replacement, compoundClasses);
      } else if (target == allocateMethod) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node,
            allowCompounds: true, allowVoid: true);

        // Inline the body to get rid of a generic invocation of sizeOf.
        // TODO(http://dartbug.com/39964): Add `alignmentOf<T>()` call.
        Expression? sizeInBytes = inlineSizeOf(nativeType as InterfaceType);
        if (sizeInBytes != null) {
          if (node.arguments.positional.length == 2) {
            sizeInBytes = multiply(node.arguments.positional[1], sizeInBytes);
          }
          final FunctionType allocateFunctionType =
              allocatorAllocateMethod.getterType as FunctionType;
          return InstanceInvocation(
              InstanceAccessKind.Instance,
              node.arguments.positional[0],
              allocatorAllocateMethod.name,
              Arguments([sizeInBytes], types: node.arguments.types),
              interfaceTarget: allocatorAllocateMethod,
              functionType: FunctionTypeInstantiator.instantiate(
                  allocateFunctionType, node.arguments.types));
        }
      } else if (target == nativeAddressOf) {
        return _replaceNativeAddressOf(node);
      }
    } on FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
    }

    return node;
  }

  /// Create Dart function which calls native code.
  ///
  /// Adds a native effect invoking a compound constructors if this is used
  /// as return type.
  Expression _replaceAsFunction({
    required Expression functionPointer,
    required DartType pointerType,
    required DartType nativeSignature,
    required FunctionType dartSignature,
    required bool isLeaf,
    required int fileOffset,
  }) {
    assert(dartSignature.namedParameters.isEmpty);
    final functionPointerVarName = '#ffiTarget$callCount';
    final closureName = '#ffiClosure$callCount';
    ++callCount;

    final pointerVar = VariableDeclaration(functionPointerVarName,
        initializer: functionPointer, type: pointerType, isSynthesized: true);

    final positionalParameters = [
      for (int i = 0; i < dartSignature.positionalParameters.length; ++i)
        VariableDeclaration(
          'arg${i + 1}',
          type: dartSignature.positionalParameters[i],
        )
    ];

    final closure = FunctionDeclaration(
        VariableDeclaration(closureName,
            type: dartSignature, isSynthesized: true)
          ..addAnnotation(ConstantExpression(
              InstanceConstant(coreTypes.pragmaClass.reference, [], {
            coreTypes.pragmaName.fieldReference:
                StringConstant('vm:ffi:call-closure'),
            coreTypes.pragmaOptions.fieldReference: InstanceConstant(
              ffiCallClass.reference,
              [nativeSignature],
              {
                ffiCallIsLeafField.fieldReference: BoolConstant(isLeaf),
              },
            ),
          }))),
        FunctionNode(
            Block([
              for (final param in positionalParameters)
                ExpressionStatement(StaticInvocation(
                    nativeEffectMethod, Arguments([VariableGet(param)]))),
              ReturnStatement(StaticInvocation(
                  ffiCallMethod,
                  Arguments([
                    VariableGet(pointerVar),
                  ], types: [
                    dartSignature.returnType,
                  ]))
                ..fileOffset = fileOffset),
            ]),
            positionalParameters: positionalParameters,
            requiredParameterCount: dartSignature.requiredParameterCount,
            returnType: dartSignature.returnType)
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;

    final result = BlockExpression(
        Block([
          pointerVar,
          closure,
        ]),
        VariableGet(closure.variable));

    final possibleCompoundReturn = findCompoundReturnType(dartSignature);
    if (possibleCompoundReturn != null) {
      return invokeCompoundConstructor(result, possibleCompoundReturn);
    }

    return result;
  }

  Expression invokeCompoundConstructors(
          Expression nestedExpression, List<Class> compoundClasses) =>
      compoundClasses
          .distinct()
          .fold(nestedExpression, invokeCompoundConstructor);

  // We need to replace calls to 'DynamicLibrary.lookupFunction' with explicit
  // Kernel, because we cannot have a generic call to 'asFunction' in its body.
  //
  // Above, in 'visitStaticInvocation', we ensure that the type arguments to
  // 'lookupFunction' are constants, so by inlining the call to 'asFunction' at
  // the call-site, we ensure that there are no generic calls to 'asFunction'.
  Expression _replaceLookupFunction(StaticInvocation node) {
    final DartType nativeSignature = node.arguments.types[0];
    final DartType dartSignature = node.arguments.types[1];

    final List<DartType> lookupTypeArgs = [
      InterfaceType(
          nativeFunctionClass, currentLibrary.nonNullable, [nativeSignature])
    ];
    final Arguments lookupArgs =
        Arguments([node.arguments.positional[1]], types: lookupTypeArgs);
    final FunctionType lookupFunctionType =
        libraryLookupMethod.getterType as FunctionType;

    final lookupResult = InstanceInvocation(InstanceAccessKind.Instance,
        node.arguments.positional[0], libraryLookupMethod.name, lookupArgs,
        interfaceTarget: libraryLookupMethod,
        functionType: FunctionTypeInstantiator.instantiate(
            lookupFunctionType, lookupTypeArgs));

    final isLeaf = getIsLeafBoolean(node) ?? false;

    return _replaceAsFunction(
      functionPointer: lookupResult,
      pointerType: lookupResult.functionType.returnType,
      nativeSignature: nativeSignature,
      dartSignature: dartSignature as FunctionType,
      isLeaf: isLeaf,
      fileOffset: node.fileOffset,
    );
  }

  // We need to rewrite calls to 'fromFunction' into two calls, representing the
  // compile-time and run-time aspects of creating the closure:
  //
  // final dynamic _#ffiCallback0 = Pointer.fromFunction<T>(f, e) =>
  //   _createNativeCallableIsolateLocal<NativeFunction<T>>(
  //     _nativeCallbackFunction<T>(f, e), null, false);
  //
  //  ... _#ffiCallback0 ...
  //
  // We must implement this as a Kernel rewrite because <T> must be a
  // compile-time constant to any invocation of '_nativeCallbackFunction'.
  //
  // Creating this closure requires a runtime call, so we save the result in a
  // synthetic top-level field to avoid recomputing it.
  Expression _replaceFromFunction(
      StaticInvocation node, Expression exceptionalReturn) {
    final nativeFunctionType = InterfaceType(
        nativeFunctionClass, currentLibrary.nonNullable, node.arguments.types);
    var name = Name("_#ffiCallback${callbackCount++}", currentLibrary);
    var getterReference = currentLibraryIndex?.lookupGetterReference(name);
    final Field field = Field.immutable(name,
        type: InterfaceType(
            pointerClass, currentLibrary.nonNullable, [nativeFunctionType]),
        initializer: StaticInvocation(
            createNativeCallableIsolateLocalProcedure,
            Arguments([
              StaticInvocation(
                  nativeCallbackFunctionProcedure,
                  Arguments([
                    node.arguments.positional[0],
                    exceptionalReturn,
                  ], types: node.arguments.types)),
              NullLiteral(),
              BoolLiteral(false),
            ], types: [
              nativeFunctionType
            ])),
        isStatic: true,
        isFinal: true,
        fileUri: currentLibrary.fileUri,
        getterReference: getterReference)
      ..fileOffset = node.fileOffset;
    currentLibrary.addField(field);
    return StaticGet(field);
  }

  // NativeCallable<T>.isolateLocal(target, exceptionalReturn) calls become:
  // isStaticFunction is false:
  //   _NativeCallableIsolateLocal<T>(
  //       _createNativeCallableIsolateLocal<NativeFunction<T>>(
  //           _nativeIsolateLocalCallbackFunction<T>(exceptionalReturn),
  //           target,
  //           true));
  // isStaticFunction is true:
  //   _NativeCallableIsolateLocal<T>(
  //       _createNativeCallableIsolateLocal<NativeFunction<T>>(
  //           _nativeCallbackFunction<T>(target, exceptionalReturn),
  //           null,
  //           true);
  Expression _replaceNativeCallableIsolateLocalConstructor(
      StaticInvocation node,
      Expression exceptionalReturn,
      bool isStaticFunction) {
    final nativeFunctionType = InterfaceType(
        nativeFunctionClass, currentLibrary.nonNullable, node.arguments.types);
    final target = node.arguments.positional[0];
    late StaticInvocation pointerValue;
    if (isStaticFunction) {
      pointerValue = StaticInvocation(
          createNativeCallableIsolateLocalProcedure,
          Arguments([
            StaticInvocation(
                nativeCallbackFunctionProcedure,
                Arguments([
                  target,
                  exceptionalReturn,
                ], types: node.arguments.types)),
            NullLiteral(),
            BoolLiteral(true),
          ], types: [
            nativeFunctionType,
          ]));
    } else {
      pointerValue = StaticInvocation(
          createNativeCallableIsolateLocalProcedure,
          Arguments([
            StaticInvocation(nativeIsolateLocalCallbackFunctionProcedure,
                Arguments([exceptionalReturn], types: node.arguments.types)),
            target,
            BoolLiteral(true),
          ], types: [
            nativeFunctionType,
          ]));
    }
    return ConstructorInvocation(nativeCallablePrivateIsolateLocalConstructor,
        Arguments([pointerValue], types: node.arguments.types));
  }

  // NativeCallable<T>.listener(target) calls become:
  // void _handler(List args) => target(args[0], args[1], ...)
  // final _callback = _NativeCallableListener<T>(_handler, debugName);
  // _callback._pointer = _createNativeCallableListener<NativeFunction<T>>(
  //       _nativeAsyncCallbackFunction<T>(), _callback._rawPort);
  // expression result: _callback;
  Expression _replaceNativeCallableListenerConstructor(StaticInvocation node) {
    final nativeFunctionType = InterfaceType(
        nativeFunctionClass, currentLibrary.nonNullable, node.arguments.types);
    final listType = InterfaceType(listClass, currentLibrary.nonNullable);
    final nativeCallableType = InterfaceType(
        nativeCallableClass, currentLibrary.nonNullable, node.arguments.types);
    final targetType = node.arguments.types[0] as FunctionType;

    // void _handler(List args) => target(args[0], args[1], ...)
    final args = VariableDeclaration('args', type: listType, isFinal: true)
      ..fileOffset = node.fileOffset;
    final targetArgs = <Expression>[];
    for (int i = 0; i < targetType.positionalParameters.length; ++i) {
      targetArgs.add(InstanceInvocation(InstanceAccessKind.Instance,
          VariableGet(args), listElementAt.name, Arguments([IntLiteral(i)]),
          interfaceTarget: listElementAt,
          functionType: Substitution.fromInterfaceType(listType)
              .substituteType(listElementAt.getterType) as FunctionType));
    }
    final target = node.arguments.positional[0];
    final handlerBody = ExpressionStatement(FunctionInvocation(
      FunctionAccessKind.FunctionType,
      target,
      Arguments(targetArgs),
      functionType: targetType,
    ));
    final handler = FunctionNode(handlerBody,
        positionalParameters: [args], returnType: VoidType())
      ..fileOffset = node.fileOffset;

    // final _callback = NativeCallable<T>._listener(_handler, debugName);
    final nativeCallable = VariableDeclaration.forValue(
        ConstructorInvocation(
            nativeCallablePrivateListenerConstructor,
            Arguments([
              FunctionExpression(handler),
              StringLiteral('NativeCallable($target)'),
            ], types: [
              targetType,
            ])),
        type: nativeCallableType,
        isFinal: true)
      ..fileOffset = node.fileOffset;

    // _callback._pointer = _createNativeCallableListener<NativeFunction<T>>(
    //       _nativeAsyncCallbackFunction<T>(), _callback._rawPort);
    final pointerValue = StaticInvocation(
        createNativeCallableListenerProcedure,
        Arguments([
          StaticInvocation(nativeAsyncCallbackFunctionProcedure,
              Arguments([], types: [targetType])),
          InstanceGet(InstanceAccessKind.Instance, VariableGet(nativeCallable),
              nativeCallablePortField.name,
              interfaceTarget: nativeCallablePortField,
              resultType: nativeCallablePortField.getterType),
        ], types: [
          nativeFunctionType,
        ]));
    final pointerSetter = ExpressionStatement(InstanceSet(
      InstanceAccessKind.Instance,
      VariableGet(nativeCallable),
      nativeCallablePointerField.name,
      pointerValue,
      interfaceTarget: nativeCallablePointerField,
    ));

    // expression result: _callback;
    return BlockExpression(
        Block([
          nativeCallable,
          pointerSetter,
        ]),
        VariableGet(nativeCallable));
  }

  Expression _verifyAndReplaceNativeCallableIsolateLocal(StaticInvocation node,
      {bool fromFunction = false}) {
    final DartType nativeType = InterfaceType(nativeFunctionClass,
        currentLibrary.nonNullable, [node.arguments.types[0]]);
    final Expression func = node.arguments.positional[0];
    final DartType dartType = func.getStaticType(staticTypeContext!);

    final isStaticFunction = _isStaticFunction(func);
    if (fromFunction && !isStaticFunction) {
      diagnosticReporter.report(
          templateFfiNotStatic.withArguments(fromFunctionMethod.name.text),
          func.fileOffset,
          1,
          func.location?.file);
      return node;
    }

    ensureNativeTypeValid(nativeType, node);
    ensureNativeTypeToDartType(
      nativeType,
      dartType,
      node,
      allowTypedData: true, // TypedData-specific errors emitted below.
    );
    ensureOnlyLeafCallsUseTypedData(
      node.arguments.types[0],
      dartType,
      isLeaf: false,
      isCall: false,
      reportErrorOn: node,
    );

    final funcType = dartType as FunctionType;

    // Check `exceptionalReturn`'s type.
    final Class expectedReturnClass =
        ((node.arguments.types[0] as FunctionType).returnType as InterfaceType)
            .classNode;
    final NativeType? expectedReturn = getType(expectedReturnClass);

    Expression exceptionalReturn = NullLiteral();
    bool hasExceptionalReturn = false;
    if (fromFunction) {
      if (node.arguments.positional.length > 1) {
        exceptionalReturn = node.arguments.positional[1];
        hasExceptionalReturn = true;
      }
    } else {
      if (node.arguments.named.isNotEmpty) {
        exceptionalReturn = node.arguments.named[0].value;
        hasExceptionalReturn = true;
      }
    }

    if (expectedReturn == NativeType.kVoid ||
        expectedReturn == NativeType.kPointer ||
        expectedReturn == NativeType.kHandle ||
        expectedReturnClass.superclass == structClass ||
        expectedReturnClass.superclass == unionClass) {
      if (hasExceptionalReturn) {
        diagnosticReporter.report(
            templateFfiExpectedNoExceptionalReturn.withArguments(
                funcType.returnType, currentLibrary.isNonNullableByDefault),
            node.fileOffset,
            1,
            node.location?.file);
        return node;
      }
    } else {
      // The exceptional return value is not optional for other return types.
      if (!hasExceptionalReturn) {
        diagnosticReporter.report(
            templateFfiExpectedExceptionalReturn.withArguments(
                funcType.returnType, currentLibrary.isNonNullableByDefault),
            node.fileOffset,
            1,
            node.location?.file);
        return node;
      }

      // The exceptional return value must be a constant so that it can be
      // referenced by precompiled trampoline's object pool.
      if (exceptionalReturn is! BasicLiteral &&
          !(exceptionalReturn is ConstantExpression &&
              exceptionalReturn.constant is PrimitiveConstant)) {
        diagnosticReporter.report(messageFfiExpectedConstant, node.fileOffset,
            1, node.location?.file);
        return node;
      }

      // Moreover it may not be null.
      if (exceptionalReturn is NullLiteral ||
          (exceptionalReturn is ConstantExpression &&
              exceptionalReturn.constant is NullConstant)) {
        diagnosticReporter.report(messageFfiExceptionalReturnNull,
            node.fileOffset, 1, node.location?.file);
        return node;
      }

      final DartType returnType =
          exceptionalReturn.getStaticType(staticTypeContext!);

      if (!env.isSubtypeOf(returnType, funcType.returnType,
          SubtypeCheckMode.ignoringNullabilities)) {
        diagnosticReporter.report(
            templateFfiDartTypeMismatch.withArguments(returnType,
                funcType.returnType, currentLibrary.isNonNullableByDefault),
            exceptionalReturn.fileOffset,
            1,
            exceptionalReturn.location?.file);
        return node;
      }
    }

    final replacement = fromFunction
        ? _replaceFromFunction(node, exceptionalReturn)
        : _replaceNativeCallableIsolateLocalConstructor(
            node, exceptionalReturn, isStaticFunction);

    final compoundClasses = funcType.positionalParameters
        .whereType<InterfaceType>()
        .map((t) => t.classNode)
        .where((c) => c.superclass == structClass || c.superclass == unionClass)
        .toList();
    return invokeCompoundConstructors(replacement, compoundClasses);
  }

  Expression _replaceGetRef(StaticInvocation node) {
    final dartType = node.arguments.types[0];
    final clazz = (dartType as InterfaceType).classNode;
    final referencedStruct = ReferencedCompoundSubtypeCfe(clazz);

    Expression pointer = NullCheck(node.arguments.positional[0]);
    if (node.arguments.positional.length == 2) {
      pointer = InstanceInvocation(
          InstanceAccessKind.Instance,
          pointer,
          offsetByMethod.name,
          Arguments([
            multiply(node.arguments.positional[1], inlineSizeOf(dartType)!)
          ]),
          interfaceTarget: offsetByMethod,
          functionType:
              Substitution.fromPairs(pointerClass.typeParameters, [dartType])
                  .substituteType(offsetByMethod.getterType) as FunctionType);
    }

    return referencedStruct.generateLoad(
      dartType: dartType,
      transformer: this,
      typedDataBase: pointer,
      offsetInBytes: ConstantExpression(IntConstant(0)),
      fileOffset: node.fileOffset,
    );
  }

  /// Replaces a `.ref=` or `[]=` on a compound pointer extension with a mem
  /// copy call.
  Expression _replaceSetRef(StaticInvocation node) {
    final target = node.arguments.positional[0]; // Receiver of extension
    final referencedStruct = ReferencedCompoundSubtypeCfe(
        (node.arguments.types[0] as InterfaceType).classNode);

    final Expression sourceStruct, targetOffset;

    if (node.arguments.positional.length == 3) {
      // []= call, args are (receiver, index, source)
      sourceStruct = node.arguments.positional[2];
      targetOffset = multiply(node.arguments.positional[1],
          inlineSizeOf(node.arguments.types[0] as InterfaceType)!);
    } else {
      // .ref= call, args are (receiver, source)
      sourceStruct = node.arguments.positional[1];
      targetOffset = ConstantExpression(IntConstant(0));
    }

    return referencedStruct.generateStore(
      sourceStruct,
      dartType: node.arguments.types[0],
      offsetInBytes: targetOffset,
      typedDataBase: target,
      transformer: this,
      fileOffset: node.fileOffset,
    );
  }

  Expression _replaceRefArray(StaticInvocation node) {
    final dartType = node.arguments.types[0];
    final clazz = (dartType as InterfaceType).classNode;
    final constructor = clazz.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));

    final arrayVar = VariableDeclaration("#array",
        initializer: NullCheck(node.arguments.positional[0]),
        type: InterfaceType(arrayClass, Nullability.nonNullable),
        isSynthesized: true)
      ..fileOffset = node.fileOffset;
    final indexVar = VariableDeclaration("#index",
        initializer: NullCheck(node.arguments.positional[1]),
        type: coreTypes.intNonNullableRawType,
        isSynthesized: true)
      ..fileOffset = node.fileOffset;

    return BlockExpression(
      Block([
        arrayVar,
        indexVar,
        ExpressionStatement(InstanceInvocation(
          InstanceAccessKind.Instance,
          VariableGet(arrayVar),
          arrayCheckIndex.name,
          Arguments([VariableGet(indexVar)]),
          interfaceTarget: arrayCheckIndex,
          functionType: arrayCheckIndex.getterType as FunctionType,
        )),
      ]),
      ConstructorInvocation(
        constructor,
        Arguments([
          typedDataBaseOffset(
            getArrayTypedDataBaseField(VariableGet(arrayVar)),
            multiply(VariableGet(indexVar), inlineSizeOf(dartType)!),
            inlineSizeOf(dartType)!,
            dartType,
            node.fileOffset,
          )
        ]),
      ),
    );
  }

  /// Generates an expression that returns a new `Array<dartType>`.
  ///
  /// Sample input getter:
  /// ```
  /// this<Array<T>>[index]
  /// ```
  ///
  /// Sample output getter:
  ///
  /// ```
  /// Array #array = this!;
  /// int #index = index!;
  /// #array._checkIndex(#index);
  /// int #singleElementSize = inlineSizeOf<innermost(T)>();
  /// int #elementSize = #array.nestedDimensionsFlattened * #singleElementSize;
  /// int #offset = #elementSize * #index;
  ///
  /// new Array<T>._(
  ///   typedDataBaseOffset(#array._typedDataBase, #offset, #elementSize),
  ///   #array.nestedDimensionsFirst,
  ///   #array.nestedDimensionsRest
  /// )
  /// ```
  ///
  /// Sample input setter:
  /// ```
  /// this<Array<T>>[index] = value
  /// ```
  ///
  /// Sample output setter:
  ///
  /// ```
  /// Array #array = this!;
  /// int #index = index!;
  /// #array._checkIndex(#index);
  /// int #singleElementSize = inlineSizeOf<innermost(T)>();
  /// int #elementSize = #array.nestedDimensionsFlattened * #singleElementSize;
  /// int #offset = #elementSize * #index;
  ///
  /// _memCopy(
  ///   #array._typedDataBase, #offset, value._typedDataBase, 0, #elementSize)
  /// ```
  Expression _replaceArrayArrayElemAt(StaticInvocation node,
      {bool setter = false}) {
    final dartType = node.arguments.types[0];
    final elementType = arraySingleElementType(dartType as InterfaceType);

    final arrayVar = VariableDeclaration("#array",
        initializer: NullCheck(node.arguments.positional[0]),
        type: InterfaceType(arrayClass, Nullability.nonNullable),
        isSynthesized: true)
      ..fileOffset = node.fileOffset;
    final indexVar = VariableDeclaration("#index",
        initializer: NullCheck(node.arguments.positional[1]),
        type: coreTypes.intNonNullableRawType,
        isSynthesized: true)
      ..fileOffset = node.fileOffset;
    final singleElementSizeVar = VariableDeclaration("#singleElementSize",
        initializer: inlineSizeOf(elementType as InterfaceType),
        type: coreTypes.intNonNullableRawType,
        isSynthesized: true)
      ..fileOffset = node.fileOffset;
    final elementSizeVar = VariableDeclaration("#elementSize",
        initializer: multiply(
            VariableGet(singleElementSizeVar),
            InstanceGet(InstanceAccessKind.Instance, VariableGet(arrayVar),
                arrayNestedDimensionsFlattened.name,
                interfaceTarget: arrayNestedDimensionsFlattened,
                resultType: arrayNestedDimensionsFlattened.getterType)),
        type: coreTypes.intNonNullableRawType,
        isSynthesized: true)
      ..fileOffset = node.fileOffset;
    final offsetVar = VariableDeclaration("#offset",
        initializer:
            multiply(VariableGet(elementSizeVar), VariableGet(indexVar)),
        type: coreTypes.intNonNullableRawType,
        isSynthesized: true)
      ..fileOffset = node.fileOffset;

    final checkIndexAndLocalVars = Block([
      arrayVar,
      indexVar,
      ExpressionStatement(InstanceInvocation(
        InstanceAccessKind.Instance,
        VariableGet(arrayVar),
        arrayCheckIndex.name,
        Arguments([VariableGet(indexVar)]),
        interfaceTarget: arrayCheckIndex,
        functionType: arrayCheckIndex.getterType as FunctionType,
      )),
      singleElementSizeVar,
      elementSizeVar,
      offsetVar
    ]);

    if (!setter) {
      // `[]`
      return BlockExpression(
          checkIndexAndLocalVars,
          ConstructorInvocation(
              arrayConstructor,
              Arguments([
                typedDataBaseOffset(
                    getArrayTypedDataBaseField(VariableGet(arrayVar)),
                    VariableGet(offsetVar),
                    VariableGet(elementSizeVar),
                    dartType,
                    node.fileOffset),
                InstanceGet(InstanceAccessKind.Instance, VariableGet(arrayVar),
                    arrayNestedDimensionsFirst.name,
                    interfaceTarget: arrayNestedDimensionsFirst,
                    resultType: arrayNestedDimensionsFirst.getterType),
                InstanceGet(InstanceAccessKind.Instance, VariableGet(arrayVar),
                    arrayNestedDimensionsRest.name,
                    interfaceTarget: arrayNestedDimensionsRest,
                    resultType: arrayNestedDimensionsRest.getterType)
              ], types: [
                dartType
              ])));
    }

    // `[]=`
    return BlockExpression(
        checkIndexAndLocalVars,
        StaticInvocation(
            memCopy,
            Arguments([
              getArrayTypedDataBaseField(
                  VariableGet(arrayVar), node.fileOffset),
              VariableGet(offsetVar),
              getArrayTypedDataBaseField(
                  node.arguments.positional[2], node.fileOffset),
              ConstantExpression(IntConstant(0)),
              VariableGet(elementSizeVar),
            ]))
          ..fileOffset = node.fileOffset);
  }

  bool _isStaticFunction(Expression node) =>
      (node is StaticGet && node.target is Procedure) ||
      (node is ConstantExpression && node.constant is StaticTearOffConstant);

  /// Returns the class that should not be implemented or extended.
  ///
  /// If the superclass is not sealed, returns `null`.
  Class? _extendsOrImplementsSealedClass(Class klass) {
    // Classes in dart:ffi themselves can extend FFI classes.
    if (klass == arrayClass ||
        klass == arraySizeClass ||
        klass == compoundClass ||
        klass == opaqueClass ||
        klass == structClass ||
        klass == unionClass ||
        klass == abiSpecificIntegerClass ||
        klass == varArgsClass ||
        classNativeTypes[klass] != null) {
      return null;
    }

    // The Opaque and Struct classes can be extended, but subclasses
    // cannot be (nor implemented).
    final onlyDirectExtendsClasses = [
      opaqueClass,
      structClass,
      unionClass,
      abiSpecificIntegerClass,
    ];
    final superClass = klass.superclass;
    for (final onlyDirectExtendsClass in onlyDirectExtendsClasses) {
      if (hierarchy.isSubInterfaceOf(klass, onlyDirectExtendsClass)) {
        if (superClass == onlyDirectExtendsClass) {
          // Directly extending is fine.
          return null;
        } else {
          return superClass;
        }
      }
    }

    return null;
  }

  void _ensureNotExtendsOrImplementsSealedClass(Class klass) {
    final Class? extended = _extendsOrImplementsSealedClass(klass);
    if (extended != null) {
      diagnosticReporter.report(
          templateFfiExtendsOrImplementsSealedClass
              .withArguments(extended.name),
          klass.fileOffset,
          1,
          klass.location?.file);
      throw FfiStaticTypeError();
    }
  }

  void _ensureIsLeafIsConst(StaticInvocation node) {
    final isLeaf = getIsLeafBoolean(node);
    if (isLeaf == null) {
      diagnosticReporter.report(
          templateFfiExpectedConstantArg.withArguments('isLeaf'),
          node.fileOffset,
          1,
          node.location?.file);
      // Throw so we don't get another error about not replacing
      // `lookupFunction`, which will shadow the above error.
      throw FfiStaticTypeError();
    }
  }

  /// Replaces calls to `Native.addressOf(x)` by looking up the `@Native`
  /// annotation of `x` and rewriting the expression to use
  /// `_addressOf(annotation)`, which is implemented in the VM.
  ///
  /// By implementing this in the VM, we can re-use the implementation used to
  /// lookup addresses for `@Native` invocations. We could also replace the
  /// call with an invocation to `Native._ffi_resolver_function` and wrap the
  /// result in a `Pointer`. To support static linking of native functions in
  /// the future, having the unresolved symbol in the assembly generated for
  /// each call site in the VM will be necessary. So we're already doing this
  /// in the VM today.
  ///
  /// The transformation works by looking up the resolved `@Native` annotation
  /// left by the native transformer in a pragma. Looking for a `@Native`
  /// annotation on the argument wouldn't work because it's removed by the
  /// native transformer and because it requires context from the library to
  /// resolve the asset id.
  StaticInvocation _replaceNativeAddressOf(StaticInvocation node) {
    final arg = node.arguments.positional.single;
    final nativeType = node.arguments.types.single;

    final potentiallyNativeTarget = switch (arg) {
      ConstantExpression(constant: StaticTearOffConstant method) =>
        method.target,
      StaticGet(:var targetReference) => targetReference.asMember,
      _ => null,
    };
    Constant? nativeAnnotation;

    if (potentiallyNativeTarget != null) {
      for (final annotation in potentiallyNativeTarget.annotations) {
        if (annotation
            case ConstantExpression(constant: final InstanceConstant c)) {
          if (c.classNode == coreTypes.pragmaClass) {
            final name = c.fieldValues[coreTypes.pragmaName.fieldReference];
            if (name is StringConstant &&
                name.value == native.FfiNativeTransformer.nativeMarker) {
              nativeAnnotation =
                  c.fieldValues[coreTypes.pragmaOptions.fieldReference]!;
              break;
            }
          }
        }
      }
    }

    if (nativeAnnotation == null) {
      diagnosticReporter.report(messageFfiAddressOfMustBeNative, arg.fileOffset,
          1, node.location?.file);
      return node;
    }

    ensureNativeTypeValid(nativeType, node,
        allowCompounds: true, allowInlineArray: true);
    ensureNativeTypeToDartType(
        nativeType, arg.getStaticType(staticTypeContext!), node,
        allowArray: true);

    return StaticInvocation(
      nativePrivateAddressOf,
      Arguments([ConstantExpression(nativeAnnotation)], types: [nativeType]),
    )..fileOffset = arg.fileOffset;
  }
}

extension<T extends Object> on List<T> {
  /// Order-preserved distinct elements.
  List<T> distinct() {
    final seen = <T>{};
    return where((element) => seen.add(element)).toList();
  }
}
