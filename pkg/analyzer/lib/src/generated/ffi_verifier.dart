// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/error/ffi_code.dart';

/// A visitor used to find problems with the way the `dart:ffi` APIs are being
/// used. See 'pkg/vm/lib/transformations/ffi_checks.md' for the specification
/// of the desired hints.
class FfiVerifier extends RecursiveAstVisitor<void> {
  static const _abiSpecificIntegerClassName = 'AbiSpecificInteger';
  static const _abiSpecificIntegerMappingClassName =
      'AbiSpecificIntegerMapping';
  static const _allocateExtensionMethodName = 'call';
  static const _allocatorClassName = 'Allocator';
  static const _allocatorExtensionName = 'AllocatorAlloc';
  static const _arrayClassName = 'Array';
  static const _dartFfiLibraryName = 'dart.ffi';
  static const _dartTypedDataLibraryName = 'dart.typed_data';
  static const _finalizableClassName = 'Finalizable';
  static const _isLeafParamName = 'isLeaf';
  static const _nativeAddressOf = 'Native.addressOf';
  static const _nativeCallable = 'NativeCallable';
  static const _opaqueClassName = 'Opaque';

  static const _addressOfExtensionNames = {
    ..._addressOfCompoundExtensionNames,
    ..._addressOfPrimitiveExtensionNames,
    ..._addressOfTypedDataExtensionNames,
  };

  static const _addressOfCompoundExtensionNames = {
    'ArrayAddress',
    'StructAddress',
    'UnionAddress',
  };

  static const _addressOfPrimitiveExtensionNames = {
    'BoolAddress',
    'DoubleAddress',
    'IntAddress',
  };

