// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/error/ffi_code.dart';

/// A visitor used to find problems with the way the `dart:ffi` APIs are being
/// used. See 'pkg/vm/lib/transformations/ffi_checks.md' for the specification
/// of the desired hints.
class FfiVerifier extends RecursiveAstVisitor<void> {
  static const _allocatorClassName = 'Allocator';
  static const _allocateExtensionMethodName = 'call';
  static const _allocatorExtensionName = 'AllocatorAlloc';
  static const _arrayClassName = 'Array';
  static const _dartFfiLibraryName = 'dart.ffi';
  static const _opaqueClassName = 'Opaque';

  static const List<String> _primitiveIntegerNativeTypes = [
    'Int8',
    'Int16',
    'Int32',
    'Int64',
    'Uint8',
    'Uint16',
    'Uint32',
    'Uint64',
    'IntPtr'
  ];

  static const List<String> _primitiveDoubleNativeTypes = [
    'Float',
    'Double',
  ];

  static const _structClassName = 'Struct';

  static const _unionClassName = 'Union';

  /// The type system used to check types.
  final TypeSystemImpl typeSystem;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// A flag indicating whether we are currently visiting inside a subclass of
  /// `Struct`.
  bool inCompound = false;

  /// Subclass of `Struct` or `Union` we are currently visiting, or `null`.
  ClassDeclaration? compound;

