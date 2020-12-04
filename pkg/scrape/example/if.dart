// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:scrape/scrape.dart';

void main(List<String> arguments) {
  Scrape()
    ..addHistogram('If')
    ..addVisitor(() => IfVisitor())
    ..runCommandLine(arguments);
}

class IfVisitor extends ScrapeVisitor {
  @override
  void visitIfStatement(IfStatement node) {
    if (node.elseStatement != null) {
      record('If', 'else');
    } else {
      record('If', 'no else');
    }
    super.visitIfStatement(node);
  }
}
