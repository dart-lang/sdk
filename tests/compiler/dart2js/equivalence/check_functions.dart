// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Equivalence test functions for data objects.

library dart2js.equivalence.functions;

import 'package:compiler/src/js/js_debug.dart' as js;
import 'package:js_ast/js_ast.dart' as js;

bool areJsNodesEquivalent(js.Node node1, js.Node node2) {
  return new JsEquivalenceVisitor().testNodes(node1, node2);
}

class JsEquivalenceVisitor extends js.EquivalenceVisitor {
  Map<String, String> labelsMap = <String, String>{};

  @override
  bool failAt(js.Node node1, js.Node node2) {
    print('Node mismatch:');
    print('  ${node1 != null ? js.nodeToString(node1) : '<null>'}');
    print('  ${node2 != null ? js.nodeToString(node2) : '<null>'}');
    return false;
  }

  @override
  bool testValues(js.Node node1, Object value1, js.Node node2, Object value2) {
    if (value1 != value2) {
      print('Value mismatch:');
      print('  ${value1}');
      print('  ${value2}');
      print('at');
      print('  ${node1 != null ? js.nodeToString(node1) : '<null>'}');
      print('  ${node2 != null ? js.nodeToString(node2) : '<null>'}');
      return false;
    }
    return true;
  }

  @override
  bool testLabels(js.Node node1, String label1, js.Node node2, String label2) {
    if (label1 == null && label2 == null) return true;
    if (labelsMap.containsKey(label1)) {
      String expectedValue = labelsMap[label1];
      if (expectedValue != label2) {
        print('Value mismatch:');
        print('  ${label1}');
        print('  found ${label2}, expected ${expectedValue}');
        print('at');
        print('  ${js.nodeToString(node1)}');
        print('  ${js.nodeToString(node2)}');
      }
      return expectedValue == label2;
    } else {
      labelsMap[label1] = label2;
      return true;
    }
  }
}
