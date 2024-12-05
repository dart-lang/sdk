// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'prefix_vs_import_lib1.dart' as foo;
import 'prefix_vs_import_lib2.dart';
import 'prefix_vs_import_lib3.dart';
import 'prefix_vs_import_lib1.dart' as bar;

test() {
  foo.method();
  bar.method();
}
