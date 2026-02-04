// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';

class CreateExtensionGetter extends _CreateExtensionMember {
  String _getterName = '';

  CreateExtensionGetter({required super.context});

  @override
  List<String> get fixArguments => [_getterName];

  @override
  FixKind get fixKind => DartFixKind.createExtensionGetter;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var addStaticKeyword = inStaticContext;
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }
    if (!nameNode.inGetterContext()) {
      return;
    }

    _getterName = nameNode.name;

    // prepare target
    Expression? target;
    switch (nameNode.parent) {
      case PrefixedIdentifier prefixedIdentifier:
        if (prefixedIdentifier.identifier == nameNode) {
          target = prefixedIdentifier.prefix;
        }
      case PropertyAccess propertyAccess:
        if (propertyAccess.propertyName == nameNode) {
          target = propertyAccess.realTarget;
        }
    }

    DartType? targetType;
    ExtensionElement? extensionElement;
    if (target is ExtensionOverride) {
      targetType = target.extendedType;
      extensionElement = target.element;
    } else if (target == null) {
      extensionElement = node.enclosingInstanceElement?.ifTypeOrNull();
      targetType = extensionElement?.thisType;
    } else {
      // We need the type for the extension.
      targetType = target.staticType;
    }
    if (targetType == null && target is SimpleIdentifier) {
      extensionElement = target.element?.ifTypeOrNull();
      targetType = extensionElement?.thisType;
      addStaticKeyword = true;
    }

    // TODO(FMorschel): We should take into account if the target type contains
    // a setter for the same name and stop the fix from being applied.
    // We need the type for the extension.
    if (targetType == null ||
        targetType is DynamicType ||
        targetType is InvalidType) {
      return;
    }

    // Try to find the type of the field.
    var fieldTypeNode = climbPropertyAccess(nameNode);
    var fieldType = inferUndefinedExpressionType(fieldTypeNode);
    if (fieldType is InvalidType) {
      return;
    }

    void writeGetter(DartEditBuilder builder) {
      if (addStaticKeyword) {
        builder.write('static ');
      }
      if (fieldType != null) {
        builder.writeType(
          fieldType,
          typeParametersInScope: methodBeingCopied?.typeParameters,
        );
        builder.write(' ');
      }
      builder.write('get $_getterName => ');
      builder.addLinkedEdit('VALUE', (builder) {
        builder.write('null');
      });
      builder.write(';');
    }

    bool updatedExisting;
    if (extensionElement != null) {
      updatedExisting = await _updateExistingExtension2(
        builder,
        extensionElement,
        (extension, builder) {
          builder.insertGetter(extension, (builder) {
            writeGetter(builder);
          });
        },
      );
    } else {
      updatedExisting = await _updateExistingExtension(builder, targetType, (
        extension,
        builder,
      ) {
        builder.insertGetter(extension, (builder) {
          writeGetter(builder);
        });
      });
    }
    if (updatedExisting) {
      return;
    }

    await _addNewExtension(
      builder,
      targetType,
      nameNode,
      writeGetter,
      involvedTypes: [fieldType],
    );
  }
}

class CreateExtensionMethod extends _CreateExtensionMember {
  String _methodName = '';

  CreateExtensionMethod({required super.context});

  @override
  List<String> get fixArguments => [_methodName];

