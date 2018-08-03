// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class B<T> {}

abstract class C<T> {}

class Base implements B {}

class Child1 extends Base implements C<int> {}

class Child2 extends Base implements C<double> {}

main() {}
