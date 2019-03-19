// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/builder/source_library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// Used to resolve some AST nodes - variable initializers, and annotations.
class AstResolver {
  final Linker _linker;

  LibraryElement _library;
  Scope _nameScope;

  AstResolver(this._linker, Reference libraryRef) {
    _library = _linker.elementFactory.elementOfReference(libraryRef);
    _nameScope = LibraryScope(_library);
  }

  LinkedNode resolve(UnitBuilder unit, AstNode node) {
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
    node.accept(resolverVisitor);

    var writer = AstBinaryWriter(
      _linker.linkingBundleContext,
      unit.context.tokensContext,
    );
    return writer.writeNode(node);
  }
}

class _FakeSource implements Source {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
