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
  // 2) the corresponding native parameter is Pointer.
  FunctionType _pointerizeFunctionType(
      FunctionType dartType, FunctionType nativeType) {
    final parameters = <DartType>[];
    for (var i = 0; i < dartType.positionalParameters.length; i++) {
      final parameter = dartType.positionalParameters[i];
      if (parameter is InterfaceType) {
        final nativeParameter = nativeType.positionalParameters[i];
        if (_extendsNativeFieldWrapperClass1(parameter) &&
            env.isSubtypeOf(nativeParameter, pointerVoidType,
                SubtypeCheckMode.ignoringNullabilities)) {
          parameters.add(pointerVoidType);
          continue;
        }
      }
      parameters.add(parameter);
    }
    return FunctionType(parameters, dartType.returnType, dartType.nullability);
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
      InstanceConstant annotationConst,
      String dartFunctionName,
      FunctionType dartType,
      FunctionType nativeType,
      TreeNode? parent,
      int fileOffset) {
    final nativeFunctionName = annotationConst
        .fieldValues[ffiNativeNameField.fieldReference] as StringConstant;
    final isLeaf = annotationConst
        .fieldValues[ffiNativeIsLeafField.fieldReference] as BoolConstant;

    // int Function(Pointer<Void>)
    final dartTypePointerized = _pointerizeFunctionType(dartType, nativeType);

    // Derive number of arguments from the native function signature.
    final numberNativeArgs = nativeType.positionalParameters.length;

    // _ffi_resolver('...', 'DoXYZ', 1)
    final resolverInvocation = FunctionInvocation(
        FunctionAccessKind.FunctionType,
        StaticGet(resolverField),
        Arguments([
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
        Arguments([
          resolverInvocation
        ], types: [
          InterfaceType(nativeFunctionClass, Nullability.legacy, [nativeType])
        ]))
      ..fileOffset = fileOffset;

    // NativeFunctionPointer.asFunction
    //     <Double Function(Double), double Function(double)>(..., isLeaf:true)
    final asFunctionInvocation = StaticInvocation(
        asFunctionMethod,
        Arguments([fromAddressInvocation],
            types: [nativeType, dartTypePointerized],
            named: [NamedExpression('isLeaf', BoolLiteral(isLeaf.value))]))
      ..fileOffset = fileOffset;

    var fileUri = currentLibrary.fileUri;
    if (parent is Class) {
      fileUri = parent.fileUri;
    } else if (parent is Library) {
      fileUri = parent.fileUri;
    }

    // static final _doXyz$FfiNative$Ptr = ...
    final fieldName =
        Name('_$dartFunctionName\$FfiNative\$Ptr', currentLibrary);
    final functionPointerField = Field.immutable(fieldName,
        type: dartTypePointerized,
        initializer: asFunctionInvocation,
        isStatic: true,
        isFinal: true,
        fileUri: fileUri,
        getterReference: currentLibraryIndex?.lookupGetterReference(fieldName))
      ..fileOffset = fileOffset;

    // Add field to the parent the FfiNative function belongs to.
    if (parent is Class) {
      parent.addField(functionPointerField);
    } else if (parent is Library) {
      parent.addField(functionPointerField);
    } else {
      throw 'Unexpected parent of @FfiNative function. '
          'Expected Class or Library, but found ${parent}.';
    }

    return functionPointerField;
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
  Expression _convertArgumentsNativeFieldWrapperClass1ToPointer(
      FunctionInvocation invocation,
      List<DartType> ffiParameters,
      List<VariableDeclaration> dartParameters) {
    // Create lists of temporary variables for arguments potentially being
    // wrapped, and the (potentially) wrapped arguments to be passed.
    final temporariesForArguments = [];
    final callArguments = <Expression>[];
    final fencedArguments = [];
    bool hasPointer = false;
    for (int i = 0; i < invocation.arguments.positional.length; i++) {
      if (env.isSubtypeOf(ffiParameters[i], pointerVoidType,
              SubtypeCheckMode.ignoringNullabilities) &&
          !env.isSubtypeOf(dartParameters[i].type, pointerVoidType,
              SubtypeCheckMode.ignoringNullabilities)) {
        // Only NativeFieldWrapperClass1 instances can be passed as pointer.
        if (!_extendsNativeFieldWrapperClass1(dartParameters[i].type)) {
          diagnosticReporter.report(
              messageFfiNativeOnlyNativeFieldWrapperClassCanBePointer,
              dartParameters[i].fileOffset,
              1,
              invocation.location?.file);
        }

        hasPointer = true;

        // final NativeFieldWrapperClass1 #t0 = ClassWithNativeField();
        final argument = VariableDeclaration(variableDeclarationTemporaryName,
            initializer: invocation.arguments.positional[i],
            type: nativeFieldWrapperClass1Type,
            isFinal: true);
        temporariesForArguments.add(argument);
        fencedArguments.add(argument);

        // Pointer.fromAddress(_getNativeField(#t0))
        final ptr = StaticInvocation(
            fromAddressInternal,
            Arguments([
              StaticInvocation(
                  getNativeFieldFunction, Arguments([VariableGet(argument)]))
            ], types: [
              voidType
            ]));
        callArguments.add(ptr);

        continue;
      }
      // Note: We also evaluate, and assign temporaries for, non-wrapped
      // arguments as we need to preserve the original evaluation order.
      final argument = VariableDeclaration(variableDeclarationTemporaryName,
          initializer: invocation.arguments.positional[i],
          type: dartParameters[i].type,
          isFinal: true);
      temporariesForArguments.add(argument);
      callArguments.add(VariableGet(argument));
    }

    // If there are no arguments to convert then we can drop the whole wrap.
    if (!hasPointer) {
      return invocation;
    }

    invocation.arguments = Arguments(callArguments);

    // {
    //   final NativeFieldWrapperClass1 #t0 = ClassWithNativeField();
    //   final T #t1 = foo(Pointer.fromAddress(_getNativeField(#t0)));
    //   reachabilityFence(#t0);
    // } => #t1
    final result = VariableDeclaration(variableDeclarationTemporaryName,
        initializer: invocation,
        type: invocation.functionType!.returnType,
        isFinal: true);
    return BlockExpression(
      Block([
        ...temporariesForArguments,
        result,
        for (final argument in fencedArguments)
          ExpressionStatement(StaticInvocation(
              reachabilityFenceFunction, Arguments([VariableGet(argument)])))
      ]),
      VariableGet(result),
    );
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
  Procedure _transformInstanceMethod(
      Procedure node, InstanceConstant ffiConstant, int annotationOffset) {
    final ffiSignature = ffiConstant.typeArguments[0] as FunctionType;

    // The FfiNative annotation should have an extra parameter for `self`.
    if (node.function.positionalParameters.length + 1 !=
        ffiSignature.positionalParameters.length) {
      diagnosticReporter.report(
          templateFfiNativeUnexpectedNumberOfParametersWithReceiver
              .withArguments(node.function.positionalParameters.length + 1,
                  ffiSignature.positionalParameters.length),
          annotationOffset,
          1,
          node.location?.file);
      return node;
    }

    final cls = node.parent as Class;

    final staticParameters = [
      // Add the implicit `self` for the inner glue functions.
      VariableDeclaration('self',
          type: cls.getThisType(coreTypes, Nullability.nonNullable)),
      for (final parameter in node.function.positionalParameters)
        VariableDeclaration(parameter.name, type: parameter.type)
    ];

    final staticFunctionType = FunctionType(
        staticParameters.map((e) => e.type).toList(),
        node.function.returnType,
        Nullability.nonNullable);

    // static final _myMethod$FfiNative$Ptr = ..
    final resolvedField = _createResolvedFfiNativeField(
        ffiConstant,
        node.name.text,
        staticFunctionType,
        ffiSignature,
        node.parent,
        node.fileOffset);

    //   _myMethod$FfiNative$Ptr(self, x)
    final functionPointerInvocation = FunctionInvocation(
        FunctionAccessKind.FunctionType,
        StaticGet(resolvedField),
        Arguments(
            [for (final parameter in staticParameters) VariableGet(parameter)]),
        functionType: staticFunctionType)
      ..fileOffset = node.fileOffset;

    //   static _myMethod$FfiNative(MyNativeClass self, int x)
    //     => _myMethod$FfiNative$Ptr(
    //       Pointer<Void>.fromAddress(_getNativeField(self)), x)
    final ffiProcedure = Procedure(
        Name('_${node.name.text}\$FfiNative', currentLibrary),
        ProcedureKind.Method,
        FunctionNode(
            ReturnStatement(_convertArgumentsNativeFieldWrapperClass1ToPointer(
                functionPointerInvocation,
                ffiSignature.positionalParameters,
                staticParameters)),
            positionalParameters: staticParameters),
        isStatic: true,
        fileUri: node.fileUri)
      ..fileOffset = node.fileOffset;
    cls.addProcedure(ffiProcedure);

    //   => _myMethod$FfiNative(this, x)
    node.function.body = ReturnStatement(StaticInvocation(
        ffiProcedure,
        Arguments([
          ThisExpression(),
          for (var parameter in node.function.positionalParameters)
            VariableGet(parameter)
        ])))
      ..parent = node.function;

    return node;
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
      Procedure node, InstanceConstant ffiConstant, int annotationOffset) {
    final ffiSignature = ffiConstant.typeArguments[0] as FunctionType;

    if (node.function.positionalParameters.length !=
        ffiSignature.positionalParameters.length) {
      diagnosticReporter.report(
          templateFfiNativeUnexpectedNumberOfParameters.withArguments(
              node.function.positionalParameters.length,
              ffiSignature.positionalParameters.length),
          annotationOffset,
          1,
          node.location?.file);
      return node;
    }

    // _myFunction$FfiNative$Ptr = ..
    final resolvedField = _createResolvedFfiNativeField(
        ffiConstant,
        node.name.text,
        node.function.computeThisFunctionType(Nullability.nonNullable),
        ffiSignature,
        node.parent,
        node.fileOffset);

    // _myFunction$FfiNative$Ptr(obj, x)
    final functionPointerInvocation = FunctionInvocation(
        FunctionAccessKind.FunctionType,
        StaticGet(resolvedField),
        Arguments([
          for (final parameter in node.function.positionalParameters)
            VariableGet(parameter)
        ]),
        functionType: resolvedField.type as FunctionType)
      ..fileOffset = node.fileOffset;

    //   => _myFunction$FfiNative$Ptr(
    //     Pointer<Void>.fromAddress(_getNativeField(obj)), x)
    node.function.body = ReturnStatement(
        _convertArgumentsNativeFieldWrapperClass1ToPointer(
            functionPointerInvocation,
            ffiSignature.positionalParameters,
            node.function.positionalParameters))
      ..parent = node.function;

    return node;
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

    if (!node.isStatic) {
      return _transformInstanceMethod(
          node,
          ffiNativeAnnotation.constant as InstanceConstant,
          ffiNativeAnnotation.fileOffset);
    }

    return _transformStaticFunction(
        node,
        ffiNativeAnnotation.constant as InstanceConstant,
        ffiNativeAnnotation.fileOffset);
  }
}
