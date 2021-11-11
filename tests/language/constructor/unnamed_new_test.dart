// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "unnamed_new_test.dart" as prefix;

// Tests that `Classname.new` is allowed and works
// as an alias for the unnamed constructor.

// Constructor using `new` syntax.
class New<T> {
  final int x;
  const New.new([this.x = 0]) : super.new();
  const New.thisNew(int x) : this.new(x);
  const New.thisNoNew(int x) : this(x);
  const factory New.factoryNew(int x) = New<T>.new;
  const factory New.factoryNoNew(int x) = New<T>;
}

class NewSub<T> extends New<T> {
  const NewSub.new(); // Implicit `: super()`
  const NewSub.implicit(); // Implicit `: super()`
  const NewSub.superNew(int x) : super.new(x);
  const NewSub.superNoNew(int x) : super(x);
}

// Same without `.new` on the constructor declaration.
// Can still be referred to as `.new`.
class NoNew<T> {
  final int x;
  const NoNew([this.x = 0]);
  const NoNew.thisNew(int x) : this.new(x);
  const NoNew.thisNoNew(int x) : this(x);
  const factory NoNew.factoryNew(int x) = NoNew<T>.new;
  const factory NoNew.factoryNoNew(int x) = NoNew<T>;
}

class NoNewSub<T> extends NoNew<T> {
  const NoNewSub.new(); // Implicit `: super()`
  const NoNewSub.implicit(); // Implicit `: super()`
  const NoNewSub.superNew(int x) : super.new(x);
  const NoNewSub.superNoNew(int x) : super(x);
}

// Avoid "unused value" warnings from the analyzer.
void use(Object _) {}

