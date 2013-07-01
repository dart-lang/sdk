// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that native classes can be used as type arguments in checks.

import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

void main() {
  useHtmlConfiguration();

  expect(document.queryAll('foo') is List<Node>, isTrue);
  expect(document.queryAll('foo') is List<int>, isFalse);
}
