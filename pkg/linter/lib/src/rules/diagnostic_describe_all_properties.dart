// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';
import '../util/flutter_utils.dart';

const _desc = r'DO reference all public properties in debug methods.';

class DiagnosticDescribeAllProperties extends AnalysisRule {
  DiagnosticDescribeAllProperties()
    : super(
        name: LintNames.diagnostic_describe_all_properties,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.diagnosticDescribeAllProperties;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final List<Token> properties;
  _IdentifierVisitor(this.properties);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    String debugName;
    String name;
    const debugPrefix = 'debug';
    if (node.name.startsWith(debugPrefix) &&
        node.name.length > debugPrefix.length) {
      debugName = node.name;
      name =
          '${node.name[debugPrefix.length].toLowerCase()}'
          '${node.name.substring(debugPrefix.length + 1)}';
    } else {
      name = node.name;
      debugName =
          '$debugPrefix${node.name[0].toUpperCase()}${node.name.substring(1)}';
    }
    properties.removeWhere(
      (property) => property.lexeme == debugName || property.lexeme == name,
    );

    super.visitSimpleIdentifier(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  void removeReferences(MethodDeclaration? method, List<Token> properties) {
    method?.body.accept(_IdentifierVisitor(properties));
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // We only care about Diagnosticables.
    var type = node.declaredFragment?.element.thisType;
    if (!type.implementsInterface('Diagnosticable', '')) return;

    var body = node.body;
    if (body is! BlockClassBody) {
      return;
    }

    var properties = <Token>[];

    // Check primary constructor for declaring parameters.
    if (node.namePart case PrimaryConstructorDeclaration namePart) {
      for (var parameter in namePart.formalParameters.parameters) {
        var declaredElement = parameter.declaredFragment?.element;
        if (declaredElement is FieldFormalParameterElement &&
            declaredElement.isDeclaring) {
          var field = declaredElement.field;
          if (field == null) continue;
          if (field.type.isWidgetProperty) continue;
          if (field.shouldBeDescribed) {
            var name = parameter.name;
            if (name != null) {
              properties.add(name);
            }
          }
        }
      }
    }

    for (var member in body.members) {
      if (member is MethodDeclaration && member.isGetter) {
        if (member.isStatic) continue;
        var declaredElement = member.declaredFragment?.element;
        if (declaredElement == null) continue;
        if (declaredElement.type.returnType.isWidgetProperty) continue;
        if (declaredElement.shouldBeDescribed) {
          properties.add(member.name);
        }
      } else if (member is FieldDeclaration) {
        for (var v in member.fields.variables) {
          if (member.isStatic) continue;
          var declaredElement = v.declaredFragment?.element;
          if (declaredElement == null) continue;
          if (declaredElement.type.isWidgetProperty) continue;
          if (declaredElement.shouldBeDescribed) {
            properties.add(v.name);
          }
        }
      }
    }

    if (properties.isEmpty) return;

    var debugFillProperties = body.members.getMethod('debugFillProperties');
    var debugDescribeChildren = body.members.getMethod('debugDescribeChildren');

    // Remove any defined in `debugFillProperties`.
    removeReferences(debugFillProperties, properties);

    // Remove any defined in `debugDescribeChildren`.
    removeReferences(debugDescribeChildren, properties);

    // Flag the rest.
    properties.forEach(rule.reportAtToken);
  }
}

extension on Element {
  bool get shouldBeDescribed => isPublic && overriddenMember == null;
}

extension on List<ClassMember> {
  MethodDeclaration? getMethod(String name) => whereType<MethodDeclaration>()
      .firstWhereOrNull((node) => node.name.lexeme == name);
}
