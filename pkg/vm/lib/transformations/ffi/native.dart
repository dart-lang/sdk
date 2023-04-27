// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageFfiNativeMustBeExternal,
        messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer,
        templateCantHaveNamedParameters,
        templateCantHaveOptionalParameters,
        templateFfiNativeUnexpectedNumberOfParameters,
        templateFfiNativeUnexpectedNumberOfParametersWithReceiver;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_environment.dart';

import 'common.dart' show FfiStaticTypeError, FfiTransformer;

/// Transform @Native annotated functions into FFI native function pointer
/// functions.
void transformLibraries(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex? referenceFromIndex) {
  final index = LibraryIndex(component,
      ['dart:ffi', 'dart:_internal', 'dart:typed_data', 'dart:nativewrappers']);
  // Skip if dart:ffi isn't loaded (e.g. during incremental compile).
  if (index.tryGetClass('dart:ffi', 'FfiNative') == null) {
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
  final Class ffiNativeClass;
  final Class nativeClass;
  final Class nativeFunctionClass;
  final Field assetAssetField;
  final Field nativeSymbolField;
  final Field ffiNativeNameField;
  final Field nativeAssetField;
  final Field nativeIsLeafField;
  final Field ffiNativeIsLeafField;
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
        ffiNativeClass = index.getClass('dart:ffi', 'FfiNative'),
        nativeFunctionClass = index.getClass('dart:ffi', 'NativeFunction'),
        assetAssetField = index.getField('dart:ffi', 'DefaultAsset', 'id'),
        nativeSymbolField = index.getField('dart:ffi', 'Native', 'symbol'),
        ffiNativeNameField =
            index.getField('dart:ffi', 'FfiNative', 'nativeName'),
        nativeAssetField = index.getField('dart:ffi', 'Native', 'assetId'),
        nativeIsLeafField = index.getField('dart:ffi', 'Native', 'isLeaf'),
        ffiNativeIsLeafField =
            index.getField('dart:ffi', 'FfiNative', 'isLeaf'),
        resolverField = index.getTopLevelField('dart:ffi', '_ffi_resolver'),
        super(index, coreTypes, hierarchy, diagnosticReporter,
            referenceFromIndex);

  @override
  TreeNode visitLibrary(Library node) {
    assert(currentAsset == null);
    final annotation = tryGetAssetAnnotation(node);
    if (annotation != null) {
      currentAsset = (annotation.constant as InstanceConstant)
          .fieldValues[assetAssetField.fieldReference] as StringConstant;
    }
    final result = super.visitLibrary(node);
    currentAsset = null;
    return result;
  }

  ConstantExpression? tryGetAnnotation(
      Annotatable node, List<Class> instanceOf) {
    for (final Expression annotation in node.annotations) {
      if (annotation is! ConstantExpression) {
        continue;
      }
      final annotationConstant = annotation.constant;
      if (annotationConstant is! InstanceConstant) {
        continue;
      }
      if (instanceOf.contains(annotationConstant.classNode)) {
        return annotation;
      }
    }
    return null;
  }

  ConstantExpression? tryGetAssetAnnotation(Library node) =>
      tryGetAnnotation(node, [assetClass]);

  ConstantExpression? tryGetFfiNativeAnnotation(Member node) =>
      tryGetAnnotation(node, [ffiNativeClass]);

  ConstantExpression? tryGetNativeAnnotation(Member node) =>
      tryGetAnnotation(node, [nativeClass]);

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

  // Create field holding the resolved native function pointer.
  //
  // For:
  //   @FfiNative<IntPtr Function(Pointer<Void>)>('DoXYZ', isLeaf:true)
  //   external int doXyz(NativeFieldWrapperClass1 obj);
  //
  // Create:
  //   static final _doXyz$FfiNative$ptr =
  //       Pointer<NativeFunction<IntPtr Function(Pointer<Void>)>>
  //           .fromAddress(_ffi_resolver('..', 'DoXYZ', 1))
  //           .asFunction<int Function(Pointer<Void>)>(isLeaf:true);
  Field _createResolvedFfiNativeField(
    String dartFunctionName,
    StringConstant nativeFunctionName,
    StringConstant? assetName,
    bool isLeaf,
    FunctionType dartFunctionType,
    FunctionType ffiFunctionType,
    int fileOffset,
    Uri fileUri,
  ) {
    // Derive number of arguments from the native function signature.
    final numberNativeArgs = ffiFunctionType.positionalParameters.length;

    final nativeFunctionType = InterfaceType(
      nativeFunctionClass,
      Nullability.legacy,
      <DartType>[ffiFunctionType],
    );

    // _ffi_resolver('...', 'DoXYZ', 1)
    final resolverInvocation = FunctionInvocation(
        FunctionAccessKind.FunctionType,
        StaticGet(resolverField),
        Arguments(<Expression>[
          ConstantExpression(
              assetName ?? StringConstant(currentLibrary.importUri.toString())),
          ConstantExpression(nativeFunctionName),
          ConstantExpression(IntConstant(numberNativeArgs)),
        ]),
        functionType: resolverField.type as FunctionType)
      ..fileOffset = fileOffset;

    // _fromAddress<NativeFunction<Double Function(Double)>>(...)
    final functionPointerExpression = StaticInvocation(
        fromAddressInternal,
        Arguments(
          <Expression>[resolverInvocation],
          types: [nativeFunctionType],
        ))
      ..fileOffset = fileOffset;

    final asFunctionInvocation = buildAsFunctionInternal(
      functionPointer: functionPointerExpression,
      dartSignature: dartFunctionType,
      nativeSignature: ffiFunctionType,
      isLeaf: isLeaf,
      fileOffset: fileOffset,
    );

    // static final _doXyz$FfiNative$Ptr = ...
    final fieldName =
        Name('_$dartFunctionName\$FfiNative\$Ptr', currentLibrary);
    final functionPointerField = Field.immutable(fieldName,
        type: dartFunctionType,
        initializer: asFunctionInvocation,
        isStatic: true,
        isFinal: true,
        fileUri: fileUri,
        getterReference: currentLibraryIndex?.lookupGetterReference(fieldName))
      ..fileOffset = fileOffset;

    return functionPointerField;
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

  // FfiNative calls that pass objects extending NativeFieldWrapperClass1
  // should be passed as Pointer instead so we don't have the overhead of
  // converting Handles.
  // If we find a NativeFieldWrapperClass1 object being passed to an FfiNative
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
    required FunctionInvocation invocation,
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

  Procedure _transformProcedure(
    Procedure node,
    StringConstant nativeFunctionName,
    StringConstant? assetName,
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

    final parent = node.parent;

    // static final _myMethod$FfiNative$Ptr = ..
    final resolvedField = _createResolvedFfiNativeField(
      '${node.name.text}\$${node.kind.name}',
      nativeFunctionName,
      assetName,
      isLeaf,
      wrappedDartFunctionType,
      ffiFunctionType,
      node.fileOffset,
      node.fileUri,
    );

    // Add field to the parent the FfiNative function belongs to.
    if (parent is Class) {
      parent.addField(resolvedField);
    } else if (parent is Library) {
      parent.addField(resolvedField);
    } else {
      throw 'Unexpected parent of @FfiNative function. '
          'Expected Class or Library, but found ${parent}.';
    }

    // _myFunction$FfiNative$Ptr(obj, x)
    final functionPointerInvocation = FunctionInvocation(
        FunctionAccessKind.FunctionType,
        StaticGet(resolvedField),
        Arguments(argumentList),
        functionType: wrappedDartFunctionType)
      ..fileOffset = node.fileOffset;

    Expression result = (wrappedDartFunctionType == dartFunctionType
        ? functionPointerInvocation
        : _wrapArgumentsAndReturn(
            invocation: functionPointerInvocation,
            dartFunctionType: dartFunctionType,
            ffiFunctionType: ffiFunctionType,
            checkReceiverForNullptr: checkReceiverForNullptr,
          ));

    //   => _myFunction$FfiNative$Ptr(
    //     Pointer<Void>.fromAddress(_getNativeField(obj)), x)
    node.function.body = ReturnStatement(result)..parent = node.function;

    return node;
  }

  // Transform FfiNative instance methods.
  // Example:
  //   class MyNativeClass extends NativeFieldWrapperClass1 {
  //     @FfiNative<IntPtr Function(Pointer<Void>, IntPtr)>('MyClass_MyMethod')
  //     external int myMethod(int x);
  //   }
  // Becomes, roughly:
  //   ... {
  //     static final _myMethod$FfiNative$Ptr = ...
  //     static _myMethod$FfiNative(MyNativeClass self, int x)
  //       => _myMethod$FfiNative$Ptr(
  //         Pointer<Void>.fromAddress(_getNativeField(self)), x);
  //     int myMethod(int x) => _myMethod$FfiNative(this, x);
  //   }
  //
  //   ... {
  //     static final _myMethod$FfiNative$Ptr = ...
  //     int myMethod(int x)
  //       => _myMethod$FfiNative$Ptr(
  //         Pointer<Void>.fromAddress(_getNativeField(this)), x);
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

  // Transform FfiNative static functions.
  // Example:
  //   @FfiNative<IntPtr Function(Pointer<Void>, IntPtr)>('MyFunction')
  //   external int myFunction(MyNativeClass obj, int x);
  // Becomes, roughly:
  //   static final _myFunction$FfiNative$Ptr = ...
  //   int myFunction(MyNativeClass obj, int x)
  //     => myFunction$FfiNative$Ptr(
  //       Pointer<Void>.fromAddress(_getNativeField(obj)), x);
  Procedure _transformStaticFunction(
      Procedure node,
      FunctionType ffiFunctionType,
      StringConstant nativeFunctionName,
      StringConstant? assetName,
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
      assetName,
      isLeaf,
      annotationOffset,
      dartFunctionType,
      ffiFunctionType,
      argumentList,
      checkReceiverForNullptr: false,
    );
  }

  @override
  visitProcedure(Procedure node) {
    // Only transform functions that are external and have FfiNative annotation:
    //   @FfiNative<Double Function(Double)>('Math_sqrt')
    //   external double _square_root(double x);
    final ffiNativeAnnotation =
        tryGetNativeAnnotation(node) ?? tryGetFfiNativeAnnotation(node);
    if (ffiNativeAnnotation == null) {
      return node;
    }

    if (!node.isExternal) {
      diagnosticReporter.report(messageFfiNativeMustBeExternal, node.fileOffset,
          1, node.location?.file);
      return node;
    }
    node.isExternal = false;

    node.annotations.remove(ffiNativeAnnotation);

    final ffiConstant = ffiNativeAnnotation.constant as InstanceConstant;
    final nativeType = ffiConstant.typeArguments[0];
    try {
      final nativeFunctionType = InterfaceType(
          nativeFunctionClass, Nullability.nonNullable, [nativeType]);
      ensureNativeTypeValid(nativeFunctionType, ffiNativeAnnotation,
          allowCompounds: true, allowHandle: true);
    } on FfiStaticTypeError {
      // We've already reported an error.
      return node;
    }
    final ffiFunctionType = ffiConstant.typeArguments[0] as FunctionType;
    final nativeFunctionConst =
        (ffiConstant.fieldValues[nativeSymbolField.fieldReference] ??
            ffiConstant.fieldValues[ffiNativeNameField.fieldReference]);
    final nativeFunctionName = nativeFunctionConst is StringConstant
        ? nativeFunctionConst
        : StringConstant(node.name.text);
    final assetConstant =
        ffiConstant.fieldValues[nativeAssetField.fieldReference];
    final assetName =
        assetConstant is StringConstant ? assetConstant : currentAsset;
    final isLeaf = ((ffiConstant
                    .fieldValues[nativeIsLeafField.fieldReference] ??
                ffiConstant.fieldValues[ffiNativeIsLeafField.fieldReference])
            as BoolConstant)
        .value;

    if (!node.isStatic) {
      return _transformInstanceMethod(node, ffiFunctionType, nativeFunctionName,
          assetName, isLeaf, ffiNativeAnnotation.fileOffset);
    }

    return _transformStaticFunction(node, ffiFunctionType, nativeFunctionName,
        assetName, isLeaf, ffiNativeAnnotation.fileOffset);
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
        nativeFunctionClass, Nullability.legacy, [ffiFunctionType]);

    try {
      ensureNativeTypeValid(nativeType, node);
      ensureNativeTypeToDartType(nativeType, wrappedDartFunctionType, node,
          allowHandle: true);
      ensureLeafCallDoesNotUseHandles(nativeType, isLeaf, node);
    } on FfiStaticTypeError {
      // It's OK to swallow the exception because the diagnostics issued will
      // cause compilation to fail. By continuing, we can report more
      // diagnostics before compilation ends.
      return null;
    }

    return wrappedDartFunctionType;
  }
}
