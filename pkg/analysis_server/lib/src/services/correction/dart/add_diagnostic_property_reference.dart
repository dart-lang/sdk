// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddDiagnosticPropertyReference extends ResolvedCorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE;

  @override
  FixKind get multiFixKind =>
      DartFixKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    String name;
    if (node is MethodDeclaration) {
      name = node.name.lexeme;
    } else if (node is VariableDeclaration) {
      name = node.name.lexeme;
    } else {
      return;
    }

    var classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null ||
        // TODO(dantup): Remove this and update this fix to handle
        //  augmenting the method once augmented() expressions are
        //  fully implemented.
        //  https://github.com/dart-lang/sdk/issues/55326
        classDeclaration.declaredElement!.isAugmentation ||
        !classDeclaration.declaredElement!.thisType.isDiagnosticable) {
      return;
    }

    var type = _getReturnType(node);
    if (type == null) {
      return;
    }

    String constructorId;
    List<DartType>? typeArgs;
    var constructorName = '';

    if (type is FunctionType) {
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
    } else if (type.isColor) {
      constructorId = 'ColorProperty';
    } else if (type.isMatrix4) {
      constructorId = 'TransformProperty';
    } else {
      constructorId = 'DiagnosticsProperty';
      if (!(type is DynamicType || type is InvalidType)) {
        typeArgs = [type];
      }
    }

    void writePropertyReference(
      DartEditBuilder builder, {
      required String prefix,
      required String builderName,
    }) {
      builder.write('$prefix$builderName.add($constructorId');
      if (typeArgs != null) {
        builder.write('<');
        builder.writeTypes(typeArgs);
        builder.write('>');
      } else if (type is DynamicType || type is InvalidType) {
        TypeAnnotation? declType;
        var decl = node.thisOrAncestorOfType<VariableDeclarationList>();
        if (decl != null) {
          declType = decl.type;
          // getter
        } else if (node is MethodDeclaration) {
          declType = node.returnType;
        }

        if (declType != null) {
          var typeText = utils.getNodeText(declType);
          if (typeText != 'dynamic') {
            builder.write('<');
            builder.write(utils.getNodeText(declType));
            builder.write('>');
          }
        }
      }
      builder.writeln("$constructorName('$name', $name));");
    }

    var debugFillProperties = classDeclaration.members
        .whereType<MethodDeclaration>()
        .where((e) => e.name.lexeme == 'debugFillProperties')
        .singleOrNull;
    if (debugFillProperties == null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.insertMethod(classDeclaration, (builder) {
          var declPrefix = utils.oneIndent;
          var bodyPrefix = utils.twoIndents;

          builder.writeln('@override');
          builder.writeln(
              '${declPrefix}void debugFillProperties(DiagnosticPropertiesBuilder properties) {');
          builder
              .writeln('${bodyPrefix}super.debugFillProperties(properties);');
          writePropertyReference(builder,
              prefix: bodyPrefix, builderName: 'properties');
          builder.write('$declPrefix}');
        });
      });
      return;
    }

    var body = debugFillProperties.body;
    if (body is BlockFunctionBody) {
      var functionBody = body;

      int offset;
      String prefix;
      if (functionBody.block.statements.isEmpty) {
        offset = functionBody.block.leftBracket.offset;
        prefix = utils.getLinePrefix(offset) + utils.oneIndent;
      } else {
        offset = functionBody.block.statements.last.endToken.offset;
        prefix = utils.getLinePrefix(offset);
      }

      var parameterList = debugFillProperties.parameters;
      if (parameterList == null) {
        return;
      }

      String? propertiesBuilderName;
      for (var parameter in parameterList.parameters) {
        if (parameter is SimpleFormalParameter) {
          var type = parameter.type;
          var identifier = parameter.name;
          if (type is NamedType && identifier != null) {
            if (type.name2.lexeme == 'DiagnosticPropertiesBuilder') {
              propertiesBuilderName = identifier.lexeme;
              break;
            }
          }
        }
      }
      if (propertiesBuilderName == null) {
        return;
      }

      var final_propertiesBuilderName = propertiesBuilderName;
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(utils.getLineNext(offset), (builder) {
          writePropertyReference(builder,
              prefix: prefix, builderName: final_propertiesBuilderName);
        });
      });
    }
  }

  /// Return the return type of the given [node].
  DartType? _getReturnType(AstNode node) {
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
    return type is InterfaceType && type.element is EnumElement;
  }

  bool _isIterable(DartType type) {
    return type.asInstanceOf(typeProvider.iterableElement) != null;
  }
}
