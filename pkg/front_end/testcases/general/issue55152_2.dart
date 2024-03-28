// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A();
  const factory A.redir() = B;
  const factory A.redir2() = B;
  const A.named();
  const A.named2();
  const factory A.selfRedir() = A.named;
  const factory A.selfRedir2() = A.named2;
}

class B extends A {
  const B();
}

typedef TA = A;

test(@TA.redir() int x, @TA.named() int x2, @A.redir() int x3,
    @A.selfRedir() int x4) {
  @TA.redir2()
  int localVariable = 0;

  @TA.redir2()
  void localFunction() {}

  @TA.named2()
  int localVariable2 = 0;

  @TA.named2()
  void localFunction2() {}

  @A.redir2()
  int localVariable3 = 0;

  @A.redir2()
  void localFunction3() {}

  @A.selfRedir2()
  int localVariable4 = 0;

  @A.selfRedir2()
  void localFunction4() {}
}

class Test {
  test(@TA.redir() int x, @TA.named() int x2, @A.redir() int x3,
      @A.selfRedir() int x4) {
    @TA.redir2()
    int localVariable = 0;

    @TA.redir2()
    void localFunction() {}

    @TA.named2()
    int localVariable2 = 0;

    @TA.named2()
    void localFunction2() {}

    @A.redir2()
    int localVariable3 = 0;

    @A.redir2()
    void localFunction3() {}

    @A.selfRedir2()
    int localVariable4 = 0;

    @A.selfRedir2()
    void localFunction4() {}
  }
}
