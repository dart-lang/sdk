// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'import_conflicting_type_member_lib1.dart';
import 'import_conflicting_type_member_lib2.dart';

main() {}

errors() {
  Foo foo;
  Foo();
}