  /// Initialize a newly created verifier.
  FfiVerifier(this.typeSystem, this._errorReporter);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    inCompound = false;
    compound = null;
    // Only the Allocator, Opaque and Struct class may be extended.
    var extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final TypeName superclass = extendsClause.superclass;
      final ffiClass = superclass.ffiClass;
      if (ffiClass != null) {
        final className = ffiClass.name;
        if (className == _structClassName || className == _unionClassName) {
          inCompound = true;
          compound = node;
          if (node.declaredElement!.isEmptyStruct) {
            _errorReporter
                .reportErrorForNode(FfiCode.EMPTY_STRUCT, node, [node.name]);
          }
          if (className == _structClassName) {
            _validatePackedAnnotation(node.metadata);
          }
        } else if (className != _allocatorClassName &&
            className != _opaqueClassName) {
          _errorReporter.reportErrorForNode(
              FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS,
              superclass.name,
              [node.name.name, superclass.name.name]);
        }
      } else if (superclass.isCompoundSubtype) {
        _errorReporter.reportErrorForNode(
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS,
            superclass,
            [node.name.name, superclass.name.name]);
      }
    }

    // No classes from the FFI may be explicitly implemented.
    void checkSupertype(TypeName typename, FfiCode subtypeOfFfiCode,
        FfiCode subtypeOfStructCode) {
      final superName = typename.name.staticElement?.name;
      if (superName == _allocatorClassName) {
        return;
      }
      if (typename.ffiClass != null) {
        _errorReporter.reportErrorForNode(
            subtypeOfFfiCode, typename, [node.name, typename.name]);
      } else if (typename.isCompoundSubtype) {
        _errorReporter.reportErrorForNode(
            subtypeOfStructCode, typename, [node.name, typename.name]);
      }
    }

    var implementsClause = node.implementsClause;
    if (implementsClause != null) {
      for (TypeName type in implementsClause.interfaces) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS,
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS);
      }
    }
    var withClause = node.withClause;
    if (withClause != null) {
      for (TypeName type in withClause.mixinTypes) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH,
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH);
      }
    }

    if (inCompound && node.declaredElement!.typeParameters.isNotEmpty) {
      _errorReporter.reportErrorForNode(
          FfiCode.GENERIC_STRUCT_SUBCLASS, node.name, [node.name]);
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (inCompound) {
      _errorReporter.reportErrorForNode(
          FfiCode.FIELD_INITIALIZER_IN_STRUCT, node);
    }
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (inCompound) {
      _validateFieldsInCompound(node);
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var element = node.staticElement;
    if (element is MethodElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isAllocatorExtension &&
          element.name == _allocateExtensionMethodName) {
        _validateAllocate(node);
      }
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    var element = node.staticElement;
    if (element is MethodElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeStructArrayExtension) {
        if (element.name == '[]') {
          _validateRefIndexed(node);
        }
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var element = node.methodName.staticElement;
    if (element is MethodElement) {
      Element enclosingElement = element.enclosingElement;
      if (enclosingElement.isPointer) {
        if (element.name == 'fromFunction') {
          _validateFromFunction(node, element);
        } else if (element.name == 'elementAt') {
          _validateElementAt(node);
        }
      } else if (enclosingElement.isNativeFunctionPointerExtension) {
        if (element.name == 'asFunction') {
          _validateAsFunction(node, element);
        }
      } else if (enclosingElement.isDynamicLibraryExtension) {
        if (element.name == 'lookupFunction') {
          _validateLookupFunction(node);
        }
      }
    } else if (element is FunctionElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is CompilationUnitElement) {
        if (element.library.name == 'dart.ffi') {
          if (element.name == 'sizeOf') {
            _validateSizeOf(node);
          }
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    var element = node.staticElement;
    if (element != null) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isNativeStructPointerExtension) {
        if (element.name == 'ref') {
          _validateRefPrefixedIdentifier(node);
        }
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var element = node.propertyName.staticElement;
    if (element != null) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isNativeStructPointerExtension) {
        if (element.name == 'ref') {
          _validateRefPropertyAccess(node);
        }
      }
    }
    super.visitPropertyAccess(node);
  }

  /// Returns `true` if [nativeType] is a C type that has a size.
  bool _isSized(DartType nativeType) {
    switch (_primitiveNativeType(nativeType)) {
      case _PrimitiveDartType.double:
        return true;
      case _PrimitiveDartType.int:
        return true;
      case _PrimitiveDartType.void_:
        return false;
      case _PrimitiveDartType.handle:
        return false;
      case _PrimitiveDartType.none:
        break;
    }
    if (nativeType.isCompoundSubtype) {
      return true;
    }
    if (nativeType.isPointer) {
      return true;
    }
    if (nativeType.isArray) {
      return true;
    }
    return false;
  }

  /// Validates that the given type is a valid dart:ffi native function
  /// signature.
  bool _isValidFfiNativeFunctionType(DartType nativeType) {
    if (nativeType is FunctionType && !nativeType.isDartCoreFunction) {
      if (nativeType.namedParameterTypes.isNotEmpty ||
          nativeType.optionalParameterTypes.isNotEmpty) {
        return false;
      }
      if (!_isValidFfiNativeType(nativeType.returnType,
          allowVoid: true, allowEmptyStruct: false, allowHandle: true)) {
        return false;
      }

      for (final DartType typeArg in nativeType.normalParameterTypes) {
        if (!_isValidFfiNativeType(typeArg,
            allowVoid: false, allowEmptyStruct: false, allowHandle: true)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// Validates that the given [nativeType] is a valid dart:ffi native type.
  bool _isValidFfiNativeType(DartType? nativeType,
      {bool allowVoid = false,
      bool allowEmptyStruct = false,
      bool allowArray = false,
      bool allowHandle = false}) {
    if (nativeType is InterfaceType) {
      final primitiveType = _primitiveNativeType(nativeType);
      switch (primitiveType) {
        case _PrimitiveDartType.void_:
          return allowVoid;
        case _PrimitiveDartType.handle:
          return allowHandle;
        case _PrimitiveDartType.double:
        case _PrimitiveDartType.int:
          return true;
        case _PrimitiveDartType.none:
          // These are the cases below.
          break;
      }
      if (nativeType.isNativeFunction) {
        return _isValidFfiNativeFunctionType(nativeType.typeArguments.single);
      }
      if (nativeType.isPointer) {
        final nativeArgumentType = nativeType.typeArguments.single;
        return _isValidFfiNativeType(nativeArgumentType,
                allowVoid: true, allowEmptyStruct: true, allowHandle: true) ||
            nativeArgumentType.isCompoundSubtype ||
            nativeArgumentType.isNativeType;
      }
      if (nativeType.isCompoundSubtype) {
        if (!allowEmptyStruct) {
          if (nativeType.element.isEmptyStruct) {
            // TODO(dartbug.com/36780): This results in an error message not
            // mentioning empty structs at all.
            return false;
          }
        }
        return true;
      }
      if (nativeType.isOpaqueSubtype) {
        return true;
      }
      if (allowArray && nativeType.isArray) {
        return _isValidFfiNativeType(nativeType.typeArguments.single,
            allowVoid: false, allowEmptyStruct: false);
      }
    } else if (nativeType is FunctionType) {
      return _isValidFfiNativeFunctionType(nativeType);
    }
    return false;
  }

  _PrimitiveDartType _primitiveNativeType(DartType nativeType) {
    if (nativeType is InterfaceType) {
      final element = nativeType.element;
      if (element.isFfiClass) {
        final String name = element.name;
        if (_primitiveIntegerNativeTypes.contains(name)) {
          return _PrimitiveDartType.int;
        }
        if (_primitiveDoubleNativeTypes.contains(name)) {
          return _PrimitiveDartType.double;
        }
        if (name == 'Void') {
          return _PrimitiveDartType.void_;
        }
        if (name == 'Handle') {
          return _PrimitiveDartType.handle;
        }
      }
    }
    return _PrimitiveDartType.none;
  }

  /// Return an indication of the Dart type associated with the [annotation].
  _PrimitiveDartType _typeForAnnotation(Annotation annotation) {
    var element = annotation.element;
    if (element is ConstructorElement) {
      String name = element.enclosingElement.name;
      if (_primitiveIntegerNativeTypes.contains(name)) {
        return _PrimitiveDartType.int;
      } else if (_primitiveDoubleNativeTypes.contains(name)) {
        return _PrimitiveDartType.double;
      }
    }
    return _PrimitiveDartType.none;
  }

  void _validateAllocate(FunctionExpressionInvocation node) {
    final typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    final DartType dartType = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(dartType,
        allowVoid: true, allowEmptyStruct: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
          errorNode,
          ['$_allocatorExtensionName.$_allocateExtensionMethodName']);
    }
  }

  /// Validate that the [annotations] include exactly one annotation that
  /// satisfies the [requiredTypes]. If an error is produced that cannot be
  /// associated with an annotation, associate it with the [errorNode].
  void _validateAnnotations(AstNode errorNode, NodeList<Annotation> annotations,
      _PrimitiveDartType requiredType) {
    bool requiredFound = false;
    List<Annotation> extraAnnotations = [];
    for (Annotation annotation in annotations) {
      if (annotation.element.ffiClass != null) {
        if (requiredFound) {
          extraAnnotations.add(annotation);
        } else {
          _PrimitiveDartType foundType = _typeForAnnotation(annotation);
          if (foundType == requiredType) {
            requiredFound = true;
          } else {
            extraAnnotations.add(annotation);
          }
        }
      }
    }
    if (extraAnnotations.isNotEmpty) {
      if (!requiredFound) {
        Annotation invalidAnnotation = extraAnnotations.removeAt(0);
        _errorReporter.reportErrorForNode(
            FfiCode.MISMATCHED_ANNOTATION_ON_STRUCT_FIELD, invalidAnnotation);
      }
      for (Annotation extraAnnotation in extraAnnotations) {
        _errorReporter.reportErrorForNode(
            FfiCode.EXTRA_ANNOTATION_ON_STRUCT_FIELD, extraAnnotation);
      }
    } else if (!requiredFound) {
      _errorReporter.reportErrorForNode(
          FfiCode.MISSING_ANNOTATION_ON_STRUCT_FIELD, errorNode);
    }
  }

  /// Validate the invocation of the instance method
  /// `Pointer<T>.asFunction<F>()`.
  void _validateAsFunction(MethodInvocation node, MethodElement element) {
    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments != null && typeArguments.length == 1) {
      if (_validateTypeArgument(typeArguments[0], 'asFunction')) {
        return;
      }
    }
    var target = node.realTarget!;
    var targetType = target.staticType;
    if (targetType is InterfaceType && targetType.isPointer) {
      final DartType T = targetType.typeArguments[0];
      if (!T.isNativeFunction ||
          !_isValidFfiNativeFunctionType(
              (T as InterfaceType).typeArguments.single)) {
        final AstNode errorNode =
            typeArguments != null ? typeArguments[0] : node;
        _errorReporter.reportErrorForNode(
            FfiCode.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER,
            errorNode,
            [T]);
        return;
      }

      final DartType TPrime = T.typeArguments[0];
      final DartType F = node.typeArgumentTypes![0];
      if (!_validateCompatibleFunctionTypes(F, TPrime)) {
        _errorReporter.reportErrorForNode(
            FfiCode.MUST_BE_A_SUBTYPE, node, [TPrime, F, 'asFunction']);
      }
    }
  }

  /// Validates that the given [nativeType] is, when native types are converted
  /// to their Dart equivalent, a subtype of [dartType].
  bool _validateCompatibleFunctionTypes(
      DartType dartType, DartType nativeType) {
    // We require both to be valid function types.
    if (dartType is! FunctionType ||
        dartType.isDartCoreFunction ||
        nativeType is! FunctionType ||
        nativeType.isDartCoreFunction) {
      return false;
    }

    // We disallow any optional parameters.
    final int parameterCount = dartType.normalParameterTypes.length;
    if (parameterCount != nativeType.normalParameterTypes.length) {
      return false;
    }
    // We disallow generic function types.
    if (dartType.typeFormals.isNotEmpty || nativeType.typeFormals.isNotEmpty) {
      return false;
    }
    if (dartType.namedParameterTypes.isNotEmpty ||
        dartType.optionalParameterTypes.isNotEmpty ||
        nativeType.namedParameterTypes.isNotEmpty ||
        nativeType.optionalParameterTypes.isNotEmpty) {
      return false;
    }

    // Validate that the return types are compatible.
    if (!_validateCompatibleNativeType(
        dartType.returnType, nativeType.returnType, false)) {
      return false;
    }

    // Validate that the parameter types are compatible.
    for (int i = 0; i < parameterCount; ++i) {
      if (!_validateCompatibleNativeType(dartType.normalParameterTypes[i],
          nativeType.normalParameterTypes[i], true)) {
        return false;
      }
    }

    // Signatures have same number of parameters and the types match.
    return true;
  }

  /// Validates that, if we convert [nativeType] to it's corresponding
  /// [dartType] the latter is a subtype of the former if
  /// [checkCovariance].
  bool _validateCompatibleNativeType(
      DartType dartType, DartType nativeType, bool checkCovariance) {
    final nativeReturnType = _primitiveNativeType(nativeType);
    if (nativeReturnType == _PrimitiveDartType.int) {
      return dartType.isDartCoreInt;
    } else if (nativeReturnType == _PrimitiveDartType.double) {
      return dartType.isDartCoreDouble;
    } else if (nativeReturnType == _PrimitiveDartType.void_) {
      return dartType.isVoid;
    } else if (nativeReturnType == _PrimitiveDartType.handle) {
      InterfaceType objectType = typeSystem.objectStar;
      return checkCovariance
          ? /* everything is subtype of objectStar */ true
          : typeSystem.isSubtypeOf(objectType, dartType);
    } else if (dartType is InterfaceType && nativeType is InterfaceType) {
      return checkCovariance
          ? typeSystem.isSubtypeOf(dartType, nativeType)
          : typeSystem.isSubtypeOf(nativeType, dartType);
    } else {
      // If the [nativeType] is not a primitive int/double type then it has to
      // be a Pointer type atm.
      return false;
    }
  }

  void _validateElementAt(MethodInvocation node) {
    var targetType = node.realTarget?.staticType;
    if (targetType is InterfaceType && targetType.isPointer) {
      final DartType T = targetType.typeArguments[0];

      if (!_isValidFfiNativeType(T, allowVoid: true, allowEmptyStruct: true)) {
        final AstNode errorNode = node;
        _errorReporter.reportErrorForNode(
            FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['elementAt']);
      }
    }
  }

  /// Validate that the fields declared by the given [node] meet the
  /// requirements for fields within a struct or union class.
  void _validateFieldsInCompound(FieldDeclaration node) {
    if (node.isStatic) {
      return;
    }
    VariableDeclarationList fields = node.fields;
    NodeList<Annotation> annotations = node.metadata;
    var fieldType = fields.type;
    if (fieldType == null) {
      _errorReporter.reportErrorForNode(
          FfiCode.MISSING_FIELD_TYPE_IN_STRUCT, fields.variables[0].name);
    } else {
      DartType declaredType = fieldType.typeOrThrow;
      if (declaredType.isDartCoreInt) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.int);
      } else if (declaredType.isDartCoreDouble) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.double);
      } else if (declaredType.isPointer) {
        _validateNoAnnotations(annotations);
      } else if (declaredType.isArray) {
        final typeArg = (declaredType as InterfaceType).typeArguments.single;
        if (!_isSized(typeArg)) {
          _errorReporter.reportErrorForNode(FfiCode.NON_SIZED_TYPE_ARGUMENT,
              fieldType, [_arrayClassName, typeArg.toString()]);
        }
        final arrayDimensions = declaredType.arrayDimensions;
        _validateSizeOfAnnotation(fieldType, annotations, arrayDimensions);
        final arrayElement = declaredType.arrayElementType;
        if (arrayElement.isCompoundSubtype) {
          final elementClass = (arrayElement as InterfaceType).element;
          _validatePackingNesting(compound!.declaredElement!, elementClass,
              errorNode: fieldType);
        }
      } else if (declaredType.isCompoundSubtype) {
        final clazz = (declaredType as InterfaceType).element;
        if (clazz.isEmptyStruct) {
          _errorReporter
              .reportErrorForNode(FfiCode.EMPTY_STRUCT, node, [clazz.name]);
        }
        _validatePackingNesting(compound!.declaredElement!, clazz,
            errorNode: fieldType);
      } else {
        _errorReporter.reportErrorForNode(FfiCode.INVALID_FIELD_TYPE_IN_STRUCT,
            fieldType, [fieldType.toSource()]);
      }
    }
    for (VariableDeclaration field in fields.variables) {
      if (field.initializer != null) {
        _errorReporter.reportErrorForNode(
            FfiCode.FIELD_IN_STRUCT_WITH_INITIALIZER, field.name);
      }
    }
  }

  /// Validate the invocation of the static method
  /// `Pointer<T>.fromFunction(f, e)`.
  void _validateFromFunction(MethodInvocation node, MethodElement element) {
    final int argCount = node.argumentList.arguments.length;
    if (argCount < 1 || argCount > 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    final DartType T = node.typeArgumentTypes![0];
    if (!_isValidFfiNativeFunctionType(T)) {
      _errorReporter.reportErrorForNode(
          FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, node, [T, 'fromFunction']);
      return;
    }

    Expression f = node.argumentList.arguments[0];
    DartType FT = f.typeOrThrow;
    if (!_validateCompatibleFunctionTypes(FT, T)) {
      _errorReporter.reportErrorForNode(
          FfiCode.MUST_BE_A_SUBTYPE, f, [f.staticType, T, 'fromFunction']);
      return;
    }

    // TODO(brianwilkerson) Validate that `f` is a top-level function.
    final DartType R = (T as FunctionType).returnType;
    if ((FT as FunctionType).returnType.isVoid ||
        R.isPointer ||
        R.isHandle ||
        R.isCompoundSubtype) {
      if (argCount != 1) {
        _errorReporter.reportErrorForNode(
            FfiCode.INVALID_EXCEPTION_VALUE, node.argumentList.arguments[1]);
      }
    } else if (argCount != 2) {
      _errorReporter.reportErrorForNode(
          FfiCode.MISSING_EXCEPTION_VALUE, node.methodName);
    } else {
      Expression e = node.argumentList.arguments[1];
      // TODO(brianwilkerson) Validate that `e` is a constant expression.
      if (!_validateCompatibleNativeType(e.typeOrThrow, R, true)) {
        _errorReporter.reportErrorForNode(
            FfiCode.MUST_BE_A_SUBTYPE, e, [e.staticType, R, 'fromFunction']);
      }
    }
  }

  /// Validate the invocation of the instance method
  /// `DynamicLibrary.lookupFunction<S, F>()`.
  void _validateLookupFunction(MethodInvocation node) {
    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments?.length != 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    final List<DartType> argTypes = node.typeArgumentTypes!;
    final DartType S = argTypes[0];
    final DartType F = argTypes[1];
    if (!_isValidFfiNativeFunctionType(S)) {
      final AstNode errorNode = typeArguments![0];
      _errorReporter.reportErrorForNode(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
          errorNode, [S, 'lookupFunction']);
      return;
    }
    if (!_validateCompatibleFunctionTypes(F, S)) {
      final AstNode errorNode = typeArguments![1];
      _errorReporter.reportErrorForNode(
          FfiCode.MUST_BE_A_SUBTYPE, errorNode, [S, F, 'lookupFunction']);
    }
  }

  /// Validate that none of the [annotations] are from `dart:ffi`.
  void _validateNoAnnotations(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      if (annotation.element.ffiClass != null) {
        _errorReporter.reportErrorForNode(
            FfiCode.ANNOTATION_ON_POINTER_FIELD, annotation);
      }
    }
  }

  /// Validate that the [annotations] include at most one packed annotation.
  void _validatePackedAnnotation(NodeList<Annotation> annotations) {
    final ffiPackedAnnotations =
        annotations.where((annotation) => annotation.isPacked).toList();

    if (ffiPackedAnnotations.isEmpty) {
      return;
    }

    if (ffiPackedAnnotations.length > 1) {
      final extraAnnotations = ffiPackedAnnotations.skip(1);
      for (final annotation in extraAnnotations) {
        _errorReporter.reportErrorForNode(
            FfiCode.PACKED_ANNOTATION, annotation);
      }
    }

    // Check number of dimensions.
    final annotation = ffiPackedAnnotations.first;
    final value = annotation.elementAnnotation?.packedMemberAlignment;
    if (![1, 2, 4, 8, 16].contains(value)) {
      _errorReporter.reportErrorForNode(
          FfiCode.PACKED_ANNOTATION_ALIGNMENT, annotation);
    }
  }

  void _validatePackingNesting(ClassElement outer, ClassElement nested,
      {required TypeAnnotation errorNode}) {
    final outerPacking = outer.structPacking;
    if (outerPacking == null) {
      // No packing for outer class, so we're done.
      return;
    }
    bool error = false;
    final nestedPacking = nested.structPacking;
    if (nestedPacking == null) {
      // The outer struct packs, but the nested struct does not.
      error = true;
    } else if (outerPacking < nestedPacking) {
      // The outer struct packs tighter than the nested struct.
      error = true;
    }
    if (error) {
      _errorReporter.reportErrorForNode(FfiCode.PACKED_NESTING_NON_PACKED,
          errorNode, [nested.name, outer.name]);
    }
  }

  void _validateRefIndexed(IndexExpression node) {
    var targetType = node.realTarget.staticType;
    if (!_isValidFfiNativeType(targetType,
        allowVoid: false, allowEmptyStruct: true, allowArray: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['[]']);
    }
  }

  /// Validate the invocation of the extension method
  /// `Pointer<T extends Struct>.ref`.
  void _validateRefPrefixedIdentifier(PrefixedIdentifier node) {
    var targetType = node.prefix.typeOrThrow;
    if (!_isValidFfiNativeType(targetType,
        allowVoid: false, allowEmptyStruct: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['ref']);
    }
  }

  void _validateRefPropertyAccess(PropertyAccess node) {
    var targetType = node.realTarget.staticType;
    if (!_isValidFfiNativeType(targetType,
        allowVoid: false, allowEmptyStruct: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['ref']);
    }
  }

  void _validateSizeOf(MethodInvocation node) {
    final typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    final DartType T = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(T, allowVoid: true, allowEmptyStruct: true)) {
      final AstNode errorNode = node;
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, errorNode, ['sizeOf']);
    }
  }

  /// Validate that the [annotations] include exactly one size annotation. If
  /// an error is produced that cannot be associated with an annotation,
  /// associate it with the [errorNode].
  void _validateSizeOfAnnotation(AstNode errorNode,
      NodeList<Annotation> annotations, int arrayDimensions) {
    final ffiSizeAnnotations =
        annotations.where((annotation) => annotation.isArray).toList();

    if (ffiSizeAnnotations.isEmpty) {
      _errorReporter.reportErrorForNode(
          FfiCode.MISSING_SIZE_ANNOTATION_CARRAY, errorNode);
      return;
    }

    if (ffiSizeAnnotations.length > 1) {
      final extraAnnotations = ffiSizeAnnotations.skip(1);
      for (final annotation in extraAnnotations) {
        _errorReporter.reportErrorForNode(
            FfiCode.EXTRA_SIZE_ANNOTATION_CARRAY, annotation);
      }
    }

    // Check number of dimensions.
    final annotation = ffiSizeAnnotations.first;
    final dimensions = annotation.elementAnnotation?.arraySizeDimensions ?? [];
    final annotationDimensions = dimensions.length;
    if (annotationDimensions != arrayDimensions) {
      _errorReporter.reportErrorForNode(
          FfiCode.SIZE_ANNOTATION_DIMENSIONS, annotation);
    }
  }

  /// Validate that the given [typeArgument] has a constant value. Return `true`
  /// if a diagnostic was produced because it isn't constant.
  bool _validateTypeArgument(TypeAnnotation typeArgument, String functionName) {
    if (typeArgument.type is TypeParameterType) {
      _errorReporter.reportErrorForNode(
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT, typeArgument, [functionName]);
      return true;
    }
    return false;
  }
}

