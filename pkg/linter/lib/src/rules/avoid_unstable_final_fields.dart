// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
// ignore:implementation_imports
import 'package:analyzer/src/diagnostic/diagnostic.dart';

import '../analyzer.dart';

const _desc = r'Avoid overriding a final field to return '
    'different values if called multiple times.';

const _details = r'''
**AVOID** overriding or implementing a final field as a getter which could
return different values if it is invoked multiple times on the same receiver.
This could occur because the getter is an implicitly induced getter of a
non-final field, or it could be an explicitly declared getter with a body
that isn't known to return the same value each time it is called.

The underlying motivation for this rule is that if it is followed then a final
field is an immutable property of an object. This is important for correctness
because it is then safe to assume that the value does not change during the
execution of an algorithm. In contrast, it may be necessary to re-check any
other getter repeatedly if it is not known to have this property. Similarly,
it is safe to cache the immutable property in a local variable and promote it,
but for any other property it is necessary to check repeatedly that the
underlying property hasn't changed since it was promoted.

**BAD:**
```dart
class A {
  final int i;
  A(this.i);
}

var j = 0;

class B1 extends A {
  int get i => ++j + super.i; // LINT.
  B1(super.i);
}

class B2 implements A {
  int i; // LINT.
  B2(this.i);
}
```

**GOOD:**
```dart
class C {
  final int i;
  C(this.i);
}

class D1 implements C {
  late final int i = someExpression; // OK.
}

class D2 extends C {
  int get i => super.i + 1; // OK.
  D2(super.i);
}

class D3 implements C {
  final int i; // OK.
  D3(this.i);
}
```

''';

bool _isLocallyStable(Element element) {
  if (element is PropertyAccessorElement &&
      element.isGetter &&
      element.isSynthetic &&
      element.correspondingSetter == null) {
    // This is a final, non-local variable, and they are stable.
    var metadata = element.variable.metadata;
    if (metadata.isNotEmpty) {
      for (var elementAnnotation in metadata) {
        var metadataElement = elementAnnotation.element;
        if (metadataElement is ConstructorElement) {
          var metadataOwner = metadataElement.declaration.enclosingElement;
          if (metadataOwner is ClassElement && metadataOwner.isDartCoreObject) {
            // A declaration with `@Object()` is not considered stable.
            return false;
          }
        }
      }
    }
    return true;
  } else if (element is FunctionElement) {
    // A tear-off of a top-level function or static method is stable,
    // local functions and function literals are not.
    return element.isStatic;
  } else if (element is EnumElement ||
      element is MixinElement ||
      element is ClassElement) {
    // A reified type of a class/mixin/enum is stable.
    return true;
  } else if (element is MethodElement) {
    // An instance method tear-off is never stable,
    // but a static method tear-off is stable.
    return element.isStatic;
  }
  // TODO(eernst): Any cases still missing?
  return false;
}

