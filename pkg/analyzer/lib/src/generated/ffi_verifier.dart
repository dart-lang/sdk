// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

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

  /// Whether implicit casts should be reported as potential problems.
  final bool strictCasts;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// A flag indicating whether we are currently visiting inside a subclass of
  /// `Struct`.
  bool inCompound = false;

  /// Subclass of `Struct` or `Union` we are currently visiting, or `null`.
  ClassDeclaration? compound;

  /// The `Void` type from `dart:ffi`, or `null` if unresolved.
  InterfaceType? ffiVoidType;

  /// Initialize a newly created verifier.
  FfiVerifier(this.typeSystem, this._errorReporter,
      {required this.strictCasts});

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    inCompound = false;
    compound = null;
    // Only the Allocator, Opaque and Struct class may be extended.
    var extendsClause = node.extendsClause;
    if (extendsClause != null) {
      NamedType superclass = extendsClause.superclass;
      var ffiClass = superclass.ffiClass;
      if (ffiClass != null) {
        var className = ffiClass.name3;
        if (className == _structClassName || className == _unionClassName) {
          inCompound = true;
          compound = node;
          if (node.declaredFragment!.element.isEmptyStruct) {
            _errorReporter.atToken(
              node.name,
              FfiCode.EMPTY_STRUCT,
              arguments: [node.name.lexeme, className ?? '<null>'],
            );
          }
          if (className == _structClassName) {
            _validatePackedAnnotation(node.metadata);
          }
        } else if (className == _abiSpecificIntegerClassName) {
          _validateAbiSpecificIntegerAnnotation(node);
          _validateAbiSpecificIntegerMappingAnnotation(
              node.name, node.metadata);
        }
      } else if (superclass.isCompoundSubtype ||
          superclass.isAbiSpecificIntegerSubtype) {
        _errorReporter.atNode(
          superclass,
          FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS,
          arguments: [node.name.lexeme, superclass.name2.lexeme],
        );
      }
    }

    // No classes from the FFI may be explicitly implemented.
    void checkSupertype(NamedType typename, FfiCode subtypeOfStructCode) {
      var superName = typename.element2?.name3;
      if (superName == _allocatorClassName ||
          superName == _finalizableClassName) {
        return;
      }
      if (typename.isCompoundSubtype || typename.isAbiSpecificIntegerSubtype) {
        _errorReporter.atNode(
          typename,
          subtypeOfStructCode,
          arguments: [node.name.lexeme, typename.name2.lexeme],
        );
      }
    }

    var implementsClause = node.implementsClause;
    if (implementsClause != null) {
      for (NamedType type in implementsClause.interfaces) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS);
      }
    }
    var withClause = node.withClause;
    if (withClause != null) {
      for (NamedType type in withClause.mixinTypes) {
        checkSupertype(type, FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH);
      }
    }

    if (inCompound) {
      if (node.declaredFragment!.element.typeParameters2.isNotEmpty) {
        _errorReporter.atToken(
          node.name,
          FfiCode.GENERIC_STRUCT_SUBCLASS,
          arguments: [node.name.lexeme],
        );
      }
      var implementsClause = node.implementsClause;
      if (implementsClause != null) {
        var compoundType = node.declaredFragment!.element.thisType;
        var structType = compoundType.superclass!;
        var ffiLibrary = structType.element3.library2;
        var finalizableElement = ffiLibrary.getClass2(_finalizableClassName)!;
        var finalizableType = finalizableElement.thisType;
        if (typeSystem.isSubtypeOf(compoundType, finalizableType)) {
          _errorReporter.atToken(
            node.name,
            FfiCode.COMPOUND_IMPLEMENTS_FINALIZABLE,
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
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var element = node.element;
    if (element is MethodElement2) {
      var enclosingElement = element.enclosingElement2;
      if (enclosingElement.isAllocatorExtension &&
          element.name3 == _allocateExtensionMethodName) {
        _validateAllocate(node);
      }
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    var element = node.element;
    if (element is MethodElement2) {
      var enclosingElement = element.enclosingElement2;
      if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeStructArrayExtension ||
          enclosingElement.isNativeUnionPointerExtension ||
          enclosingElement.isNativeUnionArrayExtension) {
        if (element.name3 == '[]') {
          _validateRefIndexed(node);
        }
      }
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructor = node.constructorName.element;
    var class_ = constructor?.enclosingElement2;
    if (class_.isStructSubclass || class_.isUnionSubclass) {
      if (!constructor!.isFactory) {
        _errorReporter.atNode(
          node.constructorName,
          FfiCode.CREATION_OF_STRUCT_OR_UNION,
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

    if (node.element2 case LibraryElement2 library) {
      for (var metadata in library.metadata) {
        var annotationValue = metadata.computeConstantValue();
        if (annotationValue != null && annotationValue.isDefaultAsset) {
          if (hasDefaultAsset) {
            var name = (metadata as ElementAnnotationImpl).annotationAst.name;
            _errorReporter.atNode(
              name,
              FfiCode.FFI_NATIVE_INVALID_DUPLICATE_DEFAULT_ASSET,
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
  void visitMethodInvocation(MethodInvocation node) {
    var element = node.methodName.element;
    if (element is MethodElement2) {
      var enclosingElement = element.enclosingElement2;
      if (enclosingElement.isPointer) {
        if (element.name3 == 'fromFunction') {
          _validateFromFunction(node, element);
        } else if (element.name3 == 'elementAt') {
          _validateElementAt(node);
        }
      } else if (enclosingElement.isStruct || enclosingElement.isUnion) {
        if (element.name3 == 'create') {
          _validateCreate(node, enclosingElement!.name3!);
        }
      } else if (enclosingElement.isNative) {
        if (element.name3 == 'addressOf') {
          _validateNativeAddressOf(node);
        }
      } else if (enclosingElement.isNativeFunctionPointerExtension) {
        if (element.name3 == 'asFunction') {
          _validateAsFunction(node, element);
        }
      } else if (enclosingElement.isDynamicLibraryExtension) {
        if (element.name3 == 'lookupFunction') {
          _validateLookupFunction(node);
        }
      } else if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeUnionPointerExtension) {
        if (element.name3 == 'refWithFinalizer') {
          _validateRefWithFinalizer(node);
        }
      }
    } else if (element is TopLevelFunctionElement) {
      if (element.library2.name3 == 'dart.ffi') {
        if (element.name3 == 'sizeOf') {
          _validateSizeOf(node);
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    var element = node.element;
    if (element != null) {
      var enclosingElement = element.enclosingElement2;
      if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeUnionPointerExtension) {
        if (element.name3 == 'ref') {
          _validateRefPrefixedIdentifier(node);
        }
      } else if (enclosingElement.isAddressOfExtension) {
        if (element.name3 == 'address') {
          _validateAddressPrefixedIdentifier(node);
        }
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var element = node.propertyName.element;
    if (element != null) {
      var enclosingElement = element.enclosingElement2;
      if (enclosingElement.isNativeStructPointerExtension ||
          enclosingElement.isNativeUnionPointerExtension) {
        if (element.name3 == 'ref') {
          _validateRefPropertyAccess(node);
        }
      } else if (enclosingElement.isAddressOfExtension) {
        if (element.name3 == 'address') {
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

  DartType? _canonicalFfiTypeForDartType(DartType dartType) {
    if (dartType.isPointer || dartType.isCompoundSubtype || dartType.isArray) {
      return dartType;
    } else {
      return null;
    }
  }

  void _checkFfiNative({
    required Token errorNode,
    required Element2 declarationElement,
    required NodeList<Annotation> metadata,
    required FormalParameterList? formalParameterList,
    required bool isExternal,
  }) {
    var formalParameters =
        formalParameterList?.parameters ?? <FormalParameter>[];
    var hadNativeAnnotation = false;

    for (var annotation in declarationElement.metadata) {
      var annotationValue = annotation.computeConstantValue();
      var annotationType = annotationValue?.type; // Native<T>

      if (annotationValue == null ||
          annotationType is! InterfaceType ||
          !annotationValue.isNative) {
        continue;
      }

      if (hadNativeAnnotation) {
        var name = (annotation as ElementAnnotationImpl).annotationAst.name;
        _errorReporter.atNode(
          name,
          FfiCode.FFI_NATIVE_INVALID_MULTIPLE_ANNOTATIONS,
        );
        break;
      }

      hadNativeAnnotation = true;

      if (!isExternal) {
        _errorReporter.atToken(
          errorNode,
          FfiCode.FFI_NATIVE_MUST_BE_EXTERNAL,
        );
      }

      var ffiSignature = annotationType.typeArguments[0]; // The T in @Native<T>

      if (ffiSignature is FunctionType) {
        if (declarationElement is ExecutableElement2) {
          _checkFfiNativeFunction(
            errorNode,
            declarationElement,
            ffiSignature,
            annotationValue,
            formalParameters,
          );
        } else {
          // Field annotated with a function type, that can't work.
          _errorReporter.atToken(
            errorNode,
            FfiCode.NATIVE_FIELD_INVALID_TYPE,
            arguments: [ffiSignature],
          );
        }
      } else {
        if (declarationElement
            case TopLevelFunctionElement() || MethodElement2()) {
          declarationElement = declarationElement as ExecutableElement2;
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
                returnType: ffiVoidType ??= annotationType.element3.library2
                    .getClass2('Void')!
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
          _errorReporter.atToken(
            errorNode,
            FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
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
    Element2 declarationElement,
    NodeList<Annotation> metadata,
    DartType ffiSignature,
    DartObject annotationValue,
    bool allowVariableLength,
  ) {
    DartType type;

    if (declarationElement is FieldElement2) {
      if (!declarationElement.isStatic) {
        _errorReporter.atToken(
          errorToken,
          FfiCode.NATIVE_FIELD_NOT_STATIC,
        );
      }
      type = declarationElement.type;
    } else if (declarationElement is TopLevelVariableElement2) {
      type = declarationElement.type;
    } else if (declarationElement is PropertyAccessorElement2) {
      var variable = declarationElement.variable3;
      if (variable == null) {
        return;
      }
      type = variable.type;
    } else {
      _errorReporter.atToken(
        errorToken,
        FfiCode.NATIVE_FIELD_NOT_STATIC,
      );
      return;
    }

    if (ffiSignature is DynamicType) {
      // Attempt to infer the native type from the Dart type.
      var canonical = _canonicalFfiTypeForDartType(type);

      if (canonical == null) {
        _errorReporter.atToken(
          errorToken,
          FfiCode.NATIVE_FIELD_MISSING_TYPE,
        );
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
      _errorReporter.atToken(
        errorToken,
        FfiCode.MUST_BE_A_SUBTYPE,
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
      _errorReporter.atToken(
        errorToken,
        FfiCode.NATIVE_FIELD_INVALID_TYPE,
        arguments: [ffiSignature],
      );
    }
  }

  void _checkFfiNativeFunction(
    Token errorToken,
    ExecutableElement2 declarationElement,
    FunctionType ffiSignature,
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

    if ((declarationElement is MethodElement2 ||
            declarationElement is PropertyAccessorElement2) &&
        !declarationElement.isStatic) {
      // Instance methods must have the receiver as an extra parameter in the
      // Native annotation.
      if (formalParameters.length + 1 != ffiParameterTypes.length) {
        _errorReporter.atToken(
          errorToken,
          FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER,
          arguments: [formalParameters.length + 1, ffiParameterTypes.length],
        );
        return;
      }

      // Receiver can only be Pointer if the class extends
      // NativeFieldWrapperClass1.
      if (ffiSignature.normalParameterTypes[0].isPointer) {
        var cls = declarationElement.enclosingElement2 as InterfaceElement2;
        if (!_extendsNativeFieldWrapperClass1(cls.thisType)) {
          _errorReporter.atToken(
            errorToken,
            FfiCode
                .FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER,
          );
        }
      }

      ffiParameterTypes = ffiParameterTypes.sublist(1);
      ffiParameters = ffiParameters.sublist(1);
    } else {
      // Number of parameters in the Native annotation must match the
      // annotated declaration.
      if (formalParameters.length != ffiParameterTypes.length) {
        _errorReporter.atToken(
          errorToken,
          FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS,
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
          _errorReporter.atToken(
            errorToken,
            FfiCode
                .FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER,
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
      var nativeTypeIsOmitted = (annotationValue.type! as InterfaceType)
          .typeArguments[0] is DynamicType;
      if (nativeTypeIsOmitted) {
        _errorReporter.atToken(
          errorToken,
          FfiCode.NATIVE_FUNCTION_MISSING_TYPE,
        );
      } else {
        _errorReporter.atToken(
          errorToken,
          FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
          arguments: [nativeType, 'Native'],
        );
      }
      return;
    }
    if (!_validateCompatibleFunctionTypes(
        _FfiTypeCheckDirection.nativeToDart, dartType, nativeType,
        nativeFieldWrappersAsPointer: true, permissiveReturnType: true)) {
      _errorReporter.atToken(
        errorToken,
        FfiCode.MUST_BE_A_SUBTYPE,
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
      var element = type.element3;
      type = element.supertype;
    }
    return false;
  }

  bool _isConst(Expression expr) {
    if (expr is Literal) {
      return true;
    }
    if (expr is Identifier) {
      var element = expr.element;
      if (element is VariableElement2 && element.isConst) {
        return true;
      }
      if (element is PropertyAccessorElement2) {
        var variable = element.variable3;
        if (variable != null && variable.isConst) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isLeaf(NodeList<Expression>? args) {
    if (args == null) {
      return false;
    }
    for (var arg in args) {
      if (arg is! NamedExpression || arg.element2?.name3 != _isLeafParamName) {
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
  bool _isValidFfiNativeFunctionType(DartType nativeType) {
    if (nativeType is FunctionType && !nativeType.isDartCoreFunction) {
      if (nativeType.namedParameterTypes.isNotEmpty ||
          nativeType.optionalParameterTypes.isNotEmpty) {
        return false;
      }
      if (!_isValidFfiNativeType(nativeType.returnType,
          allowVoid: true, allowHandle: true)) {
        return false;
      }

      for (DartType typeArg
          in nativeType.normalParameterTypes.flattenVarArgs()) {
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
    DartType? nativeType, {
    bool allowVoid = false,
    bool allowEmptyStruct = false,
    bool allowArray = false,
    bool allowHandle = false,
    bool allowOpaque = false,
  }) {
    if (nativeType is InterfaceType) {
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
          if (nativeType.element3.isEmptyStruct) {
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
    } else if (nativeType is FunctionType) {
      return _isValidFfiNativeFunctionType(nativeType);
    }
    return false;
  }

  bool _isValidTypedData(InterfaceType nativeType, InterfaceType dartType) {
    if (nativeType.isPointer) {
      var elementType = nativeType.typeArguments.single;
      var elementName = elementType.element3?.name3;
      if (dartType.element3.isTypedDataClass) {
        if (elementName == 'Float' &&
            dartType.element3.name3 == 'Float32List') {
          return true;
        }
        if (elementName == 'Double' &&
            dartType.element3.name3 == 'Float64List') {
          return true;
        }
        if (_primitiveIntegerNativeTypesFixedSize.contains(elementName) &&
            dartType.element3.name3 == '${elementName}List') {
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
      if (element is VariableElement2 && element.isConst) {
        return element.computeConstantValue()?.toBoolValue();
      }
      if (element is PropertyAccessorElement2) {
        var variable = element.variable3;
        if (variable == null) {
          return null;
        }
        if (variable.isConst) {
          return variable.computeConstantValue()?.toBoolValue();
        }
      }
    }
    return null;
  }

  _PrimitiveDartType _primitiveNativeType(DartType nativeType) {
    if (nativeType is InterfaceType) {
      var element = nativeType.element3;
      if (element.isFfiClass) {
        var name = element.name3;
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
    var element = annotation.element2;
    if (element is ConstructorElement2) {
      var name = element.enclosingElement2.name3;
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
      _errorReporter.atToken(
        node.name,
        FfiCode.ABI_SPECIFIC_INTEGER_INVALID,
      );
    }
  }

  /// Validate that the [annotations] include at most one mapping annotation.
  void _validateAbiSpecificIntegerMappingAnnotation(
      Token errorToken, NodeList<Annotation> annotations) {
    var ffiPackedAnnotations = annotations
        .where((annotation) => annotation.isAbiSpecificIntegerMapping)
        .toList();

    if (ffiPackedAnnotations.isEmpty) {
      _errorReporter.atToken(
        errorToken,
        FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_MISSING,
      );
      return;
    }

    if (ffiPackedAnnotations.length > 1) {
      var extraAnnotations = ffiPackedAnnotations.skip(1);
      for (var annotation in extraAnnotations) {
        _errorReporter.atNode(
          annotation.name,
          FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_EXTRA,
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
              var name = valueType.element3.name3!;
              if (!_primitiveIntegerNativeTypesFixedSize.contains(name)) {
                _errorReporter.atNode(
                  element.value,
                  FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED,
                  arguments: [name],
                );
              }
            }
          }
        }
        return;
      }
    }
    var annotationConstant =
        annotation.elementAnnotation?.computeConstantValue();
    var mappingValues = annotationConstant?.getField('mapping')?.toMapValue();
    if (mappingValues == null) {
      return;
    }
    for (var nativeType in mappingValues.values) {
      var type = nativeType?.type;
      if (type is InterfaceType) {
        var nativeTypeName = type.element3.name3!;
        if (!_primitiveIntegerNativeTypesFixedSize.contains(nativeTypeName)) {
          _errorReporter.atNode(
            arguments.first,
            FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED,
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
        parent.methodName.element is MethodElement2 &&
        parent.methodName.name == "cast" &&
        parent.methodName.element?.enclosingElement2 is ClassElement2 &&
        parent.methodName.element!.enclosingElement2.isPointer) {
      parent = parent.parent;
    }
    var grandParent = parent?.parent;
    if (parent is! ArgumentList ||
        grandParent is! MethodInvocation ||
        !grandParent.isNativeLeafInvocation) {
      _errorReporter.atNode(
        errorNode,
        FfiCode.ADDRESS_POSITION,
      );
    }
  }

  void _validateAddressPrefixedIdentifier(PrefixedIdentifier node) {
    var errorNode = node.identifier;
    _validateAddressPosition(node, errorNode);
    var extensionName = node.element?.enclosingElement2?.name3;
    var receiver = node.prefix;
    _validateAddressReceiver(node, extensionName, receiver, errorNode);
  }

  void _validateAddressPropertyAccess(PropertyAccess node) {
    var errorNode = node.propertyName;
    _validateAddressPosition(node, errorNode);
    var extensionName = node.propertyName.element?.enclosingElement2?.name3;
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
    _errorReporter.atNode(
      errorNode,
      FfiCode.ADDRESS_RECEIVER,
    );
  }

  void _validateAllocate(FunctionExpressionInvocation node) {
    var typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    DartType dartType = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(dartType,
        allowVoid: true, allowEmptyStruct: true)) {
      AstNode errorNode = node;
      _errorReporter.atNode(
        errorNode,
        FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
        arguments: ['$_allocatorExtensionName.$_allocateExtensionMethodName'],
      );
    }
  }

  /// Validate that the [annotations] include exactly one annotation that
  /// satisfies the [requiredType]. If an error is produced that cannot be
  /// associated with an annotation, associate it with the [errorNode].
  void _validateAnnotations(TypeAnnotation errorNode,
      NodeList<Annotation> annotations, _PrimitiveDartType requiredType) {
    bool requiredFound = false;
    List<Annotation> extraAnnotations = [];
    for (Annotation annotation in annotations) {
      if (annotation.element2.ffiClass != null ||
          annotation.element2?.enclosingElement2.isAbiSpecificIntegerSubclass ==
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
        _errorReporter.atNode(
          invalidAnnotation,
          FfiCode.MISMATCHED_ANNOTATION_ON_STRUCT_FIELD,
        );
      }
      for (Annotation extraAnnotation in extraAnnotations) {
        _errorReporter.atNode(
          extraAnnotation,
          FfiCode.EXTRA_ANNOTATION_ON_STRUCT_FIELD,
        );
      }
    } else if (!requiredFound) {
      _errorReporter.atNode(
        errorNode,
        FfiCode.MISSING_ANNOTATION_ON_STRUCT_FIELD,
        arguments: [
          errorNode.type!,
          compound!.extendsClause!.superclass.name2.lexeme
        ],
      );
    }
  }

  /// Validate the invocation of the instance method
  /// `Pointer<T>.asFunction<F>()`.
  void _validateAsFunction(MethodInvocation node, MethodElement2 element) {
    var typeArguments = node.typeArguments?.arguments;
    AstNode errorNode = typeArguments != null ? typeArguments[0] : node;
    if (typeArguments != null && typeArguments.length == 1) {
      if (_validateTypeArgument(typeArguments[0], 'asFunction')) {
        return;
      }
    }
    var target = node.realTarget!;
    var targetType = target.staticType;
    if (targetType is InterfaceType && targetType.isPointer) {
      DartType T = targetType.typeArguments[0];
      if (!T.isNativeFunction) {
        return;
      }
      DartType pointerTypeArg = (T as InterfaceType).typeArguments.single;
      if (pointerTypeArg is TypeParameterType) {
        _errorReporter.atNode(
          target,
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
          arguments: ['asFunction'],
        );
        return;
      }
      if (!_isValidFfiNativeFunctionType(pointerTypeArg)) {
        _errorReporter.atNode(
          errorNode,
          FfiCode.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER,
          arguments: [T],
        );
        return;
      }

      DartType TPrime = T.typeArguments[0];
      DartType F = node.typeArgumentTypes![0];
      var isLeaf = _isLeaf(node.argumentList.arguments);
      if (!_validateCompatibleFunctionTypes(
          _FfiTypeCheckDirection.nativeToDart, F, TPrime)) {
        _errorReporter.atNode(
          node,
          FfiCode.MUST_BE_A_SUBTYPE,
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
  /// [permissiveReturnType] means that the [direction] is ignored for return
  /// types, and subtyping is allowed in either direction.
  bool _validateCompatibleFunctionTypes(
    _FfiTypeCheckDirection direction,
    DartType dartType,
    DartType nativeType, {
    bool nativeFieldWrappersAsPointer = false,
    bool permissiveReturnType = false,
  }) {
    // We require both to be valid function types.
    if (dartType is! FunctionType ||
        dartType.isDartCoreFunction ||
        nativeType is! FunctionType ||
        nativeType.isDartCoreFunction) {
      return false;
    }

    var nativeTypeNormalParameterTypes =
        nativeType.normalParameterTypes.flattenVarArgs();

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
    if (permissiveReturnType) {
      // TODO(dacoharkes): Fix inconsistency between `FfiNative` and
      // `asFunction`. http://dartbug.com/49518.
      if (!(_validateCompatibleNativeType(_FfiTypeCheckDirection.nativeToDart,
              dartType.returnType, nativeType.returnType) ||
          _validateCompatibleNativeType(_FfiTypeCheckDirection.dartToNative,
              dartType.returnType, nativeType.returnType))) {
        return false;
      }
    } else if (!_validateCompatibleNativeType(
        direction, dartType.returnType, nativeType.returnType)) {
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
    DartType dartType,
    DartType nativeType, {
    bool nativeFieldWrappersAsPointer = false,
    bool allowFunctions = false,
  }) {
    var nativeReturnType = _primitiveNativeType(nativeType);
    if (nativeReturnType == _PrimitiveDartType.int ||
        (nativeType is InterfaceType &&
            nativeType.superclass?.element3.name3 ==
                _abiSpecificIntegerClassName)) {
      return dartType.isDartCoreInt;
    } else if (nativeReturnType == _PrimitiveDartType.double) {
      return dartType.isDartCoreDouble;
    } else if (nativeReturnType == _PrimitiveDartType.bool) {
      return dartType.isDartCoreBool;
    } else if (nativeReturnType == _PrimitiveDartType.void_) {
      return direction == _FfiTypeCheckDirection.dartToNative
          ? true
          : dartType is VoidType;
    } else if (dartType is VoidType) {
      // Don't allow other native subtypes if the Dart return type is void.
      return nativeReturnType == _PrimitiveDartType.void_;
    } else if (nativeReturnType == _PrimitiveDartType.handle) {
      switch (direction) {
        case _FfiTypeCheckDirection.dartToNative:
          // Everything is a subtype of `Object?`.
          return true;
        case _FfiTypeCheckDirection.nativeToDart:
          return typeSystem.isSubtypeOf(typeSystem.objectNone, dartType);
      }
    } else if (dartType is InterfaceType && nativeType is InterfaceType) {
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
    } else if (dartType is FunctionType &&
        allowFunctions &&
        nativeType is InterfaceType &&
        nativeType.isNativeFunction) {
      var nativeFunction = nativeType.typeArguments[0];
      return _validateCompatibleFunctionTypes(
          direction, dartType, nativeFunction,
          nativeFieldWrappersAsPointer: nativeFieldWrappersAsPointer);
    } else {
      // If the [nativeType] is not a primitive int/double type then it has to
      // be a Pointer type atm.
      return false;
    }
  }

  void _validateCreate(MethodInvocation node, String errorClass) {
    var typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    DartType dartType = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(dartType)) {
      AstNode errorNode = node;
      _errorReporter.atNode(
        errorNode,
        FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
        arguments: ['$errorClass.create'],
      );
    }
  }

  void _validateElementAt(MethodInvocation node) {
    var targetType = node.realTarget?.staticType;
    if (targetType is InterfaceType && targetType.isPointer) {
      DartType T = targetType.typeArguments[0];

      if (!_isValidFfiNativeType(T, allowVoid: true, allowEmptyStruct: true)) {
        AstNode errorNode = node;
        _errorReporter.atNode(
          errorNode,
          FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
          arguments: ['elementAt'],
        );
      }
    }
  }

  void _validateFfiLeafCallUsesNoHandles(
      DartType nativeType, SyntacticEntity errorEntity) {
    if (nativeType is FunctionType) {
      if (_primitiveNativeType(nativeType.returnType) ==
          _PrimitiveDartType.handle) {
        _errorReporter.atEntity(
          errorEntity,
          FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE,
        );
      }
      for (var param in nativeType.normalParameterTypes) {
        if (_primitiveNativeType(param) == _PrimitiveDartType.handle) {
          _errorReporter.atEntity(
            errorEntity,
            FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE,
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
      _errorReporter.atToken(
        fields.variables[0].name,
        FfiCode.FIELD_MUST_BE_EXTERNAL_IN_STRUCT,
      );
    }

    var fieldType = fields.type;
    if (fieldType == null) {
      _errorReporter.atToken(
        fields.variables[0].name,
        FfiCode.MISSING_FIELD_TYPE_IN_STRUCT,
      );
    } else {
      DartType declaredType = fieldType.typeOrThrow;
      if (declaredType.nullabilitySuffix == NullabilitySuffix.question) {
        _errorReporter.atNode(
          fieldType,
          FfiCode.INVALID_FIELD_TYPE_IN_STRUCT,
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
          _errorReporter.atNode(
            errorNode,
            FfiCode.NON_SIZED_TYPE_ARGUMENT,
            arguments: [_arrayClassName, typeArg],
          );
        }
        var arrayDimensions = declaredType.arrayDimensions;
        var fieldElement =
            node.fields.variables.first.declaredFragment?.element;
        var lastElement = (fieldElement?.enclosingElement2 as ClassElement2?)
            ?.fields2
            .reversed
            .where((field) {
          if (field.isStatic) return false;
          if (!field.isExternal) {
            if (!(field.getter2?.isExternal ?? false) &&
                !(field.setter2?.isExternal ?? false)) {
              return false;
            }
          }
          return true;
        }).firstOrNull;
        var isLastField = fieldElement == lastElement;
        _validateSizeOfAnnotation(
          fieldType,
          annotations,
          arrayDimensions,
          isLastField,
        );
      } else if (declaredType.isCompoundSubtype) {
        var clazz = (declaredType as InterfaceType).element3;
        if (clazz.isEmptyStruct) {
          _errorReporter.atNode(
            node,
            FfiCode.EMPTY_STRUCT,
            arguments: [
              clazz.name3!,
              clazz.supertype!.getDisplayString(),
            ],
          );
        }
      } else {
        _errorReporter.atNode(
          fieldType,
          FfiCode.INVALID_FIELD_TYPE_IN_STRUCT,
          arguments: [fieldType.toSource()],
        );
      }
    }
  }

  /// Validate the invocation of the static method
  /// `Pointer<T>.fromFunction(f, e)`.
  void _validateFromFunction(MethodInvocation node, MethodElement2 element) {
    int argCount = node.argumentList.arguments.length;
    if (argCount < 1 || argCount > 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    DartType T = node.typeArgumentTypes![0];
    if (!_isValidFfiNativeFunctionType(T)) {
      AstNode errorNode = node.methodName;
      var typeArgument = node.typeArguments?.arguments[0];
      if (typeArgument != null) {
        errorNode = typeArgument;
      }
      _errorReporter.atNode(
        errorNode,
        FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
        arguments: [T, 'fromFunction'],
      );
      return;
    }

    Expression f = node.argumentList.arguments[0];
    DartType FT = f.typeOrThrow;
    if (!_validateCompatibleFunctionTypes(
        _FfiTypeCheckDirection.dartToNative, FT, T)) {
      _errorReporter.atNode(
        f,
        FfiCode.MUST_BE_A_SUBTYPE,
        arguments: [FT, T, 'fromFunction'],
      );
      return;
    }

    // TODO(brianwilkerson): Validate that `f` is a top-level function.
    DartType R = (T as FunctionType).returnType;
    if (_primitiveNativeType(R) == _PrimitiveDartType.void_ ||
        R.isPointer ||
        R.isHandle ||
        R.isCompoundSubtype) {
      if (argCount != 1) {
        _errorReporter.atNode(
          node.argumentList.arguments[1],
          FfiCode.INVALID_EXCEPTION_VALUE,
          arguments: ['fromFunction'],
        );
      }
    } else if (argCount != 2) {
      _errorReporter.atNode(
        node.methodName,
        FfiCode.MISSING_EXCEPTION_VALUE,
        arguments: ['fromFunction'],
      );
    } else {
      Expression e = node.argumentList.arguments[1];
      var eType = e.typeOrThrow;
      if (!_validateCompatibleNativeType(
          _FfiTypeCheckDirection.dartToNative, eType, R)) {
        _errorReporter.atNode(
          e,
          FfiCode.MUST_BE_A_SUBTYPE,
          arguments: [eType, R, 'fromFunction'],
        );
      }
      if (!_isConst(e)) {
        _errorReporter.atNode(
          e,
          FfiCode.ARGUMENT_MUST_BE_A_CONSTANT,
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
          if (arg.element2?.name3 == _isLeafParamName) {
            if (!_isConst(arg.expression)) {
              _errorReporter.atNode(
                arg.expression,
                FfiCode.ARGUMENT_MUST_BE_A_CONSTANT,
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
  void _validateLookupFunction(MethodInvocation node) {
    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 2) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    List<DartType> argTypes = node.typeArgumentTypes!;
    DartType S = argTypes[0];
    DartType F = argTypes[1];
    if (!_isValidFfiNativeFunctionType(S)) {
      AstNode errorNode = typeArguments[0];
      _errorReporter.atNode(
        errorNode,
        FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
        arguments: [S, 'lookupFunction'],
      );
      return;
    }
    var isLeaf = _isLeaf(node.argumentList.arguments);
    if (!_validateCompatibleFunctionTypes(
        _FfiTypeCheckDirection.nativeToDart, F, S)) {
      AstNode errorNode = typeArguments[1];
      _errorReporter.atNode(
        errorNode,
        FfiCode.MUST_BE_A_SUBTYPE,
        arguments: [S, F, 'lookupFunction'],
      );
    }
    _validateIsLeafIsConst(node);
    if (isLeaf) {
      _validateFfiLeafCallUsesNoHandles(S, typeArguments[0]);
    }
  }

  /// Validate the invocation of `Native.addressOf`.
  void _validateNativeAddressOf(MethodInvocation node) {
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
      Identifier() => argument.element?.nonSynthetic2,
      _ => null,
    };

    if (referencedElement != null) {
      for (var annotation in referencedElement.metadata) {
        var value = annotation.computeConstantValue();
        var annotationType = value?.type;

        if (annotationType is InterfaceType &&
            annotationType.element3.isNative) {
          var nativeType = annotationType.typeArguments[0];

          if (nativeType is FunctionType) {
            // When referencing a function, the target type must be a
            // `NativeFunction<T>` so that `T` matches the type from the
            // annotation.
            if (targetType case InterfaceType(isNativeFunction: true)) {
              var targetFunctionType = targetType.typeArguments[0];
              if (!typeSystem.isEqualTo(nativeType, targetFunctionType)) {
                _errorReporter.atNode(
                  node,
                  FfiCode.MUST_BE_A_SUBTYPE,
                  arguments: [nativeType, targetFunctionType, _nativeAddressOf],
                );
              }
            } else {
              _errorReporter.atNode(
                node,
                FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
                arguments: [targetType, _nativeAddressOf],
              );
            }
          } else {
            if (argument.staticType case var staticType?
                when nativeType is DynamicType) {
              // No type argument was given on the @Native annotation, so we try
              // to infer the native type from the Dart signature.
              if (staticType is FunctionType) {
                if (staticType.returnType is VoidType) {
                  // The Dart signature has a `void` return type, so we create a
                  // new `FunctionType` with FFI's `Void` as the return type.
                  staticType = FunctionTypeImpl.v2(
                    typeParameters: staticType.typeParameters,
                    formalParameters: staticType.formalParameters,
                    returnType: ffiVoidType ??= annotationType.element3.library2
                        .getClass2('Void')!
                        .thisType,
                    nullabilitySuffix: staticType.nullabilitySuffix,
                  );
                }

                if (targetType case InterfaceType(isNativeFunction: true)) {
                  var targetFunctionType = targetType.typeArguments[0];
                  if (!typeSystem.isEqualTo(staticType, targetFunctionType)) {
                    _errorReporter.atNode(
                      node,
                      FfiCode.MUST_BE_A_SUBTYPE,
                      arguments: [
                        staticType,
                        targetFunctionType,
                        _nativeAddressOf
                      ],
                    );
                  }
                } else {
                  _errorReporter.atNode(
                    node,
                    FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
                    arguments: [targetType, _nativeAddressOf],
                  );
                }
              } else {
                if (!typeSystem.isEqualTo(staticType, targetType)) {
                  _errorReporter.atNode(
                    node,
                    FfiCode.MUST_BE_A_SUBTYPE,
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
      _errorReporter.atNode(
        argument,
        FfiCode.ARGUMENT_MUST_BE_NATIVE,
      );
    }
  }

  /// Validate the invocation of the constructor `NativeCallable.listener(f)`
  /// or `NativeCallable.isolateLocal(f)`.
  void _validateNativeCallable(InstanceCreationExpression node) {
    var name = node.constructorName.name?.toString() ?? '';
    var isolateLocal = name == 'isolateLocal';

    // listener takes 1 arg, isolateLocal takes 1 or 2.
    var argCount = node.argumentList.arguments.length;
    if (!(argCount == 1 || (isolateLocal && argCount == 2))) {
      // There are other diagnostics reported against the invocation and the
      // diagnostics generated below might be inaccurate, so don't report them.
      return;
    }

    var typeArg = (node.staticType as ParameterizedType).typeArguments[0];
    if (!_isValidFfiNativeFunctionType(typeArg)) {
      _errorReporter.atNode(
        node.constructorName,
        FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE,
        arguments: [typeArg, _nativeCallable],
      );
      return;
    }

    var f = node.argumentList.arguments[0];
    var funcType = f.typeOrThrow;
    if (!_validateCompatibleFunctionTypes(
        _FfiTypeCheckDirection.dartToNative, funcType, typeArg)) {
      _errorReporter.atNode(
        f,
        FfiCode.MUST_BE_A_SUBTYPE,
        arguments: [funcType, typeArg, _nativeCallable],
      );
      return;
    }

    var natRetType = (typeArg as FunctionType).returnType;
    if (isolateLocal) {
      if (_primitiveNativeType(natRetType) == _PrimitiveDartType.void_ ||
          natRetType.isPointer ||
          natRetType.isHandle ||
          natRetType.isCompoundSubtype) {
        if (argCount != 1) {
          _errorReporter.atNode(
            node.argumentList.arguments[1],
            FfiCode.INVALID_EXCEPTION_VALUE,
            arguments: [name],
          );
        }
      } else if (argCount != 2) {
        _errorReporter.atNode(
          node,
          FfiCode.MISSING_EXCEPTION_VALUE,
          arguments: [name],
        );
      } else {
        var e = (node.argumentList.arguments[1] as NamedExpression).expression;
        var eType = e.typeOrThrow;
        if (!_validateCompatibleNativeType(
            _FfiTypeCheckDirection.dartToNative, eType, natRetType)) {
          _errorReporter.atNode(
            e,
            FfiCode.MUST_BE_A_SUBTYPE,
            arguments: [eType, natRetType, name],
          );
        }
        if (!_isConst(e)) {
          _errorReporter.atNode(
            e,
            FfiCode.ARGUMENT_MUST_BE_A_CONSTANT,
            arguments: ['exceptionalReturn'],
          );
        }
      }
    } else {
      if (_primitiveNativeType(natRetType) != _PrimitiveDartType.void_) {
        _errorReporter.atNode(
          f,
          FfiCode.MUST_RETURN_VOID,
          arguments: [natRetType],
        );
      }
    }
  }

  /// Validate that none of the [annotations] are from `dart:ffi`.
  void _validateNoAnnotations(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      if (annotation.element2.ffiClass != null) {
        _errorReporter.atNode(
          annotation,
          FfiCode.ANNOTATION_ON_POINTER_FIELD,
        );
      }
    }
  }

  /// Validate that the [annotations] include at most one packed annotation.
  void _validatePackedAnnotation(NodeList<Annotation> annotations) {
    var ffiPackedAnnotations =
        annotations.where((annotation) => annotation.isPacked).toList();

    if (ffiPackedAnnotations.isEmpty) {
      return;
    }

    if (ffiPackedAnnotations.length > 1) {
      var extraAnnotations = ffiPackedAnnotations.skip(1);
      for (var annotation in extraAnnotations) {
        _errorReporter.atNode(
          annotation,
          FfiCode.PACKED_ANNOTATION,
        );
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
      _errorReporter.atNode(
        errorNode,
        FfiCode.PACKED_ANNOTATION_ALIGNMENT,
      );
    }
  }

  void _validateRefIndexed(IndexExpression node) {
    var targetType = node.realTarget.staticType;
    if (!_isValidFfiNativeType(targetType,
        allowEmptyStruct: true, allowArray: true)) {
      AstNode errorNode = node;
      _errorReporter.atNode(
        errorNode,
        FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
        arguments: ['[]'],
      );
    }
  }

  /// Validate the invocation of the extension method
  /// `Pointer<T extends Struct>.ref`.
  void _validateRefPrefixedIdentifier(PrefixedIdentifier node) {
    var targetType = node.prefix.staticType;
    if (!_isValidFfiNativeType(targetType, allowEmptyStruct: true)) {
      AstNode errorNode = node;
      _errorReporter.atNode(
        errorNode,
        FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
        arguments: ['ref'],
      );
    }
  }

  void _validateRefPropertyAccess(PropertyAccess node) {
    var targetType = node.realTarget.staticType;
    if (!_isValidFfiNativeType(targetType, allowEmptyStruct: true)) {
      AstNode errorNode = node;
      _errorReporter.atNode(
        errorNode,
        FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
        arguments: ['ref'],
      );
    }
  }

  /// Validate the invocation of the
  /// `Pointer<T extends Struct>.refWithFinalizer` and
  /// `Pointer<T extends Union>.refWithFinalizer` extension methods.
  void _validateRefWithFinalizer(MethodInvocation node) {
    var targetType = node.realTarget?.staticType;
    if (!_isValidFfiNativeType(targetType, allowEmptyStruct: true)) {
      _errorReporter.atNode(
        node,
        FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
        arguments: ['refWithFinalizer'],
      );
    }
  }

  void _validateSizeOf(MethodInvocation node) {
    var typeArgumentTypes = node.typeArgumentTypes;
    if (typeArgumentTypes == null || typeArgumentTypes.length != 1) {
      return;
    }
    DartType T = typeArgumentTypes[0];
    if (!_isValidFfiNativeType(T, allowVoid: true, allowEmptyStruct: true)) {
      AstNode errorNode = node;
      _errorReporter.atNode(
        errorNode,
        FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
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
    var ffiSizeAnnotations =
        annotations.where((annotation) => annotation.isArray).toList();

    if (ffiSizeAnnotations.isEmpty) {
      _errorReporter.atEntity(
        errorEntity,
        FfiCode.MISSING_SIZE_ANNOTATION_CARRAY,
      );
      return;
    }

    if (ffiSizeAnnotations.length > 1) {
      var extraAnnotations = ffiSizeAnnotations.skip(1);
      for (var annotation in extraAnnotations) {
        _errorReporter.atNode(
          annotation,
          FfiCode.EXTRA_SIZE_ANNOTATION_CARRAY,
        );
      }
    }

    // Check number of dimensions.
    var annotation = ffiSizeAnnotations.first;
    var (dimensions, variableLength) =
        annotation.elementAnnotation?.arraySizeDimensions ?? (<int>[], false);
    var annotationDimensions = dimensions.length;
    if (annotationDimensions != arrayDimensions) {
      _errorReporter.atNode(
        annotation,
        FfiCode.SIZE_ANNOTATION_DIMENSIONS,
      );
    }

    if (variableLength) {
      if (!allowVariableLength) {
        _errorReporter.atNode(
          annotation,
          FfiCode.VARIABLE_LENGTH_ARRAY_NOT_LAST,
        );
      }
    }

    // Check dimensions are valid.
    (List<AstNode>? dimensionsNodes, AstNode? variableDimensionNode)
        getArgumentNodes() {
      return switch (annotation.arguments) {
        // `@Array.variableMulti([..], variableDimension: ..)`
        ArgumentList(
          arguments: [ListLiteral dimensions, NamedExpression variableDimension]
        ) =>
          (dimensions.elements, variableDimension.expression),
        // `@Array.variableMulti([..])`
        ArgumentList(arguments: [ListLiteral dimensions]) => (
            dimensions.elements,
            null
          ),
        // `@Array(..)`, `@Array.variable(..)`,
        // `@Array.variableWithVariableDimension(..)`
        ArgumentList(arguments: NodeList<AstNode> dimensions) => (
            dimensions,
            null
          ),
        _ => (null, null)
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
          _errorReporter.atNode(
            errorNode,
            FfiCode.NEGATIVE_VARIABLE_DIMENSION,
          );
        }
        continue;
      }

      if (dimensions[i] <= 0) {
        _errorReporter.atNode(
          errorNode,
          FfiCode.NON_POSITIVE_ARRAY_DIMENSION,
        );
      }
    }
  }

  /// Validate that the given [typeArgument] has a constant value. Return `true`
  /// if a diagnostic was produced because it isn't constant.
  bool _validateTypeArgument(TypeAnnotation typeArgument, String functionName) {
    if (typeArgument.type is TypeParameterType) {
      _errorReporter.atNode(
        typeArgument,
        FfiCode.NON_CONSTANT_TYPE_ARGUMENT,
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
    var element = element2;
    return element is ConstructorElement2 &&
        element.ffiClass != null &&
        element.enclosingElement2.name3 ==
            FfiVerifier._abiSpecificIntegerMappingClassName;
  }

  bool get isArray {
    var element = element2;
    return element is ConstructorElement2 &&
        element.ffiClass != null &&
        element.enclosingElement2.name3 == 'Array';
  }

  bool get isPacked {
    var element = element2;
    return element is ConstructorElement2 &&
        element.ffiClass != null &&
        element.enclosingElement2.name3 == 'Packed';
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
          variableLength
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
    var element = element2;
    return element is ConstructorElement2 &&
        element.ffiClass != null &&
        element.enclosingElement2.name3 == 'Array';
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
    var element = element2;
    return element is ConstructorElement2 &&
        element.ffiClass != null &&
        element.enclosingElement2.name3 == 'Packed';
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
    for (var annotation in metadata2.annotations) {
      if (annotation.isNativeLeaf) {
        return true;
      }
    }
    return false;
  }
}

extension on MethodElement2 {
  /// @Native(isLeaf: true) external function.
  bool get isNativeLeaf {
    for (var annotation in metadata2.annotations) {
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
    if (element is MethodElement2) {
      return element.isNativeLeaf;
    }
    return false;
  }
}

extension on DartObject {
  bool get isDefaultAsset {
    return switch (type) {
      InterfaceType(:var element3) => element3.isDefaultAsset,
      _ => false,
    };
  }

  bool get isNative {
    return switch (type) {
      InterfaceType(:var element3) => element3.isNative,
      _ => false,
    };
  }
}

extension on Element2? {
  /// If this is a class element from `dart:ffi`, return it.
  ClassElement2? get ffiClass {
    var element = this;
    if (element is ConstructorElement2) {
      element = element.enclosingElement2;
    }
    if (element is ClassElement2 && element.isFfiClass) {
      return element;
    }
    return null;
  }

  /// Return `true` if this represents the class `AbiSpecificInteger`.
  bool get isAbiSpecificInteger {
    var element = this;
    return element is ClassElement2 &&
        element.name3 == FfiVerifier._abiSpecificIntegerClassName &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class
  /// `AbiSpecificInteger`.
  bool get isAbiSpecificIntegerSubclass {
    var element = this;
    return element is ClassElement2 && element.supertype.isAbiSpecificInteger;
  }

  bool get isAddressOfExtension {
    var element = this;
    return element is ExtensionElement2 &&
        element.isFfiExtension &&
        FfiVerifier._addressOfExtensionNames.contains(element.name3);
  }

  /// Return `true` if this represents the extension `AllocatorAlloc`.
  bool get isAllocatorExtension {
    var element = this;
    return element is ExtensionElement2 &&
        element.name3 == FfiVerifier._allocatorExtensionName &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the class `DefaultAsset`.
  bool get isDefaultAsset {
    var element = this;
    return element is ClassElement2 &&
        element.name3 == 'DefaultAsset' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the extension `DynamicLibraryExtension`.
  bool get isDynamicLibraryExtension {
    var element = this;
    return element is ExtensionElement2 &&
        element.name3 == 'DynamicLibraryExtension' &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the class `Native`.
  bool get isNative {
    var element = this;
    return element is ClassElement2 &&
        element.name3 == 'Native' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the class `NativeCallable`.
  bool get isNativeCallable {
    var element = this;
    return element is ClassElement2 &&
        element.name3 == FfiVerifier._nativeCallable &&
        element.isFfiClass;
  }

  bool get isNativeFunctionPointerExtension {
    var element = this;
    return element is ExtensionElement2 &&
        element.name3 == 'NativeFunctionPointer' &&
        element.isFfiExtension;
  }

  bool get isNativeStructArrayExtension {
    var element = this;
    return element is ExtensionElement2 &&
        element.name3 == 'StructArray' &&
        element.isFfiExtension;
  }

  bool get isNativeStructPointerExtension {
    var element = this;
    return element is ExtensionElement2 &&
        element.name3 == 'StructPointer' &&
        element.isFfiExtension;
  }

  bool get isNativeUnionArrayExtension {
    var element = this;
    return element is ExtensionElement2 &&
        element.name3 == 'UnionArray' &&
        element.isFfiExtension;
  }

  bool get isNativeUnionPointerExtension {
    var element = this;
    return element is ExtensionElement2 &&
        element.name3 == 'UnionPointer' &&
        element.isFfiExtension;
  }

  /// Return `true` if this represents the class `Opaque`.
  bool get isOpaque {
    var element = this;
    return element is ClassElement2 &&
        element.name3 == FfiVerifier._opaqueClassName &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the class `Pointer`.
  bool get isPointer {
    var element = this;
    return element is ClassElement2 &&
        element.name3 == 'Pointer' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents the class `Struct`.
  bool get isStruct {
    var element = this;
    return element is ClassElement2 &&
        element.name3 == 'Struct' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class `Struct`.
  bool get isStructSubclass {
    var element = this;
    return element is ClassElement2 && element.supertype.isStruct;
  }

  /// Return `true` if this represents the class `Union`.
  bool get isUnion {
    var element = this;
    return element is ClassElement2 &&
        element.name3 == 'Union' &&
        element.isFfiClass;
  }

  /// Return `true` if this represents a subclass of the class `Union`.
  bool get isUnionSubclass {
    var element = this;
    return element is ClassElement2 && element.supertype.isUnion;
  }
}

extension on InterfaceElement2 {
  bool get isEmptyStruct {
    for (var field in fields2) {
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
    return library2.name3 == FfiVerifier._dartFfiLibraryName;
  }

  bool get isTypedDataClass {
    return library2.name3 == FfiVerifier._dartTypedDataLibraryName;
  }
}

extension on ExtensionElement2 {
  bool get isFfiExtension {
    return library2.name3 == FfiVerifier._dartFfiLibraryName;
  }
}

extension on DartType? {
  bool get isAbiSpecificInteger {
    var self = this;
    return self is InterfaceType && self.element3.isAbiSpecificInteger;
  }

  bool get isStruct {
    var self = this;
    return self is InterfaceType && self.element3.isStruct;
  }

  bool get isUnion {
    var self = this;
    return self is InterfaceType && self.element3.isUnion;
  }
}

extension on DartType {
  int get arrayDimensions {
    DartType iterator = this;
    int dimensions = 0;
    while (iterator is InterfaceType &&
        iterator.element3.name3 == FfiVerifier._arrayClassName &&
        iterator.element3.isFfiClass) {
      dimensions++;
      iterator = iterator.typeArguments.single;
    }
    return dimensions;
  }

  bool get isAbiSpecificInteger {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element3;
      var name = element.name3;
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
      var superType = self.element3.supertype;
      if (superType != null) {
        var superClassElement = superType.element3;
        return superClassElement.name3 ==
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
      var element = self.element3;
      return element.name3 == FfiVerifier._arrayClassName && element.isFfiClass;
    }
    return false;
  }

  bool get isCompound {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element3;
      var name = element.name3;
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
      var superType = self.element3.supertype;
      if (superType != null) {
        return superType.isCompound;
      }
    }
    return false;
  }

  bool get isHandle {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element3;
      return element.name3 == 'Handle' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a `ffi.NativeFunction<???>` type.
  bool get isNativeFunction {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element3;
      return element.name3 == 'NativeFunction' && element.isFfiClass;
    }
    return false;
  }

  /// Returns `true` iff this is a `ffi.NativeType` type.
  bool get isNativeType {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element3;
      return element.name3 == 'NativeType' && element.isFfiClass;
    }
    return false;
  }

  bool get isOpaque {
    var self = this;
    return self is InterfaceType && self.element3.isOpaque;
  }

  /// Returns `true` iff this is a opaque type, i.e. a subtype of `Opaque`.
  bool get isOpaqueSubtype {
    var self = this;
    if (self is InterfaceType) {
      var superType = self.element3.supertype;
      if (superType != null) {
        return superType.element3.isOpaque;
      }
    }
    return false;
  }

  bool get isPointer {
    var self = this;
    return self is InterfaceType && self.element3.isPointer;
  }

  /// Only the subset of typed data classes that correspond to a Pointer.
  bool get isTypedData {
    var self = this;
    if (self is! InterfaceType) {
      return false;
    }
    if (!self.element3.isTypedDataClass) {
      return false;
    }
    var elementName = self.element3.name3!;
    if (!elementName.endsWith('List')) {
      return false;
    }
    if (elementName == 'Float32List' || elementName == 'Float64List') {
      return true;
    }
    var fixedIntegerTypeName = elementName.replaceAll('List', '');
    return FfiVerifier._primitiveIntegerNativeTypesFixedSize
        .contains(fixedIntegerTypeName);
  }

  /// Returns `true` iff this is a `ffi.VarArgs` type.
  bool get isVarArgs {
    var self = this;
    if (self is InterfaceType) {
      var element = self.element3;
      return element.name3 == 'VarArgs' && element.isFfiClass;
    }
    return false;
  }
}

extension on NamedType {
  /// If this is a name of class from `dart:ffi`, return it.
  ClassElement2? get ffiClass {
    return element2.ffiClass;
  }

  /// Return `true` if this represents a subtype of `Struct` or `Union`.
  bool get isAbiSpecificIntegerSubtype {
    var element = element2;
    if (element is ClassElement2) {
      return element.allSupertypes.any((e) => e.isAbiSpecificInteger);
    }
    return false;
  }

  /// Return `true` if this represents a subtype of `Struct` or `Union`.
  bool get isCompoundSubtype {
    var element = element2;
    if (element is ClassElement2) {
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
    var last = this.last;
    if (!last.isVarArgs) {
      return this;
    }
    var typeArgument = (last as InterfaceType).typeArguments.single;
    if (typeArgument is! RecordType) {
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
