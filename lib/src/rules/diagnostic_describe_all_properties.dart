// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../util/dart_type_utilities.dart';
import '../util/flutter_utils.dart';

const _desc = r'DO reference all public properties in debug methods.';

const _details = r'''
**DO** reference all public properties in `debug` method implementations.

Implementers of `DiagnosticableMixin` should reference all public properties in
a `debugFillProperties(...)` or `debugDescribeChildren(...)` method
implementation to improve debuggability at runtime.

Public properties are defined as fields and getters that are

* not package-private (e.g., prefixed with `_`)
* not `static` or overriding
* not themselves `Widget`s or collections of `Widget`s

In addition, the "debug" prefix is treated specially for properties in Flutter.
For the purposes of diagnostics, a property `foo` and a prefixed property
`debugFoo` are treated as effectively describing the same property and it is
sufficient to refer to one or the other.

**BAD:**
```
class Absorber extends Widget {
  bool get absorbing => _absorbing;
  bool _absorbing;
  bool get ignoringSemantics => _ignoringSemantics;
  bool _ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    // Missing reference to ignoringSemantics
  }
}  
```

**GOOD:**
```
class Absorber extends Widget {
  bool get absorbing => _absorbing;
  bool _absorbing;
  bool get ignoringSemantics => _ignoringSemantics;
  bool _ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}  
```
''';

class DiagnosticsDescribeAllProperties extends LintRule
    implements NodeLintRule {
  DiagnosticsDescribeAllProperties()
      : super(
          name: 'diagnostic_describe_all_properties',
          description: _desc,
          details: _details,
          maturity: Maturity.stable,
          group: Group.errors,
        );

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  void removeReferences(
      MethodDeclaration method, List<SimpleIdentifier> properties) {
    if (method == null) {
      return;
    }
    DartTypeUtilities.traverseNodesInDFS(method.body)
        .whereType<SimpleIdentifier>()
        .forEach((p) {
      var debugName;
      var name;
      const debugPrefix = 'debug';
      if (p.name.startsWith(debugPrefix) &&
          p.name.length > debugPrefix.length) {
        debugName = p.name;
        name =
            '${p.name[debugPrefix.length].toLowerCase()}${p.name.substring(debugPrefix.length + 1)}';
      } else {
        name = p.name;
        debugName =
            '$debugPrefix${p.name[0].toUpperCase()}${p.name.substring(1)}';
      }
      properties.removeWhere(
          (property) => property.name == debugName || property.name == name);
    });
  }

  bool skipForDiagnostic(
          {Element element, DartType type, SimpleIdentifier name}) =>
      isPrivate(name) || _isOverridingMember(element) || isWidgetProperty(type);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // We only care about Diagnosticables.
    final type = node.declaredElement.thisType;
    if (!DartTypeUtilities.implementsInterface(
        type, 'DiagnosticableMixin', '')) {
      return;
    }

    final properties = <SimpleIdentifier>[];
    for (var member in node.members) {
      if (member is MethodDeclaration && member.isGetter) {
        if (!member.isStatic &&
            !skipForDiagnostic(
              element: member.declaredElement,
              name: member.name,
              type: member.returnType?.type,
            )) {
          properties.add(member.name);
        }
      } else if (member is FieldDeclaration) {
        for (var v in member.fields.variables) {
          if (!v.declaredElement.isStatic &&
              !skipForDiagnostic(
                element: v.declaredElement,
                name: v.name,
                type: v.declaredElement.type,
              )) {
            properties.add(v.name);
          }
        }
      }
    }

    if (properties.isEmpty) {
      return;
    }

    final debugFillProperties = node.getMethod('debugFillProperties');
    final debugDescribeChildren = node.getMethod('debugDescribeChildren');

    // Remove any defined in debugFillProperties.
    removeReferences(debugFillProperties, properties);

    // Remove any defined in debugDescribeChildren.
    removeReferences(debugDescribeChildren, properties);

    // Flag the rest.
    properties.forEach(rule.reportLint);
  }

  bool _isOverridingMember(Element member) {
    if (member == null) {
      return false;
    }

    final classElement = member.thisOrAncestorOfType<ClassElement>();
    if (classElement == null) {
      return false;
    }
    final libraryUri = classElement.library.source.uri;
    return context.inheritanceManager.getInherited(
            classElement.thisType, Name(libraryUri, member.name)) !=
        null;
  }
}
