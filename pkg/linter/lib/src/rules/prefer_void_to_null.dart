// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r"Don't use the Null type, unless you are positive that you don't want void.";

const _details = r'''
**DON'T** use the type Null where void would work.

**BAD:**
```dart
Null f() {}
Future<Null> f() {}
Stream<Null> f() {}
f(Null x) {}
```

**GOOD:**
```dart
void f() {}
Future<void> f() {}
Stream<void> f() {}
f(void x) {}
```

Some exceptions include formulating special function types:

```dart
Null Function(Null, Null);
```

and for making empty literals which are safe to pass into read-only locations
for any type of map or list:

```dart
<Null>[];
<int, Null>{};
```
''';

class PreferVoidToNull extends LintRule {
  static const LintCode code = LintCode(
      'prefer_void_to_null', "Unnecessary use of the type 'Null'.",
      correctionMessage: "Try using 'void' instead.");

  PreferVoidToNull()
      : super(
            name: 'prefer_void_to_null',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;
  _Visitor(this.rule, this.context);

  bool isFutureOrVoid(DartType type) {
    if (!type.isDartAsyncFutureOr) return false;
    if (type is! InterfaceType) return false;
    return type.typeArguments.first is VoidType;
  }

  bool isVoidIncompatibleOverride(MethodDeclaration parent, AstNode node) {
    // Make sure we're checking a return type.
    if (parent.returnType?.offset != node.offset) return false;

    var member =
        context.inheritanceManager.overriddenMember(parent.declaredElement);
    if (member == null) return false;

    var returnType = member.returnType;
    if (returnType is VoidType) return false;
    if (isFutureOrVoid(returnType)) return false;

    return true;
  }

  @override
  void visitNamedType(NamedType node) {
    var nodeType = node.type;
    if (nodeType == null || !nodeType.isDartCoreNull) {
      return;
    }

    var parent = node.parent;

    // Null Function()
    if (parent is GenericFunctionType) return;

    // case var _ as Null
    if (parent is CastPattern) return;

    // a as Null
    if (parent is AsExpression) return;

    // Function(Null)
    if (parent is SimpleFormalParameter &&
        parent.parent is FormalParameterList &&
        parent.parent?.parent is GenericFunctionType) {
      return;
    }

    if (parent is VariableDeclarationList &&
        node == parent.type &&
        parent.parent is! FieldDeclaration) {
      // We should not recommend to use `void` for local or top-level variables.
      return;
    }

    // <Null>[] or <Null, Null>{}
    if (parent is TypeArgumentList) {
      var literal = parent.parent;
      if (literal is ListLiteral && literal.elements.isEmpty) {
        return;
      } else if (literal is SetOrMapLiteral && literal.elements.isEmpty) {
        return;
      }
    }

    // extension _ on Null {}
    if (parent is ExtensionDeclaration) {
      return;
    }

    // https://github.com/dart-lang/linter/issues/2792
    if (parent is MethodDeclaration &&
        isVoidIncompatibleOverride(parent, node)) {
      return;
    }

    rule.reportLintForToken(node.name2);
  }
}
