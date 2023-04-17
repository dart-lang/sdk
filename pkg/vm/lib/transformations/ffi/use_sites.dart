// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageFfiCreateOfStructOrUnion,
        messageFfiExceptionalReturnNull,
        messageFfiExpectedConstant,
        templateFfiDartTypeMismatch,
        templateFfiExpectedConstantArg,
        templateFfiExpectedExceptionalReturn,
        templateFfiExpectedNoExceptionalReturn,
        templateFfiExtendsOrImplementsSealedClass,
        templateFfiNotStatic;

import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart';

import 'abi.dart' show wordSize;
import 'native_type_cfe.dart';
import 'common.dart'
    show
        FfiStaticTypeError,
        FfiTransformer,
        NativeType,
        nativeTypeSizes,
        UNKNOWN,
        WORD_SIZE;
import 'finalizable.dart';

/// Checks and replaces calls to dart:ffi compound fields and methods.
void transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex? referenceFromIndex) {
  final index = LibraryIndex(component,
      ["dart:ffi", "dart:_internal", "dart:typed_data", "dart:nativewrappers"]);
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

  @override
  TreeNode visitLibrary(Library node) {
    callbackCount = 0;
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
      if (target == abiSpecificIntegerPointerGetValue ||
          target == abiSpecificIntegerPointerSetValue ||
          target == abiSpecificIntegerPointerElemAt ||
          target == abiSpecificIntegerPointerSetElemAt ||
          target == abiSpecificIntegerArrayElemAt ||
          target == abiSpecificIntegerArraySetElemAt) {
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
          typedDataBase: (target == abiSpecificIntegerArrayElemAt ||
                  target == abiSpecificIntegerArraySetElemAt)
              ? getArrayTypedDataBaseField(node.arguments.positional[0])
              : node.arguments.positional[0],
          index: (target == abiSpecificIntegerPointerElemAt ||
                  target == abiSpecificIntegerPointerSetElemAt ||
                  target == abiSpecificIntegerArrayElemAt ||
                  target == abiSpecificIntegerArraySetElemAt)
              ? node.arguments.positional[1]
              : null,
          value: (target == abiSpecificIntegerPointerSetValue ||
                  target == abiSpecificIntegerPointerSetElemAt ||
                  target == abiSpecificIntegerArraySetElemAt)
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
          target == unionPointerElementAt) {
        final pointer = node.arguments.positional[0];
        final index = node.arguments.positional[1];
        final pointerType =
            pointer.getStaticType(staticTypeContext!) as InterfaceType;
        ensureNativeTypeValid(pointerType, pointer,
            allowCompounds: true, allowInlineArray: true);
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        Expression? inlineSizeOf = _inlineSizeOf(nativeType as InterfaceType);
        if (inlineSizeOf != null) {
          // Generates `receiver.offsetBy(inlineSizeOfExpression)`.
          return InstanceInvocation(InstanceAccessKind.Instance, pointer,
              offsetByMethod.name, Arguments([multiply(index, inlineSizeOf)]),
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
          Expression? inlineSizeOf = _inlineSizeOf(nativeType);
          if (inlineSizeOf != null) {
            return inlineSizeOf;
          }
        }
      } else if (target == lookupFunctionMethod) {
        final nativeType = InterfaceType(
            nativeFunctionClass, Nullability.legacy, [node.arguments.types[0]]);
        final DartType dartType = node.arguments.types[1];

        ensureNativeTypeValid(nativeType, node);
        ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureIsLeafIsConst(node);
        final isLeaf = getIsLeafBoolean(node) ?? false;
        ensureLeafCallDoesNotUseHandles(nativeType, isLeaf, node);

        return _replaceLookupFunction(node);
      } else if (target == asFunctionMethod) {
        final dartType = node.arguments.types[1];
        final InterfaceType nativeType = InterfaceType(nativeFunctionClass,
            Nullability.nonNullable, [node.arguments.types[0]]);

        ensureNativeTypeValid(nativeType, node);
        ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureIsLeafIsConst(node);

        final isLeaf = getIsLeafBoolean(node) ?? false;
        ensureLeafCallDoesNotUseHandles(nativeType, isLeaf, node);

        final DartType nativeSignature = nativeType.typeArguments[0];

        return buildAsFunctionInternal(
          functionPointer: node.arguments.positional[0],
          nativeSignature: nativeSignature,
          dartSignature: dartType,
          isLeaf: isLeaf,
          fileOffset: node.fileOffset,
        );
      } else if (target == fromFunctionMethod) {
        final DartType nativeType = InterfaceType(
            nativeFunctionClass, Nullability.legacy, [node.arguments.types[0]]);
        final Expression func = node.arguments.positional[0];
        final DartType dartType = func.getStaticType(staticTypeContext!);

        _ensureIsStaticFunction(func);

        ensureNativeTypeValid(nativeType, node);
        ensureNativeTypeToDartType(nativeType, dartType, node);

        final funcType = dartType as FunctionType;

        // Check `exceptionalReturn`'s type.
        final Class expectedReturnClass =
            ((node.arguments.types[0] as FunctionType).returnType
                    as InterfaceType)
                .classNode;
        final NativeType? expectedReturn = getType(expectedReturnClass);

        if (expectedReturn == NativeType.kVoid ||
            expectedReturn == NativeType.kPointer ||
            expectedReturn == NativeType.kHandle ||
            expectedReturnClass.superclass == structClass ||
            expectedReturnClass.superclass == unionClass) {
          if (node.arguments.positional.length > 1) {
            diagnosticReporter.report(
                templateFfiExpectedNoExceptionalReturn.withArguments(
                    funcType.returnType, currentLibrary.isNonNullableByDefault),
                node.fileOffset,
                1,
                node.location?.file);
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
                node.location?.file);
            return node;
          }

          final Expression exceptionalReturn = node.arguments.positional[1];

          // The exceptional return value must be a constant so that it be
          // referenced by precompiled trampoline's object pool.
          if (exceptionalReturn is! BasicLiteral &&
              !(exceptionalReturn is ConstantExpression &&
                  exceptionalReturn.constant is PrimitiveConstant)) {
            diagnosticReporter.report(messageFfiExpectedConstant,
                node.fileOffset, 1, node.location?.file);
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

        final replacement = _replaceFromFunction(node);

        final compoundClasses = funcType.positionalParameters
            .whereType<InterfaceType>()
            .map((t) => t.classNode)
            .where((c) =>
                c.superclass == structClass || c.superclass == unionClass)
            .toList();
        return _invokeCompoundConstructors(replacement, compoundClasses);
      } else if (target == allocateMethod) {
        final DartType nativeType = node.arguments.types[0];

        ensureNativeTypeValid(nativeType, node,
            allowCompounds: true, allowVoid: true);

        // Inline the body to get rid of a generic invocation of sizeOf.
        // TODO(http://dartbug.com/39964): Add `alignmentOf<T>()` call.
        Expression? sizeInBytes = _inlineSizeOf(nativeType as InterfaceType);
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
              functionType: Substitution.fromPairs(
                      allocateFunctionType.typeParameters, node.arguments.types)
                  .substituteType(allocateFunctionType
                      .withoutTypeParameters) as FunctionType);
        }
      }
    } on FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
    }

    return node;
  }

  Expression _invokeCompoundConstructors(
          Expression nestedExpression, List<Class> compoundClasses) =>
      compoundClasses
          .distinct()
          .fold(nestedExpression, invokeCompoundConstructor);

  Expression? _inlineSizeOf(InterfaceType nativeType) {
    final Class nativeClass = nativeType.classNode;
    final NativeType? nt = getType(nativeClass);
    if (nt == null) {
      // User-defined compounds.
      final Procedure sizeOfGetter = nativeClass.procedures
          .firstWhere((function) => function.name == Name('#sizeOf'));
      return StaticGet(sizeOfGetter);
    }
    final int size = nativeTypeSizes[nt]!;
    if (size == WORD_SIZE) {
      return runtimeBranchOnLayout(wordSize);
    }
    if (size != UNKNOWN) {
      return ConstantExpression(
          IntConstant(size), InterfaceType(intClass, Nullability.legacy));
    }
    // Size unknown.
    return null;
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
    // _asFunctionInternal<DS, NS>(lookup<NativeFunction<NS>>(symbolName),
    //     isLeaf)
    final DartType nativeSignature = node.arguments.types[0];
    final DartType dartSignature = node.arguments.types[1];

    final List<DartType> lookupTypeArgs = [
      InterfaceType(nativeFunctionClass, Nullability.legacy, [nativeSignature])
    ];
    final Arguments lookupArgs =
        Arguments([node.arguments.positional[1]], types: lookupTypeArgs);
    final FunctionType lookupFunctionType =
        libraryLookupMethod.getterType as FunctionType;

    final Expression lookupResult = InstanceInvocation(
        InstanceAccessKind.Instance,
        node.arguments.positional[0],
        libraryLookupMethod.name,
        lookupArgs,
        interfaceTarget: libraryLookupMethod,
        functionType: Substitution.fromPairs(
                    lookupFunctionType.typeParameters, lookupTypeArgs)
                .substituteType(lookupFunctionType.withoutTypeParameters)
            as FunctionType);

    final isLeaf = getIsLeafBoolean(node) ?? false;

    return buildAsFunctionInternal(
      functionPointer: lookupResult,
      nativeSignature: nativeSignature,
      dartSignature: dartSignature,
      isLeaf: isLeaf,
      fileOffset: node.fileOffset,
    );
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
    var getterReference = currentLibraryIndex?.lookupGetterReference(name);
    final Field field = Field.immutable(name,
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
        getterReference: getterReference)
      ..fileOffset = node.fileOffset;
    currentLibrary.addField(field);
    return StaticGet(field);
  }

  Expression _replaceGetRef(StaticInvocation node) {
    final dartType = node.arguments.types[0];
    final clazz = (dartType as InterfaceType).classNode;
    final constructor = clazz.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));
    Expression pointer = NullCheck(node.arguments.positional[0]);
    if (node.arguments.positional.length == 2) {
      pointer = InstanceInvocation(
          InstanceAccessKind.Instance,
          pointer,
          offsetByMethod.name,
          Arguments([
            multiply(node.arguments.positional[1], _inlineSizeOf(dartType)!)
          ]),
          interfaceTarget: offsetByMethod,
          functionType:
              Substitution.fromPairs(pointerClass.typeParameters, [dartType])
                  .substituteType(offsetByMethod.getterType) as FunctionType);
    }
    return ConstructorInvocation(constructor, Arguments([pointer]));
  }

  /// Replaces a `.ref=` or `[]=` on a compound pointer extension with a mem
  /// copy call.
  Expression _replaceSetRef(StaticInvocation node) {
    final target = node.arguments.positional[0]; // Receiver of extension

    final Expression source, targetOffset;

    if (node.arguments.positional.length == 3) {
      // []= call, args are (receiver, index, source)
      source = getCompoundTypedDataBaseField(
          node.arguments.positional[2], node.fileOffset);
      targetOffset = multiply(node.arguments.positional[1],
          _inlineSizeOf(node.arguments.types[0] as InterfaceType)!);
    } else {
      // .ref= call, args are (receiver, source)
      source = getCompoundTypedDataBaseField(
          node.arguments.positional[1], node.fileOffset);
      targetOffset = ConstantExpression(IntConstant(0));
    }

    return StaticInvocation(
      memCopy,
      Arguments([
        target,
        targetOffset,
        source,
        ConstantExpression(IntConstant(0)),
        _inlineSizeOf(node.arguments.types[0] as InterfaceType)!,
      ]),
    );
  }

  Expression _replaceRefArray(StaticInvocation node) {
    final dartType = node.arguments.types[0];
    final clazz = (dartType as InterfaceType).classNode;
    final constructor = clazz.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));

    final typedDataBasePrime = typedDataBaseOffset(
        getArrayTypedDataBaseField(NullCheck(node.arguments.positional[0])),
        multiply(node.arguments.positional[1], _inlineSizeOf(dartType)!),
        _inlineSizeOf(dartType)!,
        dartType,
        node.fileOffset);

    return ConstructorInvocation(constructor, Arguments([typedDataBasePrime]));
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
  /// int #singleElementSize = _inlineSizeOf<innermost(T)>();
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
  /// int #singleElementSize = _inlineSizeOf<innermost(T)>();
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
        initializer: _inlineSizeOf(elementType as InterfaceType),
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
          functionType: arrayCheckIndex.getterType as FunctionType)),
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

  void _ensureIsStaticFunction(Expression node) {
    if ((node is StaticGet && node.target is Procedure) ||
        (node is ConstantExpression &&
            node.constant is StaticTearOffConstant)) {
      return;
    }
    diagnosticReporter.report(
        templateFfiNotStatic.withArguments(fromFunctionMethod.name.text),
        node.fileOffset,
        1,
        node.location?.file);
    throw FfiStaticTypeError();
  }

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
      if (hierarchy.isSubtypeOf(klass, onlyDirectExtendsClass)) {
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
}

extension<T extends Object> on List<T> {
  /// Order-preserved distinct elements.
  List<T> distinct() {
    final seen = <T>{};
    return where((element) => seen.add(element)).toList();
  }
}
