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
* calling the `open` method of Window
* calling the `setInnerHtml` method of Element
* calling the `Element.html` constructor
* calling the `DocumentFragment.html` constructor


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
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  // TODO(srawlins): Reference attributes ('href', 'src', and 'srcdoc') with
  // single-quotes to match the convention in the analyzer and linter packages.
  // This requires some coordination within Google, as various allow-lists are
  // keyed on the exact text of the LintCode message.
  static const unsafeAttributeCode =
      LintCode('unsafe_html', '$_descPrefix (assigning "{0}" attribute).');
  static const unsafeMethodCode = LintCode(
      'unsafe_html', "$_descPrefix (calling the '{0}' method of {1}).");
  static const unsafeConstructorCode = LintCode(
      'unsafe_html', "$_descPrefix (calling the '{0}' constructor of {1}).");

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
        rule.reportLint(assignment,
            arguments: ['href'], errorCode: unsafeAttributeCode);
      }
    } else if (property.name == 'src') {
      final type = target.staticType;
      if (type.isDynamic ||
          type.extendsDartHtmlClass('EmbedElement') ||
          type.extendsDartHtmlClass('IFrameElement') ||
          type.extendsDartHtmlClass('ImageElement') ||
          type.extendsDartHtmlClass('ScriptElement')) {
        rule.reportLint(assignment,
            arguments: ['src'], errorCode: unsafeAttributeCode);
      }
    } else if (property.name == 'srcdoc') {
      final type = target.staticType;
      if (type.isDynamic || type.extendsDartHtmlClass('IFrameElement')) {
        rule.reportLint(assignment,
            arguments: ['srcdoc'], errorCode: unsafeAttributeCode);
      }
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var type = node.staticType;
    if (type == null) return;

    var constructorName = node.constructorName;
    if (constructorName?.name?.name == 'html') {
      if (type.extendsDartHtmlClass('DocumentFragment')) {
        rule.reportLint(node,
            arguments: ['html', 'DocumentFragment'],
            errorCode: unsafeConstructorCode);
      } else if (type.extendsDartHtmlClass('Element')) {
        rule.reportLint(node,
            arguments: ['html', 'Element'], errorCode: unsafeConstructorCode);
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
      rule.reportLint(node,
          arguments: ['createFragment', 'Element'],
          errorCode: unsafeMethodCode);
    } else if (methodName == 'setInnerHtml' &&
        (type.isDynamic || type.extendsDartHtmlClass('Element'))) {
      rule.reportLint(node,
          arguments: ['setInnerHtml', 'Element'], errorCode: unsafeMethodCode);
    } else if (methodName == 'open' &&
        (type.isDynamic || type.extendsDartHtmlClass('Window'))) {
      rule.reportLint(node,
          arguments: ['open', 'Window'], errorCode: unsafeMethodCode);
    }
  }
}
