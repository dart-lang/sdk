// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'source_mapping_tester.dart';

void main() {
  test(['invokes'], whiteListFunction: (String configuration, String file) {
    // TODO(redemption): Create source information from kernel.
    if (configuration == 'kernel') return (_) => true;
    return emptyWhiteList;
  });
}
