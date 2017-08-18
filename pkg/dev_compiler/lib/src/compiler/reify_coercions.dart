// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/type.dart' show DartType;
import 'package:analyzer/src/dart/ast/ast.dart' show FunctionBodyImpl;
import 'package:analyzer/src/dart/ast/utilities.dart' show NodeReplacer;
import 'package:analyzer/src/dart/element/type.dart' show DynamicTypeImpl;
import 'package:analyzer/src/generated/parser.dart' show ResolutionCopier;
import 'package:analyzer/src/task/strong/ast_properties.dart' as ast_properties;
import 'package:logging/logging.dart' as logger;

import 'ast_builder.dart' show AstBuilder, RawAstBuilder;
import 'element_helpers.dart' show isInlineJS;

final _log = new logger.Logger('dev_compiler.reify_coercions');

// This class implements a pass which modifies (in place) the ast replacing
// abstract coercion nodes with their dart implementations.
class CoercionReifier extends analyzer.GeneralizingAstVisitor<Object> {
  final cloner = new _TreeCloner();

  CoercionReifier._();

  /// Transforms the given compilation units, and returns a new AST with
  /// explicit coercion nodes in appropriate places.
  static List<CompilationUnit> reify(List<CompilationUnit> units) {
    var cr = new CoercionReifier._();
    return units.map(cr.visitCompilationUnit).toList(growable: false);
  }

  /// True if the `as` [node] is a required runtime check for soundness.
  // TODO(sra): Find a better way to recognize reified coercion, since we
  // can't set the isSynthetic attribute.
  static bool isRequiredForSoundness(AsExpression node) =>
      node.asOperator.offset == 0;

  /// Creates an implicit cast for expression [e] to [toType].
  static Expression castExpression(Expression e, DartType toType) {
    // We use an empty name in the AST, because the JS code generator only cares
    // about the target type. It does not look at the AST name.
    var typeName =
        astFactory.typeName(AstBuilder.identifierFromString(''), null);
    typeName.type = toType;
    var cast = AstBuilder.asExpression(e, typeName);
    cast.staticType = toType;
    return cast;
  }

  @override
  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    if (ast_properties.hasImplicitCasts(node)) {
      // Clone compilation unit, so we don't modify the originals.
      node = _clone(node);
      super.visitCompilationUnit(node);
    }
    return node;
  }

  @override
  visitExpression(Expression node) {
    node.visitChildren(this);

    var castType = ast_properties.getImplicitCast(node);
    if (castType != null) {
      _replaceNode(node.parent, node, castExpression(node, castType));
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (isInlineJS(node.methodName.staticElement)) {
      // Don't cast our inline-JS code in SDK.
      ast_properties.setImplicitCast(node, null);
    }
    visitExpression(node);
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    super.visitParenthesizedExpression(node);
    node.staticType = node.expression.staticType;
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    // Visit other children.
    node.iterable.accept(this);
    node.body.accept(this);

    // If needed, assert a cast inside the body before the variable is read.
    var variable = node.identifier ?? node.loopVariable.identifier;
    var castType = ast_properties.getImplicitCast(variable);
    if (castType != null) {
      // Build the cast. We will place this cast in the body, so need to clone
      // the variable's AST node and clear out its static type (otherwise we
      // will optimize away the cast).
      var cast = castExpression(
          _clone(variable)..staticType = DynamicTypeImpl.instance, castType);

      var body = node.body;
      var blockBody = <Statement>[RawAstBuilder.expressionStatement(cast)];
      if (body is Block) {
        blockBody.addAll(body.statements);
      } else {
        blockBody.add(body);
      }
      _replaceNode(node, body, RawAstBuilder.block(blockBody));
    }
  }

  void _replaceNode(AstNode parent, AstNode oldNode, AstNode newNode) {
    if (!identical(oldNode, newNode)) {
      var replaced = parent.accept(new NodeReplacer(oldNode, newNode));
      // It looks like NodeReplacer will always return true.
      // It does throw IllegalArgumentException though, if child is not found.
      assert(replaced);
    }
  }

  /*=T*/ _clone/*<T extends AstNode>*/(/*=T*/ node) {
    var copy = node.accept(cloner) as dynamic/*=T*/;
    ResolutionCopier.copyResolutionData(node, copy);
    return copy;
  }
}

class _TreeCloner extends analyzer.AstCloner {
  void _cloneProperties(AstNode clone, AstNode node) {
    if (clone is Expression) {
      ast_properties.setImplicitCast(
          clone, ast_properties.getImplicitCast(node));
      ast_properties.setImplicitOperationCast(
          clone, ast_properties.getImplicitOperationCast(node));
      ast_properties.setIsDynamicInvoke(
          clone, ast_properties.isDynamicInvoke(node));
    }
    if (clone is ClassDeclaration) {
      ast_properties.setClassCovariantParameters(
          clone, ast_properties.getClassCovariantParameters(node));
      ast_properties.setSuperclassCovariantParameters(
          clone, ast_properties.getSuperclassCovariantParameters(node));
    }
  }

  @override
  /*=E*/ cloneNode/*<E extends AstNode>*/(/*=E*/ node) {
    var clone = super.cloneNode(node);
    _cloneProperties(clone, node);
    return clone;
  }

  @override
  List/*<E>*/ cloneNodeList/*<E extends AstNode>*/(List/*<E>*/ list) {
    var clone = super.cloneNodeList(list);
    for (int i = 0, len = list.length; i < len; i++) {
      _cloneProperties(clone[i], list[i]);
    }
    return clone;
  }

  // TODO(jmesserly): ResolutionCopier is not copying this yet.
  @override
  BlockFunctionBody visitBlockFunctionBody(BlockFunctionBody node) {
    var clone = super.visitBlockFunctionBody(node);
    (clone as FunctionBodyImpl).localVariableInfo =
        (node as FunctionBodyImpl).localVariableInfo;
    return clone;
  }

  @override
  ExpressionFunctionBody visitExpressionFunctionBody(
      ExpressionFunctionBody node) {
    var clone = super.visitExpressionFunctionBody(node);
    (clone as FunctionBodyImpl).localVariableInfo =
        (node as FunctionBodyImpl).localVariableInfo;
    return clone;
  }

  // TODO(jmesserly): workaround for
  // https://github.com/dart-lang/sdk/issues/26368
  @override
  TypeName visitTypeName(TypeName node) {
    var clone = super.visitTypeName(node);
    clone.type = node.type;
    return clone;
  }
}
