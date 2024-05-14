// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/codes/fasta_codes.dart'
    show
        messageFfiDefaultAssetDuplicate,
        messageFfiNativeDuplicateAnnotations,
        messageFfiNativeFieldMissingType,
        messageFfiNativeFieldMustBeStatic,
        messageFfiNativeFieldType,
        messageFfiNativeMustBeExternal,
        messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer,
        templateCantHaveNamedParameters,
        templateCantHaveOptionalParameters,
        templateFfiNativeUnexpectedNumberOfParameters,
        templateFfiNativeUnexpectedNumberOfParametersWithReceiver,
        templateFfiTypeInvalid;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_environment.dart';

import 'common.dart'
    show FfiStaticTypeError, FfiTransformer, NativeType, FfiTypeCheckDirection;
import 'native_type_cfe.dart';

/// Transform @Native annotated functions into FFI native function pointer
/// functions.
void transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex? referenceFromIndex) {
  final index = LibraryIndex(component, [
    'dart:ffi',
    'dart:_internal',
    'dart:typed_data',
    'dart:nativewrappers',
    'dart:isolate'
  ]);
  // Skip if dart:ffi isn't loaded (e.g. during incremental compile).
  if (index.tryGetClass('dart:ffi', 'Native') == null) {
    return;
  }
  final transformer = FfiNativeTransformer(
      index, coreTypes, hierarchy, diagnosticReporter, referenceFromIndex);
  libraries.forEach(transformer.visitLibrary);
}

class FfiNativeTransformer extends FfiTransformer {
  final DiagnosticReporter diagnosticReporter;
  final ReferenceFromIndex? referenceFromIndex;
  final Class assetClass;
  final Class nativeClass;
  final Class nativeFunctionClass;
  final Field assetAssetField;
  final Field nativeSymbolField;
  final Field nativeAssetField;
  final Field resolverField;

  StringConstant? currentAsset;

  // VariableDeclaration names can be null or empty string, in which case
  // they're automatically assigned a "temporary" name like `#t0`.
  static const variableDeclarationTemporaryName = null;

  FfiNativeTransformer(
      LibraryIndex index,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      this.diagnosticReporter,
      this.referenceFromIndex)
      : assetClass = index.getClass('dart:ffi', 'DefaultAsset'),
        nativeClass = index.getClass('dart:ffi', 'Native'),
        nativeFunctionClass = index.getClass('dart:ffi', 'NativeFunction'),
        assetAssetField = index.getField('dart:ffi', 'DefaultAsset', 'id'),
        nativeSymbolField = index.getField('dart:ffi', 'Native', 'symbol'),
        nativeAssetField = index.getField('dart:ffi', 'Native', 'assetId'),
        resolverField = index.getField('dart:ffi', 'Native', '_ffi_resolver'),
        super(index, coreTypes, hierarchy, diagnosticReporter,
            referenceFromIndex);

  @override
  TreeNode visitLibrary(Library node) {
    assert(currentAsset == null);
    final annotation = tryGetAssetAnnotationOrWarnOnDuplicates(node);
    if (annotation != null) {
      currentAsset = (annotation.constant as InstanceConstant)
          .fieldValues[assetAssetField.fieldReference] as StringConstant;
    }
    final result = super.visitLibrary(node);
    currentAsset = null;
    return result;
  }

  List<ConstantExpression> tryGetAnnotation(
      Annotatable node, Class instanceOf) {
    final annotations = <ConstantExpression>[];

    for (final Expression annotation in node.annotations) {
      if (annotation is! ConstantExpression) {
        continue;
      }
      final annotationConstant = annotation.constant;
      if (annotationConstant is! InstanceConstant) {
        continue;
      }
      if (annotationConstant.classNode == instanceOf) {
        annotations.add(annotation);
      }
    }

    return annotations;
  }

  ConstantExpression? tryGetAssetAnnotationOrWarnOnDuplicates(Library node) {
    ConstantExpression? assetAnnotation;

    for (final annotation in tryGetAnnotation(node, assetClass)) {
      if (assetAnnotation != null) {
        // Duplicate @DefaultAsset annotations are forbidden.
        diagnosticReporter.report(messageFfiDefaultAssetDuplicate,
            annotation.fileOffset, 1, annotation.location?.file);
        return null;
      } else {
        assetAnnotation = annotation;
      }
    }

    return assetAnnotation;
  }

