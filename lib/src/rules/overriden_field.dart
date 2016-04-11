// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.overriden_field;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
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

''';

class OverridenField extends LintRule {
  OverridenField()
      : super(
            name: 'overriden_field',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new _Visitor(this);
}

class _Visitor extends SimpleAstVisitor {
  InheritanceManager _manager;

  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitCompilationUnit(CompilationUnit node) {
    LibraryElement library = node?.element?.library;
    _manager = library == null ? null : new InheritanceManager(library);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    node.fields.variables.forEach((VariableDeclaration variable) {
      ExecutableElement member = _getOverriddenMember(variable.element);
      if (member is PropertyAccessorElement && member.isSynthetic) {
        rule.reportLint(variable.name);
      }
    });
  }

  ExecutableElement _getOverriddenMember(Element member) {
    if (member == null || _manager == null) {
      return null;
    }

    ClassElement classElement =
        member.getAncestor((element) => element is ClassElement);
    if (classElement == null) {
      return null;
    }

    return _manager.lookupInheritance(classElement, member.name);
  }
}