enum _PrimitiveDartType {
  double,
  int,
  void_,
  handle,
  none,
}

extension on Annotation {
  bool get isArray {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Array';
  }

  bool get isPacked {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Packed';
  }
}

extension on ElementAnnotation {
  bool get isArray {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Array';
    // Note: this is 'Array' instead of '_ArraySize' because it finds the
    // forwarding factory instead of the forwarded constructor.
  }

  bool get isPacked {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Packed';
  }

  List<int> get arraySizeDimensions {
    assert(isArray);
    final value = computeConstantValue();

    // Element of `@Array.multi([1, 2, 3])`.
    final listField = value?.getField('dimensions');
    if (listField != null) {
      final listValues = listField
          .toListValue()
          ?.map((dartValue) => dartValue.toIntValue())
          .whereType<int>()
          .toList();
      if (listValues != null) {
        return listValues;
      }
    }

    // Element of `@Array(1, 2, 3)`.
    const dimensionFieldNames = [
      'dimension1',
      'dimension2',
      'dimension3',
      'dimension4',
      'dimension5',
    ];
    var result = <int>[];
    for (final dimensionFieldName in dimensionFieldNames) {
      final dimensionValue = value?.getField(dimensionFieldName)?.toIntValue();
      if (dimensionValue != null) {
        result.add(dimensionValue);
      }
    }
    return result;
  }

