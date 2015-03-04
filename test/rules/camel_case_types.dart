// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class DB {}

class FooBar {}

class _Foo {}

class Foo extends _Foo {}

typedef bool predicate(); //LINT [14:9]

class fooBar { //LINT

}

class Foo$Bar { //LINT

}

class Foo_Bar { //LINT

}
