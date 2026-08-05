// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid raw types.';

class NoRawTypes extends AnalysisRule {
  new()
    : super(
        name: LintNames.no_raw_types,
        description: _desc,
        state: .stable(since: .new(3, 13, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.noRawTypes;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  new(this.rule);

  @override
  void visitNamedType(NamedType node) {
    var parent = node.parent;
    if (parent is ConstructorName &&
        parent.parent is InstanceCreationExpression) {
      return;
    }

    if (node.typeArguments != null) return;

    var type = node.type;
    if (type == null) return;

    var element = node.element;
    if (element == null) return;

    List<DartType> typeArguments;
    var alias = type.alias;
    if (alias != null) {
      typeArguments = alias.typeArguments;
    } else if (type is InterfaceType) {
      typeArguments = type.typeArguments;
    } else {
      return;
    }

    if (!typeArguments.any((t) => t is DynamicType)) return;
    if (element.metadata.hasOptionalTypeArgs) return;

    if (node.parentEscapingTypeArguments
        case AsExpression() ||
            CastPattern() ||
            IsExpression() ||
            ObjectPattern() ||
            TypeLiteral()) {
      // Do not report a "strict raw type" warning in this case; too noisy,
      // especially in the case of unstructured data parsing, like JSON and
      // YAML.
      return;
    }

    rule.reportAtNode(node, arguments: [type]);
  }
}

extension on NamedType {
  AstNode get parentEscapingTypeArguments {
    var ancestor = parent!;
    while (ancestor is TypeArgumentList || ancestor is NamedType) {
      if (ancestor.parent case var grandancestor?) {
        ancestor = grandancestor;
      } else {
        return ancestor;
      }
    }
    return ancestor;
  }
}