  int? get packedMemberAlignment {
    assert(isPacked);
    final value = computeConstantValue();
    return value?.getField('memberAlignment')?.toIntValue();
  }
}

extension on Element? {
  /// Return `true` if this represents the extension `AllocatorAlloc`.
  bool get isAllocatorExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == FfiVerifier._allocatorExtensionName &&
        element.isFfiExtension;
  }

  bool get isNativeFunctionPointerExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == 'NativeFunctionPointer' &&
        element.isFfiExtension;
  }

  bool get isNativeStructArrayExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == 'StructArray' &&
        element.isFfiExtension;
  }

  bool get isNativeStructPointerExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == 'StructPointer' &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the extension `DynamicLibraryExtension`.
  bool get isDynamicLibraryExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == 'DynamicLibraryExtension' &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the class `Pointer`.
  bool get isPointer {
    final element = this;
    return element is ClassElement &&
        element.name == 'Pointer' &&
        element.isFfiClass;
  }

  /// If this is a class element from `dart:ffi`, return it.
  ClassElement? get ffiClass {
    var element = this;
    if (element is ConstructorElement) {
      element = element.enclosingElement;
    }
    if (element is ClassElement && element.isFfiClass) {
      return element;
    }
    return null;
  }
}

extension on ClassElement {
  bool get isEmptyStruct {
    for (final field in fields) {
      final declaredType = field.type;
      if (declaredType.isDartCoreInt) {
        return false;
      } else if (declaredType.isDartCoreDouble) {
        return false;
      } else if (declaredType.isPointer) {
        return false;
      } else if (declaredType.isCompoundSubtype) {
        return false;
      } else if (declaredType.isArray) {
        return false;
      }
    }
    return true;
  }

