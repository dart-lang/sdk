// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.listEquals([], [].sublist(0, 0));
  Expect.listEquals([], const [].sublist(0, 0));

  Expect.listEquals([1, 2], [1, 2].sublist(0, 2));
  Expect.listEquals([1, 2], const [1, 2].sublist(0, 2));

  Expect.listEquals([1], [1, 2].sublist(0, 1));
  Expect.listEquals([1], const [1, 2].sublist(0, 1));

  Expect.listEquals([2], [1, 2].sublist(1, 2));
  Expect.listEquals([2], const [1, 2].sublist(1, 2));

  Expect.listEquals([], [1, 2].sublist(0, 0));
  Expect.listEquals([], const [1, 2].sublist(0, 0));

  Expect.listEquals([2, 3], [1, 2, 3, 4].sublist(1, 3));
  Expect.listEquals([2, 3], const [1, 2, 3, 4].sublist(1, 3));

  Expect.listEquals([2, 3], [1, 2, 3, 4].sublist(1, 3));
  Expect.listEquals([2, 3], const [1, 2, 3, 4].sublist(1, 3));

  Expect.throwsArgumentError(() => [].sublist(-1, null));
  Expect.throwsArgumentError(() => const [].sublist(-1, null));
  Expect.throwsArgumentError(() => [].sublist(-1, 0));
  Expect.throwsArgumentError(() => const [].sublist(-1, 0));
  Expect.throwsArgumentError(() => [].sublist(-1, -1));
  Expect.throwsArgumentError(() => const [].sublist(-1, -1));
  Expect.throwsArgumentError(() => [].sublist(-1, 1));
  Expect.throwsArgumentError(() => const [].sublist(-1, 1));
  Expect.throwsArgumentError(() => [].sublist(0, -1));
  Expect.throwsArgumentError(() => const [].sublist(0, -1));
  Expect.throwsArgumentError(() => [].sublist(0, 1));
  Expect.throwsArgumentError(() => const [].sublist(0, 1));
  Expect.throwsArgumentError(() => [].sublist(1, null));
  Expect.throwsArgumentError(() => const [].sublist(1, null));
  Expect.throwsArgumentError(() => [].sublist(1, 0));
  Expect.throwsArgumentError(() => const [].sublist(1, 0));
  Expect.throwsArgumentError(() => [].sublist(1, -1));
  Expect.throwsArgumentError(() => const [].sublist(1, -1));
  Expect.throwsArgumentError(() => [].sublist(1, 1));
  Expect.throwsArgumentError(() => const [].sublist(1, 1));

  Expect.throwsArgumentError(() => [1].sublist(0, 2));
  Expect.throwsArgumentError(() => [1].sublist(1, 2));
  Expect.throwsArgumentError(() => [1].sublist(1, 0));
}
