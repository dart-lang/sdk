// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'uninstantiated_type_variable_lib.dart' deferred as lib;

/// Regression test: if a type variable is used, but not instantiated, it still
/// needs to be mapped to the deferred unit where it is used.
///
/// If not, we may include it in the main unit and may not see that the base
/// class is not added to the main unit.
main() {
  lib.loadLibrary().then((_) {
    dontInline(new lib.C()).box.value;
  });
}

@NoInline()
dontInline(x) => x;
