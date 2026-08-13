// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A(int x, {String? y});
  const factory A.redir(int x, {String? y}) = A;
}

test1() => const A(y: "foo", 0);
test2() => const A.redir(y: "foo", 0);

main() {}
