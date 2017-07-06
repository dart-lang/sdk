// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/**
 * Search the [unit] for the [Element]s with the given [name].
 */
List<Element> findElementsByName(CompilationUnit unit, String name) {
  var finder = new _ElementsByNameFinder(name);
  unit.accept(finder);
  return finder.elements;
}

class _ElementsByNameFinder extends RecursiveAstVisitor<Null> {
  final String name;
  final List<Element> elements = [];

  _ElementsByNameFinder(this.name);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name && node.inDeclarationContext()) {
      elements.add(node.staticElement);
    }
  }
}
