// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './issue41842.dart';

class Foo<T> extends A<T> {
  Foo(int x);
  Foo.foo(int x);
  factory Foo.bar(int x) => Foo.foo(x);
}

class Bar<T> extends A<T> {
  factory Bar(int x) => Bar.named(x);
  Bar.named(int x);
  Bar.foo(int x);
  factory Bar.bar(int x) => Bar.foo(x);
}
