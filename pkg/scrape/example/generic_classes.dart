// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';

import 'package:scrape/scrape.dart';

void main(List<String> arguments) {
  Scrape()
    ..addHistogram('Classes', order: SortOrder.numeric)
    ..addVisitor(() => GenericClassVisitor())
    ..runCommandLine(arguments);
}

class GenericClassVisitor extends ScrapeVisitor {
  @override
  void visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.typeParameters == null) {
      record('Classes', 0);
    } else {
      record('Classes', node.typeParameters.typeParameters.length);
    }
    super.visitClassDeclaration(node);
  }
}
