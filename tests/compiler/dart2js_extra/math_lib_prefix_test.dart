// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:math", prefix: "foo");

main() {
  Expect.equals(2.0, foo.sqrt(4));
  Expect.equals(2.25, foo.pow(1.5, 2.0));
}
