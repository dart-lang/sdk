// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: languageVersion=2.8*/

// Test that bin and test files within the root folder of a package are
// associated with the package.

import 'foo/bin/bin_file.dart';
import 'foo/test/test_file.dart';
import 'package:foo/foo.dart';

main() {
  method1();
  method2();
  method3();
}
