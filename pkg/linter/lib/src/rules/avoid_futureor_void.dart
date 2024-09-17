// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart'
    show TypeParameterElementImpl;

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r"Avoid using 'FutureOr<void>' as the type of a result.";

const _details = r'''
**AVOID** using `FutureOr<void>` as the type of a result. This type is
problematic because it may appear to encode that a result is either a
`Future<void>`, or the result should be discarded (when it is `void`).
However, there is no safe way to detect whether we have one or the other
case (because an expression of type `void` can evaluate to any object
whatsoever, including a future of any type).

It is also conceptually unsound to have a type whose meaning is something
like "ignore this object; also, take a look because it might be a future".

An exception is made for contravariant occurrences of the type
`FutureOr<void>` (e.g., for the type of a formal parameter), and no
warning is emitted for these occurrences. The reason for this exception
is that the type does not describe a result, it describes a constraint
on a value provided by others. Similarly, an exception is made for type
alias declarations, because they may well be used in a contravariant
position (e.g., as the type of a formal parameter). Hence, in type alias
declarations, only the type parameter bounds are checked.

A replacement for the type `FutureOr<void>` which is often useful is 
`Future<void>?`. This type encodes that the result is either a 
`Future<void>` or it is null, and there is no ambiguity at run time
since no object can have both types.

It may not always be possible to use the type `Future<void>?` as a
replacement for the type `FutureOr<void>`, because the latter is a
supertype of all types, and the former is not. In this case it may be a
useful remedy to replace `FutureOr<void>` by the type `void`.

**BAD:**
```dart
FutureOr<void> m() {...}
```

**GOOD:**
```dart
Future<void>? m() {...}
```

**This rule is experimental.** It is being evaluated, and it may be changed
or removed. Feedback on its behavior is welcome! The main issue is here:
https://github.com/dart-lang/linter/issues/4622
''';

const _in = Variance._in;

const _inout = Variance._inout;

const _out = Variance._out;

