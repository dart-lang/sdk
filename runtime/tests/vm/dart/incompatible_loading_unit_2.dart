// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "incompatible_loading_unit_2_deferred.dart" deferred as lib;

main() async {
  await lib.loadLibrary();
  lib.foo();
}
