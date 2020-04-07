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

**AVOID**

* assigning directly to the `href` field of an AnchorElement
* assigning directly to the `src` field of an EmbedElement, IFrameElement,
  ImageElement, or ScriptElement
* assigning directly to the `srcdoc` field of an IFrameElement
* calling the `createFragment` method of Element
* calling the `setInnerHtml` method of Element


**BAD:**
```
var script = ScriptElement()..src = 'foo.js';
```
''';

extension on DartType {
  /// Returns whether this type extends [className] from the dart:html library.
  bool extendsDartHtmlClass(String className) =>
      DartTypeUtilities.extendsClass(this, className, 'dart.dom.html');
}

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
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const hrefAttributeCode =
      LintCode('unsafe_html', '$_descPrefix (assigning "href" attribute).');
  static const srcAttributeCode =
      LintCode('unsafe_html', '$_descPrefix (assigning "src" attribute).');
  static const srcdocAttributeCode =
      LintCode('unsafe_html', '$_descPrefix (assigning "srcdoc" attribute).');
  static const createFragmentMethodCode = LintCode('unsafe_html',
      '$_descPrefix (calling the "createFragment" method of Element).');
  static const setInnerHtmlMethodCode = LintCode('unsafe_html',
      '$_descPrefix (calling the "setInnerHtml" method of Element).');

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
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

    // It is more efficient to check the setter's name before checking whether
    // the target is an interesting type.
    if (property.name == 'href') {
      final type = target.staticType;
      if (type.isDynamic || type.extendsDartHtmlClass('AnchorElement')) {
        rule.reportLint(assignment, errorCode: hrefAttributeCode);
      }
    } else if (property.name == 'src') {
      final type = target.staticType;
      if (type.isDynamic ||
          type.extendsDartHtmlClass('EmbedElement') ||
          type.extendsDartHtmlClass('IFrameElement') ||
          type.extendsDartHtmlClass('ImageElement') ||
          type.extendsDartHtmlClass('ScriptElement')) {
        rule.reportLint(assignment, errorCode: srcAttributeCode);
      }
    } else if (property.name == 'srcdoc') {
      final type = target.staticType;
      if (type.isDynamic || type.extendsDartHtmlClass('IFrameElement')) {
        rule.reportLint(assignment, errorCode: srcdocAttributeCode);
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var type = node.target?.staticType;
    if (type == null) return;

    var methodName = node.methodName?.name;
    if (methodName == null) return;

    if (methodName == 'createFragment' &&
        (type.isDynamic || type.extendsDartHtmlClass('Element'))) {
      rule.reportLint(node, errorCode: createFragmentMethodCode);
    } else if (methodName == 'setInnerHtml' &&
        (type.isDynamic || type.extendsDartHtmlClass('Element'))) {
      rule.reportLint(node, errorCode: setInnerHtmlMethodCode);
    }
  }
}