  @override
  FixKind get fixKind => DartFixKind.createExtensionMethod;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var addStaticKeyword = inStaticContext;
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }

    var parent = nameNode.parent;
    var isInvocation = true;
    MethodInvocation? invocation;
    Expression? target;
    if (parent is! MethodInvocation) {
      isInvocation = false;
      target = switch (parent) {
        PropertyAccess(:var realTarget) => realTarget,
        PrefixedIdentifier(:var prefix) => prefix,
        _ => null,
      };
    } else if (parent.methodName == nameNode) {
      invocation = parent;
      target = invocation.realTarget;
    } else {
      return;
    }
    _methodName = nameNode.name;

    DartType? targetType;
    ExtensionElement? extensionElement;
    if (target is ExtensionOverride) {
      targetType = target.extendedType;
      extensionElement = target.element;
    } else if (target == null) {
      var enclosingInstanceElement = node.enclosingInstanceElement;
      extensionElement = enclosingInstanceElement?.ifTypeOrNull();
      targetType = enclosingInstanceElement?.thisType;
    } else {
      // We need the type for the extension.
      targetType = target.staticType;
    }
    if (targetType == null && target is SimpleIdentifier) {
      extensionElement = target.element?.ifTypeOrNull();
      targetType = extensionElement?.thisType;
      addStaticKeyword = true;
    }
    if (targetType == null ||
        targetType is DynamicType ||
        targetType is InvalidType) {
      return;
    }

    // Try to find the return type.
    DartType? returnType;
    if (invocation ?? parent case Expression exp) {
      returnType = inferUndefinedExpressionType(exp);
    }
    if (returnType is InvalidType) {
      return;
    }

    if (returnType is InterfaceType && returnType.isDartCoreFunction) {
      returnType = FunctionTypeImpl(
        typeParameters: const [],
        parameters: const [],
        returnType: DynamicTypeImpl.instance,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    if (returnType is! FunctionType && !isInvocation) {
      return;
    }

    var functionType = !isInvocation ? returnType as FunctionType : null;

    void writeMethod(DartEditBuilder builder) {
      if (addStaticKeyword) {
        builder.write('static ');
      }

      if (builder.writeType(
        isInvocation ? returnType : functionType?.returnType,
        groupName: 'RETURN_TYPE',
        typeParametersInScope:
            methodBeingCopied?.typeParameters ??
            (isInvocation
                ? [if (returnType is TypeParameterType) returnType.element]
                : functionType?.typeParameters),
      )) {
        builder.write(' ');
      }

      builder.addLinkedEdit('NAME', (builder) {
        builder.write(_methodName);
      });

      builder.writeTypeParameters(
        ([
              isInvocation ? returnType : functionType?.returnType,
              ...?functionType?.formalParameters.map((e) => e.type),
              ...?invocation?.argumentList.arguments.map((e) => e.staticType),
            ].typeParameters..addAll([...?functionType?.typeParameters]))
            .whereNot([targetType].typeParameters.contains)
            .toList(),
      );

      if (invocation?.argumentList case var arguments?) {
        builder.write('(');
        builder.writeParametersMatchingArguments(
          arguments,
          typeParametersInScope: methodBeingCopied?.typeParameters,
        );
        builder.write(')');
      } else if (functionType != null) {
        builder.writeFormalParameters(
          functionType.formalParameters,
          typeParametersInScope: methodBeingCopied?.typeParameters,
        );
      }
      builder.write(' {}');
    }

    bool updatedExisting;
    if (extensionElement != null) {
      updatedExisting = await _updateExistingExtension2(
        builder,
        extensionElement,
        (extension, builder) {
          builder.insertMethod(extension, (builder) {
            writeMethod(builder);
          });
        },
      );
    } else {
      updatedExisting = await _updateExistingExtension(builder, targetType, (
        extension,
        builder,
      ) {
        builder.insertMethod(extension, (builder) {
          writeMethod(builder);
        });
      });
    }
    if (updatedExisting) {
      return;
    }

    await _addNewExtension(builder, targetType, nameNode, writeMethod);
  }
}

class CreateExtensionOperator extends _CreateExtensionMember {
  String _operator = '';

  CreateExtensionOperator({required super.context});

  @override
  List<String>? get fixArguments => [_operator];

  @override
  FixKind get fixKind => DartFixKind.createExtensionOperator;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    bool indexSetter = false;
    bool innerParameter = true;
    var node = this.node;
    if (node is! Expression) {
      return;
    }

    Expression? target;
    DartType? parameterType;
    DartType? assigningType;

