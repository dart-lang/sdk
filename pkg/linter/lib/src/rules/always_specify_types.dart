// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../util/ascii_utils.dart';

const _desc = r'Specify type annotations.';

class AlwaysSpecifyTypes extends MultiAnalysisRule {
  AlwaysSpecifyTypes()
    : super(name: LintNames.always_specify_types, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.alwaysSpecifyTypesAddType,
    diag.alwaysSpecifyTypesReplaceKeyword,
    diag.alwaysSpecifyTypesSpecifyType,
    diag.alwaysSpecifyTypesSplitToTypes,
  ];

  @override
  List<String> get incompatibleRules => const [
    LintNames.avoid_types_on_closure_parameters,
    LintNames.omit_local_variable_types,
    LintNames.omit_obvious_local_variable_types,
    LintNames.omit_obvious_property_types,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addDeclaredIdentifier(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
    registry.addSimpleFormalParameter(this, visitor);
    registry.addNamedType(this, visitor);
    registry.addDeclaredVariablePattern(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;

  _Visitor(this.rule);

  void checkLiteral(TypedLiteral literal) {
    if (literal.typeArguments == null) {
      rule.reportAtToken(
        literal.beginToken,
        diagnosticCode: diag.alwaysSpecifyTypesAddType,
      );
    }
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    var keyword = node.keyword;
    if (node.type == null && keyword != null) {
      var element = node.declaredFragment?.element;
      if (element is VariableElement) {
        if (keyword.keyword == Keyword.VAR) {
          rule.reportAtToken(
            keyword,
            diagnosticCode: diag.alwaysSpecifyTypesReplaceKeyword,
            arguments: [keyword.lexeme, element!.type],
          );
        } else {
          rule.reportAtToken(
            keyword,
            diagnosticCode: diag.alwaysSpecifyTypesSpecifyType,
            arguments: [element!.type],
          );
        }
      }
    }
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.type == null) {
      var type = node.matchedValueType!;
      var keyword = node.keyword;
      var tokenToLint = keyword ?? node.name;
      if (keyword != null && keyword.keyword == Keyword.VAR) {
        rule.reportAtToken(
          tokenToLint,
          arguments: [keyword.lexeme, type],
          diagnosticCode: diag.alwaysSpecifyTypesReplaceKeyword,
        );
      } else {
        rule.reportAtToken(
          tokenToLint,
          arguments: [type],
          diagnosticCode: diag.alwaysSpecifyTypesSpecifyType,
        );
      }
    }
  }

  @override
  void visitListLiteral(ListLiteral literal) {
    checkLiteral(literal);
  }

  @override
  void visitNamedType(NamedType namedType) {
    var type = namedType.type;
    if (type is InterfaceType) {
      var element = namedType.element;
      if (element is TypeParameterizedElement &&
          element.typeParameters.isNotEmpty &&
          namedType.typeArguments == null &&
          namedType.parent is! IsExpression &&
          !element.metadata.hasOptionalTypeArgs) {
        rule.reportAtNode(
          namedType,
          diagnosticCode: diag.alwaysSpecifyTypesAddType,
        );
      }
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral literal) {
    checkLiteral(literal);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter param) {
    var name = param.name;
    if (name != null && param.type == null && !name.lexeme.isJustUnderscores) {
      var keyword = param.keyword;
      var type = param.declaredFragment?.element.type;
      if (keyword != null) {
        if (keyword.type == Keyword.VAR &&
            type != null &&
            type is! DynamicType) {
          rule.reportAtToken(
            keyword,
            arguments: [keyword.lexeme, type],
            diagnosticCode: diag.alwaysSpecifyTypesReplaceKeyword,
          );
        } else {
          rule.reportAtToken(
            keyword,
            diagnosticCode: diag.alwaysSpecifyTypesAddType,
          );
        }
      } else if (type != null) {
        if (type is DynamicType) {
          rule.reportAtNode(
            param,
            diagnosticCode: diag.alwaysSpecifyTypesAddType,
          );
        } else {
          rule.reportAtNode(
            param,
            arguments: [type],
            diagnosticCode: diag.alwaysSpecifyTypesSpecifyType,
          );
        }
      }
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList list) {
    var keyword = list.keyword;
    if (list.type == null && keyword != null) {
      Set<String> types;
      var parent = list.parent;
      if (parent is TopLevelVariableDeclaration) {
        types = _getTypes(parent.variables);
      } else if (parent is ForPartsWithDeclarations) {
        types = _getTypes(parent.variables);
      } else if (parent is FieldDeclaration) {
        types = _getTypes(parent.fields);
      } else if (parent is VariableDeclarationStatement) {
        types = _getTypes(parent.variables);
      } else {
        return;
      }

      var singleType = types.length == 1;

      List<Object> arguments;
      DiagnosticCode lintCode;
      if (types.isEmpty) {
        arguments = [];
        lintCode = diag.alwaysSpecifyTypesAddType;
      } else if (keyword.type == Keyword.VAR) {
        if (singleType) {
          arguments = [keyword.lexeme, types.first];
          lintCode = diag.alwaysSpecifyTypesReplaceKeyword;
        } else {
          arguments = [];
          lintCode = diag.alwaysSpecifyTypesSplitToTypes;
        }
      } else {
        if (singleType) {
          arguments = [types.first];
          lintCode = diag.alwaysSpecifyTypesSpecifyType;
        } else {
          arguments = [];
          lintCode = diag.alwaysSpecifyTypesAddType;
        }
      }
      rule.reportAtToken(
        keyword,
        arguments: arguments,
        diagnosticCode: lintCode,
      );
    }
  }

  Set<String> _getTypes(VariableDeclarationList list) {
    var types = <String>{};
    for (var variable in list.variables) {
      var initializer = variable.initializer;
      if (initializer != null) {
        DartType? type;
        if (initializer is Identifier) {
          var element = initializer.element;
          if (element is LocalVariableElement) {
            type = element.type;
          }
        }

        type ??= variable.initializer?.staticType;

        if (type != null) {
          types.add(type.getDisplayString());
        }
      }
    }
    return types;
  }
}
