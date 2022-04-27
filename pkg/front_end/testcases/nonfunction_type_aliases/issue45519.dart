// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<X> {}
typedef G<X> = X Function(X);
typedef A<X extends G<C<X>>> = C<X>;

typedef H<X> = C<X Function(X)>;
typedef B<X extends H<X>> = C<X>;

test() {
  A a = throw 42; // Error.
  B b = throw 42; // Error.
}

main() {}
