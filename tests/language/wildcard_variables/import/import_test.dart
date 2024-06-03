// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Import prefixes named `_` are non-binding, but will provide access to the
// non-private extensions in that library.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

import 'import_lib.dart' as _;

main() {
  var value = 'str';
  Expect.isTrue(value.foo);
}
