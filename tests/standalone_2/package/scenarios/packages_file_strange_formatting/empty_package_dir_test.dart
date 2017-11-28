// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Packages=empty_package_dir.packages

// In this test, we give a packages file that associates the package 'foo' with
// the empty string. This causes both the VM and dart2js to resolve
// 'package:foo' imports relative to the root directory. So the import statement
// `import 'package:foo/foo.dart'` is equivalent to `import '/foo.dart'`.
library empty_package_dir_test;

import 'package:foo/foo.dart';

main() {}
