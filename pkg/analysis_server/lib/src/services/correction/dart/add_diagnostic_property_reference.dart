// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:meta/meta.dart';

class AddDiagnosticPropertyReference extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE;

  @override
  FixKind get fixKind => DartFixKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! SimpleIdentifier) {
      return;
    }

    var classDeclaration = node.thisOrAncestorOfType<ClassOrMixinDeclaration>();
    if (classDeclaration == null ||
        !flutter.isDiagnosticable(classDeclaration.declaredElement.thisType)) {
      return;
    }

    SimpleIdentifier name = node;
    final parent = node.parent;

    var type = _getReturnType(parent);
    if (type == null) {
      return;
    }

    String constructorId;
    List<DartType> typeArgs;
    var constructorName = '';

    if (type.element is FunctionTypedElement) {
      constructorId = 'ObjectFlagProperty';
      typeArgs = [type];
      constructorName = '.has';
    } else if (type.isDartCoreInt) {
      constructorId = 'IntProperty';
    } else if (type.isDartCoreDouble) {
      constructorId = 'DoubleProperty';
    } else if (type.isDartCoreString) {
      constructorId = 'StringProperty';
    } else if (_isEnum(type)) {
      constructorId = 'EnumProperty';
      typeArgs = [type];
    } else if (_isIterable(type)) {
      constructorId = 'IterableProperty';
      typeArgs = (type as InterfaceType).typeArguments;
    } else if (flutter.isColor(type)) {
      constructorId = 'ColorProperty';
    } else if (flutter.isMatrix4(type)) {
      constructorId = 'TransformProperty';
    } else {
      constructorId = 'DiagnosticsProperty';
      if (!type.isDynamic) {
        typeArgs = [type];
      }
    }

    void writePropertyReference(
      DartEditBuilder builder, {
      @required String prefix,
      @required String builderName,
    }) {
      builder.write('$prefix$builderName.add($constructorId');
      if (typeArgs != null) {
        builder.write('<');
        builder.writeTypes(typeArgs);
        builder.write('>');
      } else if (type.isDynamic) {
        TypeAnnotation declType;
        final decl = node.thisOrAncestorOfType<VariableDeclarationList>();
        if (decl != null) {
          declType = decl.type;
          // getter
        } else if (parent is MethodDeclaration) {
          declType = parent.returnType;
        }

        if (declType != null) {
          final typeText = utils.getNodeText(declType);
          if (typeText != 'dynamic') {
            builder.write('<');
            builder.write(utils.getNodeText(declType));
            builder.write('>');
          }
        }
      }
      builder.writeln("$constructorName('${name.name}', ${name.name}));");
    }

    final debugFillProperties =
        classDeclaration.getMethod('debugFillProperties');
    if (debugFillProperties == null) {
      final insertOffset =
          utils.prepareNewMethodLocation(classDeclaration).offset;
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(utils.getLineNext(insertOffset), (builder) {
          final declPrefix =
              utils.getLinePrefix(classDeclaration.offset) + utils.getIndent(1);
          final bodyPrefix = declPrefix + utils.getIndent(1);

          builder.writeln('$declPrefix@override');
          builder.writeln(
              '${declPrefix}void debugFillProperties(DiagnosticPropertiesBuilder properties) {');
          builder
              .writeln('${bodyPrefix}super.debugFillProperties(properties);');
          writePropertyReference(builder,
              prefix: bodyPrefix, builderName: 'properties');
          builder.writeln('$declPrefix}');
        });
      });
      return;
    }

    final body = debugFillProperties.body;
    if (body is BlockFunctionBody) {
      var functionBody = body;

      int offset;
      String prefix;
      if (functionBody.block.statements.isEmpty) {
        offset = functionBody.block.leftBracket.offset;
        prefix = utils.getLinePrefix(offset) + utils.getIndent(1);
      } else {
        offset = functionBody.block.statements.last.endToken.offset;
        prefix = utils.getLinePrefix(offset);
      }

      var parameters = debugFillProperties.parameters.parameters;
      String propertiesBuilderName;
      for (var parameter in parameters) {
        if (parameter is SimpleFormalParameter) {
          final type = parameter.type;
          if (type is TypeName) {
            if (type.name.name == 'DiagnosticPropertiesBuilder') {
              propertiesBuilderName = parameter.identifier.name;
              break;
            }
          }
        }
      }
      if (propertiesBuilderName == null) {
        return null;
      }

      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(utils.getLineNext(offset), (builder) {
          writePropertyReference(builder,
              prefix: prefix, builderName: propertiesBuilderName);
        });
      });
    }
  }

  /// Return the return type of the given [node].
  DartType _getReturnType(AstNode node) {
    if (node is MethodDeclaration) {
      // Getter.
      var element = node.declaredElement;
      if (element is PropertyAccessorElement) {
        return element.returnType;
      }
    } else if (node is VariableDeclaration) {
      // Field.
      var element = node.declaredElement;
      if (element is FieldElement) {
        return element.type;
      }
    }
    return null;
  }

  bool _isEnum(DartType type) {
    final element = type.element;
    return element is ClassElement && element.isEnum;
  }

  bool _isIterable(DartType type) {
    return type.asInstanceOf(typeProvider.iterableElement) != null;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddDiagnosticPropertyReference newInstance() =>
      AddDiagnosticPropertyReference();
}
