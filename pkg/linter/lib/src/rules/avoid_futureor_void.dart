// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r"Avoid using 'FutureOr<void>' as the type of a result.";

const _in = Variance._in;

const _inout = Variance._inout;

const _out = Variance._out;

class AvoidFutureOrVoid extends LintRule {
  AvoidFutureOrVoid()
      : super(
            name: LintNames.avoid_futureor_void,
            description: _desc,
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
          var element = typeAnnotation.element2?.baseElement;
          List<TypeParameterElement2>? typeParameterList;
          if (element != null) {
            switch (element) {
              case ClassElement2(:var typeParameters2):
              case MixinElement2(:var typeParameters2):
              case EnumElement2(:var typeParameters2):
              case TypeAliasElement2(:var typeParameters2):
                typeParameterList = typeParameters2;
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
              var argument = arguments[i];
              Variance parameterVariance;
              var parameterFragment =
                  parameter.firstFragment as TypeParameterElementImpl;
              if (parameterFragment.isLegacyCovariant ||
                  parameterFragment.variance.isCovariant) {
                parameterVariance = variance;
              } else if (parameterFragment.variance.isContravariant) {
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
