// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:js_ast/js_ast.dart';

class Source implements JavaScriptNodeSourceInformation {
  final Object tag;
  Source(this.tag);

  @override
  String toString() => 'Source($tag)';
}

void check(Node node, expectedSource, expectedAnnotations) {
  Expect.equals('$expectedSource', '${node.sourceInformation}', 'source');
  Expect.equals('$expectedAnnotations', '${node.annotations}', 'annotations');
}

void simpleTests(Node node) {
  check(node, null, []);

  final s1 = node.withSourceInformation(Source(1));
  check(node, null, []);
  check(s1, Source(1), []);

  final a1 = node.withAnnotation(1);
  check(node, null, []);
  check(s1, Source(1), []);
  check(a1, null, [1]);

  final a2 = node.withAnnotation(2);
  check(node, null, []);
  check(s1, Source(1), []);
  check(a1, null, [1]);
  check(a2, null, [2]);

  final s1a3 = s1.withAnnotation(3);
  check(node, null, []);
  check(s1, Source(1), []);
  check(s1, Source(1), []);
  check(a2, null, [2]);
  check(s1a3, Source(1), [3]);

  final s1a3a4 = s1a3.withAnnotation(4);
  check(node, null, []);
  check(s1, Source(1), []);
  check(s1, Source(1), []);
  check(a2, null, [2]);
  check(s1a3, Source(1), [3]);
  check(s1a3a4, Source(1), [3, 4]);

  final a2s5 = a2.withSourceInformation(Source(5));
  check(node, null, []);
  check(s1, Source(1), []);
  check(s1, Source(1), []);
  check(a2, null, [2]);
  check(s1a3, Source(1), [3]);
  check(s1a3a4, Source(1), [3, 4]);
  check(a2s5, Source(5), [2]);
}

bool debugging = false;

/// Explore all combinations of withSourceInformation and withAnnotation.
void testGraph(Node root) {
  // At each node in the graph, all the previous checks are re-run to ensure
  // that source information or annotations do not change.
  List<void Function(String state)> tests = [];

  void explore(
      String state,
      Node node,
      int sourceDepth,
      int annotationDepth,
      JavaScriptNodeSourceInformation? expectedSource,
      List<Object> expectedAnnotations) {
    void newCheck(String currentState) {
      if (debugging) {
        print('In state $currentState check $state:'
            ' source: $expectedSource, annotations: $expectedAnnotations');
      }
      Expect.equals(
          '$expectedSource',
          '${node.sourceInformation}',
          ' at state $currentState for node at state $state:'
              ' ${node.debugPrint()}');
      Expect.equals(
          '$expectedAnnotations',
          '${node.annotations}',
          ' at state $currentState for node at state $state:'
              ' ${node.debugPrint()}');
    }

    tests.add(newCheck);

    for (final test in tests) {
      test(state);
    }

    if (sourceDepth < 3) {
      final newSourceDepth = sourceDepth + 1;
      final newSource = Source(newSourceDepth);
      final newState = '$state-s$newSourceDepth';
      final newNode = node.withSourceInformation(newSource);

      explore(newState, newNode, newSourceDepth, annotationDepth, newSource,
          expectedAnnotations);
    }
    if (annotationDepth < 3) {
      final newAnnotationDepth = annotationDepth + 1;
      final newAnnotation = 'a:$newAnnotationDepth';
      final newAnnotations = [...expectedAnnotations, newAnnotation];
      final newState = '$state-a$newAnnotationDepth';
      final newNode = node.withAnnotation(newAnnotation);

      explore(newState, newNode, sourceDepth, newAnnotationDepth,
          expectedSource, newAnnotations);
    }
  }

  explore('root', root, 0, 0, null, []);
}

void main() {
  simpleTests(js('x + 1'));
  simpleTests(js.statement('f()'));

  testGraph(js('1'));
  testGraph(js('x + 1'));
  testGraph(js('f()'));
  testGraph(js.statement('f()'));
  testGraph(js.statement('break'));
}
