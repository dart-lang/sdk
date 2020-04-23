// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class Foo<T> {
  final Future<dynamic> Function() quux;
  T t;

  Foo(this.quux, this.t);

  Future<T> call() => quux().then<T>((_) => t);
}

class Bar {
  Foo<Baz> qux;

  Future<void> quuz() =>
      qux().then((baz) => corge(baz)).then((grault) => garply(grault));

  Grault corge(Baz baz) => null;

  void garply(Grault grault) {}
}

class Baz {}

class Grault {}

main() {}
