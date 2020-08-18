// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: global#Type:instance,typeLiteral*/

import "package:expect/expect.dart";

void main(bool b) {
  Expect.isTrue(dynamic is Type);
  Expect.isFalse(dynamic == (b ? Type : dynamic)); // ?: avoids constant folding
}
