// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib.dart' deferred as lib;

/// Regression test: if a type variable is used, but not instantiated, it still
/// needs to be mapped to the deferred unit where it is used.
///
/// If not, we may include it in the main unit and may not see that the base
/// class is not added to the main unit.
/*member: main:member_unit=main{}*/
main() {
  lib.loadLibrary().then(/*closure_unit=main{}*/ (_) {
    dontInline(new lib.C()).box.value;
  });
}

@pragma('dart2js:noInline')
/*member: dontInline:member_unit=main{}*/
dontInline(x) => x;
