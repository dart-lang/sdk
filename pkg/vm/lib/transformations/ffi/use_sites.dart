// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageFfiExceptionalReturnNull,
        messageFfiExpectedConstant,
        messageFfiLeafCallMustNotReturnHandle,
        messageFfiLeafCallMustNotTakeHandle,
        templateFfiDartTypeMismatch,
        templateFfiExpectedConstantArg,
        templateFfiExpectedExceptionalReturn,
        templateFfiExpectedNoExceptionalReturn,
        templateFfiExtendsOrImplementsSealedClass,
        templateFfiNotStatic,
        templateFfiTypeInvalid,
        templateFfiTypeMismatch;

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
    show NativeType, FfiTransformer, nativeTypeSizes, WORD_SIZE, UNKNOWN;
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
    } on _FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
      return super.visitClass(node);
    }
  }

  @override
  visitProcedure(Procedure node) {
    assert(_inFfiTearoff == false);
    _inFfiTearoff = (isFfiLibrary &&
        node.isExtensionMember &&
        (node == allocationTearoff ||
            node == asFunctionTearoff ||
            node == lookupFunctionTearoff));
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
    // this node itself. Visit its sub exprssions.
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
        _ensureNativeTypeValid(pointerType, pointer,
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

        _ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        return _replaceGetRef(node);
      } else if (target == structPointerSetRef ||
          target == structPointerSetElemAt ||
          target == unionPointerSetRef ||
          target == unionPointerSetElemAt) {
        final DartType nativeType = node.arguments.types[0];

        _ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        return _replaceSetRef(node);
      } else if (target == structArrayElemAt || target == unionArrayElemAt) {
        final DartType nativeType = node.arguments.types[0];

        _ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        return _replaceRefArray(node);
      } else if (target == arrayArrayElemAt) {
        final DartType nativeType = node.arguments.types[0];

        _ensureNativeTypeValid(nativeType, node,
            allowInlineArray: true, allowCompounds: true);

        return _replaceArrayArrayElemAt(node);
      } else if (target == arrayArrayAssignAt) {
        final DartType nativeType = node.arguments.types[0];

        _ensureNativeTypeValid(nativeType, node,
            allowInlineArray: true, allowCompounds: true);

        return _replaceArrayArrayElemAt(node, setter: true);
      } else if (target == sizeOfMethod) {
        final DartType nativeType = node.arguments.types[0];

        _ensureNativeTypeValid(nativeType, node, allowCompounds: true);

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

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureIsLeafIsConst(node);
        _ensureLeafCallDoesNotUseHandles(nativeType, node);

        final replacement = _replaceLookupFunction(node);

        if (dartType is FunctionType) {
          final returnType = dartType.returnType;
          if (returnType is InterfaceType) {
            final clazz = returnType.classNode;
            if (clazz.superclass == structClass ||
                clazz.superclass == unionClass) {
              return _invokeCompoundConstructor(replacement, clazz);
            }
          }
        }
        return replacement;
      } else if (target == asFunctionMethod) {
        final dartType = node.arguments.types[1];
        final InterfaceType nativeType = InterfaceType(
            nativeFunctionClass, Nullability.legacy, [node.arguments.types[0]]);

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureIsLeafIsConst(node);
        _ensureLeafCallDoesNotUseHandles(nativeType, node);

        final DartType nativeSignature = nativeType.typeArguments[0];

        bool? isLeaf = _getIsLeafBoolean(node);
        if (isLeaf == null) {
          isLeaf = false;
        }

        // Inline function body to make all type arguments instatiated.
        final replacement = StaticInvocation(
            asFunctionInternal,
            Arguments([node.arguments.positional[0], BoolLiteral(isLeaf)],
                types: [dartType, nativeSignature]));

        if (dartType is FunctionType) {
          final returnType = dartType.returnType;
          if (returnType is InterfaceType) {
            final clazz = returnType.classNode;
            if (clazz.superclass == structClass ||
                clazz.superclass == unionClass) {
              return _invokeCompoundConstructor(replacement, clazz);
            }
          }
        }
        return replacement;
      } else if (target == fromFunctionMethod) {
        final DartType nativeType = InterfaceType(
            nativeFunctionClass, Nullability.legacy, [node.arguments.types[0]]);
        final Expression func = node.arguments.positional[0];
        final DartType dartType = func.getStaticType(staticTypeContext!);

        _ensureIsStaticFunction(func);

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);

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

        _ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        // Inline the body to get rid of a generic invocation of sizeOf.
        // TODO(http://dartbug.com/39964): Add `allignmentOf<T>()` call.
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
    } on _FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
    }

    return node;
  }

  /// Prevents the struct from being tree-shaken in TFA by invoking its
  /// constructor in a `_nativeEffect` expression.
  Expression _invokeCompoundConstructor(
      Expression nestedExpression, Class compoundClass) {
    final constructor = compoundClass.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));
    return BlockExpression(
        Block([
          ExpressionStatement(StaticInvocation(
              nativeEffectMethod,
              Arguments([
                ConstructorInvocation(
                    constructor,
                    Arguments([
                      StaticInvocation(
                          uint8ListFactory,
                          Arguments([
                            ConstantExpression(IntConstant(1)),
                          ]))
                        ..fileOffset = nestedExpression.fileOffset,
                    ]))
                  ..fileOffset = nestedExpression.fileOffset
              ])))
        ]),
        nestedExpression)
      ..fileOffset = nestedExpression.fileOffset;
  }

  Expression _invokeCompoundConstructors(
          Expression nestedExpression, List<Class> compoundClasses) =>
      compoundClasses
          .distinct()
          .fold(nestedExpression, _invokeCompoundConstructor);

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
          IntConstant(size),
          InterfaceType(listClass, Nullability.legacy,
              [InterfaceType(intClass, Nullability.legacy)]));
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

    bool? isLeaf = _getIsLeafBoolean(node);
    if (isLeaf == null) {
      isLeaf = false;
    }

    return StaticInvocation(
        asFunctionInternal,
        Arguments([lookupResult, BoolLiteral(isLeaf)],
            types: [dartSignature, nativeSignature]));
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

  /// Replaces a `.ref=` or `[]=` on a compound pointer extension with a memcopy
  /// call.
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
      {bool setter: false}) {
    final dartType = node.arguments.types[0];
    final elementType = arraySingleElementType(dartType as InterfaceType);

    final arrayVar = VariableDeclaration("#array",
        initializer: NullCheck(node.arguments.positional[0]),
        type: InterfaceType(arrayClass, Nullability.nonNullable))
      ..fileOffset = node.fileOffset;
    final indexVar = VariableDeclaration("#index",
        initializer: NullCheck(node.arguments.positional[1]),
        type: coreTypes.intNonNullableRawType)
      ..fileOffset = node.fileOffset;
    final singleElementSizeVar = VariableDeclaration("#singleElementSize",
        initializer: _inlineSizeOf(elementType as InterfaceType),
        type: coreTypes.intNonNullableRawType)
      ..fileOffset = node.fileOffset;
    final elementSizeVar = VariableDeclaration("#elementSize",
        initializer: multiply(
            VariableGet(singleElementSizeVar),
            InstanceGet(InstanceAccessKind.Instance, VariableGet(arrayVar),
                arrayNestedDimensionsFlattened.name,
                interfaceTarget: arrayNestedDimensionsFlattened,
                resultType: arrayNestedDimensionsFlattened.type)),
        type: coreTypes.intNonNullableRawType)
      ..fileOffset = node.fileOffset;
    final offsetVar = VariableDeclaration("#offset",
        initializer:
            multiply(VariableGet(elementSizeVar), VariableGet(indexVar)),
        type: coreTypes.intNonNullableRawType)
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
                    resultType: arrayNestedDimensionsFirst.type),
                InstanceGet(InstanceAccessKind.Instance, VariableGet(arrayVar),
                    arrayNestedDimensionsRest.name,
                    interfaceTarget: arrayNestedDimensionsRest,
                    resultType: arrayNestedDimensionsRest.type)
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

  @override
  visitInstanceInvocation(InstanceInvocation node) {
    final modifiedExpression = _visitInstanceInvocation(node);
    if (node == modifiedExpression) {
      return super.visitInstanceInvocation(node);
    }
    // We've just created this node. We're likely not going to need to transform
    // this node itself. Visit its sub exprssions.
    return super.defaultExpression(modifiedExpression);
  }

  /// Replaces nodes if they match. Does not invoke any super visit.
  Expression _visitInstanceInvocation(InstanceInvocation node) {
    if (_inFfiTearoff) {
      return node;
    }
    final Member target = node.interfaceTarget;
    try {
      if (target == elementAtMethod) {
        final DartType pointerType =
            node.receiver.getStaticType(staticTypeContext!);
        final DartType nativeType = _pointerTypeGetTypeArg(pointerType)!;

        _ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        Expression? inlineSizeOf = _inlineSizeOf(nativeType as InterfaceType);
        if (inlineSizeOf != null) {
          // Generates `receiver.offsetBy(inlineSizeOfExpression)`.
          return InstanceInvocation(
              InstanceAccessKind.Instance,
              node.receiver,
              offsetByMethod.name,
              Arguments(
                  [multiply(node.arguments.positional.single, inlineSizeOf)]),
              interfaceTarget: offsetByMethod,
              functionType:
                  Substitution.fromInterfaceType(pointerType as InterfaceType)
                          .substituteType(offsetByMethod.getterType)
                      as FunctionType);
        }
      }
    } on _FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
    }

    return node;
  }

  DartType? _pointerTypeGetTypeArg(DartType pointerType) {
    return pointerType is InterfaceType ? pointerType.typeArguments[0] : null;
  }

  void _ensureNativeTypeToDartType(
      DartType nativeType, DartType dartType, Expression node,
      {bool allowHandle: false}) {
    final DartType correspondingDartType = convertNativeTypeToDartType(
        nativeType,
        allowCompounds: true,
        allowHandle: allowHandle)!;
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
        node.location?.file);
    throw _FfiStaticTypeError();
  }

  void _ensureNativeTypeValid(DartType nativeType, Expression node,
      {bool allowHandle: false,
      bool allowCompounds: false,
      bool allowInlineArray = false}) {
    if (!_nativeTypeValid(nativeType,
        allowCompounds: allowCompounds,
        allowHandle: allowHandle,
        allowInlineArray: allowInlineArray)) {
      diagnosticReporter.report(
          templateFfiTypeInvalid.withArguments(
              nativeType, currentLibrary.isNonNullableByDefault),
          node.fileOffset,
          1,
          node.location?.file);
      throw _FfiStaticTypeError();
    }
  }

  /// The Dart type system does not enforce that NativeFunction return and
  /// parameter types are only NativeTypes, so we need to check this.
  bool _nativeTypeValid(DartType nativeType,
      {bool allowCompounds: false,
      bool allowHandle = false,
      bool allowInlineArray = false}) {
    return convertNativeTypeToDartType(nativeType,
            allowCompounds: allowCompounds,
            allowHandle: allowHandle,
            allowInlineArray: allowInlineArray) !=
        null;
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
    throw _FfiStaticTypeError();
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

    for (final parent in nativeTypesClasses.values) {
      if (hierarchy.isSubtypeOf(klass, parent)) {
        return parent;
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
      throw _FfiStaticTypeError();
    }
  }

  // Returns
  // - `true` if leaf
  // - `false` if not leaf
  // - `null` if the expression is not valid (e.g. non-const bool, null)
  bool? _getIsLeafBoolean(StaticInvocation node) {
    for (final named in node.arguments.named) {
      if (named.name == 'isLeaf') {
        final expr = named.value;
        if (expr is BoolLiteral) {
          return expr.value;
        } else if (expr is ConstantExpression) {
          final constant = expr.constant;
          if (constant is BoolConstant) {
            return constant.value;
          }
        }
        // isLeaf is passed some invalid value.
        return null;
      }
    }
    // isLeaf defaults to false.
    return false;
  }

  void _ensureIsLeafIsConst(StaticInvocation node) {
    final isLeaf = _getIsLeafBoolean(node);
    if (isLeaf == null) {
      diagnosticReporter.report(
          templateFfiExpectedConstantArg.withArguments('isLeaf'),
          node.fileOffset,
          1,
          node.location?.file);
      // Throw so we don't get another error about not replacing
      // `lookupFunction`, which will shadow the above error.
      throw _FfiStaticTypeError();
    }
  }

  void _ensureLeafCallDoesNotUseHandles(
      InterfaceType nativeType, StaticInvocation node) {
    // Handles are only disallowed for leaf calls.
    final isLeaf = _getIsLeafBoolean(node);
    if (isLeaf == null || isLeaf == false) {
      return;
    }

    // Check if return type is Handle.
    final functionType = nativeType.typeArguments[0];
    if (functionType is FunctionType) {
      final returnType = functionType.returnType;
      if (returnType is InterfaceType) {
        if (returnType.classNode == handleClass) {
          diagnosticReporter.report(messageFfiLeafCallMustNotReturnHandle,
              node.fileOffset, 1, node.location?.file);
        }
      }
      // Check if any of the argument types are Handle.
      for (DartType param in functionType.positionalParameters) {
        if ((param as InterfaceType).classNode == handleClass) {
          diagnosticReporter.report(messageFfiLeafCallMustNotTakeHandle,
              node.fileOffset, 1, node.location?.file);
        }
      }
    }
  }
}

/// Used internally for abnormal control flow to prevent cascading error
/// messages.
class _FfiStaticTypeError implements Exception {}

extension<T extends Object> on List<T> {
  /// Order-preserved distinct elements.
  List<T> distinct() {
    final seen = <T>{};
    return where((element) => seen.add(element)).toList();
  }
}
