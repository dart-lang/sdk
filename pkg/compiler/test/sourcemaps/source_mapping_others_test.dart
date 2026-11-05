// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'helpers/sourcemap_helper.dart';
import 'tools/source_mapping_tester.dart';

void main() {
  test(['others.dart'], whiteListFunction: whiteListFunction);
}

CodePointWhiteListFunction whiteListFunction(String config, String file) {
  return (CodePoint point) {
    // Switch continue target updates don't store the source information.
    return point.jsCode.startsWith('target=');
  };
}
