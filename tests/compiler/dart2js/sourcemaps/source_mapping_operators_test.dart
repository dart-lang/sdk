// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'source_mapping_tester.dart';
import 'sourcemap_helper.dart';
import 'package:compiler/src/io/position_information.dart';

void main() {
  test(['operators'], whiteListFunction: (String config, String file) {
    bool allowGtOptimization(CodePoint codePoint) {
      // Allow missing code points for bailout optimization.
      return codePoint.jsCode.contains(r'.$gt()'); // # Issue 25304
    }

    if (config == 'cps') {
      return (CodePoint codePoint) {
        // Temporarily allow missing code points on expression statements.
        if (codePoint.kind == StepKind.EXPRESSION_STATEMENT ||
            codePoint.kind == StepKind.IF_CONDITION) {
          return true;
        }
        if (codePoint.jsCode.contains(r'H.iae(')) {
          // Allow missing code points for bailout calls.
          return true;
        }
        return allowGtOptimization(codePoint);
      };
    }
    return allowGtOptimization;
  });
}