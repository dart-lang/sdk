// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Private field could be final.';

const _details = r'''

**DO** prefer declaring private fields as final if they are not reassigned later
 in the class.

**BAD:**
```
class BadImmutable {
  var _label = 'hola mundo! BadImmutable'; // LINT
  var label = 'hola mundo! BadImmutable'; // OK
}
```

**BAD:**
```
class MultipleMutable {
  var _label = 'hola mundo! GoodMutable', _offender = 'mumble mumble!'; // LINT
  var _someOther; // LINT


  MultipleMutable() : _someOther = 5;


  MultipleMutable(this._someOther);

  void changeLabel() {
    _label= 'hello world! GoodMutable';
  }
}
```

**GOOD:**
```
class GoodImmutable {
  final label = 'hola mundo! BadImmutable', bla = 5; // OK
  final _label = 'hola mundo! BadImmutable', _bla = 5; // OK
}
```

**GOOD:**
```
class GoodMutable {
  var _label = 'hola mundo! GoodMutable';

  void changeLabel() {
    _label = 'hello world! GoodMutable';
  }
}
```
''';

class PreferFinalFields extends LintRule {
  PreferFinalFields()
      : super(
            name: 'prefer_final_fields',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new _Visitor(this);
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final Set<Element> _mutatedElements = new HashSet<Element>();

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    void recurse(node) {
      if (node is AstNode) {
        if (node is AssignmentExpression) {
          _mutatedElements.add(DartTypeUtilities
              .getCanonicalElementFromIdentifier(node.leftHandSide));
        } else if (node is PrefixExpression) {
          _mutatedElements.add(DartTypeUtilities
              .getCanonicalElementFromIdentifier(node.operand));
        } else if (node is PostfixExpression) {
          _mutatedElements.add(DartTypeUtilities
              .getCanonicalElementFromIdentifier(node.operand));
        }
        node.childEntities.forEach(recurse);
      }
    }

    recurse(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final fields = node.fields;
    if (fields.isFinal || fields.isConst) {
      return;
    }

    fields.variables.forEach((VariableDeclaration variable) {
      if (variable == null ||
          !resolutionMap
              .elementDeclaredByVariableDeclaration(variable)
              .isPrivate) {
        return;
      }

      if (variable.initializer == null) {
        return;
      }

      if (_isMutated(variable)) {
        return;
      }

      rule.reportLint(variable);
    });
  }

  bool _isMutated(VariableDeclaration variable) =>
      _mutatedElements.contains(variable.element);
}
