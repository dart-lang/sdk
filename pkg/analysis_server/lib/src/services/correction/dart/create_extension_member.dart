// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateExtensionGetter extends _CreateExtensionMember {
  String _getterName = '';

  CreateExtensionGetter({
    required super.context,
  });

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

    void writeGetter(DartEditBuilder builder) {
      if (fieldType != null) {
        builder.writeType(fieldType);
        builder.write(' ');
      }
      builder.write('get $_getterName => ');
      builder.addLinkedEdit('VALUE', (builder) {
        builder.write('null');
      });
      builder.write(';');
    }

    var updatedExisting = await _updateExistingExtension(
      builder,
      targetType,
      (extension, builder) {
        builder.insertGetter(extension, (builder) {
          writeGetter(builder);
        });
      },
    );
    if (updatedExisting) {
      return;
    }

    await _addNewExtension(builder, targetType, nameNode, writeGetter);
  }
}

class CreateExtensionMethod extends _CreateExtensionMember {
  String _methodName = '';

  CreateExtensionMethod({
    required super.context,
  });

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
      if (builder.writeType(returnType, groupName: 'RETURN_TYPE')) {
        builder.write(' ');
      }

      builder.addLinkedEdit('NAME', (builder) {
        builder.write(_methodName);
      });

      builder.write('(');
      builder.writeParametersMatchingArguments(invocation.argumentList);
      builder.write(') {}');
    }

    var updatedExisting = await _updateExistingExtension(
      builder,
      targetType,
      (extension, builder) {
        builder.insertMethod(extension, (builder) {
          writeMethod(builder);
        });
      },
    );
    if (updatedExisting) {
      return;
    }

    await _addNewExtension(builder, targetType, nameNode, writeMethod);
  }
}

class CreateExtensionSetter extends _CreateExtensionMember {
  String _setterName = '';

  CreateExtensionSetter({
    required super.context,
  });

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
      );
    }

    var updatedExisting = await _updateExistingExtension(
      builder,
      targetType,
      (extension, builder) {
        builder.insertGetter(extension, (builder) {
          writeSetter(builder);
        });
      },
    );
    if (updatedExisting) {
      return;
    }

    await _addNewExtension(builder, targetType, nameNode, writeSetter);
  }
}

abstract class _CreateExtensionMember extends ResolvedCorrectionProducer {
  _CreateExtensionMember({
    required super.context,
  });

  @override
  CorrectionApplicability get applicability {
    // Not predictably the correct action.
    return CorrectionApplicability.singleLocation;
  }

  Future<void> _addNewExtension(
    ChangeBuilder builder,
    DartType targetType,
    SimpleIdentifier nameNode,
    void Function(DartEditBuilder builder) write,
  ) async {
    // The new extension should be added after it.
    var enclosingUnitChild = nameNode.enclosingUnitChild;
    if (enclosingUnitChild == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(enclosingUnitChild.end, (builder) {
        builder.writeln();
        builder.writeln();
        builder.write('extension on ');
        builder.writeType(targetType);
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
        var element = existingExtension.declaredElement!;
        var instantiated = [element].applicableTo(
          targetLibrary: libraryElement,
          targetType: targetType,
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
    void Function(
      ExtensionDeclaration existing,
      DartFileEditBuilder builder,
    ) write,
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
