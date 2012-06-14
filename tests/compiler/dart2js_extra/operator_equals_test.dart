// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AlwaysTrue {
  operator ==(a) => true;
}

class AlwaysFalse {
  operator ==(b) => false;
}

main() {
  var a = new AlwaysTrue();
  Expect.isTrue(a == 2);
  Expect.isTrue(a == null);
  Expect.isFalse(a != 2);
  Expect.isFalse(a != null);

  a = new AlwaysFalse();
  Expect.isFalse(a == 2);
  Expect.isFalse(a == null);
  Expect.isTrue(a != 2);
  Expect.isTrue(a != null);
}
