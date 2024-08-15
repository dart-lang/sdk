// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This imports 'codes/cfe_codes.dart' instead of 'api_prototype/codes.dart' to
// avoid cyclic dependency between `package:vm/modular` and `package:front_end`.
import 'package:front_end/src/codes/cfe_codes.dart'
    show
        messageFfiAddressOfMustBeNative,
        messageFfiAddressPosition,
        messageFfiAddressReceiver,
        messageFfiCreateOfStructOrUnion,
        messageFfiExceptionalReturnNull,
        messageFfiExpectedConstant,
        templateFfiDartTypeMismatch,
        templateFfiNativeCallableListenerReturnVoid,
        templateFfiExpectedConstantArg,
        templateFfiExpectedExceptionalReturn,
        templateFfiExpectedNoExceptionalReturn,
        templateFfiExtendsOrImplementsSealedClass,
        templateFfiNotStatic;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/clone.dart';
import 'package:kernel/constructor_tearoff_lowering.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/names.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_algebra.dart'
    show FunctionTypeInstantiator, Substitution;
import 'package:kernel/type_environment.dart';

import 'common.dart'
    show FfiStaticTypeError, FfiTransformer, NativeType, FfiTypeCheckDirection;
import 'definitions.dart' as definitions;
import 'finalizable.dart';
import 'native.dart' as native;
import 'native_type_cfe.dart';

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
        target.enclosingClass != arrayClass &&
        target.enclosingClass != compoundClass &&
        target.name != Name("#fromTypedDataBase") &&
        target.name != Name("#fromTypedData")) {
      diagnosticReporter.report(messageFfiCreateOfStructOrUnion,
          node.fileOffset, 1, node.location?.file);
    }
    return super.visitConstructorInvocation(node);
  }

  /// Transforms calls to Struct.create and Union.create.
  ///
  /// Transforms `create<T>()` into
  ///
  /// ```
  /// Compound._fromTypedDataBase(Uint8List(sizeOf<T>()))
  /// ```
  ///
  /// and `create<T>(typedList)` into
  ///
  /// ```
  /// Compound._fromTypedData(typedList, sizeOf<T>())
  /// ```
  ///
  /// in subclasses of `Struct` and `Union`.
  Expression _transformCompoundCreate(StaticInvocation node) {
    final positionalArguments = node.arguments.positional;
    final nativeType = (node.arguments.types.first as InterfaceType);
    final constructors = nativeType.classNode.constructors;
    final sizeOfExpression = inlineSizeOf(nativeType)!;
    if (positionalArguments.isNotEmpty) {
      // Check length of provided typed data, use checked constructor.
      return ConstructorInvocation(
        constructors.firstWhere((c) => c.name == Name("#fromTypedData")),
        Arguments([
          node.arguments.positional.first,
          (positionalArguments.length >= 2
              ? positionalArguments[1]
              : ConstantExpression(IntConstant(0))),
          // Length in bytes to check the typedData against.
          sizeOfExpression,
        ]),
      );
    }

    // Correct-size typed data is allocated, use unchecked constructor.
    return ConstructorInvocation(
      constructors.firstWhere((c) => c.name == Name("#fromTypedDataBase")),
      Arguments([
        StaticInvocation(
          uint8ListFactory,
          Arguments([sizeOfExpression]),
        ),
        ConstantExpression(IntConstant(0)),
      ]),
    );
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
            allowStructAndUnion: true, allowInlineArray: true);

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
            typedDataBase: getCompoundTypedDataBaseField(
              VariableGet(arrayVar),
              node.fileOffset,
            ),
            offsetInBytes: getCompoundOffsetInBytesField(
              VariableGet(arrayVar),
              node.fileOffset,
            ),
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
            allowStructAndUnion: true, allowInlineArray: true);

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

        ensureNativeTypeValid(nativeType, node, allowStructAndUnion: true);

        return _replaceGetRef(node);
      } else if (target == structPointerSetRef ||
          target == structPointerSetElemAt ||
          target == unionPointerSetRef ||
          target == unionPointerSetElemAt) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node, allowStructAndUnion: true);

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
            allowStructAndUnion: true, allowInlineArray: true);
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node, allowStructAndUnion: true);

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

        ensureNativeTypeValid(nativeType, node, allowStructAndUnion: true);

        return _replaceRefArray(node);
      } else if (target == arrayArrayElemAt) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node,
            allowInlineArray: true, allowStructAndUnion: true);

        return _replaceArrayArrayElemAt(node);
      } else if (target == arrayArrayAssignAt) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node,
            allowInlineArray: true, allowStructAndUnion: true);

        return _replaceArrayArrayElemAt(node, setter: true);
      } else if (target == sizeOfMethod) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node,
            allowStructAndUnion: true, allowVoid: true);

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
        ensureNativeTypeMatch(
          FfiTypeCheckDirection.nativeToDart,
          nativeType,
          dartType,
          node,
          allowHandle: true, // Handle-specific errors emitted below.
        );
        ensureLeafCallDoesNotUseHandles(
          nativeType,
          isLeaf,
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
        ensureNativeTypeMatch(
          FfiTypeCheckDirection.nativeToDart,
          nativeType,
          dartType,
          node,
          allowHandle: true, // Handle-specific errors emitted below.
        );
        ensureLeafCallDoesNotUseHandles(
          nativeType,
          isLeaf,
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
        final ffiFuncType = ensureNativeTypeMatch(
                FfiTypeCheckDirection.dartToNative, nativeType, dartType, node)
            as FunctionType;

        final funcType = dartType as FunctionType;

        // Check return type.
        if (ffiFuncType.returnType != VoidType()) {
          diagnosticReporter.report(
              templateFfiNativeCallableListenerReturnVoid
                  .withArguments(ffiFuncType.returnType),
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
            allowStructAndUnion: true, allowVoid: true);

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
      } else if (target == structCreate || target == unionCreate) {
        final nativeType = node.arguments.types.first;
        ensureNativeTypeValid(nativeType, node, allowStructAndUnion: true);
        return _transformCompoundCreate(node);
      } else if (target == nativeAddressOf) {
        return _replaceNativeAddressOf(node);
      } else if (addressOfMethods.contains(target)) {
        // The AST is visited recursively down. Handling of native invocations
        // will inspect arguments for `<expr>.address` invocations. Any
        // remaining invocations occur are places where `<expr>.address` is
        // disallowed, so issue an error.
        diagnosticReporter.report(
            messageFfiAddressPosition, node.fileOffset, 1, node.location?.file);
      } else {
        final nativeAnnotation = memberGetNativeAnnotation(target);
        if (nativeAnnotation != null && _isLeaf(nativeAnnotation)) {
          return _replaceNativeCall(node, nativeAnnotation);
        }
      }
    } on FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
    }

    return node;
  }

  bool _isLeaf(InstanceConstant native) {
    return (native.fieldValues[nativeIsLeafField.fieldReference]
            as BoolConstant)
        .value;
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
    final ffiFuncType = ensureNativeTypeMatch(
      FfiTypeCheckDirection.dartToNative,
      nativeType,
      dartType,
      node,
    ) as FunctionType;

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
            templateFfiExpectedNoExceptionalReturn
                .withArguments(ffiFuncType.returnType),
            node.fileOffset,
            1,
            node.location?.file);
        return node;
      }
    } else {
      // The exceptional return value is not optional for other return types.
      if (!hasExceptionalReturn) {
        diagnosticReporter.report(
            templateFfiExpectedExceptionalReturn
                .withArguments(ffiFuncType.returnType),
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
            templateFfiDartTypeMismatch.withArguments(
                returnType, funcType.returnType),
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
    final DartType sourceStructType;

    if (node.arguments.positional.length == 3) {
      // []= call, args are (receiver, index, source)
      sourceStruct = node.arguments.positional[2];
      sourceStructType = node.arguments.types[0];
      targetOffset = multiply(node.arguments.positional[1],
          inlineSizeOf(node.arguments.types[0] as InterfaceType)!);
    } else {
      // .ref= call, args are (receiver, source)
      sourceStruct = node.arguments.positional[1];
      sourceStructType = node.arguments.types[0];
      targetOffset = ConstantExpression(IntConstant(0));
    }

    final sourceVar = VariableDeclaration(
      "#source",
      initializer: sourceStruct,
      type: sourceStructType,
      isSynthesized: true,
    )..fileOffset = node.fileOffset;

    return BlockExpression(
      Block([sourceVar]),
      referencedStruct.generateStore(
        sourceVar,
        dartType: node.arguments.types[0],
        offsetInBytes: targetOffset,
        typedDataBase: target,
        transformer: this,
        fileOffset: node.fileOffset,
      ),
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
          getCompoundTypedDataBaseField(
            VariableGet(arrayVar),
            node.fileOffset,
          ),
          add(
            getCompoundOffsetInBytesField(
              VariableGet(arrayVar),
              node.fileOffset,
            ),
            multiply(VariableGet(indexVar), inlineSizeOf(dartType)!),
          ),
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
  ///   #array._typedDataBase,
  ///   #offset,
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

    final checkIndexAndLocalVars = [
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
      offsetVar,
    ];

    if (!setter) {
      // `[]`
      return BlockExpression(
          Block(checkIndexAndLocalVars),
          ConstructorInvocation(
              arrayConstructor,
              Arguments([
                getCompoundTypedDataBaseField(
                  VariableGet(arrayVar),
                  node.fileOffset,
                ),
                add(
                  getCompoundOffsetInBytesField(
                    VariableGet(arrayVar),
                    node.fileOffset,
                  ),
                  VariableGet(offsetVar),
                ),
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
    final valueVar = VariableDeclaration(
      "#value",
      initializer: NullCheck(node.arguments.positional[2]),
      type: InterfaceType(arrayClass, Nullability.nonNullable),
      isSynthesized: true,
    )..fileOffset = node.fileOffset;
    return BlockExpression(
        Block([
          ...checkIndexAndLocalVars,
          valueVar,
        ]),
        StaticInvocation(
            memCopy,
            Arguments([
              getCompoundTypedDataBaseField(
                VariableGet(arrayVar),
                node.fileOffset,
              ),
              add(
                getCompoundOffsetInBytesField(
                  VariableGet(arrayVar),
                  node.fileOffset,
                ),
                VariableGet(offsetVar),
              ),
              getCompoundTypedDataBaseField(
                VariableGet(valueVar),
                node.fileOffset,
              ),
              getCompoundOffsetInBytesField(
                VariableGet(valueVar),
                node.fileOffset,
              ),
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
    Constant? nativeAnnotation =
        memberGetNativeAnnotation(potentiallyNativeTarget);

    if (nativeAnnotation == null) {
      diagnosticReporter.report(messageFfiAddressOfMustBeNative, arg.fileOffset,
          1, node.location?.file);
      return node;
    }

    ensureNativeTypeValid(nativeType, node,
        allowStructAndUnion: true, allowInlineArray: true);
    ensureNativeTypeMatch(FfiTypeCheckDirection.nativeToDart, nativeType,
        arg.getStaticType(staticTypeContext!), node,
        allowArray: true);

    return StaticInvocation(
      nativePrivateAddressOf,
      Arguments([ConstantExpression(nativeAnnotation)], types: [nativeType]),
    )..fileOffset = arg.fileOffset;
  }

  InstanceConstant? memberGetNativeAnnotation(Member? member) {
    if (member == null) {
      return null;
    }
    for (final annotation in member.annotations) {
      if (annotation
          case ConstantExpression(constant: final InstanceConstant c)) {
        if (c.classNode == coreTypes.pragmaClass) {
          final name = c.fieldValues[coreTypes.pragmaName.fieldReference];
          if (name is StringConstant &&
              name.value == native.FfiNativeTransformer.nativeMarker) {
            return c.fieldValues[coreTypes.pragmaOptions.fieldReference]
                as InstanceConstant;
          }
        }
      }
    }
    return null;
  }

  StaticInvocation _replaceNativeCall(
    StaticInvocation node,
    InstanceConstant targetNativeAnnotation,
  ) {
    final target = node.target;
    if (targetNativeAnnotation.typeArguments.length != 1) {
      return node;
    }
    final annotationType = targetNativeAnnotation.typeArguments.single;
    if (annotationType is! FunctionType) {
      return node;
    }
    final parameterTypes = [
      for (final varDecl in target.function.positionalParameters) varDecl.type,
    ];
    final numParams = parameterTypes.length;
    String methodPostfix = '';
    final newArguments = <Expression>[];
    final newParameters = <VariableDeclaration>[];
    bool isTransformed = false;
    for (int i = 0; i < numParams; i++) {
      final parameter = target.function.positionalParameters[i];
      final parameterType = parameterTypes[i];
      final argument = node.arguments.positional[i];
      final (
        postFix,
        newType,
        newArgument,
      ) = _replaceNativeCallParameterAndArgument(
        parameter,
        parameterType,
        argument,
        node.fileOffset,
      );
      methodPostfix += postFix;
      if (postFix == 'C' || postFix == 'E' || postFix == 'T') {
        isTransformed = true;
      }
      newParameters.add(VariableDeclaration(
        parameter.name,
        type: newType,
      ));
      newArguments.add(newArgument);
    }

    if (!isTransformed) {
      return node;
    }

    final newName = '${target.name.text}#$methodPostfix';
    final Procedure newTarget;
    final parent = target.parent;
    final members = switch (parent) {
      Library _ => parent.members,
      Class _ => parent.members,
      _ => throw UnimplementedError('Unexpected parent: ${parent}'),
    };

    final existingNewTarget = members
        .whereType<Procedure>()
        .where((element) => element.name.text == newName)
        .firstOrNull;
    if (existingNewTarget != null) {
      newTarget = existingNewTarget;
    } else {
      final cloner = CloneProcedureWithoutBody();
      newTarget = cloner.cloneProcedure(target, null);
      newTarget.name = Name(newName);
      newTarget.function.positionalParameters = newParameters;
      setParents(newParameters, newTarget.function);
      switch (parent) {
        case Library _:
          parent.addProcedure(newTarget);
        case Class _:
          parent.addProcedure(newTarget);
      }
    }

    return StaticInvocation(
      newTarget,
      Arguments(newArguments),
    );
  }

  /// Converts a single parameter with argument for [_replaceNativeCall].
  (
    /// '' for non-Pointer.
    /// 'P' for Pointer.
    /// 'T' for TypedData.
    /// 'C' for _Compound (TypedData/Pointer and offset in bytes).
    /// 'E' for errors.
    String methodPostFix,
    DartType parameterType,
    Expression argument,
  ) _replaceNativeCallParameterAndArgument(
    VariableDeclaration parameter,
    DartType parameterType,
    Expression argument,
    int fileOffset,
  ) {
    if (parameterType is! InterfaceType ||
        parameterType.classNode != pointerClass) {
      // Parameter is non-pointer. Keep unchanged.
      return ('', parameterType, argument);
    }

    if (argument is! StaticInvocation ||
        !addressOfMethods.contains(argument.target)) {
      // The argument has type Pointer, but it's not produced by any of the
      // `.address` getters.
      // Argument must be a Pointer object. Keep unchanged.
      return ('P', parameterType, argument);
    }

    if (addressOfMethodsTypedData.contains(argument.target)) {
      final subExpression = argument.arguments.positional.single;
      // Argument is `typedData.address`.
      final typedDataType = InterfaceType(
        typedDataClass,
        Nullability.nonNullable,
        const <DartType>[],
      );
      return ('T', typedDataType, subExpression);
    }

    final subExpression = argument.arguments.positional.single;

    if (addressOfMethodsCompound.contains(argument.target)) {
      // Argument is `structOrUnionOrArray.address`.
      return ('C', compoundType, subExpression);
    }

    assert(addressOfMethodsPrimitive.contains(argument.target));
    // Argument is an `expr.address` where `expr` is typed `bool`, `int`, or
    // `double`. Analyze `expr` further.
    switch (subExpression) {
      case InstanceGet _:
        // Look for `structOrUnion.member.address`.
        final interfaceTarget = subExpression.interfaceTarget;
        final enclosingClass = interfaceTarget.enclosingClass!;
        final targetSuperClass = enclosingClass.superclass;
        if (targetSuperClass == unionClass) {
          // `expr` is a union member access.
          // Union members have no additional offset. Pass in unchanged.
          return ('C', compoundType, subExpression.receiver);
        }
        if (targetSuperClass == structClass) {
          final getterName = interfaceTarget.name.text;
          final offsetOfName = '$getterName#offsetOf';
          final offsetGetter = enclosingClass.procedures
              .firstWhere((e) => e.name.text == offsetOfName);
          // `expr` is a struct member access. Struct members have an offset.
          // Pass in a newly constructed `_Compound`, with adjusted offset.
          return (
            'C',
            compoundType,
            _generateCompoundOffsetBy(
              subExpression.receiver,
              StaticGet(offsetGetter),
              fileOffset,
              variableName: "${parameter.name}#value",
            ),
          );
        }
      // Error, unrecognized getter.

      case StaticInvocation _:
        // Look for `array[index].address`.
        // Extensions have already been desugared, so no enclosing extension.
        final target = subExpression.target;
        if (!target.isExtensionMember) break;
        final positionalParameters = target.function.positionalParameters;
        if (positionalParameters.length != 2) break;
        final firstParamType = positionalParameters.first.type;
        if (firstParamType is! InterfaceType) break;
        if (firstParamType.classNode != arrayClass) break;
        // Extensions have already been desugared, so original name is lost.
        if (!target.name.text.endsWith('|[]')) break;
        final DartType arrayElementType;
        if (subExpression.arguments.types.isNotEmpty) {
          // AbiSpecificInteger.
          arrayElementType = subExpression.arguments.types.single;
        } else {
          arrayElementType = firstParamType.typeArguments.single;
        }
        final arrayElementSize =
            inlineSizeOf(arrayElementType as InterfaceType)!;
        // Array element. Pass in a newly constructed `_Compound`, with
        // adjusted offset.
        return (
          'C',
          compoundType,
          _generateCompoundOffsetBy(
            subExpression.arguments.positional[0],
            multiply(
              arrayElementSize,
              subExpression.arguments.positional[1], // index.
            ),
            fileOffset,
            variableName: "${parameter.name}#value",
          ),
        );

      case InstanceInvocation _:
        // Look for `typedData[index].address`
        final receiverType =
            staticTypeContext!.getExpressionType(subExpression.receiver);
        final implementsTypedData = TypeEnvironment(coreTypes, hierarchy)
            .isSubtypeOf(
                receiverType,
                InterfaceType(typedDataClass, Nullability.nonNullable),
                SubtypeCheckMode.withNullabilities);
        if (!implementsTypedData) break;
        if (receiverType is! InterfaceType) break;
        final classNode = receiverType.classNode;
        final elementSizeInBytes = _typedDataElementSizeInBytes(classNode);
        if (elementSizeInBytes == null) break;

        // Typed Data element off. Pass in new _Compound with extra
        // offset.
        return (
          'C',
          compoundType,
          ConstructorInvocation(
            compoundFromTypedDataBase,
            Arguments([
              subExpression.receiver,
              multiply(
                ConstantExpression(IntConstant(elementSizeInBytes)),
                subExpression.arguments.positional.first, // index.
              ),
            ]),
          ),
        );
      default:
    }

    diagnosticReporter.report(
      messageFfiAddressReceiver,
      argument.fileOffset,
      1,
      argument.location?.file,
    );
    // Pass nullptr to prevent cascading error messages.
    return (
      'E', // Error.
      pointerVoidType,
      StaticInvocation(
        fromAddressInternal,
        Arguments(
          <Expression>[ConstantExpression(IntConstant(0))],
          types: <DartType>[voidType],
        ),
      ),
    );
  }

  int? _typedDataElementSizeInBytes(Class classNode) {
    final name = classNode.name;
    if (name.contains('8')) {
      return 1;
    } else if (name.contains('16')) {
      return 2;
    } else if (name.contains('32')) {
      return 4;
    } else if (name.contains('64')) {
      return 8;
    }
    return null;
  }

  /// Returns:
  ///
  /// ```
  /// _Compound._fromTypedDataBase(
  ///   compound._typedDataBase,
  ///   compound._offsetInBytes + offsetInBytes,
  /// )
  /// ```
  Expression _generateCompoundOffsetBy(
    Expression compound,
    Expression offsetInBytes,
    int fileOffset, {
    String variableName = "#compoundOffset",
  }) {
    final compoundType = InterfaceType(
      compoundClass,
      Nullability.nonNullable,
      const <DartType>[],
    );

    final valueVar = VariableDeclaration(
      variableName,
      initializer: compound,
      type: compoundType,
      isSynthesized: true,
    )..fileOffset = fileOffset;
    final newArgument = BlockExpression(
      Block([
        valueVar,
      ]),
      ConstructorInvocation(
        compoundFromTypedDataBase,
        Arguments([
          getCompoundTypedDataBaseField(
            VariableGet(valueVar),
            fileOffset,
          ),
          add(
            getCompoundOffsetInBytesField(
              VariableGet(valueVar),
              fileOffset,
            ),
            offsetInBytes,
          ),
        ]),
      ),
    );
    return newArgument;
  }
}

extension<T extends Object> on List<T> {
  /// Order-preserved distinct elements.
  List<T> distinct() {
    final seen = <T>{};
    return where((element) => seen.add(element)).toList();
  }
}