  ConstantExpression? tryGetNativeAnnotationOrWarnOnDuplicates(Member node) {
    ConstantExpression? nativeAnnotation;

    for (final annotation in tryGetAnnotation(node, nativeClass)) {
      if (nativeAnnotation != null) {
        // Duplicate @Native annotations are forbidden.
        diagnosticReporter.report(messageFfiNativeDuplicateAnnotations,
            node.fileOffset, 1, node.location?.file);
        return null;
      } else {
        nativeAnnotation = annotation;
      }
    }

    return nativeAnnotation;
  }

  bool _extendsNativeFieldWrapperClass1(DartType type) {
    if (type is InterfaceType) {
      Class? cls = type.classNode;
      while (cls != null) {
        if (cls == nativeFieldWrapperClass1Class) {
          return true;
        }
        cls = cls.superclass;
      }
    }
    return false;
  }

  StringConstant _resolveNativeSymbolName(
      Member member, InstanceConstant native) {
    final nativeFunctionConst =
        native.fieldValues[nativeSymbolField.fieldReference];
    return nativeFunctionConst is StringConstant
        ? nativeFunctionConst
        : StringConstant(member.name.text);
  }

  StringConstant? _assetNameFromAnnotation(InstanceConstant native) {
    final assetConstant = native.fieldValues[nativeAssetField.fieldReference];
    return assetConstant is StringConstant ? assetConstant : null;
  }

  bool _isLeaf(InstanceConstant native) {
    return (native.fieldValues[nativeIsLeafField.fieldReference]
            as BoolConstant)
        .value;
  }

  // Replaces parameters with Pointer if:
  // 1) they extend NativeFieldWrapperClass1, and
  // 2) the corresponding FFI parameter is Pointer.
  DartType _wrapArgumentType(
      DartType dartParameterType, DartType ffiParameterType) {
    if (dartParameterType is InterfaceType) {
      if (_extendsNativeFieldWrapperClass1(dartParameterType) &&
          env.isSubtypeOf(ffiParameterType, pointerVoidType,
              SubtypeCheckMode.ignoringNullabilities)) {
        return pointerVoidType;
      }
    }
    return dartParameterType;
  }

  // Replaces return type with Object if it is Handle.
  DartType _wrapReturnType(DartType dartReturnType, DartType ffiReturnType) {
    if (env.isSubtypeOf(
            ffiReturnType,
            handleClass.getThisType(coreTypes, Nullability.nonNullable),
            SubtypeCheckMode.ignoringNullabilities) &&
        dartReturnType is! VoidType) {
      return objectClass.getThisType(coreTypes, dartReturnType.nullability);
    }
    return dartReturnType;
  }

  // Compute synthetic FFI function type, accounting for Objects passed as
  // Pointer, and Objects returned as Handles.
  FunctionType _wrapFunctionType(
      FunctionType dartFunctionType, FunctionType ffiFunctionType) {
    return FunctionType(
      <DartType>[
        for (var i = 0; i < dartFunctionType.positionalParameters.length; i++)
          _wrapArgumentType(dartFunctionType.positionalParameters[i],
              ffiFunctionType.positionalParameters[i]),
      ],
      _wrapReturnType(dartFunctionType.returnType, ffiFunctionType.returnType),
      dartFunctionType.nullability,
    );
  }

  // Whether a parameter of [dartParameterType], passed as [ffiParameterType],
  // needs to be converted to Pointer.
  bool _requiresPointerConversion(
      DartType dartParameterType, DartType ffiParameterType) {
    return (env.isSubtypeOf(ffiParameterType, pointerVoidType,
            SubtypeCheckMode.ignoringNullabilities) &&
        !env.isSubtypeOf(dartParameterType, pointerVoidType,
            SubtypeCheckMode.ignoringNullabilities));
  }

