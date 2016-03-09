// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'source_mapping_tester.dart';
import 'sourcemap_helper.dart';
import 'package:compiler/src/io/position_information.dart';

void main() {
  test(['invokes'], whiteListFunction: (String config, String file) {
    if (config == 'cps') {
      return (CodePoint codePoint) {
        // Temporarily allow missing code points on expression statements.
        return codePoint.kind == StepKind.EXPRESSION_STATEMENT;
      };
    }
    return emptyWhiteList;
  });
}