// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int foo = 42;

class Bar {
  const Bar();
  const Bar.named(x);
}

class Baz {
  Baz(@foo constructorFormal);

  factory Baz.bazFactory(@foo factoryFormal) => null;

  fisk(@foo formal1, @Bar() formal2, @Bar.named(foo) formal3,
      @foo @Bar.named(foo) formal4,
      [@foo optional]) {
    @foo
    var local1;

    @Bar()
    var local2;

    @Bar.named(foo)
    var local3;

    @foo
    @Bar.named(foo)
    var local4;

    @foo
    var localWithInitializer = "hello";

    @foo
    @Bar.named(foo)
    var localGroupPart1, localGroupPart2;

    naebdyr(@foo nestedFormal) => null;

    var roedmus = (@foo closureFormal) => null;
  }

  hest({@foo named}) => null;
}

typedef hest_t({@foo named});

main() {}
