// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.overriden_field;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/linter.dart';

const desc = r'Do not override fields.';

const details = r'''

**DO** Do not override fields.

**BAD:**
```
class Base {
  Object field = 'lorem';

  Object something = 'change';
}

class Bad1 extends Base {
  @override
  final field = 'ipsum'; // LINT
}

class Bad2 extends Base {
  @override
  Object something = 'done'; // LINT
}
```

**GOOD:**
```
class Base {
  Object field = 'lorem';

  Object something = 'change';
}

class Ok extends Base {
  Object newField; // OK

  final Object newFinal = 'ignore'; // OK
}
```

**GOOD:**
```
abstract class BaseLoggingHandler {
  Base transformer;
}

class LogPrintHandler implements BaseLoggingHandler {
  @override
  Derived transformer; // OK
}
```
''';

Iterable<InterfaceType> _findAllSupertypesAndMixins(
    InterfaceType interface, List<InterfaceType> accumulator) {
  if (interface == null ||
      interface.isObject ||
      accumulator.contains(interface)) {
    return accumulator;
  }

  accumulator.add(interface);
  InterfaceType superclass = interface.superclass;
  Iterable<InterfaceType> interfaces = [superclass]
    ..addAll(interface.element.mixins)
    ..addAll(_findAllSupertypesAndMixins(superclass, accumulator));
  return interfaces.where((i) => i != interface);
}

class OverridenField extends LintRule {
  _Visitor _visitor;

  OverridenField()
      : super(
            name: 'overriden_field',
            description: desc,
            details: details,
            group: Group.style,
            maturity: Maturity.experimental) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    node.fields.variables.forEach((VariableDeclaration variable) {
      PropertyAccessorElement field = _getOverriddenMember(variable.element);
      if (field != null) {
        rule.reportLint(variable.name);
      }
    });
  }

  PropertyAccessorElement _getOverriddenMember(Element member) {
    String memberName = member.name;
    LibraryElement library = member.library;
    bool isOverriddenMember(PropertyAccessorElement a) =>
        a.library == library && a.isSynthetic && a.name == memberName;
    bool containsOverridenMember(InterfaceType i) =>
        i.accessors.any(isOverriddenMember);
    ClassElement classElement = member.enclosingElement;

    Iterable<InterfaceType> interfaces =
        _findAllSupertypesAndMixins(classElement.type, <InterfaceType>[]);
    InterfaceType interface =
        interfaces.firstWhere(containsOverridenMember, orElse: () => null);
    return interface == null
        ? null
        : interface.accessors.firstWhere(isOverriddenMember);
  }
}
