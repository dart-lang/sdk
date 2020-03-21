// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'helpers/sourcemap_helper.dart';
import 'tools/source_mapping_tester.dart';

void main() {
  // 'operators.dart' and 'invokes.dart' are tested individually to avoid
  // test timeout.
  test(['--exclude', 'operators.dart', 'invokes.dart'],
      whiteListFunction: (String config, String file) {
    if (file == 'others.dart') {
      return (CodePoint point) {
        if (point.jsCode.startsWith('target=')) {
          // Switch continue target updates don't store the source information.
          return true;
        }
        if (point.jsCode.startsWith('t1=[P.int]')) {
          // TODO(johnniwinther): Ensure we have source information on type
          // arguments.
          return true;
        }
        return false;
      };
    }
    return emptyWhiteList;
  });
}