class AvoidUnstableFinalFields extends LintRule {
  AvoidUnstableFinalFields()
      : super(
            name: 'avoid_unstable_final_fields',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addFieldDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

abstract class _AbstractVisitor extends UnifyingAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  // Will be true initially when a getter body is traversed. Will be made
  // false if the getter body turns out to be unstable. Is checked after the
  // traversal of the body, to emit a lint if it is false at that time.
  bool isStable = true;

  // Each [PropertyAccessorElement] which is causing the lint to be reported is
  // added to this list, which is then used to create context messages.
  Set<PropertyAccessorElement> causes = {};

  // Initialized in `visitMethodDeclaration` if a lint might be emitted.
  // It is then guaranteed that `declaration.isGetter` is true.
  late final MethodDeclaration declaration;

  _AbstractVisitor(this.rule, this.context);

  void doReportLint(Token? name) {
    rule.reportLintForToken(name, contextMessages: _computeContextMessages());
  }

  // The following visitor methods will only be executed in the situation
  // where `declaration` is a getter which must be stable, and the
  // traversal is visiting the body of said getter. Hence, a lint must
  // be emitted whenever the given body is not known to be appropriate
  // for a stable getter.

  @override
  void visitAsExpression(AsExpression node) {
    if (node.expression.staticType?.isBottom ?? true) return;
    node.expression.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.staticType?.isBottom ?? true) return;
    var operator = node.operator;
    if (operator.type != TokenType.EQ) {
      // TODO(eernst): Could a compound assignment be stable?
      isStable = false;
    } else {
      // A regular assignment is stable iff its right hand side is stable.
      node.rightHandSide.accept(this);
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    // We cannot predict the outcome of awaiting a future.
    isStable = false;
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.leftOperand.staticType?.isBottom ?? true) return;
    if (node.rightOperand.staticType?.isBottom ?? true) return;
    node.leftOperand.accept(this);
    node.rightOperand.accept(this);
    if (isStable) {
      // So far no problems! Only a few cases are working,
      // see if we have one of those.
      var operatorType = node.operator.type;
      var leftType = node.leftOperand.staticType;
      if (leftType == null) {
        isStable = false; // Presumably a wrong program. Be safe.
        return;
      }
      if (operatorType == TokenType.PLUS) {
        if (leftType.isDartCoreInt ||
            leftType.isDartCoreDouble ||
            leftType.isDartCoreNum ||
            leftType.isDartCoreString) {
          // These are all stable.
          return;
        } else {
          // A user-defined `+` cannot be assumed to be stable.
          isStable = false;
        }
      } else if (operatorType == TokenType.MINUS ||
          operatorType == TokenType.STAR ||
          operatorType == TokenType.SLASH ||
          operatorType == TokenType.PERCENT ||
          operatorType == TokenType.LT ||
          operatorType == TokenType.LT_EQ ||
          operatorType == TokenType.GT ||
          operatorType == TokenType.GT_EQ) {
        if (leftType.isDartCoreInt ||
            leftType.isDartCoreDouble ||
            leftType.isDartCoreNum) {
          // These are all stable.
          return;
        } else {
          // User-defined operators in this group
          // cannot be assumed to be stable.
          isStable = false;
        }
      } else if (operatorType == TokenType.EQ_EQ ||
          operatorType == TokenType.BANG_EQ) {
        if (leftType.isDartCoreNull ||
            (node.rightOperand.staticType?.isDartCoreNull ?? false) ||
            leftType.isDartCoreBool ||
            leftType.isDartCoreInt ||
            leftType.isDartCoreString) {
          // Primitive equality of two stable expressions is stable, and so is
          // equality involving null. Note that we can only detect primitive
          // equality for a few types. Any class that inherits `Object.==` has
          // primitive equality, but an object with that static type could be
          // an instance of a subtype that overrides `==`.
          return;
        }
        // Equality is otherwise not stable, can run arbitrary code.
        isStable = false;
      } else if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
          operatorType == TokenType.BAR_BAR) {
        // Logical and/or cannot be user-defined, is stable.
        return;
      } else if (operatorType == TokenType.QUESTION_QUESTION) {
        // `e1 ?? e2` is stable when both operands are stable.
        return;
      } else if (operatorType == TokenType.TILDE_SLASH ||
          operatorType == TokenType.GT_GT ||
          operatorType == TokenType.GT_GT_GT ||
          operatorType == TokenType.LT_LT) {
        if (leftType.isDartCoreInt) {
          // These primitive arithmetic operations and relations are stable.
          return;
        } else {
          // A user-defined operator can not be assumed to be stable.
          isStable = false;
        }
      } else if (operatorType == TokenType.AMPERSAND ||
          operatorType == TokenType.BAR ||
          operatorType == TokenType.CARET) {
        if (leftType.isDartCoreInt || leftType.isDartCoreBool) {
          // These primitive logical operations are stable.
          return;
        } else {
          // A user-defined operator can not be assumed to be stable.
          isStable = false;
        }
      } else if (operatorType == TokenType.QUESTION_QUESTION) {
        // An if-null expression with stable operands is stable.
        return;
      }
      // TODO(eernst): Add support for missing cases, if any.
      isStable = false;
    }
  }

  @override
  void visitBlock(Block node) {
    // TODO(eernst): Check that only one return statement exists, and it is
    // the last statement in the body, and it returns a stable expression.
    if (node.statements.isEmpty) {
      // This getter returns null, keep it stable.
    } else if (node.statements.length == 1) {
      var statement = node.statements.first;
      if (statement is ReturnStatement) {
        statement.accept(this);
      } else {
        // This getter returns null or throws, keep it stable.
      }
    } else {
      // TODO(eernst): Allow multiple statements, just check returns.
      isStable = false;
    }
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    visitBlock(node.block);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    // Keep it stable.
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    // A cascade is stable if its target is stable.
    node.target.accept(this);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (node.condition.staticType?.isBottom ?? true) return;
    node.condition.accept(this);
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    // Keep it stable.
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    // Returns null: keep it stable.
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (node.expression.staticType?.isBottom ?? true) return;
    node.expression.accept(this);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // We cannot expect the function literal to be the same function, only if
    // we introduce constant expressions that are function literals.
    isStable = false;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.staticType?.isBottom ?? true) return;
    // We cannot expect a function invocation to be stable.
    isStable = false;
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.staticType?.isBottom ?? true) return;
    // The type system does not recognize immutable lists or similar entities,
    // so we can never hope to detect that this is stable.
    isStable = false;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!node.isConst) isStable = false;
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    // Keep it stable.
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (node.expression.staticType?.isBottom ?? true) return;
    // Testing `e is T` where `e` is stable depends on `T`. However, there is
    // no `<type>` that denotes two different types in the context of the same
    // receiver (so class type variables represent the same type each time this
    // getter is invoked, and we can't have member type variables in a getter).
    // Hence, we just need to check that `e` is stable.
    node.expression.accept(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (!node.isConst) isStable = false;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.staticType?.isBottom ?? true) return;
    // Special case `identical`.
    if (node.target == null) {
      var nodeLibrary = node.methodName.staticElement?.declaration?.library;
      var isFromCore = nodeLibrary?.isDartCore ?? false;
      if (isFromCore && node.methodName.name == 'identical') {
        var arguments = node.argumentList.arguments;
        if (arguments.length == 2) {
          // `identical(e1, e2)` is stable iff `e1` and `e2` are stable.
          arguments[0].accept(this);
          arguments[1].accept(this);
          return;
        }
      }
    }
    // We could have a notion of pure functions, but for now a
    // method invocation is never stable.
    isStable = false;
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    if (node.staticType?.isBottom ?? true) return;
    node.expression.accept(this);
  }

  @override
  void visitNode(AstNode node) {
    // Default method, only called if the specific visitor method is missing.
    assert(false, 'Missing visit method detected!');
    // It is always safe to consider an unknown construct unstable.
    isStable = false;
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    // Keep it stable.
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    if (node.staticType?.isBottom ?? true) return;
    node.unParenthesized.accept(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.staticType?.isBottom ?? true) return;
    if (node.operator.type == TokenType.BANG) {
      // A non-null assertion expression, `e!`: stable if `e` is stable.
      node.operand.accept(this);
    } else {
      // `x.y?.z` is handled in [visitPropertyAccess], this is only about
      // `<assignableExpression> <postfixOperator>`, and they are not stable.
      isStable = false;
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    var prefixDeclaration = node.prefix.staticElement?.declaration;
    var declaredElement = node.identifier.staticElement?.declaration;
    if (prefixDeclaration is PrefixElement) {
      // Import prefix followed by simple identifier.
      if (!_isStable(declaredElement)) isStable = false;
    } else if (prefixDeclaration is InterfaceElement) {
      // Static member access.
      if (!_isStable(declaredElement)) isStable = false;
    } else {
      node.prefix.accept(this);
      if (isStable) {
        if (!_isStable(declaredElement)) isStable = false;
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var operandType = node.staticType;
    if (operandType == null) return; // Program error, play safe.
    if (operandType.isBottom) return; // Will throw, is stable.
    if (node.operator.type == TokenType.MINUS) {
      node.operand.accept(this);
      if (!isStable) return;
      if (operandType.isDartCoreInt ||
          operandType.isDartCoreDouble ||
          operandType.isDartCoreNum) {
        // These all have a stable unary minus.
        return;
      } else {
        // A user-defined unary minus cannot be assumed to be stable.
        isStable = false;
      }
    } else {
      // TODO(eernst): Could probably support more unary operators.
      isStable = false;
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.realTarget.accept(this);
    if (isStable) {
      var element = node.propertyName.staticElement?.declaration;
      if (!_isStable(element)) isStable = false;
    }
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    // Record literals do not have guaranteed identity.
    isStable = false;
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    // Throws, cannot be unstable.
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    node.expression?.accept(this);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (!node.isConst) isStable = false;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var declaration = node.staticElement?.declaration;
    if (!_isStable(declaration)) {
      isStable = false;
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // No interpolations: Keep it stable.
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    var interpolationElements = node.elements;
    for (var interpolationElement in interpolationElements) {
      if (interpolationElement is InterpolationExpression) {
        var expression = interpolationElement.expression;
        var expressionType = expression.staticType;
        if (expressionType == null) {
          isStable = false;
        } else if (expressionType.isDartCoreInt ||
            expressionType.isDartCoreDouble ||
            expressionType.isDartCoreString ||
            expressionType.isDartCoreBool ||
            expressionType.isDartCoreNull) {
          // `toString` on these built-in types is stable.
          interpolationElement.expression.accept(this);
        } else {
          // `toString` is otherwise unstable, can run arbitrary code.
          isStable = false;
        }
      }
    }
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    // This is simply the keyword `super`: Keep it stable.
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    // TODO(eernst): We could include this, if the scrutinee and every branch is stable
    isStable = false;
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    // Keep it stable.
  }

  @override
  void visitThisExpression(ThisExpression node) {
    // Keep it stable.
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    // Keep it stable.
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    // A type literal can contain a type parameter of the enclosing class
    // (in a getter it can't be a type parameter of the member). This means
    // that it denotes the same type each time it is evaluated on the same
    // receiver, but it may still be a different object. So we need to exclude
    // type literals that contain type variables.

    bool containsNonConstantType(TypeAnnotation? typeAnnotation) {
      if (typeAnnotation == null) return false;
      if (typeAnnotation is NamedType) {
        var typeArguments = typeAnnotation.typeArguments;
        if (typeArguments != null) {
          for (var typeArgument in typeArguments.arguments) {
            if (containsNonConstantType(typeArgument)) return true;
          }
        }
        var typeAnnotationType = typeAnnotation.type;
        if (typeAnnotationType is InterfaceType) {
          var element = typeAnnotationType.element.declaration;
          if (element is InterfaceElement) return false;
        } else if (typeAnnotationType is TypeParameterType) {
          // We cannot rely on type parameters or parameterized types
          // containing type parameters to be stable.
          return true;
        }
        // TODO(eernst): Handle `typedef` and other missing cases.
        return true;
      } else if (typeAnnotation is GenericFunctionType) {
        // TODO(eernst): For now, just use the safe approximation.
        return true;
      } else {
        // TODO(eernst): Add missing cases. Be safe for now.
        return true;
      }
    }

    if (containsNonConstantType(node.type)) isStable = false;
  }

  List<DiagnosticMessage> _computeContextMessages() {
    var contextMessages = <DiagnosticMessage>[];
    for (var cause in causes) {
      var length = cause.nameLength;
      var offset = cause.nameOffset;
      if (offset < 0) offset = cause.variable.nameOffset;
      if (offset < 0) offset = 0;
      contextMessages.add(
        DiagnosticMessageImpl(
            filePath: cause.library.source.fullName,
            message: 'The declaration that requires this '
                'declaration to be stable is',
            offset: offset,
            length: length,
            url: null),
      );
    }
    return contextMessages;
  }

  bool _inheritsStability(InterfaceElement interfaceElement, Name name) {
    // A member of an extension type is never executed when some different
    // declaration (in a class or in an extension type) is the statically
    // known declaration. Hence, stability is not inherited.
    if (interfaceElement is ExtensionTypeElement) return false;
    // A member of a class/mixin/enum can inherit a stability requirement.
    var overriddenList =
        context.inheritanceManager.getOverridden2(interfaceElement, name);
    if (overriddenList == null) return false;
    for (var overridden in overriddenList) {
      if (_isLocallyStable(overridden)) {
        if (overridden is PropertyAccessorElement) causes.add(overridden);
        return true;
      }
      var enclosingElement = overridden.enclosingElement;
      if (enclosingElement is InterfaceElement) {
        if (_inheritsStability(enclosingElement, name)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isStable(Element? element) {
    if (element == null) return false; // This would be an error in the program.
    var enclosingElement = element.enclosingElement;
    if (_isLocallyStable(element)) return true;
    if (element is PropertyAccessorElement) {
      if (element.isStatic) return false;
      if (enclosingElement is! InterfaceElement) {
        // This should not happen, a top-level variable `isStatic`.
        // TODO(eernst): Do something like `throw Unhandled(...)`.
        return false;
      }
      var libraryUri = element.library.source.uri;
      var name = Name(libraryUri, element.name);
      return _inheritsStability(enclosingElement, name);
    }
    return false;
  }
}

class _FieldVisitor extends _AbstractVisitor {
  _FieldVisitor(super.rule, super.context);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    Uri? libraryUri;
    Name? name;
    InterfaceElement? interfaceElement;
    for (var variable in node.fields.variables) {
      var declaredElement = variable.declaredElement;
      if (declaredElement is FieldElement) {
        // A final instance variable can never violate stability.
        if (declaredElement.isFinal) continue;
        // A non-final instance variable is always a violation of stability.
        // Check if stability is required.
        interfaceElement ??=
            declaredElement.enclosingElement as InterfaceElement;
        libraryUri ??= declaredElement.library.source.uri;
        name ??= Name(libraryUri, declaredElement.name);
        if (_inheritsStability(interfaceElement, name)) {
          doReportLint(variable.name);
        }
      }
    }
  }
}

class _MethodVisitor extends _AbstractVisitor {
  _MethodVisitor(super.rule, super.context);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isGetter) return;
    declaration = node;
    var declaredElement = node.declaredElement;
    if (declaredElement != null) {
      var enclosingElement = declaredElement.enclosingElement;
      if (enclosingElement is InterfaceElement) {
        var libraryUri = declaredElement.library.source.uri;
        var name = Name(libraryUri, declaredElement.name);
        if (!_inheritsStability(enclosingElement, name)) return;
        node.body.accept(this);
        if (!isStable) doReportLint(node.name);
      } else {
        // Extensions cannot override anything.
      }
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic) {
      var visitor = _FieldVisitor(rule, context);
      visitor.visitFieldDeclaration(node);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isStatic && node.isGetter) {
      var visitor = _MethodVisitor(rule, context);
      visitor.visitMethodDeclaration(node);
    }
  }
}
