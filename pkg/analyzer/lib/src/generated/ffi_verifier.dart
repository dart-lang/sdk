// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/utilities/legacy.dart';

/// A visitor used to find problems with the way the `dart:ffi` APIs are being
/// used. See 'pkg/vm/lib/transformations/ffi_checks.md' for the specification
/// of the desired hints.
class FfiVerifier extends RecursiveAstVisitor<void> {
  static const _abiSpecificIntegerClassName = 'AbiSpecificInteger';
  static const _abiSpecificIntegerMappingClassName =
      'AbiSpecificIntegerMapping';
  static const _allocatorClassName = 'Allocator';
  static const _allocateExtensionMethodName = 'call';
  static const _allocatorExtensionName = 'AllocatorAlloc';
  static const _arrayClassName = 'Array';
  static const _dartFfiLibraryName = 'dart.ffi';
  static const _finalizableClassName = 'Finalizable';
  static const _isLeafParamName = 'isLeaf';
  static const _opaqueClassName = 'Opaque';

  static const Set<String> _primitiveIntegerNativeTypesFixedSize = {
    'Int8',
    'Int16',
    'Int32',
    'Int64',
    'Uint8',
    'Uint16',
    'Uint32',
    'Uint64',
  };
  static const Set<String> _primitiveIntegerNativeTypes = {
    ..._primitiveIntegerNativeTypesFixedSize,
    'IntPtr'
  };

  static const Set<String> _primitiveDoubleNativeTypes = {
    'Float',
    'Double',
  };

