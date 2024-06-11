// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A(int x);
  const factory A.redir(int x) = A;
}

@A.redir(1)
foo(@A.redir(2) String y) {
  @A.redir(3) dynamic z;
}

main() {
  () => (<@A.redir(0) T>() => null);
}
