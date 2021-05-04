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
    show
        FfiTransformerData,
        NativeType,
        FfiTransformer,
        nativeTypeSizes,
        WORD_SIZE,
        UNKNOWN,
        wordSize;

/// Checks and replaces calls to dart:ffi compound fields and methods.
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
      ffiTransformerData.emptyCompounds);
  libraries.forEach(transformer.visitLibrary);
}

/// Checks and replaces calls to dart:ffi compound fields and methods.
class _FfiUseSiteTransformer extends FfiTransformer {
  final Set<Class> emptyCompounds;
  StaticTypeContext _staticTypeContext;

  bool get isFfiLibrary => currentLibrary == ffiLibrary;

  // Used to create private top-level fields with unique names for each
  // callback.
  int callbackCount = 0;

  _FfiUseSiteTransformer(
      LibraryIndex index,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex referenceFromIndex,
      this.emptyCompounds)
      : super(index, coreTypes, hierarchy, diagnosticReporter,
            referenceFromIndex) {}

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
      if (node == allocationTearoff ||
          node == asFunctionTearoff ||
          node == lookupFunctionTearoff) {
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
  visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);

    final Member target = node.target;
    try {
      if (target == structPointerRef ||
          target == structPointerElemAt ||
          target == unionPointerRef ||
          target == unionPointerElemAt) {
        final DartType nativeType = node.arguments.types[0];

        _ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        return _replaceRef(node);
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
          Expression inlineSizeOf = _inlineSizeOf(nativeType);
          if (inlineSizeOf != null) {
            return inlineSizeOf;
          }
        }
      } else if (target == lookupFunctionMethod) {
        final DartType nativeType = InterfaceType(
            nativeFunctionClass, Nullability.legacy, [node.arguments.types[0]]);
        final DartType dartType = node.arguments.types[1];

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureNoEmptyCompounds(dartType, node);

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
        final DartType dartType = node.arguments.types[1];
        final DartType nativeType = InterfaceType(
            nativeFunctionClass, Nullability.legacy, [node.arguments.types[0]]);

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureNoEmptyCompounds(dartType, node);

        final DartType nativeSignature =
            (nativeType as InterfaceType).typeArguments[0];

        // Inline function body to make all type arguments instatiated.
        final replacement = StaticInvocation(
            asFunctionInternal,
            Arguments([node.arguments.positional[0]],
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
        final DartType dartType = func.getStaticType(_staticTypeContext);

        _ensureIsStaticFunction(func);

        _ensureNativeTypeValid(nativeType, node);
        _ensureNativeTypeToDartType(nativeType, dartType, node);
        _ensureNoEmptyCompounds(dartType, node);

        final funcType = dartType as FunctionType;

        // Check `exceptionalReturn`'s type.
        final Class expectedReturnClass =
            ((node.arguments.types[0] as FunctionType).returnType
                    as InterfaceType)
                .classNode;
        final NativeType expectedReturn = getType(expectedReturnClass);

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
        Expression sizeInBytes = _inlineSizeOf(nativeType);
        if (sizeInBytes != null) {
          if (node.arguments.positional.length == 2) {
            sizeInBytes = MethodInvocation(
                node.arguments.positional[1],
                numMultiplication.name,
                Arguments([sizeInBytes]),
                numMultiplication);
          }
          return MethodInvocation(
              node.arguments.positional[0],
              allocatorAllocateMethod.name,
              Arguments([sizeInBytes], types: node.arguments.types),
              allocatorAllocateMethod);
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

  Expression _inlineSizeOf(InterfaceType nativeType) {
    final Class nativeClass = nativeType.classNode;
    final NativeType nt = getType(nativeClass);
    if (nt == null) {
      // User-defined compounds.
      Field sizeOfField = nativeClass.fields.single;
      return StaticGet(sizeOfField);
    }
    final int size = nativeTypeSizes[nt.index];
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

  Expression _replaceRef(StaticInvocation node) {
    final dartType = node.arguments.types[0];
    final clazz = (dartType as InterfaceType).classNode;
    final constructor = clazz.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));
    Expression pointer = NullCheck(node.arguments.positional[0]);
    if (node.arguments.positional.length == 2) {
      pointer = MethodInvocation(
          pointer,
          offsetByMethod.name,
          Arguments([
            MethodInvocation(
                node.arguments.positional[1],
                numMultiplication.name,
                Arguments([_inlineSizeOf(dartType)]),
                numMultiplication)
          ]),
          offsetByMethod);
    }
    return ConstructorInvocation(constructor, Arguments([pointer]));
  }

  Expression _replaceRefArray(StaticInvocation node) {
    final dartType = node.arguments.types[0];
    final clazz = (dartType as InterfaceType).classNode;
    final constructor = clazz.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));

    final typedDataBasePrime = typedDataBaseOffset(
        PropertyGet(NullCheck(node.arguments.positional[0]),
            arrayTypedDataBaseField.name, arrayTypedDataBaseField),
        MethodInvocation(node.arguments.positional[1], numMultiplication.name,
            Arguments([StaticGet(clazz.fields.single)]), numMultiplication),
        StaticGet(clazz.fields.single),
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
        initializer: _inlineSizeOf(elementType),
        type: coreTypes.intNonNullableRawType)
      ..fileOffset = node.fileOffset;
    final elementSizeVar = VariableDeclaration("#elementSize",
        initializer: MethodInvocation(
            VariableGet(singleElementSizeVar),
            numMultiplication.name,
            Arguments([
              PropertyGet(
                  VariableGet(arrayVar),
                  arrayNestedDimensionsFlattened.name,
                  arrayNestedDimensionsFlattened)
            ]),
            numMultiplication),
        type: coreTypes.intNonNullableRawType)
      ..fileOffset = node.fileOffset;
    final offsetVar = VariableDeclaration("#offset",
        initializer: MethodInvocation(
            VariableGet(elementSizeVar),
            numMultiplication.name,
            Arguments([
              VariableGet(indexVar),
            ]),
            numMultiplication),
        type: coreTypes.intNonNullableRawType)
      ..fileOffset = node.fileOffset;

    final checkIndexAndLocalVars = Block([
      arrayVar,
      indexVar,
      ExpressionStatement(MethodInvocation(
          VariableGet(arrayVar),
          arrayCheckIndex.name,
          Arguments([VariableGet(indexVar)]),
          arrayCheckIndex)),
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
                    PropertyGet(VariableGet(arrayVar),
                        arrayTypedDataBaseField.name, arrayTypedDataBaseField),
                    VariableGet(offsetVar),
                    VariableGet(elementSizeVar),
                    dartType,
                    node.fileOffset),
                PropertyGet(
                    VariableGet(arrayVar),
                    arrayNestedDimensionsFirst.name,
                    arrayNestedDimensionsFirst),
                PropertyGet(VariableGet(arrayVar),
                    arrayNestedDimensionsRest.name, arrayNestedDimensionsRest)
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
              PropertyGet(VariableGet(arrayVar), arrayTypedDataBaseField.name,
                  arrayTypedDataBaseField)
                ..fileOffset = node.fileOffset,
              VariableGet(offsetVar),
              PropertyGet(node.arguments.positional[2],
                  arrayTypedDataBaseField.name, arrayTypedDataBaseField)
                ..fileOffset = node.fileOffset,
              ConstantExpression(IntConstant(0)),
              VariableGet(elementSizeVar),
            ]))
          ..fileOffset = node.fileOffset);
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

        _ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        Expression inlineSizeOf = _inlineSizeOf(nativeType);
        if (inlineSizeOf != null) {
          // Generates `receiver.offsetBy(inlineSizeOfExpression)`.
          return MethodInvocation(
              node.receiver,
              offsetByMethod.name,
              Arguments([
                MethodInvocation(
                    node.arguments.positional.single,
                    numMultiplication.name,
                    Arguments([inlineSizeOf]),
                    numMultiplication)
              ]),
              offsetByMethod);
        }
      }
    } on _FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
    }

    return node;
  }

  @override
  visitInstanceInvocation(InstanceInvocation node) {
    super.visitInstanceInvocation(node);

    final Member target = node.interfaceTarget;
    try {
      if (target == elementAtMethod) {
        final DartType pointerType =
            node.receiver.getStaticType(_staticTypeContext);
        final DartType nativeType = _pointerTypeGetTypeArg(pointerType);

        _ensureNativeTypeValid(nativeType, node, allowCompounds: true);

        Expression inlineSizeOf = _inlineSizeOf(nativeType);
        if (inlineSizeOf != null) {
          // Generates `receiver.offsetBy(inlineSizeOfExpression)`.
          return MethodInvocation(
              node.receiver,
              offsetByMethod.name,
              Arguments([
                MethodInvocation(
                    node.arguments.positional.single,
                    numMultiplication.name,
                    Arguments([inlineSizeOf]),
                    numMultiplication)
              ]),
              offsetByMethod);
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
        allowCompounds: true,
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
          node.location.file);
      throw _FfiStaticTypeError();
    }
  }

  void _ensureNoEmptyCompounds(DartType nativeType, Expression node) {
    // Error on structs with no fields.
    if (nativeType is InterfaceType) {
      final Class nativeClass = nativeType.classNode;
      if (hierarchy.isSubclassOf(nativeClass, compoundClass)) {
        if (emptyCompounds.contains(nativeClass)) {
          diagnosticReporter.report(
              templateFfiEmptyStruct.withArguments(
                  nativeClass.superclass.name, nativeClass.name),
              node.fileOffset,
              1,
              node.location.file);
        }
      }
    }

    // Recurse when seeing a function type.
    if (nativeType is FunctionType) {
      nativeType.positionalParameters
          .forEach((e) => _ensureNoEmptyCompounds(e, node));
      _ensureNoEmptyCompounds(nativeType.returnType, node);
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

  /// Returns the class that should not be implemented or extended.
  ///
  /// If the superclass is not sealed, returns `null`.
  Class _extendsOrImplementsSealedClass(Class klass) {
    // Classes in dart:ffi themselves can extend FFI classes.
    if (klass == arrayClass ||
        klass == arraySizeClass ||
        klass == compoundClass ||
        klass == opaqueClass ||
        klass == structClass ||
        klass == unionClass ||
        nativeTypesClasses.contains(klass)) {
      return null;
    }

    // The Opaque and Struct classes can be extended, but subclasses
    // cannot be (nor implemented).
    final onlyDirectExtendsClasses = [opaqueClass, structClass, unionClass];
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

    for (final parent in nativeTypesClasses) {
      if (hierarchy.isSubtypeOf(klass, parent)) {
        return parent;
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

extension<T extends Object> on List<T> {
  /// Order-preserved distinct elements.
  List<T> distinct() {
    final seen = <T>{};
    return where((element) => seen.add(element)).toList();
  }
}