  static const _addressOfTypedDataExtensionNames = {
    'Float32ListAddress',
    'Float64ListAddress',
    'Int16ListAddress',
    'Int32ListAddress',
    'Int64ListAddress',
    'Int8ListAddress',
    'Uint16ListAddress',
    'Uint32ListAddress',
    'Uint64ListAddress',
    'Uint8ListAddress',
  };

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
    'IntPtr',
  };

  static const Set<String> _primitiveDoubleNativeTypes = {'Float', 'Double'};

  static const _primitiveBoolNativeType = 'Bool';

  static const _structClassName = 'Struct';

  static const _unionClassName = 'Union';

  /// The type system used to check types.
  final TypeSystemImpl typeSystem;

  /// Whether implicit casts should be reported as potential problems.
  final bool strictCasts;

  /// The diagnostic reporter used to report diagnostics.
  final DiagnosticReporter _diagnosticReporter;

  /// A flag indicating whether we are currently visiting inside a subclass of
  /// `Struct`.
  bool inCompound = false;

  /// Subclass of `Struct` or `Union` we are currently visiting, or `null`.
  ClassDeclaration? compound;

  /// The `Void` type from `dart:ffi`, or `null` if unresolved.
  InterfaceTypeImpl? ffiVoidType;

  /// Initialize a newly created verifier.
  FfiVerifier(
    this.typeSystem,
    this._diagnosticReporter, {
    required this.strictCasts,
  });

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    inCompound = false;
    compound = null;
    // Only the Allocator, Opaque and Struct class may be extended.
    var extendsClause = node.extendsClause;
    if (extendsClause != null) {
      NamedType superclass = extendsClause.superclass;
      var ffiClass = superclass.ffiClass;
      if (ffiClass != null) {
        var className = ffiClass.name;
        if (className == _structClassName || className == _unionClassName) {
          inCompound = true;
          compound = node;
          if (node.declaredFragment!.element.isEmptyStruct) {
            _diagnosticReporter.atToken(
              node.name,
              FfiCode.emptyStruct,
              arguments: [node.name.lexeme, className ?? '<null>'],
            );
          }
          if (className == _structClassName) {
            _validatePackedAnnotation(node.metadata);
          }
        } else if (className == _abiSpecificIntegerClassName) {
          _validateAbiSpecificIntegerAnnotation(node);
          _validateAbiSpecificIntegerMappingAnnotation(
            node.name,
            node.metadata,
          );
        }
      } else if (superclass.isCompoundSubtype ||
          superclass.isAbiSpecificIntegerSubtype) {
        _diagnosticReporter.atNode(
          superclass,
          FfiCode.subtypeOfStructClassInExtends,
          arguments: [node.name.lexeme, superclass.name.lexeme],
        );
      }
    }

    // No classes from the FFI may be explicitly implemented.
    void checkSupertype(NamedType typename, FfiCode subtypeOfStructCode) {
      var superName = typename.element?.name;
      if (superName == _allocatorClassName ||
          superName == _finalizableClassName) {
        return;
      }
      if (typename.isCompoundSubtype || typename.isAbiSpecificIntegerSubtype) {
        _diagnosticReporter.atNode(
          typename,
          subtypeOfStructCode,
          arguments: [node.name.lexeme, typename.name.lexeme],
        );
      }
    }

    var implementsClause = node.implementsClause;
    if (implementsClause != null) {
      for (NamedType type in implementsClause.interfaces) {
        checkSupertype(type, FfiCode.subtypeOfStructClassInImplements);
      }
    }
    var withClause = node.withClause;
    if (withClause != null) {
      for (NamedType type in withClause.mixinTypes) {
        checkSupertype(type, FfiCode.subtypeOfStructClassInWith);
      }
    }

    if (inCompound) {
      if (node.declaredFragment!.element.typeParameters.isNotEmpty) {
        _diagnosticReporter.atToken(
          node.name,
          FfiCode.genericStructSubclass,
          arguments: [node.name.lexeme],
        );
      }
      var implementsClause = node.implementsClause;
      if (implementsClause != null) {
        var compoundType = node.declaredFragment!.element.thisType;
        var structType = compoundType.superclass!;
        var ffiLibrary = structType.element.library;
        var finalizableElement = ffiLibrary.getClass(_finalizableClassName)!;
        var finalizableType = finalizableElement.thisType;
        if (typeSystem.isSubtypeOf(compoundType, finalizableType)) {
          _diagnosticReporter.atToken(
            node.name,
            FfiCode.compoundImplementsFinalizable,
            arguments: [node.name.lexeme],
          );
        }
      }
    }
    super.visitClassDeclaration(node);
    inCompound = false;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (inCompound) {
      _validateFieldsInCompound(node);
    }

    for (var declared in node.fields.variables) {
      var declaredElement = declared.declaredFragment?.element;
      if (declaredElement != null) {
        _checkFfiNative(
          errorNode: declared.name,
          declarationElement: declaredElement,
          formalParameterList: null,
          isExternal: node.externalKeyword != null,
          metadata: node.metadata,
        );
      }
    }

    super.visitFieldDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkFfiNative(
      errorNode: node.name,
      declarationElement: node.declaredFragment!.element,
      formalParameterList: node.functionExpression.parameters,
      metadata: node.metadata,
      isExternal: node.externalKeyword != null,
    );
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionExpressionInvocation(
    covariant FunctionExpressionInvocationImpl node,
  ) {
    var element = node.element;
    if (element is InternalMethodElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isAllocatorExtension &&
          element.name == _allocateExtensionMethodName) {
        _validateAllocate(node);
      }
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitIndexExpression(covariant IndexExpressionImpl node) {
    var element = node.element;
    if (element is MethodElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeStructArrayExtension ||
          enclosingElement.isNativeUnionPointerExtension ||
          enclosingElement.isNativeUnionArrayExtension) {
        if (element.name == '[]') {
          _validateRefIndexed(node);
        }
      }
    }
  }

  @override
  void visitInstanceCreationExpression(
    covariant InstanceCreationExpressionImpl node,
  ) {
    var constructor = node.constructorName.element;
    var class_ = constructor?.enclosingElement;
    if (class_.isStructSubclass || class_.isUnionSubclass) {
      if (!constructor!.isFactory) {
        _diagnosticReporter.atNode(
          node.constructorName,
          FfiCode.creationOfStructOrUnion,
        );
      }
    } else if (class_.isNativeCallable) {
      _validateNativeCallable(node);
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    // Ensure there is at most one @DefaultAsset annotation per library
    var hasDefaultAsset = false;

    if (node.element case LibraryElementImpl library) {
      for (var annotation in library.metadata.annotations) {
        var annotationValue = annotation.computeConstantValue();
        if (annotationValue != null && annotationValue.isDefaultAsset) {
          if (hasDefaultAsset) {
            var name = annotation.annotationAst.name;
            _diagnosticReporter.atNode(
              name,
              FfiCode.ffiNativeInvalidDuplicateDefaultAsset,
            );
          }

          hasDefaultAsset = true;
        }
      }
    }

    super.visitLibraryDirective(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkFfiNative(
      errorNode: node.name,
      declarationElement: node.declaredFragment!.element,
      formalParameterList: node.parameters,
      isExternal: node.externalKeyword != null,
      metadata: node.metadata,
    );
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(covariant MethodInvocationImpl node) {
    var element = node.methodName.element;
    if (element is InternalMethodElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isPointer) {
        if (element.name == 'fromFunction') {
          _validateFromFunction(node, element);
        } else if (element.name == 'elementAt') {
          _validateElementAt(node);
        }
      } else if (enclosingElement.isStruct || enclosingElement.isUnion) {
        if (element.name == 'create') {
          _validateCreate(node, enclosingElement!.name!);
        }
      } else if (enclosingElement.isNative) {
        if (element.name == 'addressOf') {
          _validateNativeAddressOf(node);
        }
      } else if (enclosingElement.isNativeFunctionPointerExtension) {
        if (element.name == 'asFunction') {
          _validateAsFunction(node, element);
        }
      } else if (enclosingElement.isDynamicLibraryExtension) {
        if (element.name == 'lookupFunction') {
          _validateLookupFunction(node);
        }
      } else if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeUnionPointerExtension) {
        if (element.name == 'refWithFinalizer') {
          _validateRefWithFinalizer(node);
        }
      }
    } else if (element is TopLevelFunctionElement) {
      if (element.library.name == 'dart.ffi') {
        if (element.name == 'sizeOf') {
          _validateSizeOf(node);
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(covariant PrefixedIdentifierImpl node) {
    var element = node.element;
    if (element != null) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeUnionPointerExtension) {
        if (element.name == 'ref') {
          _validateRefPrefixedIdentifier(node);
        }
      } else if (enclosingElement.isAddressOfExtension) {
        if (element.name == 'address') {
          _validateAddressPrefixedIdentifier(node);
        }
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(covariant PropertyAccessImpl node) {
    var element = node.propertyName.element;
    if (element != null) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeUnionPointerExtension) {
        if (element.name == 'ref') {
          _validateRefPropertyAccess(node);
        }
      } else if (enclosingElement.isAddressOfExtension) {
        if (element.name == 'address') {
          _validateAddressPropertyAccess(node);
        }
      }
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var declared in node.variables.variables) {
      var declaredElement = declared.declaredFragment?.element;
      if (declaredElement != null) {
        _checkFfiNative(
          errorNode: declared.name,
          declarationElement: declaredElement,
          formalParameterList: null,
          isExternal: node.externalKeyword != null,
          metadata: node.metadata,
        );
      }
    }
    super.visitTopLevelVariableDeclaration(node);
  }

  TypeImpl? _canonicalFfiTypeForDartType(TypeImpl dartType) {
    if (dartType.isPointer || dartType.isCompoundSubtype || dartType.isArray) {
      return dartType;
    } else {
      return null;
    }
  }

  void _checkFfiNative({
    required Token errorNode,
    required Element declarationElement,
    required NodeList<Annotation> metadata,
    required FormalParameterList? formalParameterList,
    required bool isExternal,
  }) {
    var formalParameters =
        formalParameterList?.parameters ?? <FormalParameter>[];
    var hadNativeAnnotation = false;

    for (var annotation in declarationElement.metadata.annotations) {
      var annotationValue = annotation.computeConstantValue();
      var annotationType = annotationValue?.type; // Native<T>

      if (annotationValue == null ||
          annotationType is! InterfaceTypeImpl ||
          !annotationValue.isNative) {
        continue;
      }

      if (hadNativeAnnotation) {
        var name = (annotation as ElementAnnotationImpl).annotationAst.name;
        _diagnosticReporter.atNode(
          name,
          FfiCode.ffiNativeInvalidMultipleAnnotations,
        );
        break;
      }

      hadNativeAnnotation = true;

      if (!isExternal) {
        _diagnosticReporter.atToken(errorNode, FfiCode.ffiNativeMustBeExternal);
      }

      var ffiSignature = annotationType.typeArguments[0]; // The T in @Native<T>

      if (ffiSignature is FunctionTypeImpl) {
        if (declarationElement is InternalExecutableElement) {
          _checkFfiNativeFunction(
            errorNode,
            declarationElement,
            ffiSignature,
            annotationValue,
            formalParameters,
          );
        } else {
          // Field annotated with a function type, that can't work.
          _diagnosticReporter.atToken(
            errorNode,
            FfiCode.nativeFieldInvalidType,
            arguments: [ffiSignature],
          );
        }
      } else {
        if (declarationElement
            case TopLevelFunctionElement() || MethodElement()) {
          declarationElement = declarationElement as InternalExecutableElement;
          var dartSignature = declarationElement.type;

          if (declarationElement.isStatic && ffiSignature is DynamicType) {
            // No type argument was given on the @Native annotation, so we try
            // to infer the native type from the Dart signature.
            if (dartSignature.returnType is VoidType) {
              // The Dart signature has a `void` return type, so we create a new
              // `FunctionType` with FFI's `Void` as the return type.
              dartSignature = FunctionTypeImpl.v2(
                typeParameters: dartSignature.typeParameters,
                formalParameters: dartSignature.formalParameters,
                returnType: ffiVoidType ??= annotationType.element.library
                    .getClass('Void')!
                    .thisType,
                nullabilitySuffix: dartSignature.nullabilitySuffix,
              );
            }
            _checkFfiNativeFunction(
              errorNode,
              declarationElement,
              dartSignature,
              annotationValue,
              formalParameters,
            );
            return;
          }

          // Function annotated with something that isn't a function type.
          _diagnosticReporter.atToken(
            errorNode,
            FfiCode.mustBeANativeFunctionType,
            arguments: ['T', 'Native'],
          );
        } else {
          _checkFfiNativeField(
            errorNode,
            declarationElement,
            metadata,
            ffiSignature,
            annotationValue,
            false,
          );
        }
      }
    }
  }

  void _checkFfiNativeField(
    Token errorToken,
    Element declarationElement,
    NodeList<Annotation> metadata,
    TypeImpl ffiSignature,
    DartObject annotationValue,
    bool allowVariableLength,
  ) {
    TypeImpl type;

    if (declarationElement is InternalFieldElement) {
      if (!declarationElement.isStatic) {
        _diagnosticReporter.atToken(errorToken, FfiCode.nativeFieldNotStatic);
      }
      type = declarationElement.type;
    } else if (declarationElement is TopLevelVariableElementImpl) {
      type = declarationElement.type;
    } else if (declarationElement is InternalPropertyAccessorElement) {
      type = declarationElement.variable.type;
    } else {
      _diagnosticReporter.atToken(errorToken, FfiCode.nativeFieldNotStatic);
      return;
    }

    if (ffiSignature is DynamicType) {
      // Attempt to infer the native type from the Dart type.
      var canonical = _canonicalFfiTypeForDartType(type);

      if (canonical == null) {
        _diagnosticReporter.atToken(errorToken, FfiCode.nativeFieldMissingType);
        return;
      } else {
        ffiSignature = canonical;
      }
    }

    if (!_validateCompatibleNativeType(
      _FfiTypeCheckDirection.nativeToDart,
      type,
      ffiSignature,
      // Functions are not allowed in native fields, but allowing them in the
      // subtype check allows reporting the more-specific diagnostic for the
      // invalid field type.
      allowFunctions: true,
    )) {
      _diagnosticReporter.atToken(
        errorToken,
        FfiCode.mustBeASubtype,
        arguments: [type, ffiSignature, 'Native'],
      );
    } else if (ffiSignature.isArray) {
      // Array fields need an `@Array` size annotation.
      _validateSizeOfAnnotation(
        errorToken,
        metadata,
        ffiSignature.arrayDimensions,
        allowVariableLength,
      );
    } else if (ffiSignature.isHandle || ffiSignature.isNativeFunction) {
      _diagnosticReporter.atToken(
        errorToken,
        FfiCode.nativeFieldInvalidType,
        arguments: [ffiSignature],
      );
    }
  }

  void _checkFfiNativeFunction(
    Token errorToken,
    InternalExecutableElement declarationElement,
    FunctionTypeImpl ffiSignature,
    DartObject annotationValue,
    List<FormalParameter> formalParameters,
  ) {
    // Leaf call FFI Natives can't use Handles.
    var isLeaf =
        annotationValue.getField(_isLeafParamName)?.toBoolValue() ?? false;
    if (isLeaf) {
      _validateFfiLeafCallUsesNoHandles(ffiSignature, errorToken);
    }

    var ffiParameterTypes = ffiSignature.normalParameterTypes.flattenVarArgs();
    var ffiParameters = ffiSignature.formalParameters;

    if ((declarationElement is MethodElement ||
            declarationElement is PropertyAccessorElement) &&
        !declarationElement.isStatic) {
      // Instance methods must have the receiver as an extra parameter in the
      // Native annotation.
      if (formalParameters.length + 1 != ffiParameterTypes.length) {
        _diagnosticReporter.atToken(
          errorToken,
          FfiCode.ffiNativeUnexpectedNumberOfParametersWithReceiver,
          arguments: [formalParameters.length + 1, ffiParameterTypes.length],
        );
        return;
      }

      // Receiver can only be Pointer if the class extends
      // NativeFieldWrapperClass1.
      if (ffiSignature.normalParameterTypes[0].isPointer) {
        var cls = declarationElement.enclosingElement as InterfaceElement;
        if (!_extendsNativeFieldWrapperClass1(cls.thisType)) {
          _diagnosticReporter.atToken(
            errorToken,
            FfiCode
                .ffiNativeOnlyClassesExtendingNativefieldwrapperclass1CanBePointer,
          );
        }
      }

      ffiParameterTypes = ffiParameterTypes.sublist(1);
      ffiParameters = ffiParameters.sublist(1);
    } else {
      // Number of parameters in the Native annotation must match the
      // annotated declaration.
      if (formalParameters.length != ffiParameterTypes.length) {
        _diagnosticReporter.atToken(
          errorToken,
          FfiCode.ffiNativeUnexpectedNumberOfParameters,
          arguments: [ffiParameterTypes.length, formalParameters.length],
        );
        return;
      }
    }

    // Arguments can only be Pointer if the class extends
    // Pointer or NativeFieldWrapperClass1.
    for (var i = 0; i < formalParameters.length; i++) {
      if (ffiParameterTypes[i].isPointer) {
        var type = formalParameters[i].declaredFragment!.element.type;
        if (type is! InterfaceType ||
            (!type.isPointer &&
                !_extendsNativeFieldWrapperClass1(type) &&
                !type.isTypedData)) {
          _diagnosticReporter.atToken(
            errorToken,
            FfiCode
                .ffiNativeOnlyClassesExtendingNativefieldwrapperclass1CanBePointer,
          );
        }
      }
    }

    var dartType = declarationElement.type;
    var nativeType = FunctionTypeImpl.v2(
      typeParameters: ffiSignature.typeParameters,
      formalParameters: ffiParameters,
      returnType: ffiSignature.returnType,
      nullabilitySuffix: ffiSignature.nullabilitySuffix,
    );
    if (!_isValidFfiNativeFunctionType(nativeType)) {
      var nativeTypeIsOmitted =
          (annotationValue.type! as InterfaceType).typeArguments[0]
              is DynamicType;
      if (nativeTypeIsOmitted) {
        _diagnosticReporter.atToken(
          errorToken,
          FfiCode.nativeFunctionMissingType,
        );
      } else {
        _diagnosticReporter.atToken(
          errorToken,
          FfiCode.mustBeANativeFunctionType,
          arguments: [nativeType, 'Native'],
        );
      }
      return;
    }
    if (!_validateCompatibleFunctionTypes(
      _FfiTypeCheckDirection.nativeToDart,
      dartType,
      nativeType,
      nativeFieldWrappersAsPointer: true,
    )) {
      _diagnosticReporter.atToken(
        errorToken,
        FfiCode.mustBeASubtype,
        arguments: [nativeType, dartType, 'Native'],
      );
      return;
    }
  }

  bool _extendsNativeFieldWrapperClass1(InterfaceType? type) {
    while (type != null) {
      if (type.getDisplayString() == 'NativeFieldWrapperClass1') {
        return true;
      }
      var element = type.element;
      type = element.supertype;
    }
    return false;
  }

  bool _isConst(Expression expr) {
    var computedConstant = expr.computeConstantValue();
    return computedConstant?.value != null;
  }

  bool _isLeaf(NodeList<Expression>? args) {
    if (args == null) {
      return false;
    }
    for (var arg in args) {
      if (arg is! NamedExpression || arg.element?.name != _isLeafParamName) {
        continue;
      }
      return _maybeGetBoolConstValue(arg.expression) ?? false;
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
  bool _isValidFfiNativeFunctionType(TypeImpl nativeType) {
    if (nativeType is FunctionTypeImpl && !nativeType.isDartCoreFunction) {
      if (nativeType.namedParameterTypes.isNotEmpty ||
          nativeType.optionalParameterTypes.isNotEmpty) {
        return false;
      }
      if (!_isValidFfiNativeType(
        nativeType.returnType,
        allowVoid: true,
        allowHandle: true,
      )) {
        return false;
      }

      for (var typeArg in nativeType.normalParameterTypes.flattenVarArgs()) {
        if (!_isValidFfiNativeType(typeArg, allowHandle: true)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// Validates that the given [nativeType] is a valid dart:ffi native type.
  bool _isValidFfiNativeType(
    TypeImpl? nativeType, {
    bool allowVoid = false,
    bool allowEmptyStruct = false,
    bool allowArray = false,
    bool allowHandle = false,
    bool allowOpaque = false,
  }) {
    if (nativeType is InterfaceTypeImpl) {
      var primitiveType = _primitiveNativeType(nativeType);
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
        var nativeArgumentType = nativeType.typeArguments.single;
        return _isValidFfiNativeType(
              nativeArgumentType,
              allowVoid: true,
              allowEmptyStruct: true,
              allowHandle: true,
              allowOpaque: true,
            ) ||
            nativeArgumentType.isCompoundSubtype ||
            nativeArgumentType.isNativeType;
      }
      if (nativeType.isCompoundSubtype) {
        if (!allowEmptyStruct) {
          if (nativeType.element.isEmptyStruct) {
            // TODO(dacoharkes): This results in an error message not  mentioning
            // empty structs at all.
            // dartbug.com/36780
            return false;
          }
        }
        return true;
      }
      if (nativeType.isOpaque) {
        return allowOpaque;
      }
      if (nativeType.isOpaqueSubtype) {
        return true;
      }
      if (nativeType.isAbiSpecificIntegerSubtype) {
        return true;
      }
      if (allowArray && nativeType.isArray) {
        return _isValidFfiNativeType(nativeType.typeArguments.single);
      }
    } else if (nativeType is FunctionTypeImpl) {
      return _isValidFfiNativeFunctionType(nativeType);
    }
    return false;
  }

  bool _isValidTypedData(InterfaceType nativeType, InterfaceType dartType) {
    if (nativeType.isPointer) {
      var elementType = nativeType.typeArguments.single;
      var elementName = elementType.element?.name;
      if (dartType.element.isTypedDataClass) {
        if (elementName == 'Float' && dartType.element.name == 'Float32List') {
          return true;
        }
        if (elementName == 'Double' && dartType.element.name == 'Float64List') {
          return true;
        }
        if (_primitiveIntegerNativeTypesFixedSize.contains(elementName) &&
            dartType.element.name == '${elementName}List') {
          return true;
        }
      }
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
      var element = expr.element;
      if (element is VariableElement && element.isConst) {
        return element.computeConstantValue()?.toBoolValue();
      }
      if (element is PropertyAccessorElement) {
        var variable = element.variable;
        if (variable.isConst) {
          return variable.computeConstantValue()?.toBoolValue();
        }
      }
    }
    return null;
  }

  _PrimitiveDartType _primitiveNativeType(DartType nativeType) {
    if (nativeType is InterfaceType) {
      var element = nativeType.element;
      if (element.isFfiClass) {
        var name = element.name;
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
      var name = element.enclosingElement.name;
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
      _diagnosticReporter.atToken(node.name, FfiCode.abiSpecificIntegerInvalid);
    }
  }

  /// Validate that the [annotations] include at most one mapping annotation.
  void _validateAbiSpecificIntegerMappingAnnotation(
    Token errorToken,
    NodeList<Annotation> annotations,
  ) {
    var ffiPackedAnnotations = annotations
        .where((annotation) => annotation.isAbiSpecificIntegerMapping)
        .toList();

    if (ffiPackedAnnotations.isEmpty) {
      _diagnosticReporter.atToken(
        errorToken,
        FfiCode.abiSpecificIntegerMappingMissing,
      );
      return;
    }

    if (ffiPackedAnnotations.length > 1) {
      var extraAnnotations = ffiPackedAnnotations.skip(1);
      for (var annotation in extraAnnotations) {
        _diagnosticReporter.atNode(
          annotation.name,
          FfiCode.abiSpecificIntegerMappingExtra,
        );
      }
    }

    var annotation = ffiPackedAnnotations.first;

    var arguments = annotation.arguments?.arguments;
    if (arguments == null) {
      return;
    }

    for (var argument in arguments) {
      if (argument is SetOrMapLiteral) {
        for (var element in argument.elements) {
          if (element is MapLiteralEntry) {
            var valueType = element.value.staticType;
            if (valueType is InterfaceType) {
              var name = valueType.element.name!;
              if (!_primitiveIntegerNativeTypesFixedSize.contains(name)) {
                _diagnosticReporter.atNode(
                  element.value,
                  FfiCode.abiSpecificIntegerMappingUnsupported,
                  arguments: [name],
                );
              }
            }
          }
        }
        return;
      }
    }
    var annotationConstant = annotation.elementAnnotation
        ?.computeConstantValue();
    var mappingValues = annotationConstant?.getField('mapping')?.toMapValue();
    if (mappingValues == null) {
      return;
    }
    for (var nativeType in mappingValues.values) {
      var type = nativeType?.type;
      if (type is InterfaceType) {
        var nativeTypeName = type.element.name!;
        if (!_primitiveIntegerNativeTypesFixedSize.contains(nativeTypeName)) {
          _diagnosticReporter.atNode(
            arguments.first,
            FfiCode.abiSpecificIntegerMappingUnsupported,
            arguments: [nativeTypeName],
          );
        }
      }
    }
  }

  /// Check that .address is only used in argument lists passed to native leaf
  /// calls.
  void _validateAddressPosition(Expression node, AstNode errorNode) {
    var parent = node.parent;
    // Since we are allowing .address.cast(), we need to traverse up one level
    // to get the ffi Invocation (.cast() nested down one level the expression)
    if (parent is MethodInvocation &&
        parent.methodName.element is MethodElement &&
        parent.methodName.name == "cast" &&
        parent.methodName.element?.enclosingElement is ClassElement &&
        parent.methodName.element!.enclosingElement.isPointer) {
      parent = parent.parent;
    }
    var grandParent = parent?.parent;
    if (parent is! ArgumentList ||
        grandParent is! MethodInvocation ||
        !grandParent.isNativeLeafInvocation) {
      _diagnosticReporter.atNode(errorNode, FfiCode.addressPosition);
    }
  }

  void _validateAddressPrefixedIdentifier(PrefixedIdentifier node) {
    var errorNode = node.identifier;
    _validateAddressPosition(node, errorNode);
    var extensionName = node.element?.enclosingElement?.name;
    var receiver = node.prefix;
    _validateAddressReceiver(node, extensionName, receiver, errorNode);
  }

  void _validateAddressPropertyAccess(PropertyAccess node) {
    var errorNode = node.propertyName;
    _validateAddressPosition(node, errorNode);
    var extensionName = node.propertyName.element?.enclosingElement?.name;
    var receiver = node.target;
    _validateAddressReceiver(node, extensionName, receiver, errorNode);
  }

  void _validateAddressReceiver(
    Expression node,
    String? extensionName,
    Expression? receiver,
    AstNode errorNode,
  ) {
    if (_addressOfCompoundExtensionNames.contains(extensionName) ||
        _addressOfTypedDataExtensionNames.contains(extensionName)) {
      return; // Only primitives need their reciever checked.
    }
    if (receiver == null) {
      return;
    }
    switch (receiver) {
      case IndexExpression _:
        // Array or TypedData element.
        var arrayOrTypedData = receiver.target;
        var type = arrayOrTypedData?.staticType;
        if (type?.isArray ?? false) {
          return;
        }
        if (type?.isTypedData ?? false) {
          return;
        }
      case PrefixedIdentifier _:
        // Struct or Union field.
        var compound = receiver.prefix;
        var type = compound.staticType;
        if (type?.isCompoundSubtype ?? false) {
          return;
        }
      case PropertyAccess _:
        // Struct or Union field.
        var compound = receiver.target;
        var type = compound?.staticType;
        if (type?.isCompoundSubtype ?? false) {
          return;
        }
      default:
    }
    _diagnosticReporter.atNode(errorNode, FfiCode.addressReceiver);
  }

  void _validateAllocate(FunctionExpressionInvocationImpl node) {
    var typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    var dartType = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(
      dartType,
      allowVoid: true,
      allowEmptyStruct: true,
    )) {
      AstNode errorNode = node;
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.nonConstantTypeArgument,
        arguments: ['$_allocatorExtensionName.$_allocateExtensionMethodName'],
      );
    }
  }

  /// Validate that the [annotations] include exactly one annotation that
  /// satisfies the [requiredType]. If an error is produced that cannot be
  /// associated with an annotation, associate it with the [errorNode].
  void _validateAnnotations(
    TypeAnnotation errorNode,
    NodeList<Annotation> annotations,
    _PrimitiveDartType requiredType,
  ) {
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
        _diagnosticReporter.atNode(
          invalidAnnotation,
          FfiCode.mismatchedAnnotationOnStructField,
        );
      }
      for (Annotation extraAnnotation in extraAnnotations) {
        _diagnosticReporter.atNode(
          extraAnnotation,
          FfiCode.extraAnnotationOnStructField,
        );
      }
    } else if (!requiredFound) {
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.missingAnnotationOnStructField,
        arguments: [
          errorNode.type!,
          compound!.extendsClause!.superclass.name.lexeme,
        ],
      );
    }
  }

  /// Validate the invocation of the instance method
  /// `Pointer<T>.asFunction<F>()`.
  void _validateAsFunction(
    covariant MethodInvocationImpl node,
    InternalMethodElement element,
  ) {
    var typeArguments = node.typeArguments?.arguments;
    AstNode errorNode = typeArguments != null ? typeArguments[0] : node;
    if (typeArguments != null && typeArguments.length == 1) {
      if (_validateTypeArgument(typeArguments[0], 'asFunction')) {
        return;
      }
    }
    var target = node.realTarget!;
    var targetType = target.staticType;
    if (targetType is InterfaceTypeImpl && targetType.isPointer) {
      var T = targetType.typeArguments[0];
      if (!T.isNativeFunction) {
        return;
      }
      var pointerTypeArg = (T as InterfaceTypeImpl).typeArguments.single;
      if (pointerTypeArg is TypeParameterType) {
        _diagnosticReporter.atNode(
          target,
          FfiCode.nonConstantTypeArgument,
          arguments: ['asFunction'],
        );
        return;
      }
      if (!_isValidFfiNativeFunctionType(pointerTypeArg)) {
        _diagnosticReporter.atNode(
          errorNode,
          FfiCode.nonNativeFunctionTypeArgumentToPointer,
          arguments: [T],
        );
        return;
      }

      var TPrime = T.typeArguments[0];
      var F = node.typeArgumentTypes![0];
      var isLeaf = _isLeaf(node.argumentList.arguments);
      if (!_validateCompatibleFunctionTypes(
        _FfiTypeCheckDirection.nativeToDart,
        F,
        TPrime,
      )) {
        _diagnosticReporter.atNode(
          node,
          FfiCode.mustBeASubtype,
          arguments: [TPrime, F, 'asFunction'],
        );
      }
      if (isLeaf) {
        _validateFfiLeafCallUsesNoHandles(TPrime, node.methodName.token);
      }
    }
    _validateIsLeafIsConst(node);
  }

  /// Validates that the given [nativeType] is, when native types are converted
  /// to their Dart equivalent, a subtype of [dartType].
  bool _validateCompatibleFunctionTypes(
    _FfiTypeCheckDirection direction,
    TypeImpl dartType,
    TypeImpl nativeType, {
    bool nativeFieldWrappersAsPointer = false,
  }) {
    // We require both to be valid function types.
    if (dartType is! FunctionTypeImpl ||
        dartType.isDartCoreFunction ||
        nativeType is! FunctionTypeImpl ||
        nativeType.isDartCoreFunction) {
      return false;
    }

    var nativeTypeNormalParameterTypes = nativeType.normalParameterTypes
        .flattenVarArgs();

    // We disallow any optional parameters.
    int parameterCount = dartType.normalParameterTypes.length;
    if (parameterCount != nativeTypeNormalParameterTypes.length) {
      return false;
    }
    // We disallow generic function types.
    if (dartType.typeParameters.isNotEmpty ||
        nativeType.typeParameters.isNotEmpty) {
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
      direction,
      dartType.returnType,
      nativeType.returnType,
    )) {
      return false;
    }

    // Validate that the parameter types are compatible.
    for (int i = 0; i < parameterCount; ++i) {
      if (!_validateCompatibleNativeType(
        direction.reverse,
        dartType.normalParameterTypes[i],
        nativeTypeNormalParameterTypes[i],
        nativeFieldWrappersAsPointer: nativeFieldWrappersAsPointer,
      )) {
        return false;
      }
    }

    // Signatures have same number of parameters and the types match.
    return true;
  }

  /// Validates that the [nativeType] can be converted to the [dartType] if
  /// [direction] is [_FfiTypeCheckDirection.nativeToDart], or the reverse for
  /// [_FfiTypeCheckDirection.dartToNative].
  bool _validateCompatibleNativeType(
    _FfiTypeCheckDirection direction,
    TypeImpl dartType,
    TypeImpl nativeType, {
    bool nativeFieldWrappersAsPointer = false,
    bool allowFunctions = false,
  }) {
    var nativeReturnType = _primitiveNativeType(nativeType);
    if (nativeReturnType == _PrimitiveDartType.int ||
        (nativeType is InterfaceTypeImpl &&
            nativeType.superclass?.element.name ==
                _abiSpecificIntegerClassName)) {
      return dartType.isDartCoreInt;
    } else if (nativeReturnType == _PrimitiveDartType.double) {
      return dartType.isDartCoreDouble;
    } else if (nativeReturnType == _PrimitiveDartType.bool) {
      return dartType.isDartCoreBool;
    } else if (nativeReturnType == _PrimitiveDartType.void_) {
      return direction == _FfiTypeCheckDirection.dartToNative ||
          dartType is VoidType;
    } else if (dartType is VoidType) {
      // Don't allow other native subtypes if the Dart return type is void.
      return nativeReturnType == _PrimitiveDartType.void_;
    } else if (nativeReturnType == _PrimitiveDartType.handle) {
      // `Handle` matches against any type in positions of any variance.
      return true;
    } else if (dartType is InterfaceTypeImpl &&
        nativeType is InterfaceTypeImpl) {
      if (nativeFieldWrappersAsPointer &&
          _extendsNativeFieldWrapperClass1(dartType)) {
        // Must be `Pointer<Void>`, `Handle` already checked above.
        return nativeType.isPointer &&
            _primitiveNativeType(nativeType.typeArguments.single) ==
                _PrimitiveDartType.void_;
      }
      // Always allow typed data here, error on nonLeaf or return value in
      // `_validateFfiNonLeafCallUsesNoTypedData`.
      if (_isValidTypedData(nativeType, dartType)) {
        return true;
      }
      return direction == _FfiTypeCheckDirection.dartToNative
          ? typeSystem.isSubtypeOf(dartType, nativeType)
          : typeSystem.isSubtypeOf(nativeType, dartType);
    } else if (dartType is FunctionTypeImpl &&
        allowFunctions &&
        nativeType is InterfaceTypeImpl &&
        nativeType.isNativeFunction) {
      var nativeFunction = nativeType.typeArguments[0];
      return _validateCompatibleFunctionTypes(
        direction,
        dartType,
        nativeFunction,
        nativeFieldWrappersAsPointer: nativeFieldWrappersAsPointer,
      );
    } else {
      // If the [nativeType] is not a primitive int/double type then it has to
      // be a Pointer type atm.
      return false;
    }
  }

  void _validateCreate(MethodInvocationImpl node, String errorClass) {
    var typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    var dartType = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(dartType)) {
      AstNode errorNode = node;
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.nonConstantTypeArgument,
        arguments: ['$errorClass.create'],
      );
    }
  }

  void _validateElementAt(MethodInvocation node) {
    var targetType = node.realTarget?.staticType;
    if (targetType is InterfaceTypeImpl && targetType.isPointer) {
      var T = targetType.typeArguments[0];

      if (!_isValidFfiNativeType(T, allowVoid: true, allowEmptyStruct: true)) {
        AstNode errorNode = node;
        _diagnosticReporter.atNode(
          errorNode,
          FfiCode.nonConstantTypeArgument,
          arguments: ['elementAt'],
        );
      }
    }
  }

  void _validateFfiLeafCallUsesNoHandles(
    DartType nativeType,
    SyntacticEntity errorEntity,
  ) {
    if (nativeType is FunctionType) {
      if (_primitiveNativeType(nativeType.returnType) ==
          _PrimitiveDartType.handle) {
        _diagnosticReporter.atEntity(
          errorEntity,
          FfiCode.leafCallMustNotReturnHandle,
        );
      }
      for (var param in nativeType.normalParameterTypes) {
        if (_primitiveNativeType(param) == _PrimitiveDartType.handle) {
          _diagnosticReporter.atEntity(
            errorEntity,
            FfiCode.leafCallMustNotTakeHandle,
          );
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

    if (node.externalKeyword == null) {
      _diagnosticReporter.atToken(
        fields.variables[0].name,
        FfiCode.fieldMustBeExternalInStruct,
      );
    }

    var fieldType = fields.type;
    if (fieldType == null) {
      _diagnosticReporter.atToken(
        fields.variables[0].name,
        FfiCode.missingFieldTypeInStruct,
      );
    } else {
      DartType declaredType = fieldType.typeOrThrow;
      if (declaredType.nullabilitySuffix == NullabilitySuffix.question) {
        _diagnosticReporter.atNode(
          fieldType,
          FfiCode.invalidFieldTypeInStruct,
          arguments: [fieldType.toSource()],
        );
      } else if (declaredType.isDartCoreInt) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.int);
      } else if (declaredType.isDartCoreDouble) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.double);
      } else if (declaredType.isDartCoreBool) {
        _validateAnnotations(fieldType, annotations, _PrimitiveDartType.bool);
      } else if (declaredType.isPointer) {
        _validateNoAnnotations(annotations);
      } else if (declaredType.isArray) {
        var typeArg = (declaredType as InterfaceType).typeArguments.single;
        if (!_isSized(typeArg)) {
          AstNode errorNode = fieldType;
          if (fieldType is NamedType) {
            var typeArguments = fieldType.typeArguments?.arguments;
            if (typeArguments != null && typeArguments.isNotEmpty) {
              errorNode = typeArguments[0];
            }
          }
          _diagnosticReporter.atNode(
            errorNode,
            FfiCode.nonSizedTypeArgument,
            arguments: [_arrayClassName, typeArg],
          );
        }
        var arrayDimensions = declaredType.arrayDimensions;
        var fieldElement =
            node.fields.variables.first.declaredFragment?.element;
        var lastElement = (fieldElement?.enclosingElement as ClassElement?)
            ?.fields
            .reversed
            .where((field) {
              if (field.isStatic) return false;
              if (!field.isExternal) {
                if (!(field.getter?.isExternal ?? false) &&
                    !(field.setter?.isExternal ?? false)) {
                  return false;
                }
              }
              return true;
            })
            .firstOrNull;
        var isLastField = fieldElement == lastElement;
        _validateSizeOfAnnotation(
          fieldType,
          annotations,
          arrayDimensions,
          isLastField,
        );
      } else if (declaredType.isCompoundSubtype) {
        var clazz = (declaredType as InterfaceType).element;
        if (clazz.isEmptyStruct) {
          _diagnosticReporter.atNode(
            node,
            FfiCode.emptyStruct,
            arguments: [clazz.name!, clazz.supertype!.getDisplayString()],
          );
        }
      } else {
        _diagnosticReporter.atNode(
          fieldType,
          FfiCode.invalidFieldTypeInStruct,
          arguments: [fieldType.toSource()],
        );
      }
    }
  }

  /// Validate the invocation of the static method
  /// `Pointer<T>.fromFunction(f, e)`.
  void _validateFromFunction(MethodInvocationImpl node, MethodElement element) {
    int argCount = node.argumentList.arguments.length;
    if (argCount < 1 || argCount > 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    var T = node.typeArgumentTypes![0];
    if (!_isValidFfiNativeFunctionType(T)) {
      AstNode errorNode = node.methodName;
      var typeArgument = node.typeArguments?.arguments[0];
      if (typeArgument != null) {
        errorNode = typeArgument;
      }
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.mustBeANativeFunctionType,
        arguments: [T, 'fromFunction'],
      );
      return;
    }

    var f = node.argumentList.arguments[0];
    var FT = f.typeOrThrow;
    if (!_validateCompatibleFunctionTypes(
      _FfiTypeCheckDirection.dartToNative,
      FT,
      T,
    )) {
      _diagnosticReporter.atNode(
        f,
        FfiCode.mustBeASubtype,
        arguments: [FT, T, 'fromFunction'],
      );
      return;
    }

    // TODO(brianwilkerson): Validate that `f` is a top-level function.
    var R = (T as FunctionTypeImpl).returnType;
    if (_primitiveNativeType(R) == _PrimitiveDartType.void_ ||
        R.isPointer ||
        R.isHandle ||
        R.isCompoundSubtype) {
      if (argCount != 1) {
        _diagnosticReporter.atNode(
          node.argumentList.arguments[1],
          FfiCode.invalidExceptionValue,
          arguments: ['fromFunction'],
        );
      }
    } else if (argCount != 2) {
      _diagnosticReporter.atNode(
        node.methodName,
        FfiCode.missingExceptionValue,
        arguments: ['fromFunction'],
      );
    } else {
      Expression e = node.argumentList.arguments[1];
      var eType = e.typeOrThrow;
      if (!_validateCompatibleNativeType(
        _FfiTypeCheckDirection.dartToNative,
        eType,
        R,
      )) {
        _diagnosticReporter.atNode(
          e,
          FfiCode.mustBeASubtype,
          arguments: [eType, R, 'fromFunction'],
        );
      }
      if (!_isConst(e)) {
        _diagnosticReporter.atNode(
          e,
          FfiCode.argumentMustBeAConstant,
          arguments: ['exceptionalReturn'],
        );
      }
    }
  }

  /// Ensure `isLeaf` is const as we need the value at compile time to know
  /// which trampoline to generate.
  void _validateIsLeafIsConst(MethodInvocation node) {
    var args = node.argumentList.arguments;
    if (args.isNotEmpty) {
      for (var arg in args) {
        if (arg is NamedExpression) {
          if (arg.element?.name == _isLeafParamName) {
            if (!_isConst(arg.expression)) {
              _diagnosticReporter.atNode(
                arg.expression,
                FfiCode.argumentMustBeAConstant,
                arguments: [_isLeafParamName],
              );
            }
          }
        }
      }
    }
  }

  /// Validate the invocation of the instance method
  /// `DynamicLibrary.lookupFunction<S, F>()`.
  void _validateLookupFunction(MethodInvocationImpl node) {
    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    var argTypes = node.typeArgumentTypes!;
    var S = argTypes[0];
    var F = argTypes[1];
    if (!_isValidFfiNativeFunctionType(S)) {
      AstNode errorNode = typeArguments[0];
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.mustBeANativeFunctionType,
        arguments: [S, 'lookupFunction'],
      );
      return;
    }
    var isLeaf = _isLeaf(node.argumentList.arguments);
    if (!_validateCompatibleFunctionTypes(
      _FfiTypeCheckDirection.nativeToDart,
      F,
      S,
    )) {
      AstNode errorNode = typeArguments[1];
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.mustBeASubtype,
        arguments: [S, F, 'lookupFunction'],
      );
    }
    _validateIsLeafIsConst(node);
    if (isLeaf) {
      _validateFfiLeafCallUsesNoHandles(S, typeArguments[0]);
    }
  }

  /// Validate the invocation of `Native.addressOf`.
  void _validateNativeAddressOf(MethodInvocationImpl node) {
    var typeArguments = node.typeArgumentTypes;
    var arguments = node.argumentList.arguments;
    if (typeArguments == null ||
        typeArguments.length != 1 ||
        arguments.length != 1) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    var argument = arguments[0];
    var targetType = typeArguments[0];
    var validTarget = false;

    var referencedElement = switch (argument) {
      IdentifierImpl() => argument.element?.nonSynthetic,
      _ => null,
    };

    if (referencedElement != null) {
      for (var annotation in referencedElement.metadata.annotations) {
        var value = annotation.computeConstantValue();
        var annotationType = value?.type;

        if (annotationType is InterfaceTypeImpl &&
            annotationType.element.isNative) {
          var nativeType = annotationType.typeArguments[0];

          if (nativeType is FunctionType) {
            // When referencing a function, the target type must be a
            // `NativeFunction<T>` so that `T` matches the type from the
            // annotation.
            if (targetType case InterfaceTypeImpl(isNativeFunction: true)) {
              var targetFunctionType = targetType.typeArguments[0];
              if (!typeSystem.isEqualTo(nativeType, targetFunctionType)) {
                _diagnosticReporter.atNode(
                  node,
                  FfiCode.mustBeASubtype,
                  arguments: [nativeType, targetFunctionType, _nativeAddressOf],
                );
              }
            } else {
              _diagnosticReporter.atNode(
                node,
                FfiCode.mustBeANativeFunctionType,
                arguments: [targetType, _nativeAddressOf],
              );
            }
          } else {
            if (argument.staticType case var staticType?
                when nativeType is DynamicType) {
              // No type argument was given on the @Native annotation, so we try
              // to infer the native type from the Dart signature.
              if (staticType is FunctionTypeImpl) {
                if (staticType.returnType is VoidType) {
                  // The Dart signature has a `void` return type, so we create a
                  // new `FunctionType` with FFI's `Void` as the return type.
                  staticType = FunctionTypeImpl.v2(
                    typeParameters: staticType.typeParameters,
                    formalParameters: staticType.formalParameters,
                    returnType: ffiVoidType ??= annotationType.element.library
                        .getClass('Void')!
                        .thisType,
                    nullabilitySuffix: staticType.nullabilitySuffix,
                  );
                }

                if (targetType case InterfaceTypeImpl(isNativeFunction: true)) {
                  var targetFunctionType = targetType.typeArguments[0];
                  if (!typeSystem.isEqualTo(staticType, targetFunctionType)) {
                    _diagnosticReporter.atNode(
                      node,
                      FfiCode.mustBeASubtype,
                      arguments: [
                        staticType,
                        targetFunctionType,
                        _nativeAddressOf,
                      ],
                    );
                  }
                } else {
                  _diagnosticReporter.atNode(
                    node,
                    FfiCode.mustBeANativeFunctionType,
                    arguments: [targetType, _nativeAddressOf],
                  );
                }
              } else {
                if (!typeSystem.isEqualTo(staticType, targetType)) {
                  _diagnosticReporter.atNode(
                    node,
                    FfiCode.mustBeASubtype,
                    arguments: [staticType, targetType, _nativeAddressOf],
                  );
                }
              }
            }
          }

          validTarget = true;
          break;
        }
      }
    }

    if (!validTarget) {
      _diagnosticReporter.atNode(argument, FfiCode.argumentMustBeNative);
    }
  }

  /// Validate the invocation of the constructor `NativeCallable.listener(f)`
  /// or `NativeCallable.isolateLocal(f)`.
  void _validateNativeCallable(InstanceCreationExpressionImpl node) {
    var name = node.constructorName.name?.toString() ?? '';
    var isolateLocal = name == 'isolateLocal';

    // listener takes 1 arg, isolateLocal takes 1 or 2.
    var argCount = node.argumentList.arguments.length;
    if (!(argCount == 1 || (isolateLocal && argCount == 2))) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    var nodeType = node.typeOrThrow;
    if (nodeType is! InterfaceTypeImpl) {
      return;
    }

    var typeArg = nodeType.typeArguments[0];
    if (!_isValidFfiNativeFunctionType(typeArg)) {
      _diagnosticReporter.atNode(
        node.constructorName,
        FfiCode.mustBeANativeFunctionType,
        arguments: [typeArg, _nativeCallable],
      );
      return;
    }

    var f = node.argumentList.arguments[0];
    var funcType = f.typeOrThrow;
    if (!_validateCompatibleFunctionTypes(
      _FfiTypeCheckDirection.dartToNative,
      funcType,
      typeArg,
    )) {
      _diagnosticReporter.atNode(
        f,
        FfiCode.mustBeASubtype,
        arguments: [funcType, typeArg, _nativeCallable],
      );
      return;
    }

    var natRetType = (typeArg as FunctionTypeImpl).returnType;
    if (isolateLocal) {
      if (_primitiveNativeType(natRetType) == _PrimitiveDartType.void_ ||
          natRetType.isPointer ||
          natRetType.isHandle ||
          natRetType.isCompoundSubtype) {
        if (argCount != 1) {
          _diagnosticReporter.atNode(
            node.argumentList.arguments[1],
            FfiCode.invalidExceptionValue,
            arguments: [name],
          );
        }
      } else if (argCount != 2) {
        _diagnosticReporter.atNode(
          node,
          FfiCode.missingExceptionValue,
          arguments: [name],
        );
      } else {
        var e = (node.argumentList.arguments[1] as NamedExpression).expression;
        var eType = e.typeOrThrow;
        if (!_validateCompatibleNativeType(
          _FfiTypeCheckDirection.dartToNative,
          eType,
          natRetType,
        )) {
          _diagnosticReporter.atNode(
            e,
            FfiCode.mustBeASubtype,
            arguments: [eType, natRetType, name],
          );
        }
        if (!_isConst(e)) {
          _diagnosticReporter.atNode(
            e,
            FfiCode.argumentMustBeAConstant,
            arguments: ['exceptionalReturn'],
          );
        }
      }
    } else {
      if (_primitiveNativeType(natRetType) != _PrimitiveDartType.void_) {
        _diagnosticReporter.atNode(
          f,
          FfiCode.mustReturnVoid,
          arguments: [natRetType],
        );
      }
    }
  }

  /// Validate that none of the [annotations] are from `dart:ffi`.
  void _validateNoAnnotations(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      if (annotation.element.ffiClass != null) {
        _diagnosticReporter.atNode(
          annotation,
          FfiCode.annotationOnPointerField,
        );
      }
    }
  }

  /// Validate that the [annotations] include at most one packed annotation.
  void _validatePackedAnnotation(NodeList<Annotation> annotations) {
    var ffiPackedAnnotations = annotations
        .where((annotation) => annotation.isPacked)
        .toList();

    if (ffiPackedAnnotations.isEmpty) {
      return;
    }

    if (ffiPackedAnnotations.length > 1) {
      var extraAnnotations = ffiPackedAnnotations.skip(1);
      for (var annotation in extraAnnotations) {
        _diagnosticReporter.atNode(annotation, FfiCode.packedAnnotation);
      }
    }

    // Check number of dimensions.
    var annotation = ffiPackedAnnotations.first;
    var value = annotation.elementAnnotation?.packedMemberAlignment;
    if (![1, 2, 4, 8, 16].contains(value)) {
      AstNode errorNode = annotation;
      var arguments = annotation.arguments?.arguments;
      if (arguments != null && arguments.isNotEmpty) {
        errorNode = arguments[0];
      }
      _diagnosticReporter.atNode(errorNode, FfiCode.packedAnnotationAlignment);
    }
  }

  void _validateRefIndexed(IndexExpressionImpl node) {
    var targetType = node.realTarget.typeOrThrow;
    if (!_isValidFfiNativeType(
      targetType,
      allowEmptyStruct: true,
      allowArray: true,
    )) {
      AstNode errorNode = node;
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.nonConstantTypeArgument,
        arguments: ['[]'],
      );
    }
  }

  /// Validate the invocation of the extension method
  /// `Pointer<T extends Struct>.ref`.
  void _validateRefPrefixedIdentifier(PrefixedIdentifierImpl node) {
    var targetType = node.prefix.staticType;
    if (!_isValidFfiNativeType(targetType, allowEmptyStruct: true)) {
      AstNode errorNode = node;
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.nonConstantTypeArgument,
        arguments: ['ref'],
      );
    }
  }

  void _validateRefPropertyAccess(PropertyAccessImpl node) {
    var targetType = node.realTarget.typeOrThrow;
    if (!_isValidFfiNativeType(targetType, allowEmptyStruct: true)) {
      AstNode errorNode = node;
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.nonConstantTypeArgument,
        arguments: ['ref'],
      );
    }
  }

  /// Validate the invocation of the
  /// `Pointer<T extends Struct>.refWithFinalizer` and
  /// `Pointer<T extends Union>.refWithFinalizer` extension methods.
  void _validateRefWithFinalizer(MethodInvocationImpl node) {
    var targetType = node.realTarget?.typeOrThrow;
    if (!_isValidFfiNativeType(targetType, allowEmptyStruct: true)) {
      _diagnosticReporter.atNode(
        node,
        FfiCode.nonConstantTypeArgument,
        arguments: ['refWithFinalizer'],
      );
    }
  }

  void _validateSizeOf(MethodInvocationImpl node) {
    var typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    var T = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(T, allowVoid: true, allowEmptyStruct: true)) {
      AstNode errorNode = node;
      _diagnosticReporter.atNode(
        errorNode,
        FfiCode.nonConstantTypeArgument,
        arguments: ['sizeOf'],
      );
    }
  }

  /// Validate that the [annotations] include exactly one size annotation. If
  /// an error is produced that cannot be associated with an annotation,
  /// associate it with the [errorEntity].
  void _validateSizeOfAnnotation(
    SyntacticEntity errorEntity,
    NodeList<Annotation> annotations,
    int arrayDimensions,
    bool allowVariableLength,
  ) {
    var ffiSizeAnnotations = annotations
        .where((annotation) => annotation.isArray)
        .toList();

    if (ffiSizeAnnotations.isEmpty) {
      _diagnosticReporter.atEntity(
        errorEntity,
        FfiCode.missingSizeAnnotationCarray,
      );
      return;
    }

    if (ffiSizeAnnotations.length > 1) {
      var extraAnnotations = ffiSizeAnnotations.skip(1);
      for (var annotation in extraAnnotations) {
        _diagnosticReporter.atNode(
          annotation,
          FfiCode.extraSizeAnnotationCarray,
        );
      }
    }

    // Check number of dimensions.
    var annotation = ffiSizeAnnotations.first;
    var (dimensions, variableLength) =
        annotation.elementAnnotation?.arraySizeDimensions ?? (<int>[], false);
    var annotationDimensions = dimensions.length;
    if (annotationDimensions != arrayDimensions) {
      _diagnosticReporter.atNode(annotation, FfiCode.sizeAnnotationDimensions);
    }

    if (variableLength) {
      if (!allowVariableLength) {
        _diagnosticReporter.atNode(
          annotation,
          FfiCode.variableLengthArrayNotLast,
        );
      }
    }

    // Check dimensions are valid.
    (List<AstNode>? dimensionsNodes, AstNode? variableDimensionNode)
    getArgumentNodes() {
      return switch (annotation.arguments) {
        // `@Array.variableMulti([..], variableDimension: ..)`
        ArgumentList(
          arguments: [
            ListLiteral dimensions,
            NamedExpression variableDimension,
          ],
        ) =>
          (dimensions.elements, variableDimension.expression),
        // `@Array.variableMulti([..])`
        ArgumentList(arguments: [ListLiteral dimensions]) => (
          dimensions.elements,
          null,
        ),
        // `@Array(..)`, `@Array.variable(..)`,
        // `@Array.variableWithVariableDimension(..)`
        ArgumentList(arguments: NodeList<AstNode> dimensions) => (
          dimensions,
          null,
        ),
        _ => (null, null),
      };
    }

    var (dimensionsNodes, variableDimensionNode) = getArgumentNodes();
    AstNode errorNode = variableDimensionNode ?? annotation;

    for (int i = 0; i < dimensions.length; i++) {
      if (dimensionsNodes case var dimensionsNodes?) {
        if (dimensionsNodes.length > i && variableDimensionNode == null) {
          var node = dimensionsNodes[i];
          errorNode = node is NamedExpression ? node.expression : node;
        }
      }

      // First dimension is variable.
      if (i == 0 && variableLength) {
        // Variable dimension can't be negative.
        if (dimensions[0] < 0) {
          _diagnosticReporter.atNode(
            errorNode,
            FfiCode.negativeVariableDimension,
          );
        }
        continue;
      }

      if (dimensions[i] <= 0) {
        _diagnosticReporter.atNode(
          errorNode,
          FfiCode.nonPositiveArrayDimension,
        );
      }
    }
  }

  /// Validate that the given [typeArgument] has a constant value. Return `true`
  /// if a diagnostic was produced because it isn't constant.
  bool _validateTypeArgument(TypeAnnotation typeArgument, String functionName) {
    if (typeArgument.type is TypeParameterType) {
      _diagnosticReporter.atNode(
        typeArgument,
        FfiCode.nonConstantTypeArgument,
        arguments: [functionName],
      );
      return true;
    }
    return false;
  }
}

