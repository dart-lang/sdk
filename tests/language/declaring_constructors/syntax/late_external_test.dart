// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `late` and `external` must be initialized in the body.

// SharedOptions=--enable-experiment=declaring-constructors

class C2(this.x) {
  late int x;
  external double d;
}

class C2 {
  late int x;
  external double d;
  this(this.x);
}
