// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_codes.dart';
import 'package:linter/src/lint_names.dart';

class AddDiagnosticPropertyReference extends ResolvedCorrectionProducer {
  AddDiagnosticPropertyReference({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.addDiagnosticPropertyReference;

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
    if (classDeclaration == null) {
      return;
    }

    var classFragment = classDeclaration.declaredFragment!;
    var classElement = classFragment.element;

    // TODO(dantup): Remove this and update this fix to handle
    //  augmenting the method once augmented() expressions are
    //  fully implemented.
    //  https://github.com/dart-lang/sdk/issues/55326
    if (classFragment.isAugmentation ||
        !classElement.thisType.isDiagnosticable) {
      return;
    }

    if (applyingBulkFixes) {
      await _fixAllDiagnosticPropertyReferences(builder, classDeclaration);
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

    var debugFillProperties = classDeclaration.debugFillPropertiesDeclaration;
    if (debugFillProperties == null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.insertMethod(classDeclaration, (builder) {
          var declPrefix = utils.oneIndent;
          var bodyPrefix = utils.twoIndents;

          builder.writeln('@override');
          builder.writeln(
            '${declPrefix}void debugFillProperties(DiagnosticPropertiesBuilder properties) {',
          );
          builder.writeln(
            '${bodyPrefix}super.debugFillProperties(properties);',
          );
          writePropertyReference(
            builder,
            prefix: bodyPrefix,
            builderName: 'properties',
          );
          builder.write('$declPrefix}');
        });
      });
      return;
    }

    var body = debugFillProperties.body;
    if (body is BlockFunctionBody) {
      var propertiesBuilderName = _computeName(debugFillProperties);
      if (propertiesBuilderName == null) {
        return;
      }

      var (:offset, :prefix) = _offsetAndPrefixOfBlock(body.block);
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(utils.getLineNext(offset), (builder) {
          writePropertyReference(
            builder,
            prefix: prefix,
            builderName: propertiesBuilderName,
          );
        });
      });
    }
  }

  /// Returns the name given to the first parameter of a declaration of the
  /// `debugFillProperties` method which is typed as
  /// `DiagnosticPropertiesBuilder`.
  String? _computeName(MethodDeclaration debugFillProperties) {
    var parameterList = debugFillProperties.parameters;
    if (parameterList == null) {
      return null;
    }

    for (var parameter in parameterList.parameters) {
      if (parameter is SimpleFormalParameter) {
        var type = parameter.type;
        var identifier = parameter.name;
        if (type is NamedType &&
            identifier != null &&
            type.name.lexeme == 'DiagnosticPropertiesBuilder') {
          return identifier.lexeme;
        }
      }
    }

    return null;
  }

  /// Fixes all instances of the [LintNames.diagnostic_describe_all_properties]
  /// in the given [declaration].
  Future<void> _fixAllDiagnosticPropertyReferences(
    ChangeBuilder builder,
    ClassDeclaration declaration,
  ) async {
    var propertyDiagnostics = _getAllDiagnosticsInClass(declaration);

    // Create fixes only when its the first diagnostic.
    if (propertyDiagnostics.isNotEmpty &&
        diagnosticOffset != propertyDiagnostics.first.offset) {
      return;
    }

    void writePropertyReference(
      DartEditBuilder builder, {
      required String prefix,
      required String builderName,
      required _PropertyInfo property,
    }) {
      builder.write('$prefix$builderName.add(${property.constructorId}');
      var type = property.type;
      if (property.typeArgs != null) {
        builder.write('<');
        builder.writeTypes(property.typeArgs);
        builder.write('>');
      } else if (type is DynamicType || type is InvalidType) {
        var declType = property.declType;

        if (declType != null) {
          var typeText = utils.getNodeText(declType);
          if (typeText != 'dynamic') {
            builder.write('<');
            builder.write(utils.getNodeText(declType));
            builder.write('>');
          }
        }
      }
      builder.writeln(
        "${property.constructorName}('${property.name}', ${property.name}));",
      );
    }

    var properties = <_PropertyInfo>[];

    // Compute the information for all the properties to be added.
    for (var diagnostic in propertyDiagnostics) {
      var node = unitResult.unit.nodeCovering(
        offset: diagnostic.offset,
        length: diagnostic.length,
      );
      if (node == null) {
        continue;
      }
      var propertyInfo = _getPropertyInfo(node);
      if (propertyInfo.type != null) {
        properties.add(propertyInfo);
      }
    }

    if (properties.isEmpty) {
      return;
    }

    var debugFillProperties = declaration.debugFillPropertiesDeclaration;
    if (debugFillProperties == null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.insertMethod(declaration, (builder) {
          var declPrefix = utils.oneIndent;
          var bodyPrefix = utils.twoIndents;

          builder.writeln('@override');
          builder.writeln(
            '${declPrefix}void debugFillProperties(DiagnosticPropertiesBuilder properties) {',
          );
          builder.writeln(
            '${bodyPrefix}super.debugFillProperties(properties);',
          );

          for (var property in properties) {
            writePropertyReference(
              builder,
              prefix: bodyPrefix,
              builderName: 'properties',
              property: property,
            );
          }
          builder.write('$declPrefix}');
        });
      });
      return;
    }

    var body = debugFillProperties.body;
    if (body is BlockFunctionBody) {
      var propertiesBuilderName = _computeName(debugFillProperties);
      if (propertiesBuilderName == null) {
        return;
      }

      var (:offset, :prefix) = _offsetAndPrefixOfBlock(body.block);
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(utils.getLineNext(offset), (builder) {
          for (var property in properties) {
            writePropertyReference(
              builder,
              prefix: prefix,
              builderName: propertiesBuilderName,
              property: property,
            );
          }
        });
      });
    }
  }

  /// Returns a list of all the [Diagnostic]s of type
  /// [LinterLintCode.diagnostic_describe_all_properties] for the given
  /// [declaration].
  List<Diagnostic> _getAllDiagnosticsInClass(ClassDeclaration declaration) {
    var propertyDiagnostics = <Diagnostic>[];
    var startOffset = declaration.offset;
    var endOffset = startOffset + declaration.length;
    for (var diagnostic in unitResult.diagnostics) {
      var diagnosticCode = diagnostic.diagnosticCode;
      if (diagnosticCode.type == DiagnosticType.LINT &&
          diagnosticCode == LinterLintCode.diagnostic_describe_all_properties &&
          diagnostic.offset > startOffset &&
          diagnostic.offset < endOffset) {
        propertyDiagnostics.add(diagnostic);
      }
    }

    return propertyDiagnostics;
  }

  /// Computes the information for the property at the given [node].
  _PropertyInfo _getPropertyInfo(AstNode node) {
    String? name;
    if (node is MethodDeclaration) {
      name = node.name.lexeme;
    } else if (node is VariableDeclaration) {
      name = node.name.lexeme;
    }
    var type = _getReturnType(node);
    if (type == null) {
      return _PropertyInfo(name, type, '', [], '', null);
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

    TypeAnnotation? declType;
    if (type is DynamicType || type is InvalidType) {
      var decl = node.thisOrAncestorOfType<VariableDeclarationList>();
      if (decl != null) {
        declType = decl.type;
        // getter
      } else if (node is MethodDeclaration) {
        declType = node.returnType;
      }
    }

    return _PropertyInfo(
      name,
      type,
      constructorId,
      typeArgs,
      constructorName,
      declType,
    );
  }

  /// Return the return type of the given [node].
  DartType? _getReturnType(AstNode node) {
    switch (node) {
      case MethodDeclaration():
        var element = node.declaredFragment?.element;
        if (element is GetterElement) {
          return element.returnType;
        }
      case VariableDeclaration():
        var element = node.declaredFragment?.element;
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
    return type.asInstanceOf2(typeProvider.iterableElement) != null;
  }

  ({int offset, String prefix}) _offsetAndPrefixOfBlock(Block block) {
    if (block.statements.isEmpty) {
      var offset = block.leftBracket.offset;
      return (
        offset: offset,
        prefix: utils.getLinePrefix(offset) + utils.oneIndent,
      );
    } else {
      var offset = block.statements.last.endToken.offset;
      return (offset: offset, prefix: utils.getLinePrefix(offset));
    }
  }
}

class _PropertyInfo {
  final String? name;
  final DartType? type;
  final String constructorId;
  final List<DartType>? typeArgs;
  final String constructorName;
  final TypeAnnotation? declType;

  _PropertyInfo(
    this.name,
    this.type,
    this.constructorId,
    this.typeArgs,
    this.constructorName,
    this.declType,
  );
}

extension on ClassDeclaration {
  MethodDeclaration? get debugFillPropertiesDeclaration =>
      members
          .whereType<MethodDeclaration>()
          .where((e) => e.name.lexeme == 'debugFillProperties')
          .singleOrNull;
}
