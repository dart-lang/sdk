// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/error/ffi_code.dart';

/// A visitor used to find problems with the way the `dart:ffi` APIs are being
/// used. See 'pkg/vm/lib/transformations/ffi_checks.md' for the specification
/// of the desired hints.
class FfiVerifier extends RecursiveAstVisitor<void> {
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

  /// The type system used to check types.
  final TypeSystemImpl typeSystem;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// A flag indicating whether we are currently visiting inside a subclass of
  /// `Struct`.
  bool inStruct = false;

  /// Initialize a newly created verifier.
  FfiVerifier(this.typeSystem, this._errorReporter);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    inStruct = false;
    // Only the Struct class may be extended.
    ExtendsClause extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final TypeName superclass = extendsClause.superclass;
      if (_isDartFfiClass(superclass)) {
        if (superclass.name.staticElement.name == 'Struct') {
          inStruct = true;
        } else {
          _errorReporter.reportErrorForNode(
              FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS,
              superclass.name,
              [node.name.name, superclass.name.name]);
        }
      } else if (_isSubtypeOfStruct(superclass)) {
        _errorReporter.reportErrorForNode(
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS,
            superclass,
            [node.name.name, superclass.name.name]);
      }
    }

    // No classes from the FFI may be explicitly implemented.
    void checkSupertype(TypeName typename, FfiCode subtypeOfFfiCode,
        FfiCode subtypeOfStructCode) {
      if (_isDartFfiClass(typename)) {
        _errorReporter.reportErrorForNode(
            subtypeOfFfiCode, typename, [node.name, typename.name]);
      } else if (_isSubtypeOfStruct(typename)) {
        _errorReporter.reportErrorForNode(
            subtypeOfStructCode, typename, [node.name, typename.name]);
      }
    }

    ImplementsClause implementsClause = node.implementsClause;
    if (implementsClause != null) {
      for (TypeName type in implementsClause.interfaces) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS,
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS);
      }
    }
    WithClause withClause = node.withClause;
    if (withClause != null) {
      for (TypeName type in withClause.mixinTypes) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH,
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH);
      }
    }

    if (inStruct && node.declaredElement.typeParameters.isNotEmpty) {
      _errorReporter.reportErrorForNode(
          FfiCode.GENERIC_STRUCT_SUBCLASS, node.name, [node.name]);
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (inStruct) {
      _errorReporter.reportErrorForNode(
          FfiCode.FIELD_INITIALIZER_IN_STRUCT, node);
    }
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (inStruct) {
      _validateFieldsInStruct(node);
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    Element element = node.methodName.staticElement;
    if (element is MethodElement) {
      Element enclosingElement = element.enclosingElement;
      if (enclosingElement is ClassElement) {
        if (_isPointer(enclosingElement)) {
          if (element.name == 'fromFunction') {
            _validateFromFunction(node, element);
          }
        }
      }
      if (enclosingElement is ExtensionElement) {
        if (_isNativeFunctionPointerExtension(enclosingElement)) {
          if (element.name == 'asFunction') {
            _validateAsFunction(node, element);
          }
        } else if (_isDynamicLibraryExtension(enclosingElement) &&
            element.name == 'lookupFunction') {
          _validateLookupFunction(node);
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  /// Return `true` if the [typeName] is the name of a type from `dart:ffi`.
  bool _isDartFfiClass(TypeName typeName) =>
      _isDartFfiElement(typeName.name.staticElement);

  /// Return `true` if the [element] is a class element from `dart:ffi`.
  bool _isDartFfiElement(Element element) {
    if (element is ConstructorElement) {
      element = element.enclosingElement;
    }
    return element is ClassElement && element.library.name == 'dart.ffi';
  }

  /// Return `true` if the given [element] represents the extension
  /// `DynamicLibraryExtension`.
  bool _isDynamicLibraryExtension(Element element) =>
      element.name == 'DynamicLibraryExtension' &&
      element.library.name == 'dart.ffi';

  bool _isEmptyStruct(ClassElement classElement) {
    final fields = classElement.fields;
    var structFieldCount = 0;
    for (final field in fields) {
      final declaredType = field.type;
      if (declaredType.isDartCoreInt) {
        structFieldCount++;
      } else if (declaredType.isDartCoreDouble) {
        structFieldCount++;
      } else if (_isPointer(declaredType.element)) {
        structFieldCount++;
      } else if (_isStructClass(declaredType)) {
        structFieldCount++;
      }
    }
    return structFieldCount == 0;
  }

  bool _isHandle(Element element) =>
      element.name == 'Handle' && element.library.name == 'dart.ffi';

  /// Returns `true` iff [nativeType] is a `ffi.NativeFunction<???>` type.
  bool _isNativeFunctionInterfaceType(DartType nativeType) {
    if (nativeType is InterfaceType) {
      final element = nativeType.element;
      if (element.library.name == 'dart.ffi') {
        return element.name == 'NativeFunction' &&
            nativeType.typeArguments?.length == 1;
      }
    }
    return false;
  }

  bool _isNativeFunctionPointerExtension(Element element) =>
      element.name == 'NativeFunctionPointer' &&
      element.library.name == 'dart.ffi';

  /// Returns `true` iff [nativeType] is a `ffi.NativeType` type.
  bool _isNativeTypeInterfaceType(DartType nativeType) {
    if (nativeType is InterfaceType) {
      final element = nativeType.element;
      if (element.library.name == 'dart.ffi') {
        return element.name == 'NativeType';
      }
    }
    return false;
  }

  /// Return `true` if the given [element] represents the class `Pointer`.
  bool _isPointer(Element element) =>
      element.name == 'Pointer' && element.library.name == 'dart.ffi';

  /// Returns `true` iff [nativeType] is a `ffi.Pointer<???>` type.
  bool _isPointerInterfaceType(DartType nativeType) {
    if (nativeType is InterfaceType) {
      final element = nativeType.element;
      if (element.library.name == 'dart.ffi') {
        return element.name == 'Pointer' &&
            nativeType.typeArguments?.length == 1;
      }
    }
    return false;
  }

  /// Returns `true` iff [nativeType] is a struct type.
  bool _isStructClass(DartType nativeType) {
    if (nativeType is InterfaceType) {
      final superType = nativeType.element.supertype;
      if (superType == null) {
        return false;
      }
      final superClassElement = superType.element;
      if (superClassElement.library.name == 'dart.ffi') {
        return superClassElement.name == 'Struct' &&
            nativeType.typeArguments?.isEmpty == true;
      }
    }
    return false;
  }

  /// Return `true` if the [typeName] represents a subtype of `Struct`.
  bool _isSubtypeOfStruct(TypeName typeName) {
    Element superType = typeName.name.staticElement;
    if (superType is ClassElement) {
      bool isStruct(InterfaceType type) {
        return type != null &&
            type.element.name == 'Struct' &&
            type.element.library.name == 'dart.ffi';
      }

      return isStruct(superType.supertype) ||
          superType.interfaces.any(isStruct) ||
          superType.mixins.any(isStruct);
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
      if (!_isValidFfiNativeType(nativeType.returnType, true, false)) {
        return false;
      }

      for (final DartType typeArg in nativeType.normalParameterTypes) {
        if (!_isValidFfiNativeType(typeArg, false, false)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// Validates that the given [nativeType] is a valid dart:ffi native type.
  bool _isValidFfiNativeType(
      DartType nativeType, bool allowVoid, bool allowEmptyStruct) {
    if (nativeType is InterfaceType) {
      // Is it a primitive integer/double type (or ffi.Void if we allow it).
      final primitiveType = _primitiveNativeType(nativeType);
      if (primitiveType != _PrimitiveDartType.none &&
          (primitiveType != _PrimitiveDartType.void_ || allowVoid)) {
        return true;
      }
      if (_isNativeFunctionInterfaceType(nativeType)) {
        return _isValidFfiNativeFunctionType(nativeType.typeArguments.single);
      }
      if (_isPointerInterfaceType(nativeType)) {
        final nativeArgumentType = nativeType.typeArguments.single;
        return _isValidFfiNativeType(nativeArgumentType, true, true) ||
            _isStructClass(nativeArgumentType) ||
            _isNativeTypeInterfaceType(nativeArgumentType);
      }
      if (_isStructClass(nativeType)) {
        if (!allowEmptyStruct) {
          if (_isEmptyStruct(nativeType.element)) {
            // TODO(dartbug.com/36780): This results in an error message not
            // mentioning empty structs at all.
            return false;
          }
        }
        return true;
      }
    } else if (nativeType is FunctionType) {
      return _isValidFfiNativeFunctionType(nativeType);
    }
    return false;
  }

  _PrimitiveDartType _primitiveNativeType(DartType nativeType) {
    if (nativeType is InterfaceType) {
      final element = nativeType.element;
      if (element.library.name == 'dart.ffi') {
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
    Element element = annotation.element;
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

  /// Validate that the [annotations] include exactly one annotation that
  /// satisfies the [requiredTypes]. If an error is produced that cannot be
  /// associated with an annotation, associate it with the [errorNode].
  void _validateAnnotations(AstNode errorNode, NodeList<Annotation> annotations,
      _PrimitiveDartType requiredType) {
    bool requiredFound = false;
    List<Annotation> extraAnnotations = [];
    for (Annotation annotation in annotations) {
      if (_isDartFfiElement(annotation.element)) {
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
    NodeList<TypeAnnotation> typeArguments = node.typeArguments?.arguments;
    if (typeArguments != null && typeArguments.length == 1) {
      if (_validateTypeArgument(typeArguments[0], 'asFunction')) {
        return;
      }
    }
    Expression target = node.realTarget;
    DartType targetType = target.staticType;
    if (targetType is InterfaceType &&
        _isPointer(targetType.element) &&
        targetType.typeArguments.length == 1) {
      final DartType T = targetType.typeArguments[0];
      if (!_isNativeFunctionInterfaceType(T) ||
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

      final DartType TPrime = (T as InterfaceType).typeArguments[0];
      final DartType F = node.typeArgumentTypes[0];
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

    final dartFType = dartType as FunctionType;
    final nativeFType = nativeType as FunctionType;

    // We disallow any optional parameters.
    final int parameterCount = dartFType.normalParameterTypes.length;
    if (parameterCount != nativeFType.normalParameterTypes.length) {
      return false;
    }
    // We disallow generic function types.
    if (dartFType.typeFormals.isNotEmpty ||
        nativeFType.typeFormals.isNotEmpty) {
      return false;
    }
    if (dartFType.namedParameterTypes.isNotEmpty ||
        dartFType.optionalParameterTypes.isNotEmpty ||
        nativeFType.namedParameterTypes.isNotEmpty ||
        nativeFType.optionalParameterTypes.isNotEmpty) {
      return false;
    }

    // Validate that the return types are compatible.
    if (!_validateCompatibleNativeType(
        dartFType.returnType, nativeFType.returnType, false)) {
      return false;
    }

    // Validate that the parameter types are compatible.
    for (int i = 0; i < parameterCount; ++i) {
      if (!_validateCompatibleNativeType(dartFType.normalParameterTypes[i],
          nativeFType.normalParameterTypes[i], true)) {
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
          : typeSystem.isSubtypeOf2(objectType, dartType);
    } else if (dartType is InterfaceType && nativeType is InterfaceType) {
      return checkCovariance
          ? typeSystem.isSubtypeOf2(dartType, nativeType)
          : typeSystem.isSubtypeOf2(nativeType, dartType);
    } else {
      // If the [nativeType] is not a primitive int/double type then it has to
      // be a Pointer type atm.
      return false;
    }
  }

  /// Validate that the fields declared by the given [node] meet the
  /// requirements for fields within a struct class.
  void _validateFieldsInStruct(FieldDeclaration node) {
    if (node.isStatic) {
      return;
    }
    VariableDeclarationList fields = node.fields;
    NodeList<Annotation> annotations = node.metadata;
    TypeAnnotation fieldType = fields.type;
    if (fieldType == null) {
      _errorReporter.reportErrorForNode(
          FfiCode.MISSING_FIELD_TYPE_IN_STRUCT, fields.variables[0].name);
    } else {
      DartType declaredType = fieldType.type;
      if (declaredType.isDartCoreInt) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.int);
      } else if (declaredType.isDartCoreDouble) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.double);
      } else if (_isPointer(declaredType.element)) {
        _validateNoAnnotations(annotations);
      } else if (_isStructClass(declaredType)) {
        final clazz = (declaredType as InterfaceType).element;
        if (_isEmptyStruct(clazz)) {
          _errorReporter
              .reportErrorForNode(FfiCode.EMPTY_STRUCT, node, [clazz.name]);
        }
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

    final DartType T = node.typeArgumentTypes[0];
    if (!_isValidFfiNativeFunctionType(T)) {
      _errorReporter.reportErrorForNode(
          FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, node, [T, 'fromFunction']);
      return;
    }

    Expression f = node.argumentList.arguments[0];
    DartType FT = f.staticType;
    if (!_validateCompatibleFunctionTypes(FT, T)) {
      _errorReporter.reportErrorForNode(
          FfiCode.MUST_BE_A_SUBTYPE, f, [f.staticType, T, 'fromFunction']);
      return;
    }

    // TODO(brianwilkerson) Validate that `f` is a top-level function.
    final DartType R = (T as FunctionType).returnType;
    if ((FT as FunctionType).returnType.isVoid ||
        _isPointer(R.element) ||
        _isHandle(R.element) ||
        _isStructClass(R)) {
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
      if (!_validateCompatibleNativeType(e.staticType, R, true)) {
        _errorReporter.reportErrorForNode(
            FfiCode.MUST_BE_A_SUBTYPE, e, [e.staticType, R, 'fromFunction']);
      }
    }
  }

  /// Validate the invocation of the instance method
  /// `DynamicLibrary.lookupFunction<S, F>()`.
  void _validateLookupFunction(MethodInvocation node) {
    final NodeList<TypeAnnotation> typeArguments =
        node.typeArguments?.arguments;
    if (typeArguments?.length != 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    final List<DartType> argTypes = node.typeArgumentTypes;
    final DartType S = argTypes[0];
    final DartType F = argTypes[1];
    if (!_isValidFfiNativeFunctionType(S)) {
      final AstNode errorNode = typeArguments[0];
      _errorReporter.reportErrorForNode(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
          errorNode, [S, 'lookupFunction']);
      return;
    }
    if (!_validateCompatibleFunctionTypes(F, S)) {
      final AstNode errorNode = typeArguments[1];
      _errorReporter.reportErrorForNode(
          FfiCode.MUST_BE_A_SUBTYPE, errorNode, [S, F, 'lookupFunction']);
    }
  }

  /// Validate that none of the [annotations] are from `dart:ffi`.
  void _validateNoAnnotations(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      if (_isDartFfiElement(annotation.element)) {
        _errorReporter.reportErrorForNode(
            FfiCode.ANNOTATION_ON_POINTER_FIELD, annotation);
      }
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
