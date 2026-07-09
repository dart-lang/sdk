// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for http://dartbug.com/61222.

import 'package:expect/expect.dart';

void main() {
  var eList = <E>[?E.vn(), ?E.v1()];
  Expect.listEquals([E.v1()], eList);
}

extension type const E._(int? _) {
  const E.vn() : this._(null);
  const E.v1() : this._(1);
}
