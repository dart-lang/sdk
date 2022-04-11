// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'lib.dart' deferred as lib;

void main() {
  lib.loadLibrary().then((_) {
    lib.check(dontInline(lib.create()));
  });
}

@pragma('dart2js:noInline')
Object dontInline(Object x) => x;
