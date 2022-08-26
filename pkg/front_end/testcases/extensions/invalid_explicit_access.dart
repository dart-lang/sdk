// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

extension Extension on Class {
  method(a) {}
}

class GenericClass<T> {}

extension GenericExtension<T> on GenericClass<T> {
  method() {}
}



main() {
  String s = '';

  Class c1 = new Class();
  Extension().method(null);
  Extension(c1, null).method(null);
  Extension(receiver: c1).method(null);
  Extension(c1, receiver: null).method(null);
  Extension<int>(c1).method(null);
  Extension(s).method(null);
  Extension(c1).foo;
  Extension(c1).foo = null;
  Extension(c1).foo();
  Extension(c1).method();
  // TODO(johnniwinther): Report argument/parameter count corresponding to
  // the source code/declaration, not the converted invocation.
  // TODO(johnniwinther): Use the declaration name length for the squiggly.
  Extension(c1).method(1, 2);
  Extension(c1).method(a: 1);
  Extension(c1).method(1, a: 2);
  Extension(c1).method<int>(null);

  GenericClass<int> c2 = new GenericClass<int>();
  GenericExtension().method();
  GenericExtension<int>().method();
  GenericExtension(c2, null).method();
  GenericExtension<int>(c2, null).method();
  GenericExtension(receiver: c2).method();
  GenericExtension<int>(receiver: c2).method();
  GenericExtension(c2, receiver: null).method();
  GenericExtension<int>(c2, receiver: null).method();
  GenericExtension<int, String>(c2).method();
  GenericExtension(s).method();
  GenericExtension<int>(s).method();
}