  VariableDeclaration _declareTemporary(Expression initializer,
      DartType dartParameterType, DartType ffiParameterType) {
    final wrappedType =
        (_requiresPointerConversion(dartParameterType, ffiParameterType)
            ? nativeFieldWrapperClass1Type
            : dartParameterType);
    return VariableDeclaration(variableDeclarationTemporaryName,
        initializer: initializer,
        type: wrappedType,
        isFinal: true,
        isSynthesized: true);
  }

  Expression _getTemporary(
    VariableDeclaration temporary,
    DartType dartParameterType,
    DartType ffiParameterType, {
    required bool checkForNullptr,
  }) {
    if (_requiresPointerConversion(dartParameterType, ffiParameterType)) {
      Expression pointerAddress = StaticInvocation(getNativeFieldFunction,
          Arguments(<Expression>[VariableGet(temporary)]));

      if (checkForNullptr) {
        final pointerAddressVar = VariableDeclaration("#pointerAddress",
            initializer: pointerAddress,
            type: coreTypes.intNonNullableRawType,
            isSynthesized: true);
        pointerAddress = BlockExpression(
          Block([
            pointerAddressVar,
            IfStatement(
              InstanceInvocation(
                InstanceAccessKind.Instance,
                VariableGet(pointerAddressVar),
                objectEquals.name,
                Arguments([ConstantExpression(IntConstant(0))]),
                interfaceTarget: objectEquals,
                functionType: objectEquals.getterType as FunctionType,
              ),
              ExpressionStatement(StaticInvocation(
                stateErrorThrowNewFunction,
                Arguments([
                  ConstantExpression(StringConstant(
                    'A Dart object attempted to access a native peer, '
                    'but the native peer has been collected (nullptr). '
                    'This is usually the result of calling methods on a '
                    'native-backed object when the native resources have '
                    'already been disposed.',
                  ))
                ]),
              )),
              EmptyStatement(),
            )
          ]),
          VariableGet(pointerAddressVar),
        );
      }

      return StaticInvocation(fromAddressInternal,
          Arguments(<Expression>[pointerAddress], types: <DartType>[voidType]));
    }
    return VariableGet(temporary);
  }

  // Native calls that pass objects extending NativeFieldWrapperClass1
  // should be passed as Pointer instead so we don't have the overhead of
  // converting Handles.
  // If we find a NativeFieldWrapperClass1 object being passed to an Native
  // signature taking a Pointer, we automatically wrap the argument in a call to
  // `Pointer.fromAddress(_getNativeField(obj))`.
  //
  // Example:
  //   passAsPointer(ClassWithNativeField());
  //
  // Becomes, roughly:
  //   {
  //     final NativeFieldWrapperClass1#t0 = ClassWithNativeField();
  //     final #t1 = passAsPointer(Pointer.fromAddress(_getNativeField(#t0)));
  //     reachabilityFence(#t0);
  //   } => #t1
  Expression _wrapArgumentsAndReturn({
    required StaticInvocation invocation,
    required FunctionType dartFunctionType,
    required FunctionType ffiFunctionType,
    bool checkReceiverForNullptr = false,
  }) {
    List<DartType> ffiParameters = ffiFunctionType.positionalParameters;
    List<DartType> dartParameters = dartFunctionType.positionalParameters;
    // Create lists of temporary variables for arguments potentially being
    // wrapped, and the (potentially) wrapped arguments to be passed.
    final temporariesForArguments = [];
    final callArguments = <Expression>[];
    final fencedArguments = [];
    for (int i = 0; i < invocation.arguments.positional.length; i++) {
      final temporary = _declareTemporary(invocation.arguments.positional[i],
          dartParameters[i], ffiParameters[i]);
      // Note: We also evaluate, and assign temporaries for, non-wrapped
      // arguments as we need to preserve the original evaluation order.
      temporariesForArguments.add(temporary);
      callArguments.add(_getTemporary(
        temporary,
        dartParameters[i],
        ffiParameters[i],
        checkForNullptr: checkReceiverForNullptr && i == 0,
      ));
      if (_requiresPointerConversion(dartParameters[i], ffiParameters[i])) {
        fencedArguments.add(temporary);
        continue;
      }
    }

    Expression resultInitializer = invocation;
    if (env.isSubtypeOf(
        ffiFunctionType.returnType,
        handleClass.getThisType(coreTypes, Nullability.nonNullable),
        SubtypeCheckMode.ignoringNullabilities)) {
      resultInitializer = StaticInvocation(unsafeCastMethod,
          Arguments([invocation], types: [dartFunctionType.returnType]));
    }

    //   final T #t1 = foo(Pointer.fromAddress(_getNativeField(#t0)));
    final result = VariableDeclaration(variableDeclarationTemporaryName,
        initializer: resultInitializer,
        type: dartFunctionType.returnType,
        isFinal: true,
        isSynthesized: true);

    invocation.arguments = Arguments(callArguments);

    // {
    //   final NativeFieldWrapperClass1 #t0 = ClassWithNativeField();
    //   .. #t1 ..
    //   reachabilityFence(#t0);
    // } => #t1
    final resultBlock = BlockExpression(
      Block(<Statement>[
        ...temporariesForArguments,
        result,
        for (final argument in fencedArguments)
          ExpressionStatement(StaticInvocation(reachabilityFenceFunction,
              Arguments(<Expression>[VariableGet(argument)])))
      ]),
      VariableGet(result),
    );

    return resultBlock;
  }

