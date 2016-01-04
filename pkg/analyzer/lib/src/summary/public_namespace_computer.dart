// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.summary.public_namespace_visitor;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/summary/base.dart';
import 'package:analyzer/src/summary/format.dart';

/**
 * Compute the public namespace portion of the summary for the given [unit],
 * which is presumed to be an unresolved AST.
 */
UnlinkedPublicNamespaceBuilder computePublicNamespace(
    BuilderContext ctx, CompilationUnit unit) {
  _PublicNamespaceVisitor visitor = new _PublicNamespaceVisitor(ctx);
  unit.accept(visitor);
  return encodeUnlinkedPublicNamespace(ctx,
      names: visitor.names, exports: visitor.exports, parts: visitor.parts);
}

class _CombinatorEncoder extends SimpleAstVisitor<UnlinkedCombinatorBuilder> {
  final BuilderContext ctx;

  _CombinatorEncoder(this.ctx);

  List<String> encodeNames(NodeList<SimpleIdentifier> names) =>
      names.map((SimpleIdentifier id) => id.name).toList();

  @override
  UnlinkedCombinatorBuilder visitHideCombinator(HideCombinator node) {
    return encodeUnlinkedCombinator(ctx, hides: encodeNames(node.hiddenNames));
  }

  @override
  UnlinkedCombinatorBuilder visitShowCombinator(ShowCombinator node) {
    return encodeUnlinkedCombinator(ctx, shows: encodeNames(node.shownNames));
  }
}

class _PublicNamespaceVisitor extends RecursiveAstVisitor {
  final BuilderContext ctx;
  final List<UnlinkedPublicNameBuilder> names = <UnlinkedPublicNameBuilder>[];
  final List<UnlinkedExportBuilder> exports = <UnlinkedExportBuilder>[];
  final List<UnlinkedPartBuilder> parts = <UnlinkedPartBuilder>[];

  _PublicNamespaceVisitor(this.ctx);

  void addNameIfPublic(String name, PrelinkedReferenceKind kind) {
    if (isPublic(name)) {
      names.add(encodeUnlinkedPublicName(ctx, name: name, kind: kind));
    }
  }

  bool isPublic(String name) => !name.startsWith('_');

  @override
  visitClassDeclaration(ClassDeclaration node) {
    addNameIfPublic(node.name.name, PrelinkedReferenceKind.classOrEnum);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    addNameIfPublic(node.name.name, PrelinkedReferenceKind.classOrEnum);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    addNameIfPublic(node.name.name, PrelinkedReferenceKind.classOrEnum);
  }

  @override
  visitExportDirective(ExportDirective node) {
    exports.add(encodeUnlinkedExport(ctx,
        uri: node.uri.stringValue,
        combinators: node.combinators
            .map((Combinator c) => c.accept(new _CombinatorEncoder(ctx)))
            .toList()));
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    String name = node.name.name;
    if (node.isSetter) {
      name += '=';
    }
    addNameIfPublic(name, PrelinkedReferenceKind.other);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    addNameIfPublic(node.name.name, PrelinkedReferenceKind.typedef);
  }

  @override
  visitPartDirective(PartDirective node) {
    parts.add(encodeUnlinkedPart(ctx, uri: node.uri.stringValue));
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    String name = node.name.name;
    addNameIfPublic(name, PrelinkedReferenceKind.other);
    if (!node.isFinal && !node.isConst) {
      addNameIfPublic('$name=', PrelinkedReferenceKind.other);
    }
  }
}
