// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/utils.dart';

const _desc = r'Specify type annotations.';

const _details = r'''

From the [flutter style guide](https://flutter.io/style-guide/):

**DO** specify type annotations.

Avoid `var` when specifying that a type is unknown and short-hands that elide
type annotations.  Use `dynamic` if you are being explicit that the type is
unknown.  Use `Object` if you are being explicit that you want an object that
implements `==` and `hashCode`.

**GOOD:**
```
int foo = 10;
final Bar bar = new Bar();
String baz = 'hello';
const int quux = 20;
```

**BAD:**
```
var foo = 10;
final bar = new Bar();
const quux = 20;
```

NOTE: Using the the `@optionalTypeArgs` annotation in the `meta` package, API
authors can special-case type variables whose type needs to by dynamic but whose
declaration should be treated as optional.  For example, suppose you have a
`Key` object whose type parameter you'd like to treat as optional.  Using the
`@optionalTypeArgs` would look like this:

```
import 'package:meta/meta.dart';

@optionalTypeArgs
class Key<T> {
 ...
}

main() {
  Key s = new Key(); // OK!
}
```

''';

/// The name of `meta` library, used to define analysis annotations.
String _META_LIB_NAME = 'meta';

/// The name of the top-level variable used to mark a Class as having optional
/// type args.
String _OPTIONAL_TYPE_ARGS_VAR_NAME = 'optionalTypeArgs';

bool _isOptionallyParameterized(ParameterizedType type) {
  List<ElementAnnotation> metadata = type.element?.metadata;
  if (metadata != null) {
    return metadata
        .any((ElementAnnotation a) => _isOptionalTypeArgs(a.element));
  }
  return false;
}

bool _isOptionalTypeArgs(Element element) =>
    element is PropertyAccessorElement &&
    element.name == _OPTIONAL_TYPE_ARGS_VAR_NAME &&
    element.library?.name == _META_LIB_NAME;

class AlwaysSpecifyTypes extends LintRule implements NodeLintRule {
  AlwaysSpecifyTypes()
      : super(
            name: 'always_specify_types',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addDeclaredIdentifier(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addMapLiteral(this, visitor);
    registry.addSimpleFormalParameter(this, visitor);
    registry.addTypeName(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkLiteral(TypedLiteral literal) {
    if (literal.typeArguments == null) {
      rule.reportLintForToken(literal.beginToken);
    }
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (node.type == null) {
      rule.reportLintForToken(node.keyword);
    }
  }

  @override
  void visitListLiteral(ListLiteral literal) {
    checkLiteral(literal);
  }

  @override
  void visitMapLiteral(MapLiteral literal) {
    checkLiteral(literal);
  }

  // Future kernel API.
  visitNamedType(NamedType namedType) {
    DartType type = namedType.type;
    if (type is ParameterizedType) {
      if (type.typeParameters.isNotEmpty &&
          namedType.typeArguments == null &&
          namedType.parent is! IsExpression &&
          !_isOptionallyParameterized(type)) {
        rule.reportLint(namedType);
      }
    }
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter param) {
    if (param.type == null && !isJustUnderscores(param.identifier.name)) {
      if (param.keyword != null) {
        rule.reportLintForToken(param.keyword);
      } else {
        rule.reportLint(param);
      }
    }
  }

  @override
  void visitTypeName(NamedType typeName) {
    visitNamedType(typeName);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList list) {
    if (list.type == null) {
      rule.reportLintForToken(list.keyword);
    }
  }
}
