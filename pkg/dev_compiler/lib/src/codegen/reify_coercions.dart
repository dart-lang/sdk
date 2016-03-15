// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart' show NodeReplacer;
import 'package:analyzer/src/generated/type_system.dart'
    show StrongTypeSystemImpl;
import 'package:analyzer/src/task/strong/info.dart';
import 'package:logging/logging.dart' as logger;

import 'ast_builder.dart';
import '../utils.dart' show getStaticType;

final _log = new logger.Logger('dev_compiler.reify_coercions');

class NewTypeIdDesc {
  /// If null, then this is not a library level identifier (i.e. it's
  /// a type parameter, or a special type like void, dynamic, etc)
  LibraryElement importedFrom;

  /// True => use/def in same library
  bool fromCurrent;

  /// True => not a source variable
  bool synthetic;
  NewTypeIdDesc({this.fromCurrent, this.importedFrom, this.synthetic});
}

// This class implements a pass which modifies (in place) the ast replacing
// abstract coercion nodes with their dart implementations.
class CoercionReifier extends analyzer.GeneralizingAstVisitor<Object> {
  final StrongTypeSystemImpl _typeSystem;

  CoercionReifier(this._typeSystem);

  /// This should be the entry point for this class.
  ///
  /// Entering via the visit functions directly may not do the right
  /// thing with respect to discharging the collected definitions.
  ///
  /// Returns the set of new type identifiers added by the reifier
  void reify(List<CompilationUnit> units) {
    units.forEach(visitCompilationUnit);
  }

  @override
  Object visitExpression(Expression node) {
    var info = CoercionInfo.get(node);
    if (info is InferredTypeBase) {
      return _visitInferredTypeBase(info, node);
    } else if (info is DownCast) {
      return _visitDownCast(info, node);
    }
    return super.visitExpression(node);
  }

  ///////////////// Private //////////////////////////////////

  Object _visitInferredTypeBase(InferredTypeBase node, Expression expr) {
    DartType t = node.type;
    if (!_typeSystem.isSubtypeOf(getStaticType(expr), t)) {
      if (getStaticType(expr).isDynamic) {
        var cast = Coercion.cast(expr.staticType, t);
        var info = new DynamicCast(_typeSystem, expr, cast);
        CoercionInfo.set(expr, info);
      }
    }
    expr.visitChildren(this);
    return null;
  }

  Object _visitDownCast(DownCast node, Expression expr) {
    var parent = expr.parent;
    expr.visitChildren(this);
    Expression newE = coerceExpression(expr, node.cast);
    if (!identical(expr, newE)) {
      var replaced = parent.accept(new NodeReplacer(expr, newE));
      // It looks like NodeReplacer will always return true.
      // It does throw IllegalArgumentException though, if child is not found.
      assert(replaced);
    }
    return null;
  }

  /// Coerce [e] using [c], returning a new expression.
  Expression coerceExpression(Expression e, Coercion c) {
    assert(c != null);
    assert(c is! CoercionError);
    if (e is NamedExpression) {
      Expression inner = coerceExpression(e.expression, c);
      return new NamedExpression(e.name, inner);
    }
    if (c is Cast) return _castExpression(e, c);
    assert(c is Identity);
    return e;
  }

  ///////////////// Private //////////////////////////////////

  Expression _castExpression(Expression e, Cast c) {
    // We use an empty name in the AST, because the JS code generator only cares
    // about the target type. It does not look at the AST name.
    var typeName = new TypeName(AstBuilder.identifierFromString(''), null);
    typeName.type = c.toType;
    var cast = AstBuilder.asExpression(e, typeName);
    cast.staticType = c.toType;
    return cast;
  }
}
