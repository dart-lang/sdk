// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = '$_descPrefix.';
const _descPrefix = r'Avoid unsafe HTML APIs';

const _details = r'''
**AVOID**

* assigning directly to the `href` field of an AnchorElement
* assigning directly to the `src` field of an EmbedElement, IFrameElement, or
  ScriptElement
* assigning directly to the `srcdoc` field of an IFrameElement
* calling the `createFragment` method of Element
* calling the `open` method of Window
* calling the `setInnerHtml` method of Element
* calling the `Element.html` constructor
* calling the `DocumentFragment.html` constructor


**BAD:**
```dart
var script = ScriptElement()..src = 'foo.js';
```
''';

class UnsafeHtml extends LintRule {
  // TODO(brianwilkerson) These lint codes aren't being used by the lint, but
  //  are being used to pass the test that ensures that all lint rules define
  //  their own codes. We would like to use the codes in the future, but doing
  //  so requires coordination with other tool teams.
  static const LintCode attributeCode = LintCode(
      'unsafe_html', "Assigning to the attribute '{0}' is unsafe.",
      correctionMessage: 'Try finding a different way to implement the page.',
      uniqueName: 'LintCode.unsafe_html_attribute');

  static const LintCode methodCode = LintCode(
      'unsafe_html', "Invoking the method '{0}' is unsafe.",
      correctionMessage: 'Try finding a different way to implement the page.',
      uniqueName: 'LintCode.unsafe_html_method');

  static const LintCode constructorCode = LintCode(
      'unsafe_html', "Invoking the constructor '{0}' is unsafe.",
      correctionMessage: 'Try finding a different way to implement the page.',
      uniqueName: 'LintCode.unsafe_html_constructor');

  UnsafeHtml()
      : super(
            name: 'unsafe_html',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  List<LintCode> get lintCodes => [
        _Visitor.unsafeAttributeCode,
        _Visitor.unsafeMethodCode,
        _Visitor.unsafeConstructorCode
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
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
  // Proposed replacements are commented out in `UnsafeHtml`.
  static const unsafeAttributeCode = SecurityLintCode(
    'unsafe_html',
    '$_descPrefix (assigning "{0}" attribute).',
    uniqueName: 'LintCode.unsafe_html_attribute',
  );
  static const unsafeMethodCode = SecurityLintCode(
    'unsafe_html',
    "$_descPrefix (calling the '{0}' method of {1}).",
    uniqueName: 'LintCode.unsafe_html_method',
  );
  static const unsafeConstructorCode = SecurityLintCode(
    'unsafe_html',
    "$_descPrefix (calling the '{0}' constructor of {1}).",
    uniqueName: 'LintCode.unsafe_html_constructor',
  );

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var leftPart = node.leftHandSide.unParenthesized;
    if (leftPart is SimpleIdentifier) {
      var leftPartElement = node.writeElement;
      if (leftPartElement == null) return;
      var enclosingElement = leftPartElement.enclosingElement;
      if (enclosingElement is ClassElement) {
        _checkAssignment(enclosingElement.thisType, leftPart, node);
      }
    } else if (leftPart is PropertyAccess) {
      _checkAssignment(
          leftPart.realTarget.staticType, leftPart.propertyName, node);
    } else if (leftPart is PrefixedIdentifier) {
      _checkAssignment(leftPart.prefix.staticType, leftPart.identifier, node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var type = node.staticType;
    if (type == null) return;

    var constructorName = node.constructorName;
    if (constructorName.name?.name == 'html') {
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
    var methodName = node.methodName.name;

    // The static type of the target.
    DartType? type;
    if (node.realTarget == null) {
      // Implicit `this` target.
      var methodElement = node.methodName.staticElement;
      if (methodElement == null) return;
      var enclosingElement = methodElement.enclosingElement;
      if (enclosingElement is ClassElement) {
        type = enclosingElement.thisType;
      } else {
        return;
      }
    } else {
      type = node.realTarget?.staticType;
      if (type == null) return;
    }

    if (methodName == 'createFragment' &&
        (type is DynamicType || type.extendsDartHtmlClass('Element'))) {
      rule.reportLint(node,
          arguments: ['createFragment', 'Element'],
          errorCode: unsafeMethodCode);
    } else if (methodName == 'setInnerHtml' &&
        (type is DynamicType || type.extendsDartHtmlClass('Element'))) {
      rule.reportLint(node,
          arguments: ['setInnerHtml', 'Element'], errorCode: unsafeMethodCode);
    } else if (methodName == 'open' &&
        (type is DynamicType || type.extendsDartHtmlClass('Window'))) {
      rule.reportLint(node,
          arguments: ['open', 'Window'], errorCode: unsafeMethodCode);
    }
  }

  void _checkAssignment(DartType? type, SimpleIdentifier property,
      AssignmentExpression assignment) {
    if (type == null) return;

    // It is more efficient to check the setter's name before checking whether
    // the target is an interesting type.
    if (property.name == 'href') {
      if (type is DynamicType || type.extendsDartHtmlClass('AnchorElement')) {
        rule.reportLint(assignment,
            arguments: ['href'], errorCode: unsafeAttributeCode);
      }
    } else if (property.name == 'src') {
      if (type is DynamicType ||
          type.extendsDartHtmlClass('EmbedElement') ||
          type.extendsDartHtmlClass('IFrameElement') ||
          type.extendsDartHtmlClass('ScriptElement')) {
        rule.reportLint(assignment,
            arguments: ['src'], errorCode: unsafeAttributeCode);
      }
    } else if (property.name == 'srcdoc') {
      if (type is DynamicType || type.extendsDartHtmlClass('IFrameElement')) {
        rule.reportLint(assignment,
            arguments: ['srcdoc'], errorCode: unsafeAttributeCode);
      }
    }
  }
}

extension on DartType? {
  /// Returns whether this type extends [className] from the dart:html library.
  bool extendsDartHtmlClass(String className) =>
      extendsClass(className, 'dart.dom.html');
}
