// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/error/ffi_code.dart';

/// A visitor used to find problems with the way the `dart:ffi` APIs are being
/// used. See 'pkg/vm/lib/transformations/ffi_checks.md' for the specification
/// of the desired hints.
class FfiVerifier extends RecursiveAstVisitor<void> {
  /// The inheritance manager used to find overridden methods.
  final InheritanceManager3 _inheritance;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// A flag indicating whether we are currently visiting inside a subclass of
  /// `Struct`.
  bool inStruct = false;

  /// Initialize a newly created verifier.
  FfiVerifier(this._inheritance, this._errorReporter);

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
    if (element is MethodElement &&
        element.name == 'asFunction' &&
        _isPointer(element.enclosingElement)) {
      element.type.typeArguments;
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

  /// Validate that the fields declared by the given [node] meet the
  /// requirements for fields within a struct class.
  void _validateFieldsInStruct(FieldDeclaration node) {
    VariableDeclarationList fields = node.fields;
    NodeList<Annotation> annotations = node.metadata;
    TypeAnnotation fieldType = fields.type;
    DartType declaredType = fieldType?.type;
    if (declaredType == null) {
      _validateAnnotations(fieldType, annotations, _RequiredTypes.any);
    } else if (declaredType.isDartCoreInt) {
      _validateAnnotations(fieldType, annotations, _RequiredTypes.int);
    } else if (declaredType.isDartCoreDouble) {
      _validateAnnotations(fieldType, annotations, _RequiredTypes.double);
    } else if (_isPointer(declaredType.element)) {
      _validateNoAnnotations(annotations);
    } else {
      _errorReporter.reportErrorForNode(FfiCode.INVALID_FIELD_TYPE_IN_STRUCT,
          fieldType, [fieldType.toSource()]);
    }
    for (VariableDeclaration field in fields.variables) {
      if (field.initializer != null) {
        _errorReporter.reportErrorForNode(
            FfiCode.FIELD_IN_STRUCT_WITH_INITIALIZER, field.name);
      }
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
