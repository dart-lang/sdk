// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/**
 * Search the [unit] for declared [SimpleIdentifier]s with the given [name].
 */
List<SimpleIdentifier> findDeclaredIdentifiersByName(
    CompilationUnit unit, String name) {
  var finder = new _DeclaredIdentifiersByNameFinder(name);
  unit.accept(finder);
  return finder.identifiers;
}

class _DeclaredIdentifiersByNameFinder extends RecursiveAstVisitor<Null> {
  final String name;
  final List<SimpleIdentifier> identifiers = [];

  _DeclaredIdentifiersByNameFinder(this.name);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name && node.inDeclarationContext()) {
      identifiers.add(node);
    }
  }
}
