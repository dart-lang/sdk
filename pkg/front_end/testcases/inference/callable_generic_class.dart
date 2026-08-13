// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class ActionDispatcher<P> {
  void call([P? value]) {}
}

class Bar {}

class FooActions {
  ActionDispatcher<Bar> get foo => new ActionDispatcher<Bar>();
}

void main() {
  new FooActions().foo(new Bar());
  new FooActions().foo.call(new Bar());
  (new FooActions().foo)(new Bar());
}