  // Verify the Dart and FFI parameter types are compatible.
  bool _verifyParameter(DartType dartParameterType, DartType ffiParameterType,
      int annotationOffset, Uri? file) {
    // Only NativeFieldWrapperClass1 instances can be passed as pointer.
    if (_requiresPointerConversion(dartParameterType, ffiParameterType) &&
        !_extendsNativeFieldWrapperClass1(dartParameterType)) {
      diagnosticReporter.report(
          messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer,
          annotationOffset,
          1,
          file);
      return false;
    }
    return true;
  }

  // Verify the signatures of the Dart function and the accompanying FfiNative
  // annotation matches.
  bool _verifySignatures(Procedure node, FunctionType dartFunctionType,
      FunctionType ffiFunctionType, int annotationOffset) {
    if (ffiFunctionType.namedParameters.isNotEmpty) {
      diagnosticReporter.report(
          templateCantHaveNamedParameters.withArguments('FfiNative'),
          annotationOffset,
          0,
          node.location?.file);
      return false;
    }

    if (ffiFunctionType.positionalParameters.length >
        ffiFunctionType.requiredParameterCount) {
      diagnosticReporter.report(
          templateCantHaveOptionalParameters.withArguments('FfiNative'),
          annotationOffset,
          0,
          node.location?.file);
      return false;
    }

    if (dartFunctionType.positionalParameters.length !=
        ffiFunctionType.positionalParameters.length) {
      final template = (node.isStatic
          ? templateFfiNativeUnexpectedNumberOfParameters
          : templateFfiNativeUnexpectedNumberOfParametersWithReceiver);
      diagnosticReporter.report(
          template.withArguments(dartFunctionType.positionalParameters.length,
              ffiFunctionType.positionalParameters.length),
          annotationOffset,
          1,
          node.location?.file);
      return false;
    }

    var validSignature = true;
    for (var i = 0; i < dartFunctionType.positionalParameters.length; i++) {
      final dartParameterType = dartFunctionType.positionalParameters[i];
      if (dartParameterType is InterfaceType) {
        if (!_verifyParameter(
            dartParameterType,
            ffiFunctionType.positionalParameters[i],
            annotationOffset,
            node.location?.file)) {
          validSignature = false;
        }
      }
    }

    return validSignature;
  }

  static const _vmFfiNative = 'vm:ffi:native';

  /// A pragma annotation added to methods previously annotated with `@Native`
  /// during the transformation so that the use site transformer can find valid
  /// targets.
  static const nativeMarker = 'cfe:ffi:native-marker';

