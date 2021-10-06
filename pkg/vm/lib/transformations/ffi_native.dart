// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart'
    show IndexedLibrary, ReferenceFromIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:front_end/src/api_unstable/vm.dart'
    show messageFfiNativeAnnotationMustAnnotateStatic;

/// Transform @FfiNative annotated functions into FFI native function pointer
/// functions.
void transformLibraries(
    Component component,
    List<Library> libraries,
    DiagnosticReporter diagnosticReporter,
    ReferenceFromIndex? referenceFromIndex) {
  final index = LibraryIndex(component, ['dart:ffi']);
  // Skip if dart:ffi isn't loaded (e.g. during incremental compile).
  if (index.tryGetClass('dart:ffi', 'FfiNative') == null) {
    return;
  }
  final transformer =
      FfiNativeTransformer(index, diagnosticReporter, referenceFromIndex);
  libraries.forEach(transformer.visitLibrary);
}

class FfiNativeTransformer extends Transformer {
  Library? currentLibrary;
  IndexedLibrary? currentLibraryIndex;

  final DiagnosticReporter diagnosticReporter;
  final ReferenceFromIndex? referenceFromIndex;
  final Class ffiNativeClass;
  final Class nativeFunctionClass;
  final Field ffiNativeNameField;
  final Field ffiNativeIsLeafField;
  final Field resolverField;
  final Procedure asFunctionProcedure;
  final Procedure fromAddressInternal;

  FfiNativeTransformer(
      LibraryIndex index, this.diagnosticReporter, this.referenceFromIndex)
      : ffiNativeClass = index.getClass('dart:ffi', 'FfiNative'),
        nativeFunctionClass = index.getClass('dart:ffi', 'NativeFunction'),
        ffiNativeNameField =
            index.getField('dart:ffi', 'FfiNative', 'nativeName'),
        ffiNativeIsLeafField =
            index.getField('dart:ffi', 'FfiNative', 'isLeaf'),
        resolverField = index.getTopLevelField('dart:ffi', '_ffi_resolver'),
        asFunctionProcedure = index.getProcedure(
            'dart:ffi', 'NativeFunctionPointer', 'asFunction'),
        fromAddressInternal =
            index.getTopLevelProcedure('dart:ffi', '_fromAddress') {}

  @override
  TreeNode visitLibrary(Library node) {
    assert(currentLibrary == null);
    currentLibrary = node;
    currentLibraryIndex = referenceFromIndex?.lookupLibrary(node);
    final result = super.visitLibrary(node);
    currentLibrary = null;
    return result;
  }

  InstanceConstant? _tryGetFfiNativeAnnotation(Member node) {
    for (final Expression annotation in node.annotations) {
      if (annotation is ConstantExpression) {
        if (annotation.constant is InstanceConstant) {
          final instConst = annotation.constant as InstanceConstant;
          if (instConst.classNode == ffiNativeClass) {
            return instConst;
          }
        }
      }
    }
    return null;
  }

  // Transform:
  //   @FfiNative<Double Function(Double)>('Math_sqrt', isLeaf:true)
  //   external double _square_root(double x);
  //
  // Into:
  //   final _@FfiNative__square_root =
  //       Pointer<NativeFunction<Double Function(Double)>>
  //           .fromAddress(_ffi_resolver('dart:math', 'Math_sqrt'))
  //           .asFunction<double Function(double)>(isLeaf:true);
  //   double _square_root(double x) => _@FfiNative__square_root(x);
  Statement transformFfiNative(
      Procedure node, InstanceConstant annotationConst) {
    assert(currentLibrary != null);
    final params = node.function.positionalParameters;
    final functionName = annotationConst
        .fieldValues[ffiNativeNameField.fieldReference] as StringConstant;
    final isLeaf = annotationConst
        .fieldValues[ffiNativeIsLeafField.fieldReference] as BoolConstant;

    // double Function(double)
    final DartType dartType =
        node.function.computeThisFunctionType(Nullability.nonNullable);
    // Double Function(Double)
    final nativeType = annotationConst.typeArguments[0] as FunctionType;
    // InterfaceType(NativeFunction<Double Function(Double)>)
    final DartType nativeInterfaceType = InterfaceType(
        nativeFunctionClass, Nullability.nonNullable, [nativeType]);

    // Derive number of arguments from the native function signature.
    final args_n = nativeType.positionalParameters.length;

    // TODO(dartbug.com/31579): Add `..fileOffset`s once we can handle these in
    // patch files.

    // _ffi_resolver('dart:math', 'Math_sqrt', 1)
    final resolverInvocation = FunctionInvocation(
        FunctionAccessKind.FunctionType,
        StaticGet(resolverField),
        Arguments([
          ConstantExpression(
              StringConstant(currentLibrary!.importUri.toString())),
          ConstantExpression(functionName),
          ConstantExpression(IntConstant(args_n)),
        ]),
        functionType: resolverField.type as FunctionType);

    // _fromAddress<NativeFunction<Double Function(Double)>>(...)
    final fromAddressInvocation = StaticInvocation(fromAddressInternal,
        Arguments([resolverInvocation], types: [nativeInterfaceType]));

    // NativeFunctionPointer.asFunction
    //     <Double Function(Double), double Function(double)>(..., isLeaf:true)
    final asFunctionInvocation = StaticInvocation(
        asFunctionProcedure,
        Arguments([fromAddressInvocation],
            types: [nativeType, dartType],
            named: [NamedExpression("isLeaf", BoolLiteral(isLeaf.value))]));

    // final _@FfiNative__square_root = ...
    final fieldName = Name('_@FfiNative_${node.name.text}', currentLibrary);
    final funcPtrField = Field.immutable(fieldName,
        type: dartType,
        initializer: asFunctionInvocation,
        isStatic: true,
        isFinal: true,
        fileUri: currentLibrary!.fileUri,
        getterReference: currentLibraryIndex?.lookupGetterReference(fieldName))
      ..fileOffset = node.fileOffset;
    // Add field to the parent the FfiNative function belongs to.
    final parent = node.parent;
    if (parent is Class) {
      parent.addField(funcPtrField);
    } else if (parent is Library) {
      parent.addField(funcPtrField);
    } else {
      throw 'Unexpected parent of @FfiNative function. '
          'Expected Class or Library, but found ${parent}.';
    }

    // _@FfiNative__square_root(x)
    final callFuncPtrInvocation = FunctionInvocation(
        FunctionAccessKind.FunctionType,
        StaticGet(funcPtrField),
        Arguments(params.map<Expression>((p) => VariableGet(p)).toList()),
        functionType: dartType as FunctionType);

    return ReturnStatement(callFuncPtrInvocation);
  }

  @override
  visitProcedure(Procedure node) {
    // Only transform functions that are external and have FfiNative annotation:
    //   @FfiNative<Double Function(Double)>('Math_sqrt')
    //   external double _square_root(double x);
    if (!node.isExternal) {
      return node;
    }
    InstanceConstant? ffiNativeAnnotation = _tryGetFfiNativeAnnotation(node);
    if (ffiNativeAnnotation == null) {
      return node;
    }

    if (!node.isStatic) {
      diagnosticReporter.report(messageFfiNativeAnnotationMustAnnotateStatic,
          node.fileOffset, 1, node.location!.file);
    }

    node.isExternal = false;
    node.function.body = transformFfiNative(node, ffiNativeAnnotation)
      ..parent = node.function;

    return node;
  }
}
