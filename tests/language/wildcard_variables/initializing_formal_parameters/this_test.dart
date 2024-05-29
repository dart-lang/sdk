// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A positional initializing formal named `_` does still initialize a field
// named `_`, and you can still have a field with that name.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

void main() {
  var c = C(1);
  Expect.equals(1, c._);

  var cWithPositional = C.withPositional(1, 100);
  Expect.equals(1, cWithPositional._);

  var cWithBody = C.withBody(1);
  Expect.equals(200, cWithBody._);
}

class C<_> {
  var _;

  C(this._);
  C.withPositional(this._, _);
  C.withBody(this._) {
    _ = 200;
  }
}
