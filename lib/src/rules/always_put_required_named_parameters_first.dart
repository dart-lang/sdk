// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Put @required named parameters first.';

const _details = r'''

**DO** specify `@required` on named parameter before other named parameters.

**GOOD:**
```
m({@required a, b, c}) ;
```

**BAD:**
```
m({b, c, @required a}) ;
```

''';

class AlwaysPutRequiredNamedParametersFirst extends LintRule
    implements NodeLintRule {
  AlwaysPutRequiredNamedParametersFirst()
      : super(
            name: 'always_put_required_named_parameters_first',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addFormalParameterList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFormalParameterList(FormalParameterList node) {
    var nonRequiredSeen = false;
    for (var param in node.parameters.where((p) => p.isNamed)) {
      var element = param.declaredElement;
      if (element.hasRequired || element.isRequiredNamed) {
        if (nonRequiredSeen) {
          rule.reportLintForToken(param.identifier.token);
        }
      } else {
        nonRequiredSeen = true;
      }
    }
  }
}