    switch (node) {
      case IndexExpression(:var parent):
        if (node.target?.staticType?.element.declaresIndex ?? true) {
          return;
        }
        target = node.target;
        _operator = TokenType.INDEX.lexeme;
        parameterType = node.index.staticType;
        if (parameterType == null) {
          return;
        }
        if (parent case AssignmentExpression(
          :var leftHandSide,
          :var rightHandSide,
        ) when leftHandSide == node) {
          assigningType = rightHandSide.staticType;
          indexSetter = true;
          _operator = TokenType.INDEX_EQ.lexeme;
        }
      case BinaryExpression():
        target = node.leftOperand;
        _operator = node.operator.lexeme;
        parameterType = node.rightOperand.staticType;
        if (parameterType == null) {
          return;
        }
      case PrefixExpression():
        target = node.operand;
        _operator = node.operator.lexeme;
        innerParameter = false;
    }

    if (target == null) {
      return;
    }

    // We need the type for the extension.
    DartType? targetType;
    ExtensionElement? extensionElement;
    if (target is ExtensionOverride) {
      targetType = target.extendedType;
      extensionElement = target.element;
    } else {
      targetType = target.staticType;
    }
    if (targetType == null && target is SimpleIdentifier) {
      extensionElement = target.element?.ifTypeOrNull();
      targetType = extensionElement?.thisType;
    }
    if (targetType == null ||
        targetType is DynamicType ||
        targetType is InvalidType) {
      return;
    }

    DartType returnType;
    // If this is an index setter, the return type must be void.
    if (indexSetter) {
      returnType = VoidTypeImpl.instance;
    } else {
      // Try to find the return type.
      returnType = inferUndefinedExpressionType(node) ?? VoidTypeImpl.instance;
    }
    if (returnType is InvalidType) {
      return;
    }

    void writeMethod(DartEditBuilder builder) {
      if (builder.writeType(
        returnType,
        groupName: 'RETURN_TYPE',
        typeParametersInScope: methodBeingCopied?.typeParameters,
      )) {
        builder.write(' ');
      }

      builder.write('operator ');
      builder.write(_operator);

      builder.write('(');
      if (innerParameter) {
        builder.writeFormalParameter(
          indexSetter ? 'index' : 'other',
          type: parameterType,
          typeParametersInScope: methodBeingCopied?.typeParameters,
        );
      }
      if (indexSetter) {
        builder.write(', ');
        builder.writeFormalParameter(
          'newValue',
          type: assigningType,
          typeParametersInScope: methodBeingCopied?.typeParameters,
        );
      }
      builder.write(') {}');
    }

    bool updatedExisting;
    if (extensionElement != null) {
      updatedExisting = await _updateExistingExtension2(
        builder,
        extensionElement,
        (extension, builder) {
          builder.insertMethod(extension, (builder) {
            writeMethod(builder);
          });
        },
      );
    } else {
      updatedExisting = await _updateExistingExtension(builder, targetType, (
        extension,
        builder,
      ) {
        builder.insertMethod(extension, (builder) {
          writeMethod(builder);
        });
      });
    }
    if (updatedExisting) {
      return;
    }

    await _addNewExtension(
      builder,
      targetType,
      target,
      writeMethod,
      involvedTypes: [parameterType, returnType],
    );
  }
}

class CreateExtensionSetter extends _CreateExtensionMember {
  String _setterName = '';

  CreateExtensionSetter({required super.context});

  @override
  List<String> get fixArguments => [_setterName];

