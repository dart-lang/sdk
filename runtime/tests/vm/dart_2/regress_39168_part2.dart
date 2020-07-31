// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of regress_39168;

class B {}

abstract class C {}

// Mixin application B with C is de-duplicated with mixin application
// in regress_39168_part1.dart.
class D extends B with C {}

main() {
  new D();
}
