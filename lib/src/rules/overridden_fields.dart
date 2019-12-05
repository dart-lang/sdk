// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r"Don't override fields.";

const _details = r'''

**DON'T** override fields.

Overriding fields is almost always done unintentionally.  Regardless, it is a
bad practice to do so.

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
  final superclass = interface.superclass;
  final interfaces = <InterfaceType>[];
  if (superclass != null) {
    interfaces.add(superclass);
  }
  interfaces
    ..addAll(interface.element.mixins)
    ..addAll(_findAllSupertypesAndMixins(superclass, accumulator));
  return interfaces.where((i) => i != interface);
}

Iterable<InterfaceType> _findAllSupertypesInMixin(ClassElement classElement) {
  final supertypes = <InterfaceType>[];
  final accumulator = <InterfaceType>[];
  for (var type in classElement.superclassConstraints) {
    supertypes.add(type);
    supertypes.addAll(_findAllSupertypesAndMixins(type, accumulator));
  }
  return supertypes;
}

class OverriddenFields extends LintRule implements NodeLintRule {
  OverriddenFields()
      : super(
            name: 'overridden_fields',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic) {
      return;
    }

    node.fields.variables.forEach((VariableDeclaration variable) {
      final field = _getOverriddenMember(variable.declaredElement);
      if (field != null) {
        rule.reportLint(variable.name);
      }
    });
  }

  PropertyAccessorElement _getOverriddenMember(Element member) {
    final memberName = member.name;
    final library = member.library;
    bool isOverriddenMember(PropertyAccessorElement a) {
      if (a.isSynthetic && a.name == memberName) {
        // Ensure that private members are overriding a member of the same library.
        if (Identifier.isPrivateName(memberName)) {
          return library == a.library;
        }
        return true;
      }
      return false;
    }

    bool containsOverriddenMember(InterfaceType i) =>
        i.accessors.any(isOverriddenMember);
    final enclosingElement = member.enclosingElement;
    if (enclosingElement is! ClassElement) {
      return null;
    }
    final classElement = enclosingElement as ClassElement;

    Iterable<InterfaceType> interfaces;
    if (classElement.isMixin) {
      interfaces = _findAllSupertypesInMixin(classElement);
    } else {
      interfaces =
          _findAllSupertypesAndMixins(classElement.thisType, <InterfaceType>[]);
    }
    final interface =
        interfaces.firstWhere(containsOverriddenMember, orElse: () => null);
    return interface?.accessors?.firstWhere(isOverriddenMember);
  }
}
