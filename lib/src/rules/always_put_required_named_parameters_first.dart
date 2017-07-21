// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart' show AstVisitor;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Put @required named parameters first.';

const details = '''
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

/// The name of `meta` library, used to define analysis annotations.
String _META_LIB_NAME = 'meta';

/// The name of the top-level variable used to mark a required named parameter.
String _REQUIRED_VAR_NAME = 'required';

bool _isRequired(Element element) =>
    element is PropertyAccessorElement &&
    element.name == _REQUIRED_VAR_NAME &&
    element.library?.name == _META_LIB_NAME;

class AlwaysPutRequiredNamedParametersFirst extends LintRule {
  AlwaysPutRequiredNamedParametersFirst()
      : super(
            name: 'always_put_required_named_parameters_first',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;

  Visitor(this.rule);

  @override
  visitFormalParameterList(FormalParameterList node) {
    bool nonRequiredSeen = false;
    for (DefaultFormalParameter param
        in node.parameters.where((p) => p.kind == ParameterKind.NAMED)) {
      if (param.metadata.any((a) => _isRequired(a.element))) {
        if (nonRequiredSeen) {
          rule.reportLintForToken(param.identifier.token);
        }
      } else {
        nonRequiredSeen = true;
      }
    }
  }
}
