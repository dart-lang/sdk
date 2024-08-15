// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {}

sealed class B<X> {
  final C? Function()? foo;
  const B({required this.foo});

  const factory B.redir({C? Function()? foo}) = A;
}

mixin M {}

final class A<X> extends B<X> with M {
  const A({super.foo = null}) : super();
}

main() {
  print(new A());
}
