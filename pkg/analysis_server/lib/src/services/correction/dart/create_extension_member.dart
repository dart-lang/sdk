// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
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
  FixKind get fixKind => DartFixKind.CREATE_EXTENSION_GETTER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }
    if (!nameNode.inGetterContext()) {
      return;
    }

    _getterName = nameNode.name;

    // prepare target
    DartType? targetType;
    switch (nameNode.parent) {
      case PrefixedIdentifier prefixedIdentifier:
        if (prefixedIdentifier.identifier == nameNode) {
          targetType = prefixedIdentifier.prefix.staticType;
        }
      case PropertyAccess propertyAccess:
        if (propertyAccess.propertyName == nameNode) {
          targetType = propertyAccess.realTarget.staticType;
        }
      case ExpressionFunctionBody expressionFunctionBody:
        if (expressionFunctionBody.expression == nameNode) {
          targetType = node.enclosingInstanceElement?.thisType;
        }
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

    void writeGetter(DartEditBuilder builder) {
      if (fieldType != null) {
        builder.writeType(fieldType, methodBeingCopied: methodBeingCopied);
        builder.write(' ');
      }
      builder.write('get $_getterName => ');
      builder.addLinkedEdit('VALUE', (builder) {
        builder.write('null');
      });
      builder.write(';');
    }

    var updatedExisting = await _updateExistingExtension(builder, targetType, (
      extension,
      builder,
    ) {
      builder.insertGetter(extension, (builder) {
        writeGetter(builder);
      });
    });
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
  FixKind get fixKind => DartFixKind.CREATE_EXTENSION_METHOD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }

    var invocation = nameNode.parent;
    if (invocation is! MethodInvocation) {
      return;
    }
    if (invocation.methodName != nameNode) {
      return;
    }
    _methodName = nameNode.name;

    var target = invocation.realTarget;
    if (target == null) {
      return;
    }

    // We need the type for the extension.
    var targetType = target.staticType;
    if (targetType == null ||
        targetType is DynamicType ||
        targetType is InvalidType) {
      return;
    }

    // Try to find the return type.
    var returnType = inferUndefinedExpressionType(invocation);

    void writeMethod(DartEditBuilder builder) {
      if (builder.writeType(
        returnType,
        groupName: 'RETURN_TYPE',
        methodBeingCopied: methodBeingCopied,
      )) {
        builder.write(' ');
      }

      builder.addLinkedEdit('NAME', (builder) {
        builder.write(_methodName);
      });

      builder.writeTypeParameters(
        [
              returnType,
              ...invocation.argumentList.arguments.map((e) => e.staticType),
            ].typeParameters
            .whereNot([targetType].typeParameters.contains)
            .toList(),
      );

      builder.write('(');
      builder.writeParametersMatchingArguments(
        invocation.argumentList,
        methodBeingCopied: methodBeingCopied,
      );
      builder.write(') {}');
    }

    var updatedExisting = await _updateExistingExtension(builder, targetType, (
      extension,
      builder,
    ) {
      builder.insertMethod(extension, (builder) {
        writeMethod(builder);
      });
    });
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
  FixKind get fixKind => DartFixKind.CREATE_EXTENSION_OPERATOR;

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
    var targetType = target.staticType;
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

    void writeMethod(DartEditBuilder builder) {
      if (builder.writeType(
        returnType,
        groupName: 'RETURN_TYPE',
        methodBeingCopied: methodBeingCopied,
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
          methodBeingCopied: methodBeingCopied,
        );
      }
      if (indexSetter) {
        builder.write(', ');
        builder.writeFormalParameter(
          'newValue',
          type: assigningType,
          methodBeingCopied: methodBeingCopied,
        );
      }
      builder.write(') {}');
    }

    var updatedExisting = await _updateExistingExtension(builder, targetType, (
      extension,
      builder,
    ) {
      builder.insertMethod(extension, (builder) {
        writeMethod(builder);
      });
    });
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
  FixKind get fixKind => DartFixKind.CREATE_EXTENSION_SETTER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
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
    if (target == null) {
      return;
    }

    // TODO(FMorschel): We should take into account if the target type contains
    // a setter for the same name and stop the fix from being applied.
    // We need the type for the extension.
    var targetType = target.staticType;
    if (targetType == null ||
        targetType is DynamicType ||
        targetType is InvalidType) {
      return;
    }

    // Try to find the type of the field.
    var fieldTypeNode = climbPropertyAccess(nameNode);
    var fieldType = inferUndefinedExpressionType(fieldTypeNode);

    void writeSetter(DartEditBuilder builder) {
      builder.writeSetterDeclaration(
        _setterName,
        nameGroupName: 'NAME',
        parameterType: fieldType,
        parameterTypeGroupName: 'TYPE',
        methodBeingCopied: methodBeingCopied,
      );
    }

    var updatedExisting = await _updateExistingExtension(builder, targetType, (
      extension,
      builder,
    ) {
      builder.insertGetter(extension, (builder) {
        writeSetter(builder);
      });
    });
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
            methodBeingCopied: methodBeingCopied,
          );
          builder.write(' ');
        }
        builder.write('on ');
        builder.writeType(targetType, methodBeingCopied: methodBeingCopied);
        builder.writeln(' {');
        builder.write('  ');
        write(builder);
        builder.writeln();
        builder.write('}');
      });
    });
  }

  ExtensionDeclaration? _existingExtension(DartType targetType) {
    for (var existingExtension in unitResult.unit.declarations) {
      if (existingExtension is ExtensionDeclaration) {
        var element = existingExtension.declaredFragment!.element;
        var instantiated = [element].applicableTo(
          targetLibrary: libraryElement2,
          targetType: targetType as TypeImpl,
          strictCasts: true,
        );
        if (instantiated.isNotEmpty) {
          return existingExtension;
        }
      }
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
  List<TypeParameterElement> get typeParameters =>
      {
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
    var indexName = Name.forLibrary(element.library2, TokenType.INDEX.lexeme);
    var indexEqName = Name.forLibrary(
      element.library2,
      TokenType.INDEX_EQ.lexeme,
    );
    var member =
        element.getInterfaceMember(indexName) ??
        element.getInterfaceMember(indexEqName);
    return member != null;
  }
}