  Procedure _transformProcedure(
    Procedure node,
    StringConstant nativeFunctionName,
    StringConstant? overriddenAssetName,
    bool isLeaf,
    int annotationOffset,
    FunctionType dartFunctionType,
    FunctionType ffiFunctionType,
    List<Expression> argumentList, {
    required bool checkReceiverForNullptr,
  }) {
    final wrappedDartFunctionType = checkFfiType(
        node, dartFunctionType, ffiFunctionType, isLeaf, annotationOffset);

    if (wrappedDartFunctionType == null) {
      // It's OK to continue because the diagnostics issued will cause
      // compilation to fail. By continuing, we can report more diagnostics
      // before compilation ends.
      return node;
    }

    final resolvedNative = _generateResolvedNativeConstant(
      nativeType: ffiFunctionType,
      nativeName: nativeFunctionName,
      isLeaf: isLeaf,
      overriddenAssetName: overriddenAssetName,
    );
    final pragmaConstant = ConstantExpression(
      InstanceConstant(pragmaClass.reference, [], {
        pragmaName.fieldReference: StringConstant(_vmFfiNative),
        pragmaOptions.fieldReference: resolvedNative,
      }),
      InterfaceType(
        pragmaClass,
        Nullability.nonNullable,
        [],
      ),
    );

    // The marker annotation is always added to the original method so that the
    // use-sites transformer can find it when a tear-off is passed to e.g.
    // Native.addressOf.
    node.addAnnotation(ConstantExpression(
      InstanceConstant(pragmaClass.reference, [], {
        pragmaName.fieldReference: StringConstant(nativeMarker),
        pragmaOptions.fieldReference: resolvedNative,
      }),
      InterfaceType(
        pragmaClass,
        Nullability.nonNullable,
        [],
      ),
    ));

    final possibleCompoundReturn = findCompoundReturnType(dartFunctionType);
    if (dartFunctionType == wrappedDartFunctionType &&
        node.isStatic &&
        possibleCompoundReturn == null) {
      // We are not wrapping/unwrapping arguments or return value.
      node.addAnnotation(pragmaConstant);
      return node;
    }

    // Introduce a new function as external with the annotation and give the
    // current function a body that does the wrapping/unwrapping.
    node.isExternal = false;

    addPragmaPreferInline(node);

    final parent = node.parent;
    final fileUri = node.fileUri;

    final name = Name(
        '_${node.name.text}\$${node.kind.name}\$FfiNative', currentLibrary);
    final reference = currentLibraryIndex?.lookupGetterReference(name);

    int varCounter = 0;
    final nonWrappedFfiNative = Procedure(
      name,
      ProcedureKind.Method,
      FunctionNode(
        /*body=*/ null,
        requiredParameterCount: wrappedDartFunctionType.requiredParameterCount,
        positionalParameters: [
          for (final positionalParameter
              in wrappedDartFunctionType.positionalParameters)
            VariableDeclaration(
              /*name=*/ '#t${varCounter++}',
              type: positionalParameter,
            )..fileOffset = node.fileOffset,
        ],
        returnType: wrappedDartFunctionType.returnType,
      )..fileOffset = node.fileOffset,
      fileUri: fileUri,
      isStatic: true,
      isExternal: true,
      reference: reference,
    )
      ..isNonNullableByDefault = node.isNonNullableByDefault
      ..fileOffset = node.fileOffset;
    nonWrappedFfiNative.addAnnotation(pragmaConstant);

    // Add procedure to the parent the FfiNative function belongs to.
    if (parent is Class) {
      parent.addProcedure(nonWrappedFfiNative);
    } else if (parent is Library) {
      parent.addProcedure(nonWrappedFfiNative);
    } else {
      throw 'Unexpected parent of @Native function. '
          'Expected Class or Library, but found ${parent}.';
    }

    final nonWrappedInvocation = StaticInvocation(
      nonWrappedFfiNative,
      Arguments(argumentList),
    )..fileOffset = node.fileOffset;

    Expression result = (wrappedDartFunctionType == dartFunctionType
        ? nonWrappedInvocation
        : _wrapArgumentsAndReturn(
            invocation: nonWrappedInvocation,
            dartFunctionType: dartFunctionType,
            ffiFunctionType: ffiFunctionType,
            checkReceiverForNullptr: checkReceiverForNullptr,
          ));
    if (possibleCompoundReturn != null) {
      result = invokeCompoundConstructor(result, possibleCompoundReturn);
    }

    node.function.body = ReturnStatement(result)..parent = node.function;

    return node;
  }

