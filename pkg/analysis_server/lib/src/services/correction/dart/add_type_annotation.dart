// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddTypeAnnotation extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.ADD_TYPE_ANNOTATION;

  @override
  FixKind get fixKind => DartFixKind.ADD_TYPE_ANNOTATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is SimpleFormalParameter) {
        await _forSimpleFormalParameter(builder, node, parent);
        return;
      }
    }
    while (node != null) {
      if (node is VariableDeclarationList) {
        await _forVariableDeclaration(builder, node);
        return;
      } else if (node is DeclaredIdentifier) {
        await _forDeclaredIdentifier(builder, node);
        return;
      } else if (node is ForStatement) {
        var forLoopParts = node.forLoopParts;
        if (forLoopParts is ForEachParts) {
          var offset = this.node.offset;
          if (forLoopParts.iterable != null &&
              offset < forLoopParts.iterable.offset) {
            if (forLoopParts is ForEachPartsWithDeclaration) {
              await _forDeclaredIdentifier(builder, forLoopParts.loopVariable);
            }
          }
        }
        return;
      }
      node = node.parent;
    }
  }

  /// Configure the [utils] using the given [target].
  void _configureTargetLocation(Object target) {
    utils.targetClassElement = null;
    if (target is AstNode) {
      var targetClassDeclaration =
          target.thisOrAncestorOfType<ClassDeclaration>();
      if (targetClassDeclaration != null) {
        utils.targetClassElement = targetClassDeclaration.declaredElement;
      }
    }
  }

  Future<void> _forDeclaredIdentifier(
      ChangeBuilder builder, DeclaredIdentifier declaredIdentifier) async {
    // Ensure that there isn't already a type annotation.
    if (declaredIdentifier.type != null) {
      return;
    }
    var type = declaredIdentifier.declaredElement.type;
    if (type is! InterfaceType && type is! FunctionType) {
      return;
    }
    _configureTargetLocation(node);

    Future<bool> applyChange(ChangeBuilder builder) async {
      var validChange = true;
      await builder.addDartFileEdit(file, (builder) {
        var keyword = declaredIdentifier.keyword;
        if (keyword.keyword == Keyword.VAR) {
          builder.addReplacement(range.token(keyword), (builder) {
            validChange = builder.writeType(type);
          });
        } else {
          builder.addInsertion(declaredIdentifier.identifier.offset, (builder) {
            validChange = builder.writeType(type);
            builder.write(' ');
          });
        }
      });
      return validChange;
    }

    if (await applyChange(_temporaryBuilder(builder))) {
      await applyChange(builder);
    }
  }

  Future<void> _forSimpleFormalParameter(ChangeBuilder builder,
      SimpleIdentifier name, SimpleFormalParameter parameter) async {
    // Ensure that there isn't already a type annotation.
    if (parameter.type != null) {
      return;
    }
    // Prepare the type.
    var type = parameter.declaredElement.type;
    // TODO(scheglov) If the parameter is in a method declaration, and if the
    // method overrides a method that has a type for the corresponding
    // parameter, it would be nice to copy down the type from the overridden
    // method.
    if (type is! InterfaceType) {
      return;
    }
    _configureTargetLocation(node);

    Future<bool> applyChange(ChangeBuilder builder) async {
      var validChange = true;
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(name.offset, (builder) {
          validChange = builder.writeType(type);
          if (validChange) {
            builder.write(' ');
          }
        });
      });
      return validChange;
    }

    if (await applyChange(_temporaryBuilder(builder))) {
      await applyChange(builder);
    }
  }

  Future<void> _forVariableDeclaration(
      ChangeBuilder builder, VariableDeclarationList declarationList) async {
    // Ensure that there isn't already a type annotation.
    if (declarationList.type != null) {
      return;
    }
    // Ensure that there is a single VariableDeclaration.
    List<VariableDeclaration> variables = declarationList.variables;
    if (variables.length != 1) {
      return;
    }
    var variable = variables[0];
    // Ensure that the selection is not after the name of the variable.
    if (selectionOffset > variable.name.end) {
      return;
    }
    // Ensure that there is an initializer to get the type from.
    var initializer = variable.initializer;
    if (initializer == null) {
      return;
    }
    var type = initializer.staticType;
    // prepare type source
    if ((type is! InterfaceType || type.isDartCoreNull) &&
        type is! FunctionType) {
      return;
    }
    _configureTargetLocation(node);

    Future<bool> applyChange(ChangeBuilder builder) async {
      var validChange = true;
      await builder.addDartFileEdit(file, (builder) {
        var keyword = declarationList.keyword;
        if (keyword?.keyword == Keyword.VAR) {
          builder.addReplacement(range.token(keyword), (builder) {
            validChange = builder.writeType(type);
          });
        } else {
          builder.addInsertion(variable.offset, (builder) {
            validChange = builder.writeType(type);
            builder.write(' ');
          });
        }
      });
      return validChange;
    }

    if (await applyChange(_temporaryBuilder(builder))) {
      await applyChange(builder);
    }
  }

  ChangeBuilder _temporaryBuilder(ChangeBuilder builder) =>
      ChangeBuilder(workspace: (builder as ChangeBuilderImpl).workspace);

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddTypeAnnotation newInstance() => AddTypeAnnotation();
}
