// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/link.dart';

/// Used to resolve some AST nodes - variable initializers, and annotations.
class AstResolver {
  final Linker _linker;
  final LibraryElement _library;
  final Scope _nameScope;

  AstResolver(this._linker, this._library, this._nameScope);

  void resolve(
    AstNode node, {
    ClassElement enclosingClassElement,
    ExecutableElement enclosingExecutableElement,
    FeatureSet featureSet,
    bool doAstRewrite = false,
  }) {
    var source = _FakeSource();
    var errorListener = AnalysisErrorListener.NULL_LISTENER;

    var typeResolverVisitor = new TypeResolverVisitor(
        _library, source, _linker.typeProvider, errorListener,
        nameScope: _nameScope);
    node.accept(typeResolverVisitor);

    if (doAstRewrite) {
      var astRewriteVisitor = new AstRewriteVisitor(_linker.typeSystem,
          _library, source, _linker.typeProvider, errorListener,
          nameScope: _nameScope);
      node.accept(astRewriteVisitor);
    }

    var variableResolverVisitor = new VariableResolverVisitor(
        _library, source, _linker.typeProvider, errorListener,
        nameScope: _nameScope, localVariableInfo: LocalVariableInfo());
    node.accept(variableResolverVisitor);

//    if (_linker.getAst != null) {
//      expression.accept(_partialResolverVisitor);
//    }

    var resolverVisitor = new ResolverVisitor(_linker.inheritance, _library,
        source, _linker.typeProvider, errorListener,
        featureSet: featureSet,
        nameScope: _nameScope,
        propagateTypes: false,
        reportConstEvaluationErrors: false);
    resolverVisitor.prepareEnclosingDeclarations(
      enclosingClassElement: enclosingClassElement,
      enclosingExecutableElement: enclosingExecutableElement,
    );

    node.accept(resolverVisitor);
  }
}

class _FakeSource implements Source {
  @override
  String get fullName => '/package/lib/test.dart';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