  /// Creates a `Native` constant with all fields resolved.
  ///
  /// Re-using the constant from the original `@Native` annotation doesn't work
  /// because the asset field may be inferred from the library.
  InstanceConstant _generateResolvedNativeConstant({
    required DartType nativeType,
    required StringConstant nativeName,
    required bool isLeaf,
    StringConstant? overriddenAssetName,
  }) {
    return InstanceConstant(
      nativeClass.reference,
      [nativeType],
      {
        nativeSymbolField.fieldReference: nativeName,
        nativeAssetField.fieldReference: overriddenAssetName ??
            currentAsset ??
            StringConstant(currentLibrary.importUri.toString()),
        nativeIsLeafField.fieldReference: BoolConstant(isLeaf),
      },
    );
  }

  // Transform Native instance methods.
  //
  // Example:
  //
  //   class MyNativeClass extends NativeFieldWrapperClass1 {
  //     @Native<IntPtr Function(Pointer<Void>, IntPtr)>(symbol: 'MyClass_MyMethod')
  //     external int myMethod(int x);
  //   }
  //
  // Becomes, roughly:
  //
  //   ... {
  //     @pragma(
  //       'vm:ffi:native',
  //       Native<IntPtr Function(Pointer<Void>, IntPtr)>(
  //         symbol: 'MyClass_MyMethod',
  //         assetId: '<library uri>',
  //       ),
  //     )
  //     external int _myFunction$FfiNative(Pointer<Void> self, int x);
  //
  //     @pragma('vm:prefer-inline')
  //     int myMethod(int x) => _myMethod$FfiNative(_getNativeField(this), x);
  //   }
  Procedure _transformInstanceMethod(
      Procedure node,
      FunctionType ffiFunctionType,
      StringConstant nativeFunctionName,
      StringConstant? assetName,
      bool isLeaf,
      int annotationOffset) {
    final dartFunctionType = FunctionType([
      (node.parent as Class).getThisType(coreTypes, Nullability.nonNullable),
      for (final parameter in node.function.positionalParameters) parameter.type
    ], node.function.returnType, Nullability.nonNullable);

    final argumentList = <Expression>[
      ThisExpression(),
      for (final parameter in node.function.positionalParameters)
        VariableGet(parameter)
    ];

    return _transformProcedure(
      node,
      nativeFunctionName,
      assetName,
      isLeaf,
      annotationOffset,
      dartFunctionType,
      ffiFunctionType,
      argumentList,
      checkReceiverForNullptr: true,
    );
  }

  // Transform Native static functions.
  //
  // Example:
  //
  //   @Native<IntPtr Function(Pointer<Void>, IntPtr)>(symbol: 'MyFunction')
  //   external int myFunction(MyNativeClass obj, int x);
  //
  // Becomes, roughly:
  //
  //   @pragma(
  //     'vm:ffi:native',
  //     Native<IntPtr Function(Pointer<Void>, IntPtr)>(
  //       symbol: 'MyFunction',
  //       assetId: '<library uri>',
  //     ),
  //   )
  //   external int _myFunction$FfiNative(Pointer<Void> self, int x);
  //
  //   @pragma('vm:prefer-inline')
  //   int myFunction(MyNativeClass obj, int x)
  //     => _myFunction$FfiNative(
  //       Pointer<Void>.fromAddress(_getNativeField(obj)), x);
  Procedure _transformStaticFunction(
      Procedure node,
      FunctionType ffiFunctionType,
      StringConstant nativeFunctionName,
      StringConstant? overriddenAssetName,
      bool isLeaf,
      int annotationOffset) {
    final dartFunctionType =
        node.function.computeThisFunctionType(Nullability.nonNullable);

    final argumentList = <Expression>[
      for (final parameter in node.function.positionalParameters)
        VariableGet(parameter)
    ];

    return _transformProcedure(
      node,
      nativeFunctionName,
      overriddenAssetName,
      isLeaf,
      annotationOffset,
      dartFunctionType,
      ffiFunctionType,
      argumentList,
      checkReceiverForNullptr: false,
    );
  }

  Expression _generateAddressOfField(
      Member node, InterfaceType ffiType, InstanceConstant native) {
    return StaticInvocation(
      nativePrivateAddressOf,
      Arguments([ConstantExpression(native)], types: [ffiType]),
    )..fileOffset = node.fileOffset;
  }

