// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// PackageRoot=none
// Packages=target_with_colon.packages

library target_with_colon_test;

import 'package:quux/quux.dart' as quux;

main() {
  if (quux.quux != 'quux') {
    throw new Exception('package "quux" was not resolved correctly');
  }
}
