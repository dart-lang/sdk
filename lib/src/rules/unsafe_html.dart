// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _descPrefix = r'Avoid unsafe HTML APIs';
const _desc = '$_descPrefix.';

const _details = r'''

**AVOID** assigning directly to the src field of an EmbedElement,
IFrameElement, ImageElement, or ScriptElement, or the href field of an
AnchorElement.


**BAD:**
```
var script = ScriptElement()..src = 'foo.js';
```
''';

class UnsafeHtml extends LintRule implements NodeLintRule {
  UnsafeHtml()
      : super(
            name: 'unsafe_html',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addAssignmentExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const hrefAttributeCode =
      LintCode('unsafe_html', '$_descPrefix (assigning "href" attribute).');
  static const srcAttributeCode =
      LintCode('unsafe_html', '$_descPrefix (assigning "src" attribute).');

  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    final leftPart = node.leftHandSide.unParenthesized;
    if (leftPart is PropertyAccess) {
      _checkAssignment(leftPart.realTarget, leftPart.propertyName, node);
    } else if (leftPart is PrefixedIdentifier) {
      _checkAssignment(leftPart.prefix, leftPart.identifier, node);
    }
  }

  void _checkAssignment(Expression target, SimpleIdentifier property,
      AssignmentExpression assignment) {
    if (property == null || target == null) return;

    // It is more efficient to first check if `src` (or `href`) is being
    // assigned, _then_ check if the target of an interesting  type.
    if (property.name == 'src') {
      DartType type = target.staticType;
      if (type.isDynamic ||
          DartTypeUtilities.extendsClass(
              type, 'EmbedElement', 'dart.dom.html') ||
          DartTypeUtilities.extendsClass(
              type, 'IFrameElement', 'dart.dom.html') ||
          DartTypeUtilities.extendsClass(
              type, 'ImageElement', 'dart.dom.html') ||
          DartTypeUtilities.extendsClass(
              type, 'ScriptElement', 'dart.dom.html')) {
        rule.reportLint(assignment, errorCode: srcAttributeCode);
      }
    } else if (property.name == 'href') {
      DartType type = target.staticType;
      if (type.isDynamic ||
          DartTypeUtilities.extendsClass(
              type, 'AnchorElement', 'dart.dom.html')) {
        rule.reportLint(assignment, errorCode: hrefAttributeCode);
      }
    }
  }
}