  (DartType, NativeTypeCfe) _validateOrInferNativeFieldType(
      Member node, DartType ffiType, DartType dartType) {
    if (ffiType is DynamicType) {
      // If no type argument is given on the @Native annotation, try to infer
      // it.
      final inferred = convertDartTypeToNativeType(dartType);
      if (inferred != null) {
        ffiType = inferred;
      } else {
        diagnosticReporter.report(messageFfiNativeFieldMissingType,
            node.fileOffset, 1, node.location?.file);
        throw FfiStaticTypeError();
      }
    }

    ensureNativeTypeValid(
      ffiType,
      node,
      allowStructAndUnion: true,
      // Handles are not currently supported, but checking them separately and
      // allowing them here yields a more specific error message.
      allowHandle: true,
      allowInlineArray: true,
    );
    ensureNativeTypeMatch(
        FfiTypeCheckDirection.nativeToDart, ffiType, dartType, node,
        allowHandle: true, allowArray: true);

    // Array types must have an @Array annotation denoting its size.
    if (isArrayType(ffiType)) {
      final dimensions = ensureArraySizeAnnotation(node, ffiType);
      return (
        ffiType,
        NativeTypeCfe.withoutLayout(this, dartType, arrayDimensions: dimensions)
      );
    }

    // Apart from arrays, compound subtypes, pointers and numeric types are
    // supported for fields.
    if (!isStructOrUnionSubtype(ffiType) &&
        !isAbiSpecificIntegerSubtype(ffiType)) {
      final type = switch (ffiType) {
        InterfaceType(:var classNode) => getType(classNode),
        _ => null,
      };
      if (type == null ||
          type == NativeType.kNativeFunction ||
          type == NativeType.kHandle ||
          isArrayType(ffiType)) {
        diagnosticReporter.report(
            messageFfiNativeFieldType, node.fileOffset, 1, node.location?.file);
        throw FfiStaticTypeError();
      }
    }

    return (ffiType, NativeTypeCfe.withoutLayout(this, ffiType));
  }

  @override
  TreeNode visitField(Field node) {
    final nativeAnnotation = tryGetNativeAnnotationOrWarnOnDuplicates(node);
    if (nativeAnnotation == null) {
      return node;
    }
    // @Native annotations on fields are valid if the field is external. But
    // external fields are represented as a getter/setter pair in Kernel, so
    // only visit fields to verify that no native annotation is present.
    assert(!node.isExternal);
    diagnosticReporter.report(messageFfiNativeMustBeExternal, node.fileOffset,
        1, node.location?.file);
    return node;
  }