class AvoidFutureOrVoid extends LintRule {
  AvoidFutureOrVoid()
      : super(
            name: 'avoid_futureor_void',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.unintentional},
            state: State.experimental());

  @override
  LintCode get lintCode => LinterLintCode.avoid_futureor_void;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addAsExpression(this, visitor);
    registry.addCastPattern(this, visitor);
    registry.addExtendsClause(this, visitor);
    registry.addExtensionOnClause(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addImplementsClause(this, visitor);
    registry.addIsExpression(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addMixinOnClause(this, visitor);
    registry.addObjectPattern(this, visitor);
    registry.addRepresentationDeclaration(this, visitor);
    registry.addTypeParameter(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
    registry.addWithClause(this, visitor);
  }
}
/* 'type_analyzer_operations.dart' does support variance in some ways, but
 * this may not be supported for use in a lint. So we roll our own
 * minimal level of support for variance.
 */

enum Variance {
  _out,
  _in,
  _inout;

  Variance get inverse => switch (this) {
        _out => _in,
        _in => _out,
        _inout => _inout,
      };
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitAsExpression(AsExpression node) => _checkOut(node.type);

  @override
  void visitCastPattern(CastPattern node) => _checkOut(node.type);

  @override
  void visitExtendsClause(ExtendsClause node) => _checkOut(node.superclass);

  @override
  void visitExtensionOnClause(ExtensionOnClause node) =>
      _checkOut(node.extendedType);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkOut(node.returnType);
    var functionExpression = node.functionExpression;
    functionExpression.typeParameters?.typeParameters.forEach(_checkBound);
    functionExpression.parameters?.parameters.forEach(_checkFormalParameterIn);
  }

  @override
  void visitImplementsClause(ImplementsClause node) =>
      node.interfaces.forEach(_checkOut);

  @override
  void visitIsExpression(IsExpression node) => _checkOut(node.type);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkOut(node.returnType);
    node.typeParameters?.typeParameters.forEach(_checkBound);
    node.parameters?.parameters.forEach(_checkFormalParameterIn);
  }

  @override
  void visitMixinOnClause(MixinOnClause node) =>
      node.superclassConstraints.forEach(_checkOut);

  @override
  void visitObjectPattern(ObjectPattern node) => _checkOut(node.type);

  @override
  void visitRepresentationDeclaration(RepresentationDeclaration node) =>
      _checkOut(node.fieldType);

  @override
  void visitTypeParameter(TypeParameter node) => _checkInOut(node.bound);

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) =>
      _checkOut(node.type);

  @override
  void visitWithClause(WithClause node) => node.mixinTypes.forEach(_checkOut);

  void _check(Variance variance, TypeAnnotation? typeAnnotation) {
    if (typeAnnotation == null) return;
    // Do not lint implicit program elements.
    if (typeAnnotation.isSynthetic) return;
    switch (typeAnnotation) {
      case NamedType():
        var arguments = typeAnnotation.typeArguments?.arguments;
        if (arguments != null) {
          var element = typeAnnotation.element?.declaration;
          List<TypeParameterElement>? typeParameterList;
          if (element != null) {
            switch (element) {
              case ClassElement(:var typeParameters):
              case MixinElement(:var typeParameters):
              case EnumElement(:var typeParameters):
              case TypeAliasElement(:var typeParameters):
                typeParameterList = typeParameters;
              default:
                typeParameterList = null;
            }
          } else {
            typeParameterList = null;
          }
          if (typeParameterList == null ||
              typeParameterList.length != arguments.length) {
            // Fallback: Assume every type parameter is covariant.
            for (var argument in arguments) {
              _check(variance, argument);
            }
          } else {
            var length = arguments.length;
            for (var i = 0; i < length; ++i) {
              var parameter = typeParameterList[i];
              if (parameter is! TypeParameterElementImpl) continue;
              var argument = arguments[i];
              Variance parameterVariance;
              if (parameter.isLegacyCovariant ||
                  parameter.variance.isCovariant) {
                parameterVariance = variance;
              } else if (parameter.variance.isContravariant) {
                parameterVariance = variance.inverse;
              } else {
                parameterVariance = _inout;
              }
              _check(parameterVariance, argument);
            }
          }
        }
        var staticType = typeAnnotation.type;
        if (staticType == null) return;
        if (staticType is ParameterizedType) {
          if (variance == _in) return;
          if (!staticType.isDartAsyncFutureOr) return;
          var typeArguments = staticType.typeArguments;
          if (typeArguments.length != 1) return; // Just to be safe.
          if (typeArguments.first is VoidType) {
            rule.reportLint(typeAnnotation);
          }
        }
      case GenericFunctionType():
        _check(variance, typeAnnotation.returnType);
        for (var parameter in typeAnnotation.parameters.parameters) {
          _checkFormalParameter(variance.inverse, parameter);
        }
      case RecordTypeAnnotation():
        var positionalFields = typeAnnotation.positionalFields;
        for (var field in positionalFields) {
          _check(variance, field.type);
        }
        var namedFields = typeAnnotation.namedFields?.fields;
        if (namedFields != null) {
          for (var field in namedFields) {
            _check(variance, field.type);
          }
        }
    }
  }

  void _checkBound(TypeParameter typeParameter) =>
      _checkInOut(typeParameter.bound);

  void _checkFormalParameter(
      Variance variance, FormalParameter formalParameter) {
    if (!formalParameter.isExplicitlyTyped) return;
    switch (formalParameter) {
      case SuperFormalParameter(:var type):
      case FieldFormalParameter(:var type):
      case SimpleFormalParameter(:var type):
        _check(variance, type);
      case FunctionTypedFormalParameter(
          :var returnType,
          :var parameters,
          :var typeParameters
        ):
        _check(variance, returnType);
        typeParameters?.typeParameters.forEach(_checkBound);
        for (var parameter in parameters.parameters) {
          _checkFormalParameter(variance.inverse, parameter);
        }
      case DefaultFormalParameter():
        _checkFormalParameter(variance, formalParameter.parameter);
    }
  }

  void _checkFormalParameterIn(FormalParameter formalParameter) =>
      _checkFormalParameter(_in, formalParameter);

  void _checkInOut(TypeAnnotation? typeAnnotation) =>
      _check(_inout, typeAnnotation);

  void _checkOut(TypeAnnotation? typeAnnotation) =>
      _check(_out, typeAnnotation);
}
