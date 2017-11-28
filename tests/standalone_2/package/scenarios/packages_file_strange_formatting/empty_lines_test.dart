// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Packages=empty_lines.packages

library empty_lines_test;

import 'package:foo/foo.dart' as foo;
import 'package:bar/bar.dart' as bar;
import 'package:baz/baz.dart' as baz;

main() {
  if (foo.foo != 'foo') {
    throw new Exception('package "foo" was not resolved correctly');
  }
  if (bar.bar != 'bar') {
    throw new Exception('package "bar" was not resolved correctly');
  }
  if (baz.baz != 'baz') {
    throw new Exception('package "baz" was not resolved correctly');
  }
}
