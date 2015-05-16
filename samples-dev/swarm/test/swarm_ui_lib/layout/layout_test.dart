// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library layout_tests;

import 'package:expect/expect.dart';
import 'dart:async';
import 'dart:html';
import '../../../swarm_ui_lib/base/base.dart';
import '../../../swarm_ui_lib/layout/layout.dart';
import '../../../swarm_ui_lib/view/view.dart';
import '../../../swarm_ui_lib/util/utilslib.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

part 'grid_layout_demo.dart';
part 'grid_examples.dart';
part 'css.dart';

// TODO(jmesserly): these tests would be easier to work with if they were WebKit
// layout tests. The way content shell works is exactly what we want for
// testing layout: run the example and then print the element tree with metrics.
// The UnitTestSuite wrapper gets in our way here, because you can't "see" the
// test layout visually when you're debugging.
// See these links for more info:
//   http://www.webkit.org/quality/testwriting.html
//   http://www.w3.org/Style/CSS/Test/guidelines.html

// TODO(jmesserly): need parser unit tests, especially error conditions

/**
 * Tests the grid layout. Currently based on examples from the spec at:
 * [http://dev.w3.org/csswg/css3-grid-align/]
 */
main() {
  useHtmlConfiguration();
  addGridStyles('400px', '400px');

  test('Spec Example 1', () {
    return verifyExample('1 Adaptive Layouts', {
      'title': [0, 0, 144, 24],
      'score': [0, 376, 144, 24],
      'stats': [0, 24, 144, 24],
      'board': [144, 0, 256, 376],
      'controls': [185, 376, 174, 24],
    });
  });

  test('Spec Example 2a', () {
    return verifyExample('2a Source Independence: Portrait', {
      'title': [0, 0, 144, 24],
      'score': [0, 24, 144, 24],
      'stats': [144, 0, 256, 48],
      'board': [0, 48, 400, 328],
      'controls': [0, 376, 400, 24],
    });
  });

  test('Spec Example 2b', () {
    return verifyExample('2b Source Independence: Landscape', {
      'title': [0, 0, 144, 24],
      'score': [0, 376, 144, 24],
      'stats': [0, 24, 144, 352],
      'board': [144, 0, 256, 376],
      'controls': [144, 376, 256, 24],
    });
  });

  // Not currently supported, issue with
  // http://dev.w3.org/csswg/css3-grid-layout/#function-CalculateNormalizedFractionBreadth
  //test('Spec Example 3', () {
  //  return verifyExample('3 Grid Layering of Elements', {
  //    'lower-label': [0, 0, 204, 24],
  //    'track': [204, 0, 144, 24],
  //    'upper-label': [348, 0, 204, 24],
  //    'lower-fill': [204, 0, 72, 24],
  //    'upper-fill': [276, 0, 72, 24],
  //    'thumb': [204, 0, 144, 24],
  //  });
  //});

  test('Spec Example 5', () {
    return verifyExample('5 Grid Lines', {
      'item1': [125, 0, 275, 400],
    });
  });

  test('Spec Example 6', () {
    return verifyExample('6 Grid Lines', {
      'item1': [125, 0, 275, 400],
    });
  });

  test('Spec Example 7', () {
    return verifyExample('7 Grid Cells', {
      'item2': [0, 50, 125, 24],
      'item3': [-19, 326, 144, 24],
    });
  });

  test('Spec Example 11a', () {
    return verifyExample('11a Starting and Ending Grid Lines', {
      'item': [0, 0, 400, 400],
    });
  });

  test('Spec Example 11b', () {
    return verifyExample('11b Starting and Ending Grid Lines', {
      'item': [0, 0, 400, 400],
    });
  });

  test('Spec Example 12', () {
    return verifyExample('12 Repeating Columns and Rows', {
      'col2': [10, 0, 88, 400],
      'col4': [108, 0, 87, 400],
      'col6': [205, 0, 88, 400],
      'col8': [303, 0, 87, 400],
    });
  });

  test('Spec Example 17', () {
    return verifyExample('17 Anonymous Grid Cells', {
      'header': [0, 0, 400, 24],
      'main': [0, 24, 400, 352],
      'footer': [0, 376, 400, 24],
    });
  });

  // Not currently supported, issue with
  // http://dev.w3.org/csswg/css3-grid-layout/#function-CalculateNormalizedFractionBreadth
  //test('Spec Example 20', () {
  //  return verifyExample('20 Implicit Columns and Rows', {
  //    'A': [0, 0, 104, 24],
  //    'B': [104, 0, 104, 44],
  //    'C': [0, 20, 104, 24],
  //  });
  //});

  test('Spec Example 22', () {
    return verifyExample('22 Grid Item Alignment', {
      'A': [0, 0, 104, 24],
      'B': [296, 376, 104, 24],
    });
  });

  test('Spec Example 23', () {
    return verifyExample('23 Drawing Order of Grid Items', {
      'A': [0, 376, 400, 24],
      'B': [0, 0, 200, 200],
      'C': [200, 0, 200, 24],
      'D': [296, 200, 104, 24],
      'E': [148, 188, 104, 24],
    });
  });
}

// Note: to debug failures, best bet is to use GridLayoutDemo to run an
// individual asyncTest and see the resulting layout.

Future usingGrid(String example, Future test_(View grid)) {
  final grid = createGrid(GridExamples.styles[example]);
  grid.addToDocument(document.body);
  return new Future.delayed(new Duration()).then((_) {
    return test_(grid);
  }).then((_) {
    grid.removeFromDocument();
  });
}

Future verifyGrid(String example, [Map expected = null]) {
  printMetrics(example);
  if (expected == null) {
    return new Future.value();
  }

  for (String name in expected.keys) {
    final values = expected[name];
    final node = document.body.querySelector('#$name');
    Expect.isNotNull(node);
    return new Future.value().then((_) {
      Expect.equals(values[0], node.offsetLeft);
      Expect.equals(values[1], node.offsetTop);
      Expect.equals(values[2], node.offsetWidth);
      Expect.equals(values[3], node.offsetHeight);
    });
  }
}

Future verifyExample(String example, [Map expected = null]) {
  return usingGrid(example, (grid) => verifyGrid(example, expected));
}