  bool get isFfiClass {
    return library.name == FfiVerifier._dartFfiLibraryName;
  }

  int? get structPacking {
    final packedAnnotations =
        metadata.where((annotation) => annotation.isPacked);

    if (packedAnnotations.isEmpty) {
      return null;
    }

    return packedAnnotations.first.packedMemberAlignment;
  }
}

extension on ExtensionElement {
  bool get isFfiExtension {
    return library.name == FfiVerifier._dartFfiLibraryName;
  }
}

extension on DartType {
  /// Return `true` if this represents the class `Array`.
  bool get isArray {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == FfiVerifier._arrayClassName && element.isFfiClass;
    }
    return false;
  }

  int get arrayDimensions {
    DartType iterator = this;
    int dimensions = 0;
    while (iterator is InterfaceType &&
        iterator.element.name == FfiVerifier._arrayClassName &&
        iterator.element.isFfiClass) {
      dimensions++;
      iterator = iterator.typeArguments.single;
    }
    return dimensions;
  }

  DartType get arrayElementType {
    DartType iterator = this;
    while (iterator is InterfaceType &&
        iterator.element.name == FfiVerifier._arrayClassName &&
        iterator.element.isFfiClass) {
      iterator = iterator.typeArguments.single;
    }
    return iterator;
  }

  bool get isPointer {
    final self = this;
    return self is InterfaceType && self.element.isPointer;
  }

  bool get isHandle {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == 'Handle' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a `ffi.NativeFunction<???>` type.
  bool get isNativeFunction {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == 'NativeFunction' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a `ffi.NativeType` type.
  bool get isNativeType {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == 'NativeType' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a opaque type, i.e. a subtype of `Opaque`.
  bool get isOpaqueSubtype {
    final self = this;
    if (self is InterfaceType) {
      final superType = self.element.supertype;
      if (superType != null) {
        final superClassElement = superType.element;
        return superClassElement.name == FfiVerifier._opaqueClassName &&
            superClassElement.isFfiClass;
      }
    }
    return false;
  }

  bool get isCompound {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      final name = element.name;
      return (name == FfiVerifier._structClassName ||
              name == FfiVerifier._unionClassName) &&
          element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` if this is a struct type, i.e. a subtype of `Struct`.
  bool get isCompoundSubtype {
    final self = this;
    if (self is InterfaceType) {
      final superType = self.element.supertype;
      if (superType != null) {
        return superType.isCompound;
      }
    }
    return false;
  }
}

extension on TypeName {
  /// If this is a name of class from `dart:ffi`, return it.
  ClassElement? get ffiClass {
    return name.staticElement.ffiClass;
  }

  /// Return `true` if this represents a subtype of `Struct` or `Union`.
  bool get isCompoundSubtype {
    var element = name.staticElement;
    if (element is ClassElement) {
      bool isCompound(InterfaceType? type) {
        return type != null && type.isCompound;
      }

      return isCompound(element.supertype) ||
          element.interfaces.any(isCompound) ||
          element.mixins.any(isCompound);
    }
    return false;
  }
}
