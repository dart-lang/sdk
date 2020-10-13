// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc =
    r'Avoid <Type>.toString() in production code since results may be minified.';

const _details = r'''

**DO** avoid calls to <Type>.toString() in production code, since it does not
contractually return the user-defined name of the Type (or underlying class).
Development-mode compilers where code size is not a concern use the full name,
but release-mode compilers often choose to minify these symbols.

**BAD:**
```
void bar(Object other) {
  if (other.runtimeType.toString() == 'Bar') {
    doThing();
  }
}

Object baz(Thing myThing) {
  return getThingFromDatabase(key: myThing.runtimeType.toString());
}
```

**GOOD:**
```
void bar(Object other) {
  if (other is Bar) {
    doThing();
  }
}

class Thing {
  String get thingTypeKey => ...
}

Object baz(Thing myThing) {
  return getThingFromDatabase(key: myThing.thingTypeKey);
}
```

''';

class AvoidTypeToString extends LintRule implements NodeLintRule {
  AvoidTypeToString()
      : super(
            name: 'avoid_type_to_string',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    assert(context != null);
    final visitor =
        _Visitor(this, context.typeSystem, context.typeProvider.typeType);
    // Gathering meta information at these nodes.
    // Nodes visited in DFS, so this will be called before
    // each visitMethodInvocation.
    registry.addClassDeclaration(this, visitor);
    registry.addMixinDeclaration(this, visitor);
    registry.addExtensionDeclaration(this, visitor);

    // These nodes delegate to general visitArgumentList,
    // since SimpleAstVisitor only calls visits for concrete node subtypes.
    // TODO: replace these with addArgumentList(...) once it's added to the registry API.
    // Context: https://github.com/dart-lang/linter/pull/2209#discussion_r465196745
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addRedirectingConstructorInvocation(this, visitor);
    registry.addSuperConstructorInvocation(this, visitor);

    // Actually checking things at these nodes.
    // Also delegates to visitArgumentList.
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final TypeSystem typeSystem;
  final InterfaceType typeType;

  // Null if there is no logical `this` in the given context.
  InterfaceType thisType;

  _Visitor(this.rule, this.typeSystem, this.typeType);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    thisType = node.declaredElement.thisType;
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    thisType = node.declaredElement.thisType;
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    // Might not be InterfaceType. Ex: visiting an extension on a dynamic type.
    thisType = (node.declaredElement.extendedType is InterfaceType)
        ? node.declaredElement.extendedType as InterfaceType
        : null;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    visitArgumentList(node.argumentList);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    visitArgumentList(node.argumentList);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    visitArgumentList(node.argumentList);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    visitArgumentList(node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    visitArgumentList(node.argumentList);

    final targetType = (node.realTarget?.staticType is InterfaceType)
        ? node.realTarget.staticType as InterfaceType
        : thisType;
    _reportIfToStringOnCoreTypeClass(targetType, node.methodName);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    node.arguments.forEach(_validateArgument);
  }

  void _validateArgument(Expression expression) {
    if (expression is PropertyAccess) {
      final targetType = (expression.realTarget?.staticType is InterfaceType)
          ? expression.realTarget?.staticType as InterfaceType
          : thisType;
      _reportIfToStringOnCoreTypeClass(targetType, expression.propertyName);
    } else if (expression is PrefixedIdentifier) {
      final prefixType = expression.prefix.staticType;
      if (prefixType is InterfaceType) {
        _reportIfToStringOnCoreTypeClass(prefixType, expression.identifier);
      }
    } else if (expression is SimpleIdentifier) {
      _reportIfToStringOnCoreTypeClass(thisType, expression);
    }
  }

  void _reportIfToStringOnCoreTypeClass(
      InterfaceType targetType, SimpleIdentifier methodIdentifier) {
    if (_isToStringOnCoreTypeClass(targetType, methodIdentifier)) {
      rule.reportLint(methodIdentifier);
    }
  }

  bool _isToStringOnCoreTypeClass(
          InterfaceType targetType, SimpleIdentifier methodIdentifier) =>
      targetType != null &&
      methodIdentifier.name == 'toString' &&
      _isSimpleIdDeclByCoreObj(methodIdentifier) &&
      typeSystem.isSubtypeOf(targetType, typeType);

  bool _isSimpleIdDeclByCoreObj(SimpleIdentifier simpleIdentifier) {
    final encloser = simpleIdentifier?.staticElement?.enclosingElement;
    return encloser is ClassElement && encloser.isDartCoreObject;
  }
}