  @override
  visitProcedure(Procedure node) {
    // Only transform functions that are external and have Native annotation:
    //   @Native<Double Function(Double)>(symbol: 'Math_sqrt')
    //   external double _square_root(double x);
    final ffiNativeAnnotation = tryGetNativeAnnotationOrWarnOnDuplicates(node);
    if (ffiNativeAnnotation == null) {
      return node;
    }

    if (!node.isExternal) {
      diagnosticReporter.report(messageFfiNativeMustBeExternal, node.fileOffset,
          1, node.location?.file);
      return node;
    }

    node.annotations.remove(ffiNativeAnnotation);

    final ffiConstant = ffiNativeAnnotation.constant as InstanceConstant;
    var nativeType = ffiConstant.typeArguments[0];

    final nativeName = _resolveNativeSymbolName(node, ffiConstant);
    final overriddenAssetName = _assetNameFromAnnotation(ffiConstant);
    final isLeaf = _isLeaf(ffiConstant);

    if (nativeType is FunctionType) {
      try {
        final nativeFunctionType = InterfaceType(
            nativeFunctionClass, Nullability.nonNullable, [nativeType]);
        ensureNativeTypeValid(nativeFunctionType, ffiNativeAnnotation,
            allowStructAndUnion: true, allowHandle: true);
      } on FfiStaticTypeError {
        // We've already reported an error.
        return node;
      }
      final ffiFunctionType = ffiConstant.typeArguments[0] as FunctionType;

      if (!node.isStatic) {
        return _transformInstanceMethod(node, ffiFunctionType, nativeName,
            overriddenAssetName, isLeaf, ffiNativeAnnotation.fileOffset);
      }

      return _transformStaticFunction(node, ffiFunctionType, nativeName,
          overriddenAssetName, isLeaf, ffiNativeAnnotation.fileOffset);
    } else if (node.kind == ProcedureKind.Getter ||
        node.kind == ProcedureKind.Setter) {
      if (!node.isStatic) {
        diagnosticReporter.report(messageFfiNativeFieldMustBeStatic,
            node.fileOffset, 1, node.location?.file);
      }

      DartType dartType;
      NativeTypeCfe nativeTypeCfe;
      try {
        dartType = node.kind == ProcedureKind.Getter
            ? node.function.returnType
            : node.function.positionalParameters[0].type;
        (nativeType, nativeTypeCfe) =
            _validateOrInferNativeFieldType(node, nativeType, dartType);
      } on FfiStaticTypeError {
        return node;
      }
      final resolved = _generateResolvedNativeConstant(
        nativeType: nativeType,
        nativeName: nativeName,
        isLeaf: isLeaf,
        overriddenAssetName: overriddenAssetName,
      );
      node.isExternal = false;

      final zeroOffset = ConstantExpression(IntConstant(0));

      if (node.kind == ProcedureKind.Getter) {
        node.function.body = ReturnStatement(nativeTypeCfe.generateLoad(
          dartType: dartType,
          fileOffset: node.fileOffset,
          typedDataBase: _generateAddressOfField(
              node, nativeType as InterfaceType, resolved),
          transformer: this,
          offsetInBytes: zeroOffset,
        ));
        node.annotations.add(ConstantExpression(
          InstanceConstant(pragmaClass.reference, [], {
            pragmaName.fieldReference: StringConstant(nativeMarker),
            pragmaOptions.fieldReference: resolved,
          }),
          InterfaceType(
            pragmaClass,
            Nullability.nonNullable,
            [],
          ),
        ));
      } else {
        node.function.body = ExpressionStatement(nativeTypeCfe.generateStore(
          node.function.positionalParameters[0],
          dartType: dartType,
          fileOffset: node.fileOffset,
          typedDataBase: _generateAddressOfField(
              node, nativeType as InterfaceType, resolved),
          transformer: this,
          offsetInBytes: zeroOffset,
        ));
      }
    } else {
      // This function is not annotated with a native function type, which is
      // invalid.
      diagnosticReporter.report(
          templateFfiTypeInvalid.withArguments(nativeType),
          node.fileOffset,
          1,
          node.location?.file);
    }

    return node;
  }

  /// Checks whether the FFI function type is valid and reports any errors.
  /// Returns the Dart function type for the FFI function if the type is valid.
  ///
  /// For example, for FFI function type `Int8 Function(Double)`, this returns
  /// `int Function(double)`.
  FunctionType? checkFfiType(
      Procedure node,
      FunctionType dartFunctionType,
      FunctionType ffiFunctionTypeWithPossibleVarArgs,
      bool isLeaf,
      int annotationOffset) {
    final ffiFunctionType = flattenVarargs(ffiFunctionTypeWithPossibleVarArgs);
    if (!_verifySignatures(
        node, dartFunctionType, ffiFunctionType, annotationOffset)) {
      return null;
    }

    // int Function(Pointer<Void>)
    final wrappedDartFunctionType =
        _wrapFunctionType(dartFunctionType, ffiFunctionType);

    final nativeType = InterfaceType(
        nativeFunctionClass, Nullability.nonNullable, [ffiFunctionType]);

    try {
      ensureNativeTypeValid(nativeType, node);
      ensureNativeTypeMatch(
        FfiTypeCheckDirection.nativeToDart,
        nativeType,
        wrappedDartFunctionType,
        node,
        allowHandle: true, // Handle-specific errors emitted below.
      );
      ensureLeafCallDoesNotUseHandles(
        nativeType,
        isLeaf,
        reportErrorOn: node,
      );
    } on FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
      return null;
    }

    return wrappedDartFunctionType;
  }
}