enum _FfiTypeCheckDirection {
  // Passing a value from native code to Dart code. For example, the return type
  // of a loaded native function, or the arguments of a native callback.
  nativeToDart,

  // Passing a value from Dart code to native code. For example, the arguments
  // of a loaded native function, or the return type of a native callback.
  dartToNative;

  _FfiTypeCheckDirection get reverse {
    switch (this) {
      case nativeToDart:
        return dartToNative;
      case dartToNative:
        return nativeToDart;
    }
  }
}

enum _PrimitiveDartType { double, int, bool, void_, handle, none }

extension on Annotation {
  bool get isAbiSpecificIntegerMapping {
    var element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name ==
            FfiVerifier._abiSpecificIntegerMappingClassName;
  }

  bool get isArray {
    var element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Array';
  }

  bool get isPacked {
    var element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Packed';
  }
}

extension on ElementAnnotation {
  (List<int>, bool) get arraySizeDimensions {
    assert(isArray);
    var value = computeConstantValue();

    var variableDimension = value?.getField('variableDimension')?.toIntValue();
    var variableLength = variableDimension != null;

    // Element of `@Array.multi([1, 2, 3])`.
    var listField = value?.getField('dimensions');
    if (listField != null) {
      var listValues = listField
          .toListValue()
          ?.map((dartValue) => dartValue.toIntValue())
          .whereType<int>()
          .toList();
      if (listValues != null) {
        return (
          [if (variableLength) variableDimension, ...listValues],
          variableLength,
        );
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
    for (var dimensionFieldName in dimensionFieldNames) {
      var dimensionValue = value?.getField(dimensionFieldName)?.toIntValue();
      if (dimensionValue != null) {
        result.add(dimensionValue);
      }
    }
    return (result, variableLength);
  }

  bool get isArray {
    var element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Array';
    // Note: this is 'Array' instead of '_ArraySize' because it finds the
    // forwarding factory instead of the forwarded constructor.
  }

  /// @Native(isLeaf: true)
  bool get isNativeLeaf {
    var annotationValue = computeConstantValue();
    var annotationType = annotationValue?.type; // Native<T>
    if (annotationValue == null || annotationType is! InterfaceType) {
      return false;
    }
    if (!annotationValue.isNative) {
      return false;
    }
    return annotationValue
            .getField(FfiVerifier._isLeafParamName)
            ?.toBoolValue() ??
        false;
  }

  bool get isPacked {
    var element = this.element;
    return element is ConstructorElement &&
        element.ffiClass != null &&
        element.enclosingElement.name == 'Packed';
  }

  int? get packedMemberAlignment {
    assert(isPacked);
    var value = computeConstantValue();
    return value?.getField('memberAlignment')?.toIntValue();
  }
}

extension on TopLevelFunctionElement {
  /// @Native(isLeaf: true) external function.
  bool get isNativeLeaf {
    for (var annotation in metadata.annotations) {
      if (annotation.isNativeLeaf) {
        return true;
      }
    }
    return false;
  }
}

extension on MethodElement {
  /// @Native(isLeaf: true) external function.
  bool get isNativeLeaf {
    for (var annotation in metadata.annotations) {
      if (annotation.isNativeLeaf) {
        return true;
      }
    }
    return false;
  }
}

extension on MethodInvocation {
  /// Calls @Native(isLeaf: true) external function.
  bool get isNativeLeafInvocation {
    var element = methodName.element;
    if (element is TopLevelFunctionElement) {
      return element.isNativeLeaf;
    }
    if (element is MethodElement) {
      return element.isNativeLeaf;
    }
    return false;
  }
}

extension on DartObject {
  bool get isDefaultAsset {
    return switch (type) {
      InterfaceType(:var element) => element.isDefaultAsset,
      _ => false,
    };
  }

  bool get isNative {
    return switch (type) {
      InterfaceType(:var element) => element.isNative,
      _ => false,
    };
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
    var element = this;
    return element is ClassElement &&
        element.name == FfiVerifier._abiSpecificIntegerClassName &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class
  /// `AbiSpecificInteger`.
  bool get isAbiSpecificIntegerSubclass {
    var element = this;
    return element is ClassElement && element.supertype.isAbiSpecificInteger;
  }

  bool get isAddressOfExtension {
    var element = this;
    return element is ExtensionElement &&
        element.isFfiExtension &&
        FfiVerifier._addressOfExtensionNames.contains(element.name);
  }

  /// Return `true` if this represents the extension `AllocatorAlloc`.
  bool get isAllocatorExtension {
    var element = this;
    return element is ExtensionElement &&
        element.name == FfiVerifier._allocatorExtensionName &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the class `DefaultAsset`.
  bool get isDefaultAsset {
    var element = this;
    return element is ClassElement &&
        element.name == 'DefaultAsset' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the extension `DynamicLibraryExtension`.
  bool get isDynamicLibraryExtension {
    var element = this;
    return element is ExtensionElement &&
        element.name == 'DynamicLibraryExtension' &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the class `Native`.
  bool get isNative {
    var element = this;
    return element is ClassElement &&
        element.name == 'Native' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the class `NativeCallable`.
  bool get isNativeCallable {
    var element = this;
    return element is ClassElement &&
        element.name == FfiVerifier._nativeCallable &&
        element.isFfiClass;
  }

  bool get isNativeFunctionPointerExtension {
    var element = this;
    return element is ExtensionElement &&
        element.name == 'NativeFunctionPointer' &&
        element.isFfiExtension;
  }

  bool get isNativeStructArrayExtension {
    var element = this;
    return element is ExtensionElement &&
        element.name == 'StructArray' &&
        element.isFfiExtension;
  }

  bool get isNativeStructPointerExtension {
    var element = this;
    return element is ExtensionElement &&
        element.name == 'StructPointer' &&
        element.isFfiExtension;
  }

  bool get isNativeUnionArrayExtension {
    var element = this;
    return element is ExtensionElement &&
        element.name == 'UnionArray' &&
        element.isFfiExtension;
  }

  bool get isNativeUnionPointerExtension {
    var element = this;
    return element is ExtensionElement &&
        element.name == 'UnionPointer' &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the class `Opaque`.
  bool get isOpaque {
    var element = this;
    return element is ClassElement &&
        element.name == FfiVerifier._opaqueClassName &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the class `Pointer`.
  bool get isPointer {
    var element = this;
    return element is ClassElement &&
        element.name == 'Pointer' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the class `Struct`.
  bool get isStruct {
    var element = this;
    return element is ClassElement &&
        element.name == 'Struct' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class `Struct`.
  bool get isStructSubclass {
    var element = this;
    return element is ClassElement && element.supertype.isStruct;
  }

  /// Return `true` if this represents the class `Union`.
  bool get isUnion {
    var element = this;
    return element is ClassElement &&
        element.name == 'Union' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class `Union`.
  bool get isUnionSubclass {
    var element = this;
    return element is ClassElement && element.supertype.isUnion;
  }
}

extension on InterfaceElement {
  bool get isEmptyStruct {
    for (var field in fields) {
      var declaredType = field.type;
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

  bool get isTypedDataClass {
    return library.name == FfiVerifier._dartTypedDataLibraryName;
  }
}

extension on ExtensionElement {
  bool get isFfiExtension {
    return library.name == FfiVerifier._dartFfiLibraryName;
  }
}

extension on DartType? {
  bool get isAbiSpecificInteger {
    var self = this;
    return self is InterfaceType && self.element.isAbiSpecificInteger;
  }

  bool get isStruct {
    var self = this;
    return self is InterfaceType && self.element.isStruct;
  }

  bool get isUnion {
    var self = this;
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
    var self = this;
    if (self is InterfaceType) {
      var element = self.element;
      var name = element.name;
      return name == FfiVerifier._abiSpecificIntegerClassName &&
          element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is an Abi-specific integer type,
  /// i.e. a subtype of `AbiSpecificInteger`.
  bool get isAbiSpecificIntegerSubtype {
    var self = this;
    if (self is InterfaceType) {
      var superType = self.element.supertype;
      if (superType != null) {
        var superClassElement = superType.element;
        return superClassElement.name ==
                FfiVerifier._abiSpecificIntegerClassName &&
            superClassElement.isFfiClass;
      }
    }
    return false;
  }

  /// Return `true` if this represents the class `Array`.
  bool get isArray {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element;
      return element.name == FfiVerifier._arrayClassName && element.isFfiClass;
    }
    return false;
  }

  bool get isCompound {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element;
      var name = element.name;
      return (name == FfiVerifier._structClassName ||
              name == FfiVerifier._unionClassName) &&
          element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` if this is a struct type, i.e. a subtype of `Struct`.
  bool get isCompoundSubtype {
    var self = this;
    if (self is InterfaceType) {
      var superType = self.element.supertype;
      if (superType != null) {
        return superType.isCompound;
      }
    }
    return false;
  }

  bool get isHandle {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element;
      return element.name == 'Handle' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a `ffi.NativeFunction<???>` type.
  bool get isNativeFunction {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element;
      return element.name == 'NativeFunction' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a `ffi.NativeType` type.
  bool get isNativeType {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element;
      return element.name == 'NativeType' && element.isFfiClass;
    }
    return false;
  }

  bool get isOpaque {
    var self = this;
    return self is InterfaceType && self.element.isOpaque;
  }

  /// Returns `true` iff this is a opaque type, i.e. a subtype of `Opaque`.
  bool get isOpaqueSubtype {
    var self = this;
    if (self is InterfaceType) {
      var superType = self.element.supertype;
      if (superType != null) {
        return superType.element.isOpaque;
      }
    }
    return false;
  }

  bool get isPointer {
    var self = this;
    return self is InterfaceType && self.element.isPointer;
  }

  /// Only the subset of typed data classes that correspond to a Pointer.
  bool get isTypedData {
    var self = this;
    if (self is! InterfaceType) {
      return false;
    }
    if (!self.element.isTypedDataClass) {
      return false;
    }
    var elementName = self.element.name!;
    if (!elementName.endsWith('List')) {
      return false;
    }
    if (elementName == 'Float32List' || elementName == 'Float64List') {
      return true;
    }
    var fixedIntegerTypeName = elementName.replaceAll('List', '');
    return FfiVerifier._primitiveIntegerNativeTypesFixedSize.contains(
      fixedIntegerTypeName,
    );
  }

  /// Returns `true` iff this is a `ffi.VarArgs` type.
  bool get isVarArgs {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element;
      return element.name == 'VarArgs' && element.isFfiClass;
    }
    return false;
  }
}

extension on NamedType {
  /// If this is a name of class from `dart:ffi`, return it.
  ClassElement? get ffiClass {
    return element.ffiClass;
  }

  /// Return `true` if this represents a subtype of `Struct` or `Union`.
  bool get isAbiSpecificIntegerSubtype {
    var element = this.element;
    if (element is ClassElement) {
      return element.allSupertypes.any((e) => e.isAbiSpecificInteger);
    }
    return false;
  }

  /// Return `true` if this represents a subtype of `Struct` or `Union`.
  bool get isCompoundSubtype {
    var element = this.element;
    if (element is ClassElement) {
      return element.allSupertypes.any((e) => e.isCompound);
    }
    return false;
  }
}

extension on List<TypeImpl> {
  /// Removes the VarArgs from a DartType list.
  ///
  /// ```
  /// [Int8, Int8] -> [Int8, Int8]
  /// [Int8, VarArgs<(Int8,)>] -> [Int8, Int8]
  /// [Int8, VarArgs<(Int8, Int8)>] -> [Int8, Int8, Int8]
  /// ```
  List<TypeImpl> flattenVarArgs() {
    if (isEmpty) {
      return this;
    }
    var last = this.last;
    if (!last.isVarArgs) {
      return this;
    }
    var typeArgument = (last as InterfaceTypeImpl).typeArguments.single;
    if (typeArgument is! RecordTypeImpl) {
      return this;
    }
    if (typeArgument.namedFields.isNotEmpty) {
      // Don't flatten if invalid record.
      return this;
    }
    return [
      ...take(length - 1),
      for (var field in typeArgument.positionalFields) field.type,
    ];
  }
}
