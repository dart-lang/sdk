// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check possibly still unresolved upper bounds of default factory class.


interface A<T extends Foo> default _AImpl<T extends Foo> {
  const A();
}

class Moo extends Foo {}

class Foo extends Bar {}

class Bar {}

class _AImpl<T extends Foo> implements A<T> {
   factory _AImpl(){}
}

main() {
  var result = new A<Moo>();
}
