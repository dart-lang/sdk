// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo() {
  A<String> a;
}

typedef A<X extends int> = B<String>;
typedef B<X extends int> = C<String>;
typedef C<X extends int> = X;

main() {}