void main() {
  use(const Object.new());
  use(new Object.new());
  use(Object.new());
  use(const Symbol.new("a"));
  use(new Symbol.new("a"));
  use(Symbol.new("a"));

  use(const New(1));
  use(const New.new(1));
  use(new New(1));
  use(new New.new(1));
  use(New(1));
  use(New.new(1));

  use(const New.thisNew(1));
  use(const New.thisNoNew(1));
  use(new New.thisNew(1));
  use(new New.thisNoNew(1));
  use(New.thisNew(1));
  use(New.thisNoNew(1));

  use(const New.factoryNew(1));
  use(const New.factoryNoNew(1));
  use(new New.factoryNew(1));
  use(new New.factoryNoNew(1));
  use(New.factoryNew(1));
  use(New.factoryNoNew(1));

  use(const NewSub.new());
  use(const NewSub.implicit());
  use(const NewSub.superNew(1));
  use(const NewSub.superNoNew(1));

  use(const New<int>(1));
  use(const New<int>.new(1));
  use(new New<int>(1));
  use(new New<int>.new(1));
  use(New<int>(1));
  use(New<int>.new(1));

  use(const New<int>.thisNew(1));
  use(const New<int>.thisNoNew(1));
  use(new New<int>.thisNew(1));
  use(new New<int>.thisNoNew(1));
  use(New<int>.thisNew(1));
  use(New<int>.thisNoNew(1));

  use(const New<int>.factoryNew(1));
  use(const New<int>.factoryNoNew(1));
  use(new New<int>.factoryNew(1));
  use(new New<int>.factoryNoNew(1));
  use(New<int>.factoryNew(1));
  use(New<int>.factoryNoNew(1));

  use(const NewSub<int>.new());
  use(const NewSub<int>.implicit());
  use(const NewSub<int>.superNew(1));
  use(const NewSub<int>.superNoNew(1));

  use(New.new);
  use(New<int>.new);

  use(const prefix.New(1));
  use(const prefix.New.new(1));
  use(new prefix.New(1));
  use(new prefix.New.new(1));
  use(prefix.New(1));
  use(prefix.New.new(1));

  use(const prefix.New.thisNew(1));
  use(const prefix.New.thisNoNew(1));
  use(new prefix.New.thisNew(1));
  use(new prefix.New.thisNoNew(1));
  use(prefix.New.thisNew(1));
  use(prefix.New.thisNoNew(1));

  use(const prefix.New.factoryNew(1));
  use(const prefix.New.factoryNoNew(1));
  use(new prefix.New.factoryNew(1));
  use(new prefix.New.factoryNoNew(1));
  use(prefix.New.factoryNew(1));
  use(prefix.New.factoryNoNew(1));

  use(const prefix.NewSub.new());
  use(const prefix.NewSub.implicit());
  use(const prefix.NewSub.superNew(1));
  use(const prefix.NewSub.superNoNew(1));

  use(const prefix.New<int>(1));
  use(const prefix.New<int>.new(1));
  use(new prefix.New<int>(1));
  use(new prefix.New<int>.new(1));
  use(prefix.New<int>(1));
  use(prefix.New<int>.new(1));

  use(const prefix.New<int>.thisNew(1));
  use(const prefix.New<int>.thisNoNew(1));
  use(new prefix.New<int>.thisNew(1));
  use(new prefix.New<int>.thisNoNew(1));
  use(prefix.New<int>.thisNew(1));
  use(prefix.New<int>.thisNoNew(1));

  use(const prefix.New<int>.factoryNew(1));
  use(const prefix.New<int>.factoryNoNew(1));
  use(new prefix.New<int>.factoryNew(1));
  use(new prefix.New<int>.factoryNoNew(1));
  use(prefix.New<int>.factoryNew(1));
  use(prefix.New<int>.factoryNoNew(1));

  use(const prefix.NewSub<int>.new());
  use(const prefix.NewSub<int>.implicit());
  use(const prefix.NewSub<int>.superNew(1));
  use(const prefix.NewSub<int>.superNoNew(1));

  use(prefix.New.new);
  use(prefix.New<int>.new);

  // Ditto for NoNew
  use(const NoNew(1));
  use(const NoNew.new(1));
  use(new NoNew(1));
  use(new NoNew.new(1));
  use(NoNew(1));
  use(NoNew.new(1));

  use(const NoNew.thisNew(1));
  use(const NoNew.thisNoNew(1));
  use(new NoNew.thisNew(1));
  use(new NoNew.thisNoNew(1));
  use(NoNew.thisNew(1));
  use(NoNew.thisNoNew(1));

  use(const NoNew.factoryNew(1));
  use(const NoNew.factoryNoNew(1));
  use(new NoNew.factoryNew(1));
  use(new NoNew.factoryNoNew(1));
  use(NoNew.factoryNew(1));
  use(NoNew.factoryNoNew(1));

  use(const NoNewSub.new());
  use(const NoNewSub.implicit());
  use(const NoNewSub.superNew(1));
  use(const NoNewSub.superNoNew(1));

  use(const NoNew<int>(1));
  use(const NoNew<int>.new(1));
  use(new NoNew<int>(1));
  use(new NoNew<int>.new(1));
  use(NoNew<int>(1));
  use(NoNew<int>.new(1));

  use(const NoNew<int>.thisNew(1));
  use(const NoNew<int>.thisNoNew(1));
  use(new NoNew<int>.thisNew(1));
  use(new NoNew<int>.thisNoNew(1));
  use(NoNew<int>.thisNew(1));
  use(NoNew<int>.thisNoNew(1));

  use(const NoNew<int>.factoryNew(1));
  use(const NoNew<int>.factoryNoNew(1));
  use(new NoNew<int>.factoryNew(1));
  use(new NoNew<int>.factoryNoNew(1));
  use(NoNew<int>.factoryNew(1));
  use(NoNew<int>.factoryNoNew(1));

  use(const NoNewSub<int>.new());
  use(const NoNewSub<int>.implicit());
  use(const NoNewSub<int>.superNew(1));
  use(const NoNewSub<int>.superNoNew(1));

  use(NoNew.new);
  use(NoNew<int>.new);

  use(const prefix.NoNew(1));
  use(const prefix.NoNew.new(1));
  use(new prefix.NoNew(1));
  use(new prefix.NoNew.new(1));
  use(prefix.NoNew(1));
  use(prefix.NoNew.new(1));

  use(const prefix.NoNew.thisNew(1));
  use(const prefix.NoNew.thisNoNew(1));
  use(new prefix.NoNew.thisNew(1));
  use(new prefix.NoNew.thisNoNew(1));
  use(prefix.NoNew.thisNew(1));
  use(prefix.NoNew.thisNoNew(1));

  use(const prefix.NoNew.factoryNew(1));
  use(const prefix.NoNew.factoryNoNew(1));
  use(new prefix.NoNew.factoryNew(1));
  use(new prefix.NoNew.factoryNoNew(1));
  use(prefix.NoNew.factoryNew(1));
  use(prefix.NoNew.factoryNoNew(1));

  use(const prefix.NoNewSub.new());
  use(const prefix.NoNewSub.implicit());
  use(const prefix.NoNewSub.superNew(1));
  use(const prefix.NoNewSub.superNoNew(1));

  use(const prefix.NoNew<int>(1));
  use(const prefix.NoNew<int>.new(1));
  use(new prefix.NoNew<int>(1));
  use(new prefix.NoNew<int>.new(1));
  use(prefix.NoNew<int>(1));
  use(prefix.NoNew<int>.new(1));

  use(const prefix.NoNew<int>.thisNew(1));
  use(const prefix.NoNew<int>.thisNoNew(1));
  use(new prefix.NoNew<int>.thisNew(1));
  use(new prefix.NoNew<int>.thisNoNew(1));
  use(prefix.NoNew<int>.thisNew(1));
  use(prefix.NoNew<int>.thisNoNew(1));

  use(const prefix.NoNew<int>.factoryNew(1));
  use(const prefix.NoNew<int>.factoryNoNew(1));
  use(new prefix.NoNew<int>.factoryNew(1));
  use(new prefix.NoNew<int>.factoryNoNew(1));
  use(prefix.NoNew<int>.factoryNew(1));
  use(prefix.NoNew<int>.factoryNoNew(1));

  use(const prefix.NoNewSub<int>.new());
  use(const prefix.NoNewSub<int>.implicit());
  use(const prefix.NoNewSub<int>.superNew(1));
  use(const prefix.NoNewSub<int>.superNoNew(1));

  use(prefix.NoNew.new);
  use(prefix.NoNew<int>.new);
}
