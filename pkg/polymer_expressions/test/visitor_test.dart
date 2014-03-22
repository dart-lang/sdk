// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library visitor_test;

import 'package:polymer_expressions/parser.dart';
import 'package:polymer_expressions/visitor.dart';
import 'package:unittest/unittest.dart';

main() {

  group('visitor', () {

    // regression test
    test('should not infinitely recurse on parenthesized expressions', () {
      var visitor = new TestVisitor();
      var expr = new Parser('(1)').parse();
      visitor.visit(expr);
    });

  });
}

class TestVisitor extends RecursiveVisitor {}