  @override
  FixKind get fixKind => DartFixKind.createExtensionSetter;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var addStaticKeyword = inStaticContext;
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }
    if (!nameNode.inSetterContext()) {
      return;
    }

    _setterName = nameNode.name;

    // prepare target
    Expression? target;
    switch (nameNode.parent) {
      case PrefixedIdentifier prefixedIdentifier:
        if (prefixedIdentifier.identifier == nameNode) {
          target = prefixedIdentifier.prefix;
        }
      case PropertyAccess propertyAccess:
        if (propertyAccess.propertyName == nameNode) {
          target = propertyAccess.realTarget;
        }
    }

    DartType? targetType;
    ExtensionElement? extensionElement;
    if (target is ExtensionOverride) {
      targetType = target.extendedType;
      extensionElement = target.element;
    } else if (target == null) {
      extensionElement = node.enclosingInstanceElement?.ifTypeOrNull();
      targetType = extensionElement?.thisType;
    } else {
      // We need the type for the extension.
      targetType = target.staticType;
    }
    if (targetType == null && target is SimpleIdentifier) {
      extensionElement = target.element?.ifTypeOrNull();
      targetType = extensionElement?.thisType;
      addStaticKeyword = true;
    }

    // TODO(FMorschel): We should take into account if the target type contains
    // a setter for the same name and stop the fix from being applied.
    // We need the type for the extension.
    if (targetType == null ||
        targetType is DynamicType ||
        targetType is InvalidType) {
      return;
    }

    // Try to find the type of the field.
    var fieldTypeNode = climbPropertyAccess(nameNode);
    var fieldType = inferUndefinedExpressionType(fieldTypeNode);
    if (fieldType is InvalidType) {
      return;
    }

    void writeSetter(DartEditBuilder builder) {
      builder.writeSetterDeclaration(
        _setterName,
        nameGroupName: 'NAME',
        parameterType: fieldType,
        isStatic: addStaticKeyword,
        parameterTypeGroupName: 'TYPE',
        typeParametersInScope: methodBeingCopied?.typeParameters,
      );
    }

    bool updatedExisting;
    if (extensionElement != null) {
      updatedExisting = await _updateExistingExtension2(
        builder,
        extensionElement,
        (extension, builder) {
          builder.insertGetter(extension, (builder) {
            writeSetter(builder);
          });
        },
      );
    } else {
      updatedExisting = await _updateExistingExtension(builder, targetType, (
        extension,
        builder,
      ) {
        builder.insertGetter(extension, (builder) {
          writeSetter(builder);
        });
      });
    }
    if (updatedExisting) {
      return;
    }

    await _addNewExtension(
      builder,
      targetType,
      nameNode,
      writeSetter,
      involvedTypes: [fieldType],
    );
  }
}

abstract class _CreateExtensionMember extends ResolvedCorrectionProducer {
  _CreateExtensionMember({required super.context});

  @override
  CorrectionApplicability get applicability {
    // Not predictably the correct action.
    return CorrectionApplicability.singleLocation;
  }

  ExecutableElement? get methodBeingCopied =>
      _enclosingFunction?.declaredFragment?.element;

  FunctionDeclaration? get _enclosingFunction => node.thisOrAncestorOfType();

