// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: global#Type:instance,typeLiteral*/

import "package:compiler/src/util/testing.dart";

late bool b;

void main() {
  makeLive(dynamic is Type);
  makeLive(dynamic == (b ? Type : dynamic)); // ?: avoids constant folding
}
