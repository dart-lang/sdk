// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/operation/operation.dart';
import 'package:test/test.dart';

main() {
  group('ServerOperationPriority', () {
    test('toString', () {
      expect(ServerOperationPriority.ANALYSIS.toString(), 'ANALYSIS');
    });
  });
}