  /// Creates a change for creating a new extension on the given [targetType].
  ///
  /// The new extension should be added after the [nameNode].
  ///
  /// The [write] function is used to write the body of the new extension.
  /// Meaning a method, getter, setter or operator.
  ///
  /// The [involvedTypes] are the types that are used in the new extension and
  /// it's member. This is used to determine the type parameters of the new
  /// extension.
  Future<void> _addNewExtension(
    ChangeBuilder builder,
    DartType targetType,
    AstNode nameNode,
    void Function(DartEditBuilder builder) write, {
    List<DartType?> involvedTypes = const [],
  }) async {
    // The new extension should be added after it.
    var enclosingUnitChild = nameNode.enclosingUnitChild;
    if (enclosingUnitChild == null) {
      return;
    }

    var extensionTypeParameters = [targetType, ...involvedTypes].typeParameters;

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(enclosingUnitChild.end, (builder) {
        builder.writeln();
        builder.writeln();
        builder.write('extension ');
        if (extensionTypeParameters.isNotEmpty) {
          builder.writeTypeParameters(
            extensionTypeParameters,
            typeParametersInScope: methodBeingCopied?.typeParameters,
          );
          builder.write(' ');
        }
        builder.write('on ');
        builder.writeType(
          targetType,
          typeParametersInScope: methodBeingCopied?.typeParameters,
        );
        builder.writeln(' {');
        builder.write('  ');
        write(builder);
        builder.writeln();
        builder.write('}');
      });
    });
  }

  ExtensionDeclaration? _existingExtension(DartType targetType) {
    for (var existingExtension
        in unitResult.unit.declarations.whereType<ExtensionDeclaration>()) {
      var extendedType =
          existingExtension.declaredFragment!.element.extendedType;
      if (extendedType == targetType) {
        return existingExtension;
      }
    }
    return null;
  }

  Future<(String, ExtensionDeclaration)?> _existingExtension2(
    ExtensionElement extension,
  ) async {
    var library = extension.library;
    if (library.isInSdk) {
      return null;
    }
    var existingExtension = await getDeclarationNodeFromElement(
      extension,
      includeExtensions: true,
    );
    if (existingExtension is! ExtensionDeclaration) {
      return null;
    }
    var path =
        existingExtension.declaredFragment?.libraryFragment.source.fullName;
    if (path == null) {
      // Should never happen.
      assert(
        false,
        'How is path to an existing extension null? $existingExtension',
      );
      return null;
    }
    var unit = await unitResult.session.getResolvedUnit(path);
    if (unit is! ResolvedUnitResult) {
      return null;
    }
    var instantiated = [extension].applicableTo(
      targetLibrary: libraryElement2,
      targetType: extension.thisType as TypeImpl,
      strictCasts: true,
    );
    if (instantiated.isNotEmpty) {
      return (unit.path, existingExtension);
    }
    return null;
  }

  Future<bool> _updateExistingExtension(
    ChangeBuilder builder,
    DartType targetType,
    void Function(ExtensionDeclaration existing, DartFileEditBuilder builder)
    write,
  ) async {
    var extension = _existingExtension(targetType);
    if (extension == null) {
      return false;
    }

    await builder.addDartFileEdit(file, (builder) {
      write(extension, builder);
    });
    return true;
  }

  Future<bool> _updateExistingExtension2(
    ChangeBuilder builder,
    ExtensionElement extensionElement,
    void Function(ExtensionDeclaration existing, DartFileEditBuilder builder)
    write,
  ) async {
    var record = await _existingExtension2(extensionElement);
    if (record == null) {
      return false;
    }
    var (file, extension) = record;

    await builder.addDartFileEdit(file, (builder) {
      write(extension, builder);
    });
    return true;
  }
}

extension on List<DartType?> {
  /// Returns a list of type parameters that are used in the types.
  ///
  /// Iterates over every type in the list:
  /// - If it is itself a [TypeParameterType], it is added to the list.
  /// - If it is itself a [TypeParameterType] and it has a
  /// [TypeParameterType.bound], we get the type parameters with this getter.
  /// - If it is an [InterfaceType], we get the [InterfaceType.typeArguments]
  /// it uses and get any type parameters they use by using this same getter.
  ///
  /// These types are added internally to a set so that we don't add duplicates.
  List<TypeParameterElement> get typeParameters => {
    for (var type in whereType<TypeParameterType>()) ...[
      type.element,
      ...[type.bound].typeParameters,
    ],
    for (var type in whereType<InterfaceType>())
      ...type.typeArguments.typeParameters,
  }.toList();
}

extension on Element? {
  bool get declaresIndex {
    var element = this;
    if (element is! InterfaceElement) {
      return false;
    }
    var indexName = Name.forLibrary(element.library, TokenType.INDEX.lexeme);
    var indexEqName = Name.forLibrary(
      element.library,
      TokenType.INDEX_EQ.lexeme,
    );
    var member =
        element.getInterfaceMember(indexName) ??
        element.getInterfaceMember(indexEqName);
    return member != null;
  }
}
