// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.summary.public_namespace_visitor;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/summary/format.dart';

/**
 * Compute the public namespace portion of the summary for the given [unit],
 * which is presumed to be an unresolved AST.
 */
UnlinkedPublicNamespaceBuilder computePublicNamespace(CompilationUnit unit) {
  _PublicNamespaceVisitor visitor = new _PublicNamespaceVisitor();
  unit.accept(visitor);
  return encodeUnlinkedPublicNamespace(
      names: visitor.names, exports: visitor.exports, parts: visitor.parts);
}

class _CombinatorEncoder extends SimpleAstVisitor<UnlinkedCombinatorBuilder> {
  _CombinatorEncoder();

  List<String> encodeNames(NodeList<SimpleIdentifier> names) =>
      names.map((SimpleIdentifier id) => id.name).toList();

  @override
  UnlinkedCombinatorBuilder visitHideCombinator(HideCombinator node) {
    return encodeUnlinkedCombinator(hides: encodeNames(node.hiddenNames));
  }

  @override
  UnlinkedCombinatorBuilder visitShowCombinator(ShowCombinator node) {
    return encodeUnlinkedCombinator(shows: encodeNames(node.shownNames));
  }
}

class _PublicNamespaceVisitor extends RecursiveAstVisitor {
  final List<UnlinkedPublicNameBuilder> names = <UnlinkedPublicNameBuilder>[];
  final List<UnlinkedExportPublicBuilder> exports =
      <UnlinkedExportPublicBuilder>[];
  final List<String> parts = <String>[];

  _PublicNamespaceVisitor();

  void addNameIfPublic(
      String name, PrelinkedReferenceKind kind, int numTypeParameters) {
    if (isPublic(name)) {
      names.add(encodeUnlinkedPublicName(
          name: name, kind: kind, numTypeParameters: numTypeParameters));
    }
  }

  bool isPublic(String name) => !name.startsWith('_');

  @override
  visitClassDeclaration(ClassDeclaration node) {
    addNameIfPublic(node.name.name, PrelinkedReferenceKind.classOrEnum,
        node.typeParameters?.typeParameters?.length ?? 0);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    addNameIfPublic(node.name.name, PrelinkedReferenceKind.classOrEnum,
        node.typeParameters?.typeParameters?.length ?? 0);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    addNameIfPublic(node.name.name, PrelinkedReferenceKind.classOrEnum, 0);
  }

  @override
  visitExportDirective(ExportDirective node) {
    exports.add(encodeUnlinkedExportPublic(
        uri: node.uri.stringValue,
        combinators: node.combinators
            .map((Combinator c) => c.accept(new _CombinatorEncoder()))
            .toList()));
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    String name = node.name.name;
    if (node.isSetter) {
      name += '=';
    }
    addNameIfPublic(
        name,
        node.isGetter || node.isSetter
            ? PrelinkedReferenceKind.topLevelPropertyAccessor
            : PrelinkedReferenceKind.topLevelFunction,
        node.functionExpression.typeParameters?.typeParameters?.length ?? 0);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    addNameIfPublic(node.name.name, PrelinkedReferenceKind.typedef,
        node.typeParameters?.typeParameters?.length ?? 0);
  }

  @override
  visitPartDirective(PartDirective node) {
    parts.add(node.uri.stringValue);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    String name = node.name.name;
    addNameIfPublic(name, PrelinkedReferenceKind.topLevelPropertyAccessor, 0);
    if (!node.isFinal && !node.isConst) {
      addNameIfPublic(
          '$name=', PrelinkedReferenceKind.topLevelPropertyAccessor, 0);
    }
  }
}
