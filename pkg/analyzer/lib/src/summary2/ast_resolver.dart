// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';

/// Used to resolve some AST nodes - variable initializers, and annotations.
class AstResolver {
  final Linker _linker;
  final LibraryElement _library;
  final Scope _nameScope;

  AstResolver(this._linker, this._library, this._nameScope);

  LinkedNode resolve(
    LinkedUnitContext context,
    AstNode node, {
    ClassElement enclosingClassElement,
    ExecutableElement enclosingExecutableElement,
  }) {
    var source = _FakeSource();
    var errorListener = AnalysisErrorListener.NULL_LISTENER;

    var typeResolverVisitor = new TypeResolverVisitor(
        _library, source, _linker.typeProvider, errorListener,
        nameScope: _nameScope);
    node.accept(typeResolverVisitor);

//    expression.accept(_astRewriteVisitor);
//    expression.accept(_variableResolverVisitor);
//    if (_linker.getAst != null) {
//      expression.accept(_partialResolverVisitor);
//    }

    var resolverVisitor = new ResolverVisitor(_linker.inheritance, _library,
        source, _linker.typeProvider, errorListener,
        nameScope: _nameScope,
        propagateTypes: false,
        reportConstEvaluationErrors: false);
    resolverVisitor.prepareEnclosingDeclarations(
      enclosingClassElement: enclosingClassElement,
      enclosingExecutableElement: enclosingExecutableElement,
    );

    node.accept(resolverVisitor);

    throw UnimplementedError();
//    var writer = AstBinaryWriter(
//      _linker.linkingBundleContext,
//      context.tokensContext,
//    );
//    return writer.writeNode(node);
  }
}

class _FakeSource implements Source {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
