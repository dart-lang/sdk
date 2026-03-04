// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_utilities/src/api_summary/src/node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NodeTest);
  });
}

@reflectiveTest
class NodeTest {
  void test_printNodes_indentChildNodes() {
    var buf = StringBuffer();
    printNodes(buf, [
      (
        1,
        _SimpleNode('one', [
          (2, _SimpleNode('two')),
          (3, _SimpleNode('three')),
        ]),
      ),
      (
        4,
        _SimpleNode('four', [
          (5, _SimpleNode('five')),
          (6, _SimpleNode('six')),
        ]),
      ),
    ]);
    expect(buf.toString(), '''
one
  two
  three
four
  five
  six
''');
  }

  void test_printNodes_joinTextStrings() {
    var buf = StringBuffer();
    printNodes(buf, [
      (1, Node<num>()..text.addAll(['x', 0])),
    ]);
    expect(buf.toString(), '''
x0
''');
  }

  void test_printNodes_sortChildNodesByKey() {
    var buf = StringBuffer();
    printNodes(buf, [
      (
        0,
        _SimpleNode('zero', [
          (2, _SimpleNode('two')),
          (1, _SimpleNode('one')),
          (3, _SimpleNode('three')),
        ]),
      ),
    ]);
    expect(buf.toString(), '''
zero
  one
  two
  three
''');
  }

  void test_printNodes_sortedByKey() {
    var buf = StringBuffer();
    printNodes(buf, [
      (2, _SimpleNode('two')),
      (1, _SimpleNode('one')),
      (3, _SimpleNode('three')),
    ]);
    expect(buf.toString(), '''
one
two
three
''');
  }
}

class _SimpleNode extends Node<num> {
  _SimpleNode(String text, [List<(num, Node<num>)> childNodes = const []]) {
    this.text.add(text);
    this.childNodes.addAll(childNodes);
  }
}
