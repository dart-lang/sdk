// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The representation variable of an extension type can be named `_`, and no
// formal parameter name is introduced into any scopes.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

extension type Id(int _) {
  operator <(Id other) => _ < other._;
}

void main() {
  var id = Id(1);
  Expect.isTrue(id < Id(2));
}
