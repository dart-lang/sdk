// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.prefer_final_fields;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/visitor.dart';
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

bool _isMutated(
        VariableDeclaration variable, CompilationUnit compilationUnit) =>
    DartTypeUtilities
        .traverseNodesInDFS(compilationUnit)
        .any((n) =>
            (n is AssignmentExpression &&
                DartTypeUtilities
                        .getCanonicalElementFromIdentifier(n.leftHandSide) ==
                    variable.element) ||
            (n is PrefixExpression &&
                DartTypeUtilities
                        .getCanonicalElementFromIdentifier(n.operand) ==
                    variable.element) ||
            (n is PostfixExpression &&
                DartTypeUtilities
                        .getCanonicalElementFromIdentifier(n.operand) ==
                    variable.element));

class PreferFinalFields extends LintRule {
  _Visitor _visitor;

  PreferFinalFields()
      : super(
            name: 'prefer_final_fields',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final fields = node.fields;
    if (fields.isFinal || fields.isConst) {
      return;
    }

    CompilationUnit compilationUnit =
        node.getAncestor((a) => a is CompilationUnit);
    if (compilationUnit == null) {
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

      final isMutated = _isMutated(variable, compilationUnit);

      if (isMutated) {
        return;
      }

      rule.reportLint(variable);
    });
  }
}
