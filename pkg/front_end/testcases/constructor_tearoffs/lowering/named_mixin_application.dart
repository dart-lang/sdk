// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  int get field;
}

class Class<T> implements Interface {
  var field;

  Class([this.field = 0]);
  Class.named(this.field);
  Class.redirectingGenerative(int field) : this(field);
  factory Class.fact(int field) => new Class(field);
  factory Class.redirectingFactory(int field) = Class;
}

mixin Mixin<S> {}

class NamedMixinApplication<T, S> = Class<T> with Mixin<S>;

abstract class AbstractNamedMixinApplication<T, S> = Class<T> with Mixin<S>;

test() {
  NamedMixinApplication.fact;
  NamedMixinApplication.redirectingFactory;

  AbstractNamedMixinApplication.new;
  AbstractNamedMixinApplication.named;
  AbstractNamedMixinApplication.redirectingGenerative;
  AbstractNamedMixinApplication.fact;
  AbstractNamedMixinApplication.redirectingFactory;
}

var f1 = NamedMixinApplication.new;
var f2 = NamedMixinApplication.named;
var f3 = NamedMixinApplication.redirectingGenerative;

main() {
  var f1 = NamedMixinApplication.new;
  var f2 = NamedMixinApplication.named;
  var f3 = NamedMixinApplication.redirectingGenerative;

  NamedMixinApplication<int, String>.new;
  NamedMixinApplication<int, String>.named;
  NamedMixinApplication<int, String>.redirectingGenerative;

  NamedMixinApplication<int, String> Function([int]) n1 = f1<int, String>;
  NamedMixinApplication<int, String> Function(int) n2 = f2<int, String>;
  NamedMixinApplication<int, String> Function(int) n3 = f3<int, String>;
}
