// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  final base = Uri.base; // should not crash

  // Tests are compiled to generated files in a directory that uses the test
  // file name.
  Expect.contains('uri_base_test', '$base');
}
