// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';
import '../util/flutter_utils.dart';

const _desc = r'DO reference all public properties in debug methods.';

const _details = r'''
**DO** reference all public properties in `debug` method implementations.

Implementers of `Diagnosticable` should reference all public properties in
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
```dart
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
```dart
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

class DiagnosticDescribeAllProperties extends LintRule {
  static const LintCode code = LintCode(
      'diagnostic_describe_all_properties',
      "The public property isn't described by either 'debugFillProperties' or "
          "'debugDescribeChildren'.",
      correctionMessage: 'Try describing the property.');

  DiagnosticDescribeAllProperties()
      : super(
          name: 'diagnostic_describe_all_properties',
          description: _desc,
          details: _details,
          group: Group.errors,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor {
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
      name = '${node.name[debugPrefix.length].toLowerCase()}'
          '${node.name.substring(debugPrefix.length + 1)}';
    } else {
      name = node.name;
      debugName =
          '$debugPrefix${node.name[0].toUpperCase()}${node.name.substring(1)}';
    }
    properties.removeWhere(
        (property) => property.lexeme == debugName || property.lexeme == name);

    super.visitSimpleIdentifier(node);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  void removeReferences(MethodDeclaration? method, List<Token> properties) {
    method?.body.accept(_IdentifierVisitor(properties));
  }

  bool skipForDiagnostic({Element? element, DartType? type, Token? name}) =>
      isPrivate(name) || _isOverridingMember(element) || isWidgetProperty(type);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // We only care about Diagnosticables.
    var type = node.declaredElement?.thisType;
    if (!type.implementsInterface('Diagnosticable', '')) {
      return;
    }

    var properties = <Token>[];
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
          var declaredElement = v.declaredElement;
          if (declaredElement != null &&
              !declaredElement.isStatic &&
              !skipForDiagnostic(
                element: declaredElement,
                name: v.name,
                type: declaredElement.type,
              )) {
            properties.add(v.name);
          }
        }
      }
    }

    if (properties.isEmpty) {
      return;
    }

    var debugFillProperties = node.members.getMethod('debugFillProperties');
    var debugDescribeChildren = node.members.getMethod('debugDescribeChildren');

    // Remove any defined in debugFillProperties.
    removeReferences(debugFillProperties, properties);

    // Remove any defined in debugDescribeChildren.
    removeReferences(debugDescribeChildren, properties);

    // Flag the rest.
    properties.forEach(rule.reportLintForToken);
  }

  bool _isOverridingMember(Element? member) {
    if (member == null) {
      return false;
    }

    var classElement = member.thisOrAncestorOfType<ClassElement>();
    if (classElement == null) {
      return false;
    }
    var name = member.name;
    if (name == null) {
      return false;
    }

    var libraryUri = classElement.library.source.uri;
    return context.inheritanceManager
            .getInherited(classElement.thisType, Name(libraryUri, name)) !=
        null;
  }
}
