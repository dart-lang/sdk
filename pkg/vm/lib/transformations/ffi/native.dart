// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageFfiNativeMustBeExternal,
        messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer,
        templateFfiNativeUnexpectedNumberOfParameters,
        templateFfiNativeUnexpectedNumberOfParametersWithReceiver;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_environment.dart';

import 'common.dart' show FfiTransformer;

/// Transform @FfiNative annotated functions into FFI native function pointer
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
  final Class ffiNativeClass;
  final Class nativeFunctionClass;
  final Field ffiNativeNameField;
  final Field ffiNativeIsLeafField;
  final Field resolverField;

  // VariableDeclaration names can be null or empty string, in which case
  // they're automatically assigned a "temporary" name like `#t0`.
  static const variableDeclarationTemporaryName = null;

  FfiNativeTransformer(
      LibraryIndex index,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      this.diagnosticReporter,
      this.referenceFromIndex)
      : ffiNativeClass = index.getClass('dart:ffi', 'FfiNative'),
        nativeFunctionClass = index.getClass('dart:ffi', 'NativeFunction'),
        ffiNativeNameField =
            index.getField('dart:ffi', 'FfiNative', 'nativeName'),
        ffiNativeIsLeafField =
            index.getField('dart:ffi', 'FfiNative', 'isLeaf'),
        resolverField = index.getTopLevelField('dart:ffi', '_ffi_resolver'),
        super(index, coreTypes, hierarchy, diagnosticReporter,
            referenceFromIndex);

  ConstantExpression? _tryGetFfiNativeAnnotation(Member node) {
    for (final Expression annotation in node.annotations) {
      if (annotation is! ConstantExpression) {
        continue;
      }
      final annotationConstant = annotation.constant;
      if (annotationConstant is! InstanceConstant) {
        continue;
      }
      if (annotationConstant.classNode == ffiNativeClass) {
        return annotation;
      }
    }
    return null;
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
        SubtypeCheckMode.ignoringNullabilities)) {
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
      bool isLeaf,
      FunctionType dartFunctionType,
      FunctionType ffiFunctionType,
      int fileOffset,
      Uri fileUri) {
    // Derive number of arguments from the native function signature.
    final numberNativeArgs = ffiFunctionType.positionalParameters.length;

    // _ffi_resolver('...', 'DoXYZ', 1)
    final resolverInvocation = FunctionInvocation(
        FunctionAccessKind.FunctionType,
        StaticGet(resolverField),
        Arguments(<Expression>[
          ConstantExpression(
              StringConstant(currentLibrary.importUri.toString())),
          ConstantExpression(nativeFunctionName),
          ConstantExpression(IntConstant(numberNativeArgs)),
        ]),
        functionType: resolverField.type as FunctionType)
      ..fileOffset = fileOffset;

    // _fromAddress<NativeFunction<Double Function(Double)>>(...)
    final fromAddressInvocation = StaticInvocation(
        fromAddressInternal,
        Arguments(<Expression>[
          resolverInvocation
        ], types: [
          InterfaceType(nativeFunctionClass, Nullability.legacy,
              <DartType>[ffiFunctionType])
        ]))
      ..fileOffset = fileOffset;

    // NativeFunctionPointer.asFunction
    //     <Double Function(Double), double Function(double)>(..., isLeaf:true)
    final asFunctionInvocation = StaticInvocation(
        asFunctionMethod,
        Arguments(<Expression>[
          fromAddressInvocation
        ], types: <DartType>[
          ffiFunctionType,
          dartFunctionType
        ], named: <NamedExpression>[
          NamedExpression('isLeaf', BoolLiteral(isLeaf))
        ]))
      ..fileOffset = fileOffset;

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
        initializer: initializer, type: wrappedType, isFinal: true);
  }

  Expression _getTemporary(VariableDeclaration temporary,
      DartType dartParameterType, DartType ffiParameterType) {
    if (_requiresPointerConversion(dartParameterType, ffiParameterType)) {
      // Pointer.fromAddress(_getNativeField(#t0))
      return StaticInvocation(
          fromAddressInternal,
          Arguments(<Expression>[
            StaticInvocation(getNativeFieldFunction,
                Arguments(<Expression>[VariableGet(temporary)]))
          ], types: <DartType>[
            voidType
          ]));
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
  Expression _wrapArgumentsAndReturn(FunctionInvocation invocation,
      FunctionType dartFunctionType, FunctionType ffiFunctionType) {
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
      callArguments
          .add(_getTemporary(temporary, dartParameters[i], ffiParameters[i]));
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
        isFinal: true);

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
      bool isLeaf,
      int annotationOffset,
      FunctionType dartFunctionType,
      FunctionType ffiFunctionType,
      List<Expression> argumentList) {
    if (!_verifySignatures(
        node, ffiFunctionType, dartFunctionType, annotationOffset)) {
      return node;
    }

    // int Function(Pointer<Void>)
    final wrappedDartFunctionType =
        _wrapFunctionType(dartFunctionType, ffiFunctionType);

    final parent = node.parent;

    var fileUri = currentLibrary.fileUri;
    if (parent is Class) {
      fileUri = parent.fileUri;
    } else if (parent is Library) {
      fileUri = parent.fileUri;
    }

    // static final _myMethod$FfiNative$Ptr = ..
    final resolvedField = _createResolvedFfiNativeField(
        node.name.text,
        nativeFunctionName,
        isLeaf,
        wrappedDartFunctionType,
        ffiFunctionType,
        node.fileOffset,
        fileUri);

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
            functionPointerInvocation, dartFunctionType, ffiFunctionType));

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

    return _transformProcedure(node, nativeFunctionName, isLeaf,
        annotationOffset, dartFunctionType, ffiFunctionType, argumentList);
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
      bool isLeaf,
      int annotationOffset) {
    final dartFunctionType =
        node.function.computeThisFunctionType(Nullability.nonNullable);

    final argumentList = <Expression>[
      for (final parameter in node.function.positionalParameters)
        VariableGet(parameter)
    ];

    return _transformProcedure(node, nativeFunctionName, isLeaf,
        annotationOffset, dartFunctionType, ffiFunctionType, argumentList);
  }

  @override
  visitProcedure(Procedure node) {
    // Only transform functions that are external and have FfiNative annotation:
    //   @FfiNative<Double Function(Double)>('Math_sqrt')
    //   external double _square_root(double x);
    final ffiNativeAnnotation = _tryGetFfiNativeAnnotation(node);
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
    final ffiFunctionType = ffiConstant.typeArguments[0] as FunctionType;
    final nativeFunctionName = ffiConstant
        .fieldValues[ffiNativeNameField.fieldReference] as StringConstant;
    final isLeaf = (ffiConstant.fieldValues[ffiNativeIsLeafField.fieldReference]
            as BoolConstant)
        .value;

    if (!node.isStatic) {
      return _transformInstanceMethod(node, ffiFunctionType, nativeFunctionName,
          isLeaf, ffiNativeAnnotation.fileOffset);
    }

    return _transformStaticFunction(node, ffiFunctionType, nativeFunctionName,
        isLeaf, ffiNativeAnnotation.fileOffset);
  }
}