  static const _primitiveBoolNativeType = 'Bool';

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
      final NamedType superclass = extendsClause.superclass;
      final ffiClass = superclass.ffiClass;
      if (ffiClass != null) {
        final className = ffiClass.name;
        if (className == _structClassName || className == _unionClassName) {
          inCompound = true;
          compound = node;
          if (node.declaredElement!.isEmptyStruct) {
            _errorReporter.reportErrorForToken(
                FfiCode.EMPTY_STRUCT, node.name, [node.name.lexeme, className]);
          }
          if (className == _structClassName) {
            _validatePackedAnnotation(node.metadata);
          }
        } else if (className == _abiSpecificIntegerClassName) {
          _validateAbiSpecificIntegerAnnotation(node);
          _validateAbiSpecificIntegerMappingAnnotation(
              node.name, node.metadata);
        } else if (className != _allocatorClassName &&
            className != _opaqueClassName &&
            className != _abiSpecificIntegerClassName) {
          _errorReporter.reportErrorForNode(
              FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS,
              superclass.name,
              [node.name.lexeme, superclass.name.name]);
        }
      } else if (superclass.isCompoundSubtype ||
          superclass.isAbiSpecificIntegerSubtype) {
        _errorReporter.reportErrorForNode(
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS,
            superclass,
            [node.name.lexeme, superclass.name.name]);
      }
    }

    // No classes from the FFI may be explicitly implemented.
    void checkSupertype(NamedType typename, FfiCode subtypeOfFfiCode,
        FfiCode subtypeOfStructCode) {
      final superName = typename.name.staticElement?.name;
      if (superName == _allocatorClassName ||
          superName == _finalizableClassName) {
        return;
      }
      if (typename.ffiClass != null) {
        _errorReporter.reportErrorForNode(subtypeOfFfiCode, typename,
            [node.name.lexeme, typename.name.toSource()]);
      } else if (typename.isCompoundSubtype ||
          typename.isAbiSpecificIntegerSubtype) {
        _errorReporter.reportErrorForNode(subtypeOfStructCode, typename,
            [node.name.lexeme, typename.name.toSource()]);
      }
    }

    var implementsClause = node.implementsClause;
    if (implementsClause != null) {
      for (NamedType type in implementsClause.interfaces) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS,
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS);
      }
    }
    var withClause = node.withClause;
    if (withClause != null) {
      for (NamedType type in withClause.mixinTypes) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH,
            FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH);
      }
    }

    if (inCompound) {
      if (node.declaredElement!.typeParameters.isNotEmpty) {
        _errorReporter.reportErrorForToken(
            FfiCode.GENERIC_STRUCT_SUBCLASS, node.name, [node.name.lexeme]);
      }
      final implementsClause = node.implementsClause;
      if (implementsClause != null) {
        final compoundType = node.declaredElement!.thisType;
        final structType = compoundType.superclass!;
        final ffiLibrary = structType.element.library;
        final finalizableElement = ffiLibrary.getClass(_finalizableClassName)!;
        final finalizableType = finalizableElement.thisType;
        if (typeSystem.isSubtypeOf(compoundType, finalizableType)) {
          _errorReporter.reportErrorForToken(
              FfiCode.COMPOUND_IMPLEMENTS_FINALIZABLE,
              node.name,
              [node.name.lexeme]);
        }
      }
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (!noSoundNullSafety &&
        !typeSystem.isNonNullableByDefault &&
        inCompound) {
      _errorReporter.reportErrorForNode(
        FfiCode.FIELD_INITIALIZER_IN_STRUCT,
        node,
      );
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
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkFfiNative(
      errorNode: node,
      annotations: node.metadata,
      declarationElement: node.declaredElement!,
      formalParameterList: node.functionExpression.parameters,
    );
    super.visitFunctionDeclaration(node);
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
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructor = node.constructorName.staticElement;
    var class_ = constructor?.enclosingElement;
    if (class_.isStructSubclass || class_.isUnionSubclass) {
      _errorReporter.reportErrorForNode(
        FfiCode.CREATION_OF_STRUCT_OR_UNION,
        node.constructorName,
      );
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkFfiNative(
        errorNode: node,
        annotations: node.metadata,
        declarationElement: node.declaredElement!,
        formalParameterList: node.parameters);
    super.visitMethodDeclaration(node);
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

  void _checkFfiNative({
    required Declaration errorNode,
    required List<Annotation> annotations,
    required ExecutableElement declarationElement,
    required FormalParameterList? formalParameterList,
  }) {
    final formalParameters =
        formalParameterList?.parameters ?? <FormalParameter>[];

    for (Annotation annotation in annotations) {
      if (!annotation.isFfiNative) {
        continue;
      }

      final typeArguments = annotation.typeArguments?.arguments;
      final arguments = annotation.arguments?.arguments;
      if (typeArguments == null || arguments == null) {
        continue;
      }

      final ffiSignature = typeArguments[0].type! as FunctionType;

      // Leaf call FFI Natives can't use Handles.
      _validateFfiLeafCallUsesNoHandles(arguments, ffiSignature, errorNode);

      if (!declarationElement.isExternal) {
        _errorReporter.reportErrorForNode(
            FfiCode.FFI_NATIVE_MUST_BE_EXTERNAL, errorNode);
      }

      var ffiParameterTypes = ffiSignature.normalParameterTypes;
      var ffiParameters = ffiSignature.parameters;

      if ((declarationElement is MethodElement ||
              declarationElement is PropertyAccessorElementImpl) &&
          !declarationElement.isStatic) {
        // Instance methods must have the receiver as an extra parameter in the
        // FfiNative annotation.
        if (formalParameters.length + 1 != ffiSignature.parameters.length) {
          _errorReporter.reportErrorForNode(
              FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER,
              errorNode,
              [formalParameters.length + 1, ffiSignature.parameters.length]);
          return;
        }

        // Receiver can only be Pointer if the class extends
        // NativeFieldWrapperClass1.
        if (ffiSignature.normalParameterTypes[0].isPointer) {
          final cls = declarationElement.enclosingElement as InterfaceElement;
          if (!_extendsNativeFieldWrapperClass1(cls.thisType)) {
            _errorReporter.reportErrorForNode(
                FfiCode
                    .FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER,
                errorNode);
          }
        }

        ffiParameterTypes = ffiParameterTypes.sublist(1);
        ffiParameters = ffiParameters.sublist(1);
      } else {
        // Number of parameters in the FfiNative annotation must match the
        // annotated declaration.
        if (formalParameters.length != ffiSignature.parameters.length) {
          _errorReporter.reportErrorForNode(
              FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS,
              errorNode,
              [ffiSignature.parameters.length, formalParameters.length]);
          return;
        }
      }

      // Arguments can only be Pointer if the class extends
      // Pointer or NativeFieldWrapperClass1.
      for (var i = 0; i < formalParameters.length; i++) {
        if (ffiParameterTypes[i].isPointer) {
          final type =
              formalParameters[i].declaredElement!.type as InterfaceType;
          if (!type.isPointer && !_extendsNativeFieldWrapperClass1(type)) {
            _errorReporter.reportErrorForNode(
                FfiCode
                    .FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER,
                errorNode);
          }
        }
      }

      final dartType = declarationElement.type;
      final nativeType = FunctionTypeImpl(
        typeFormals: ffiSignature.typeFormals,
        parameters: ffiParameters,
        returnType: ffiSignature.returnType,
        nullabilitySuffix: ffiSignature.nullabilitySuffix,
      );
      if (!_isValidFfiNativeFunctionType(nativeType)) {
        _errorReporter.reportErrorForNode(
            FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
            errorNode,
            [nativeType, 'FfiNative']);
        return;
      }
      if (!_validateCompatibleFunctionTypes(dartType, nativeType,
          nativeFieldWrappersAsPointer: true, allowStricterReturn: true)) {
        _errorReporter.reportErrorForNode(FfiCode.MUST_BE_A_SUBTYPE, errorNode,
            [nativeType, dartType, 'FfiNative']);
        return;
      }
    }
  }

  bool _extendsNativeFieldWrapperClass1(InterfaceType? type) {
    while (type != null) {
      if (type.getDisplayString(withNullability: false) ==
          'NativeFieldWrapperClass1') {
        return true;
      }
      final element = type.element;
      type = element.supertype;
    }
    return false;
  }

  bool _isConst(Expression expr) {
    if (expr is Literal) {
      return true;
    }
    if (expr is Identifier) {
      final staticElm = expr.staticElement;
      if (staticElm is ConstVariableElement) {
        return true;
      }
      if (staticElm is PropertyAccessorElementImpl) {
        if (staticElm.variable is ConstVariableElement) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns `true` if [nativeType] is a C type that has a size.
  bool _isSized(DartType nativeType) {
    switch (_primitiveNativeType(nativeType)) {
      case _PrimitiveDartType.double:
        return true;
      case _PrimitiveDartType.int:
        return true;
      case _PrimitiveDartType.bool:
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
    if (nativeType.isAbiSpecificIntegerSubtype) {
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

      for (final DartType typeArg
          in nativeType.normalParameterTypes.flattenVarArgs()) {
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
        case _PrimitiveDartType.bool:
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
      if (nativeType.isAbiSpecificIntegerSubtype) {
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

  /// Get the const bool value of [expr] if it exists.
  /// Return null if it isn't a const bool.
  bool? _maybeGetBoolConstValue(Expression expr) {
    if (expr is BooleanLiteral) {
      return expr.value;
    }
    if (expr is Identifier) {
      final staticElm = expr.staticElement;
      if (staticElm is ConstVariableElement) {
        return staticElm.computeConstantValue()?.toBoolValue();
      }
      if (staticElm is PropertyAccessorElementImpl) {
        final v = staticElm.variable;
        if (v is ConstVariableElement) {
          return v.computeConstantValue()?.toBoolValue();
        }
      }
    }
    return null;
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
        if (name == _primitiveBoolNativeType) {
          return _PrimitiveDartType.bool;
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
      } else if (_primitiveBoolNativeType == name) {
        return _PrimitiveDartType.bool;
      }
      if (element.type.returnType.isAbiSpecificIntegerSubtype) {
        return _PrimitiveDartType.int;
      }
    }
    return _PrimitiveDartType.none;
  }

  void _validateAbiSpecificIntegerAnnotation(ClassDeclaration node) {
    if ((node.typeParameters?.length ?? 0) != 0 ||
        node.members.length != 1 ||
        node.members.single is! ConstructorDeclaration ||
        (node.members.single as ConstructorDeclaration).constKeyword == null) {
      _errorReporter.reportErrorForToken(
          FfiCode.ABI_SPECIFIC_INTEGER_INVALID, node.name);
    }
  }

  /// Validate that the [annotations] include at most one mapping annotation.
  void _validateAbiSpecificIntegerMappingAnnotation(
      Token errorToken, NodeList<Annotation> annotations) {
    final ffiPackedAnnotations = annotations
        .where((annotation) => annotation.isAbiSpecificIntegerMapping)
        .toList();

    if (ffiPackedAnnotations.isEmpty) {
      _errorReporter.reportErrorForToken(
          FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_MISSING, errorToken);
      return;
    }

    if (ffiPackedAnnotations.length > 1) {
      final extraAnnotations = ffiPackedAnnotations.skip(1);
      for (final annotation in extraAnnotations) {
        _errorReporter.reportErrorForNode(
            FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_EXTRA, annotation.name);
      }
    }

    var annotation = ffiPackedAnnotations.first;

    final arguments = annotation.arguments?.arguments;
    if (arguments == null) {
      return;
    }

    for (final argument in arguments) {
      if (argument is SetOrMapLiteral) {
        for (final element in argument.elements) {
          if (element is MapLiteralEntry) {
            final valueType = element.value.staticType;
            if (valueType is InterfaceType) {
              final name = valueType.element.name;
              if (!_primitiveIntegerNativeTypesFixedSize.contains(name)) {
                _errorReporter.reportErrorForNode(
                  FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED,
                  element.value,
                  [name],
                );
              }
            }
          }
        }
        return;
      }
    }
    final annotationConstant =
        annotation.elementAnnotation?.computeConstantValue();
    final mappingValues = annotationConstant?.getField('mapping')?.toMapValue();
    if (mappingValues == null) {
      return;
    }
    for (final nativeType in mappingValues.values) {
      final type = nativeType?.type;
      if (type is InterfaceType) {
        final nativeTypeName = type.element.name;
        if (!_primitiveIntegerNativeTypesFixedSize.contains(nativeTypeName)) {
          _errorReporter.reportErrorForNode(
            FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED,
            arguments.first,
            [nativeTypeName],
          );
        }
      }
    }
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
  void _validateAnnotations(TypeAnnotation errorNode,
      NodeList<Annotation> annotations, _PrimitiveDartType requiredType) {
    bool requiredFound = false;
    List<Annotation> extraAnnotations = [];
    for (Annotation annotation in annotations) {
      if (annotation.element.ffiClass != null ||
          annotation.element?.enclosingElement.isAbiSpecificIntegerSubclass ==
              true) {
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
          FfiCode.MISSING_ANNOTATION_ON_STRUCT_FIELD,
          errorNode,
          [errorNode.type!, compound!.extendsClause!.superclass.name.name]);
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
      if (!T.isNativeFunction) {
        return;
      }
      final DartType pointerTypeArg = (T as InterfaceType).typeArguments.single;
      if (pointerTypeArg is TypeParameterType) {
        _errorReporter.reportErrorForNode(
            FfiCode.NON_CONSTANT_TYPE_ARGUMENT, target, ['asFunction']);
        return;
      }
      if (!_isValidFfiNativeFunctionType(pointerTypeArg)) {
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
      _validateFfiLeafCallUsesNoHandles(
          node.argumentList.arguments, TPrime, node);
    }
    _validateIsLeafIsConst(node);
  }

  /// Validates that the given [nativeType] is, when native types are converted
  /// to their Dart equivalent, a subtype of [dartType].
  bool _validateCompatibleFunctionTypes(
    DartType dartType,
    DartType nativeType, {
    bool nativeFieldWrappersAsPointer = false,
    bool allowStricterReturn = false,
  }) {
    // We require both to be valid function types.
    if (dartType is! FunctionType ||
        dartType.isDartCoreFunction ||
        nativeType is! FunctionType ||
        nativeType.isDartCoreFunction) {
      return false;
    }

    final nativeTypeNormalParameterTypes =
        nativeType.normalParameterTypes.flattenVarArgs();

    // We disallow any optional parameters.
    final int parameterCount = dartType.normalParameterTypes.length;
    if (parameterCount != nativeTypeNormalParameterTypes.length) {
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
        dartType.returnType, nativeType.returnType)) {
      // TODO(http://dartbug.com/49518): Fix inconsistency between `FfiNative`
      // and `asFunction`.
      if (!allowStricterReturn) {
        return false;
      } else if (!_validateCompatibleNativeType(
          dartType.returnType, nativeType.returnType,
          checkCovariance: true)) {
        return false;
      }
    }

    // Validate that the parameter types are compatible.
    for (int i = 0; i < parameterCount; ++i) {
      if (!_validateCompatibleNativeType(
        dartType.normalParameterTypes[i],
        nativeTypeNormalParameterTypes[i],
        checkCovariance: true,
        nativeFieldWrappersAsPointer: nativeFieldWrappersAsPointer,
      )) {
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
    DartType dartType,
    DartType nativeType, {
    bool checkCovariance = false,
    bool nativeFieldWrappersAsPointer = false,
  }) {
    final nativeReturnType = _primitiveNativeType(nativeType);
    if (nativeReturnType == _PrimitiveDartType.int ||
        (nativeType is InterfaceType &&
            nativeType.superclass?.element.name ==
                _abiSpecificIntegerClassName)) {
      return dartType.isDartCoreInt;
    } else if (nativeReturnType == _PrimitiveDartType.double) {
      return dartType.isDartCoreDouble;
    } else if (nativeReturnType == _PrimitiveDartType.bool) {
      return dartType.isDartCoreBool;
    } else if (nativeReturnType == _PrimitiveDartType.void_) {
      return dartType is VoidType;
    } else if (dartType is VoidType) {
      // Don't allow other native subtypes if the Dart return type is void.
      return nativeReturnType == _PrimitiveDartType.void_;
    } else if (nativeReturnType == _PrimitiveDartType.handle) {
      InterfaceType objectType = typeSystem.objectStar;
      return checkCovariance
          ? /* everything is subtype of objectStar */ true
          : typeSystem.isSubtypeOf(objectType, dartType);
    } else if (dartType is InterfaceType && nativeType is InterfaceType) {
      if (nativeFieldWrappersAsPointer &&
          _extendsNativeFieldWrapperClass1(dartType)) {
        // Must be `Pointer<Void>`, `Handle` already checked above.
        return nativeType.isPointer &&
            _primitiveNativeType(nativeType.typeArguments.single) ==
                _PrimitiveDartType.void_;
      }
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

  void _validateFfiLeafCallUsesNoHandles(
      NodeList<Expression> args, DartType nativeType, AstNode errorNode) {
    if (args.isEmpty) {
      return;
    }
    for (final arg in args) {
      if (arg is! NamedExpression || arg.element?.name != _isLeafParamName) {
        continue;
      }
      // Handles are ok for regular (non-leaf) calls. Check `isLeaf:true`.
      final bool? isLeaf = _maybeGetBoolConstValue(arg.expression);
      if (isLeaf != null && isLeaf) {
        if (nativeType is FunctionType) {
          if (_primitiveNativeType(nativeType.returnType) ==
              _PrimitiveDartType.handle) {
            _errorReporter.reportErrorForNode(
                FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, errorNode);
          }
          for (final param in nativeType.normalParameterTypes) {
            if (_primitiveNativeType(param) == _PrimitiveDartType.handle) {
              _errorReporter.reportErrorForNode(
                  FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, errorNode);
            }
          }
        }
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

    if (typeSystem.isNonNullableByDefault) {
      if (node.externalKeyword == null) {
        _errorReporter.reportErrorForToken(
          FfiCode.FIELD_MUST_BE_EXTERNAL_IN_STRUCT,
          fields.variables[0].name,
        );
      }
    }

    var fieldType = fields.type;
    if (fieldType == null) {
      _errorReporter.reportErrorForToken(
          FfiCode.MISSING_FIELD_TYPE_IN_STRUCT, fields.variables[0].name);
    } else {
      DartType declaredType = fieldType.typeOrThrow;
      if (declaredType.nullabilitySuffix == NullabilitySuffix.question) {
        _errorReporter.reportErrorForNode(FfiCode.INVALID_FIELD_TYPE_IN_STRUCT,
            fieldType, [fieldType.toSource()]);
      } else if (declaredType.isDartCoreInt) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.int);
      } else if (declaredType.isDartCoreDouble) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.double);
      } else if (declaredType.isDartCoreBool) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.bool);
      } else if (declaredType.isPointer) {
        _validateNoAnnotations(annotations);
      } else if (declaredType.isArray) {
        final typeArg = (declaredType as InterfaceType).typeArguments.single;
        if (!_isSized(typeArg)) {
          AstNode errorNode = fieldType;
          if (fieldType is NamedType) {
            var typeArguments = fieldType.typeArguments?.arguments;
            if (typeArguments != null && typeArguments.isNotEmpty) {
              errorNode = typeArguments[0];
            }
          }
          _errorReporter.reportErrorForNode(FfiCode.NON_SIZED_TYPE_ARGUMENT,
              errorNode, [_arrayClassName, typeArg]);
        }
        final arrayDimensions = declaredType.arrayDimensions;
        _validateSizeOfAnnotation(fieldType, annotations, arrayDimensions);
      } else if (declaredType.isCompoundSubtype) {
        final clazz = (declaredType as InterfaceType).element;
        if (clazz.isEmptyStruct) {
          _errorReporter.reportErrorForNode(FfiCode.EMPTY_STRUCT, node, [
            clazz.name,
            clazz.supertype!.getDisplayString(withNullability: false)
          ]);
        }
      } else {
        _errorReporter.reportErrorForNode(FfiCode.INVALID_FIELD_TYPE_IN_STRUCT,
            fieldType, [fieldType.toSource()]);
      }
    }

    if (!noSoundNullSafety && !typeSystem.isNonNullableByDefault) {
      for (VariableDeclaration field in fields.variables) {
        if (field.initializer != null) {
          _errorReporter.reportErrorForToken(
            FfiCode.FIELD_IN_STRUCT_WITH_INITIALIZER,
            field.name,
          );
        }
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
      AstNode errorNode = node.methodName;
      var typeArgument = node.typeArguments?.arguments[0];
      if (typeArgument != null) {
        errorNode = typeArgument;
      }
      _errorReporter.reportErrorForNode(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
          errorNode, [T, 'fromFunction']);
      return;
    }

    Expression f = node.argumentList.arguments[0];
    DartType FT = f.typeOrThrow;
    if (!_validateCompatibleFunctionTypes(FT, T)) {
      _errorReporter.reportErrorForNode(
          FfiCode.MUST_BE_A_SUBTYPE, f, [FT, T, 'fromFunction']);
      return;
    }

    // TODO(brianwilkerson) Validate that `f` is a top-level function.
    final DartType R = (T as FunctionType).returnType;
    if ((FT as FunctionType).returnType is VoidType ||
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
      var eType = e.typeOrThrow;
      if (!_validateCompatibleNativeType(eType, R, checkCovariance: true)) {
        _errorReporter.reportErrorForNode(
            FfiCode.MUST_BE_A_SUBTYPE, e, [eType, R, 'fromFunction']);
      }
      if (!_isConst(e)) {
        _errorReporter.reportErrorForNode(
            FfiCode.ARGUMENT_MUST_BE_A_CONSTANT, e, ['exceptionalReturn']);
      }
    }
  }

  /// Ensure `isLeaf` is const as we need the value at compile time to know
  /// which trampoline to generate.
  void _validateIsLeafIsConst(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (args.isNotEmpty) {
      for (final arg in args) {
        if (arg is NamedExpression) {
          if (arg.element?.name == _isLeafParamName) {
            if (!_isConst(arg.expression)) {
              _errorReporter.reportErrorForNode(
                  FfiCode.ARGUMENT_MUST_BE_A_CONSTANT,
                  arg.expression,
                  [_isLeafParamName]);
            }
          }
        }
      }
    }
  }

  /// Validate the invocation of the instance method
  /// `DynamicLibrary.lookupFunction<S, F>()`.
  void _validateLookupFunction(MethodInvocation node) {
    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    final List<DartType> argTypes = node.typeArgumentTypes!;
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
    _validateIsLeafIsConst(node);
    _validateFfiLeafCallUsesNoHandles(
        node.argumentList.arguments, S, typeArguments[0]);
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
      AstNode errorNode = annotation;
      var arguments = annotation.arguments?.arguments;
      if (arguments != null && arguments.isNotEmpty) {
        errorNode = arguments[0];
      }
      _errorReporter.reportErrorForNode(
          FfiCode.PACKED_ANNOTATION_ALIGNMENT, errorNode);
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

    // Check dimensions are positive
    List<AstNode>? getArgumentNodes() {
      var arguments = annotation.arguments?.arguments;
      if (arguments != null && arguments.length == 1) {
        var firstArgument = arguments[0];
        if (firstArgument is ListLiteral) {
          return firstArgument.elements;
        }
      }
      return arguments;
    }

    for (int i = 0; i < dimensions.length; i++) {
      if (dimensions[i] <= 0) {
        AstNode errorNode = annotation;
        var argumentNodes = getArgumentNodes();
        if (argumentNodes != null && argumentNodes.isNotEmpty) {
          errorNode = argumentNodes[i];
        }
        _errorReporter.reportErrorForNode(
            FfiCode.NON_POSITIVE_ARRAY_DIMENSION, errorNode);
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
  bool,
  void_,
  handle,
  none,
}

extension on Annotation {
  bool get isAbiSpecificIntegerMapping {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name ==
            FfiVerifier._abiSpecificIntegerMappingClassName;
  }

  bool get isArray {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Array';
  }

  bool get isFfiNative {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        (element.enclosingElement.name == 'Native' ||
            element.enclosingElement.name == 'FfiNative');
  }

  bool get isPacked {
    final element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Packed';
  }
}

extension on ElementAnnotation {
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

  int? get packedMemberAlignment {
    assert(isPacked);
    final value = computeConstantValue();
    return value?.getField('memberAlignment')?.toIntValue();
  }
}

extension on Element? {
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

  /// Return `true` if this represents the class `AbiSpecificInteger`.
  bool get isAbiSpecificInteger {
    final element = this;
    return element is ClassElement &&
        element.name == FfiVerifier._abiSpecificIntegerClassName &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class
  /// `AbiSpecificInteger`.
  bool get isAbiSpecificIntegerSubclass {
    final element = this;
    return element is ClassElement && element.supertype.isAbiSpecificInteger;
  }

  /// Return `true` if this represents the extension `AllocatorAlloc`.
  bool get isAllocatorExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == FfiVerifier._allocatorExtensionName &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the extension `DynamicLibraryExtension`.
  bool get isDynamicLibraryExtension {
    final element = this;
    return element is ExtensionElement &&
        element.name == 'DynamicLibraryExtension' &&
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

  /// Return `true` if this represents the class `Pointer`.
  bool get isPointer {
    final element = this;
    return element is ClassElement &&
        element.name == 'Pointer' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the class `Struct`.
  bool get isStruct {
    final element = this;
    return element is ClassElement &&
        element.name == 'Struct' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class `Struct`.
  bool get isStructSubclass {
    final element = this;
    return element is ClassElement && element.supertype.isStruct;
  }

  /// Return `true` if this represents the class `Union`.
  bool get isUnion {
    final element = this;
    return element is ClassElement &&
        element.name == 'Union' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class `Struct`.
  bool get isUnionSubclass {
    final element = this;
    return element is ClassElement && element.supertype.isUnion;
  }
}

extension on InterfaceElement {
  bool get isEmptyStruct {
    for (final field in fields) {
      final declaredType = field.type;
      if (declaredType.isDartCoreInt) {
        return false;
      } else if (declaredType.isDartCoreDouble) {
        return false;
      } else if (declaredType.isDartCoreBool) {
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
}

extension on ExtensionElement {
  bool get isFfiExtension {
    return library.name == FfiVerifier._dartFfiLibraryName;
  }
}

extension on DartType? {
  bool get isAbiSpecificInteger {
    final self = this;
    return self is InterfaceType && self.element.isAbiSpecificInteger;
  }

  bool get isStruct {
    final self = this;
    return self is InterfaceType && self.element.isStruct;
  }

  bool get isUnion {
    final self = this;
    return self is InterfaceType && self.element.isUnion;
  }
}

extension on DartType {
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

  bool get isAbiSpecificInteger {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      final name = element.name;
      return name == FfiVerifier._abiSpecificIntegerClassName &&
          element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is an Abi-specific integer type,
  /// i.e. a subtype of `AbiSpecificInteger`.
  bool get isAbiSpecificIntegerSubtype {
    final self = this;
    if (self is InterfaceType) {
      final superType = self.element.supertype;
      if (superType != null) {
        final superClassElement = superType.element;
        return superClassElement.name ==
                FfiVerifier._abiSpecificIntegerClassName &&
            superClassElement.isFfiClass;
      }
    }
    return false;
  }

  /// Return `true` if this represents the class `Array`.
  bool get isArray {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == FfiVerifier._arrayClassName && element.isFfiClass;
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

  bool get isPointer {
    final self = this;
    return self is InterfaceType && self.element.isPointer;
  }

  /// Returns `true` iff this is a `ffi.VarArgs` type.
  bool get isVarArgs {
    final self = this;
    if (self is InterfaceType) {
      final element = self.element;
      return element.name == 'VarArgs' && element.isFfiClass;
    }
    return false;
  }
}

extension on NamedType {
  /// If this is a name of class from `dart:ffi`, return it.
  ClassElement? get ffiClass {
    return name.staticElement.ffiClass;
  }

  /// Return `true` if this represents a subtype of `Struct` or `Union`.
  bool get isAbiSpecificIntegerSubtype {
    var element = name.staticElement;
    if (element is ClassElement) {
      return element.allSupertypes.any((e) => e.isAbiSpecificInteger);
    }
    return false;
  }

  /// Return `true` if this represents a subtype of `Struct` or `Union`.
  bool get isCompoundSubtype {
    var element = name.staticElement;
    if (element is ClassElement) {
      return element.allSupertypes.any((e) => e.isCompound);
    }
    return false;
  }
}

extension on List<DartType> {
  /// Removes the VarArgs from a DartType list.
  ///
  /// ```
  /// [Int8, Int8] -> [Int8, Int8]
  /// [Int8, VarArgs<(Int8,)>] -> [Int8, Int8]
  /// [Int8, VarArgs<(Int8, Int8)>] -> [Int8, Int8, Int8]
  /// ```
  List<DartType> flattenVarArgs() {
    if (isEmpty) {
      return this;
    }
    final last = this.last;
    if (!last.isVarArgs) {
      return this;
    }
    final typeArgument = (last as InterfaceType).typeArguments.single;
    if (typeArgument is! RecordType) {
      return this;
    }
    if (typeArgument.namedFields.isNotEmpty) {
      // Don't flatten if invalid record.
      return this;
    }
    return [
      ...take(length - 1),
      for (final field in typeArgument.positionalFields) field.type,
    ];
  }
}
