// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import "package:expect/expect.dart";

main() {
  var shortDuration = Duration(milliseconds: 5);

  Expect.isTrue(Future<int?>.delayed(shortDuration) is Future);
  // In strong mode not passing a computation will throw when the type argument
  // passed is not nullable.
  Expect.throwsArgumentError(() => Future<int>.delayed(shortDuration));
}
