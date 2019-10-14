// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/error/ffi_code.dart';

/// A visitor used to find problems with the way the `dart:ffi` APIs are being
/// used. See 'pkg/vm/lib/transformations/ffi_checks.md' for the specification
/// of the desired hints.
class FfiVerifier extends RecursiveAstVisitor<void> {
  /// The type system used to check types.
  final TypeSystem typeSystem;

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
          NodeList<TypeAnnotation> typeArguments =
              superclass.typeArguments?.arguments;
          if (typeArguments == null) {
            _errorReporter.reportTypeErrorForNode(
                FfiCode.MISSING_TYPE_ARGUMENT_FOR_STRUCT,
                superclass.name,
                [node.name.name]);
          } else if (typeArguments.length == 1) {
            if (typeArguments[0].type.element != node.declaredElement) {
              // TODO(brianwilkerson) If the type argument is not a subclass of
              //  Struct, then we'll get two diagnostics generated. We should
              //  test for that case here and suppress the hint.
              _errorReporter.reportTypeErrorForNode(
                  FfiCode.INVALID_TYPE_ARGUMENT_FOR_STRUCT,
                  typeArguments[0],
                  [node.name.name]);
            }
          }
        } else {
          _errorReporter.reportTypeErrorForNode(
              FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS,
              superclass.name,
              [node.name.name, superclass.name.name]);
        }
      } else if (_isSubtypeOfStruct(superclass)) {
        _errorReporter.reportTypeErrorForNode(
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS,
            superclass,
            [node.name.name, superclass.name.name]);
      }
    }

    // No classes from the FFI may be explicitly implemented.
    void checkSupertype(TypeName typename, FfiCode subtypeOfFfiCode,
        FfiCode subtypeOfStructCode) {
      if (_isDartFfiClass(typename)) {
        _errorReporter.reportTypeErrorForNode(
            subtypeOfFfiCode, typename, [node.name, typename.name]);
      } else if (_isSubtypeOfStruct(typename)) {
        _errorReporter.reportTypeErrorForNode(
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
          if (element.name == 'asFunction') {
            _validateAsFunction(node, element);
          } else if (element.name == 'fromFunction') {
            _validateFromFunction(node, element);
          }
        } else if (_isDynamicLibrary(enclosingElement) &&
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

  /// Return `true` if the given [element] represents the class
  /// `DynamicLibrary`.
  bool _isDynamicLibrary(ClassElement element) =>
      element.name == 'DynamicLibrary' && element.library.name == 'dart.ffi';

  /// Return `true` if the given [element] represents the class `Pointer`.
  bool _isPointer(ClassElement element) =>
      element.name == 'Pointer' && element.library.name == 'dart.ffi';

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

  /// Return `true` if the [foundType] matches one of the [requiredTypes].
  bool _matchesAllowed(_FoundType foundType, _RequiredTypes requiredTypes) {
    return requiredTypes == _RequiredTypes.any ||
        (requiredTypes == _RequiredTypes.int && foundType == _FoundType.int) ||
        (requiredTypes == _RequiredTypes.double &&
            foundType == _FoundType.double);
  }

  /// Return an indication of the Dart type associated with the [annotation].
  _FoundType _typeForAnnotation(Annotation annotation) {
    Element element = annotation.element;
    if (element is ConstructorElement) {
      String name = element.enclosingElement.name;
      if ([
        'Int8',
        'Int16',
        'Int32',
        'Int64',
        'Uint8',
        'Uint16',
        'Uint32',
        'Uint64'
      ].contains(name)) {
        return _FoundType.int;
      } else if (['Double', 'Float'].contains(name)) {
        return _FoundType.double;
      }
    }
    return _FoundType.none;
  }

  /// Validate that the [annotations] include exactly one annotation that
  /// satisfies the [requiredTypes]. If an error is produced that cannot be
  /// associated with an annotation, associate it with the [errorNode].
  void _validateAnnotations(AstNode errorNode, NodeList<Annotation> annotations,
      _RequiredTypes requiredTypes) {
    bool requiredFound = false;
    List<Annotation> extraAnnotations = [];
    for (Annotation annotation in annotations) {
      if (_isDartFfiElement(annotation.element)) {
        if (requiredFound) {
          extraAnnotations.add(annotation);
        } else {
          _FoundType foundType = _typeForAnnotation(annotation);
          if (foundType == _FoundType.none) {
            // This should never happen because `_typeForAnnotation` should
            // handle all of the classes from dart:ffi that can be used as an
            // annotation.
          } else if (_matchesAllowed(foundType, requiredTypes)) {
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
      DartType T = targetType.typeArguments[0];
      if (T is InterfaceTypeImpl) {
        ClassElement nativeFunctionElement =
            element.enclosingElement.library.getType('NativeFunction');
        InterfaceType nativeFunctionType =
            T.asInstanceOf(nativeFunctionElement);
        if (nativeFunctionType == null) {
          _errorReporter.reportErrorForNode(
              FfiCode.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER, target);
        } else {
          DartType TPrime = nativeFunctionType.typeArguments[0];
          if (TPrime is TypeParameterType) {
            _errorReporter.reportErrorForNode(
                FfiCode.NON_CONSTANT_TYPE_ARGUMENT_TO_POINTER, target);
          } else {
            DartType F = node.typeArgumentTypes[0];
            if (!typeSystem.isSubtypeOf(TPrime, F)) {
              _errorReporter.reportTypeErrorForNode(
                  FfiCode.MUST_BE_A_SUBTYPE,
                  typeArguments[0],
                  [TPrime.displayName, F.displayName, 'asFunction']);
            }
          }
        }
      } else if (T is TypeParameterType) {
        _errorReporter.reportErrorForNode(
            FfiCode.NON_CONSTANT_TYPE_ARGUMENT_TO_POINTER, target);
      }
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
        _validateAnnotations(fieldType, annotations, _RequiredTypes.int);
      } else if (declaredType.isDartCoreDouble) {
        _validateAnnotations(fieldType, annotations, _RequiredTypes.double);
      } else if (_isPointer(declaredType.element)) {
        _validateNoAnnotations(annotations);
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
    int argCount = node.argumentList.arguments.length;
    if (argCount < 1 || argCount > 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }
    DartType T = node.typeArgumentTypes[0];
    if (T is FunctionType) {
      Expression f = node.argumentList.arguments[0];
      if (!typeSystem.isSubtypeOf(f.staticType, T)) {
        _errorReporter.reportTypeErrorForNode(
            FfiCode.MUST_BE_A_SUBTYPE, f, [f.staticType, T, 'fromFunction']);
      }
      // TODO(brianwilkerson) Validate that `f` is a top-level function.
      DartType R = T.returnType;
      if (R.isVoid || _isPointer(R.element)) {
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
        if (!typeSystem.isSubtypeOf(e.staticType, R)) {
          _errorReporter.reportTypeErrorForNode(
              FfiCode.MUST_BE_A_SUBTYPE, e, [e.staticType, R, 'fromFunction']);
        }
      }
    } else if (T is TypeParameterType) {
      _errorReporter.reportErrorForNode(FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
          node.typeArguments.arguments[0], ['fromFunction']);
    }
  }

  /// Validate the invocation of the instance method
  /// `DynamicLibrary.lookupFunction<S, F>()`.
  void _validateLookupFunction(MethodInvocation node) {
    NodeList<TypeAnnotation> typeArguments = node.typeArguments?.arguments;
    if (typeArguments != null && typeArguments.length == 2) {
      if (_validateTypeArgument(typeArguments[0], 'lookupFunction') ||
          _validateTypeArgument(typeArguments[1], 'lookupFunction')) {
        return;
      }
    }
    List<DartType> argTypes = node.typeArgumentTypes;
    DartType S = argTypes[0];
    DartType F = argTypes[1];
    if (!typeSystem.isSubtypeOf(S, F)) {
      AstNode errorNode;
      if (typeArguments != null && typeArguments.length >= 2) {
        errorNode = typeArguments[1];
      } else {
        errorNode = node.typeArguments;
      }
      _errorReporter.reportTypeErrorForNode(FfiCode.MUST_BE_A_SUBTYPE,
          errorNode, [S.displayName, F.displayName, 'lookupFunction']);
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

/// An enumeration of the type corresponding to an annotation.
enum _FoundType {
  double,
  int,
  none,
}

/// An enumeration of the type of annotation that is required to be on a field.
enum _RequiredTypes {
  any,
  double,
  int,
}
