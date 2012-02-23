// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  Expect.isTrue(null is Object);
  Expect.isFalse(null is int);
  Expect.isFalse(null is bool);
  Expect.isFalse(null is num);
  Expect.isFalse(null is String);
  Expect.isFalse(null is List);
  Expect.isFalse(null is Expect);
}
