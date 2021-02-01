// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef AAlias<X> = Function<X1 extends A<X>> ();

typedef A<X extends B<X>> = Function();

class B<X> {}

main() {}
