// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

Function? foo = null;

// Checks that contexts for the constructor allocator and constructor body are
// setup correctly when using the [dart2wasm] compiler, or this test will
// throw an error at compile time. In [dart2wasm], there are four cases:
//
// 1. No context is needed for the constructor (i.e. there are no captured
//    type parameters or normal parameters, and `this` is not captured).
// 2. Only the constructor body context is needed (i.e. `this` is captured
//    by the constructor body, or normal parameters are captured by in the
//    constructor body but nothing else is captured).
// 3. Only the constructor allocator context is needed (i.e. type
//    parameters and/or normal parameters) are captured, but `this` is not
//    captured.
// 4. Both the constructor allocator and constructor body contexts are
//    needed (i.e. type parameters and/or normal parameters are captured,
//    and `this` is captured by the constructor body).
//
// `this` cannot be captured by a constructor's initializer list, as the object
// has not been allocated yet.

var expectedValueOfA = 0;

abstract class Test {
  List<Function> assertions = [];
  Test();

  void runAssertions() {
    for (Function assertion in assertions) {
      assertion();
    }
  }
}

// No contexts should be created, as nothing is captured.
class NoContextsNothingCaptured<T> extends Test {
  Function f1;
  Function f2;

  NoContextsNothingCaptured(T a)
      : f1 = (() => {}),
        f2 = (() => {}) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() => {});
    assertions.add(() => {});
  }
}

// Combinations which should create just a constructor allocator context.

class AllocatorContextOnlyTypeParamCapturedInInitializer<T> extends Test {
  Function f1;
  Function f2;
  T a;

  AllocatorContextOnlyTypeParamCapturedInInitializer(this.a)
      : f1 = (() {
          Expect.identical(T, int);
        }),
        f2 = (() {
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() => {});
    assertions.add(() => {});
  }
}

class AllocatorContextOnlyNormalParamCapturedInInitializer<T> extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextOnlyNormalParamCapturedInInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() => {});
    assertions.add(() => {});
  }
}

class AllocatorContextTypeAndNormalParamCapturedInInitializer<T> extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextTypeAndNormalParamCapturedInInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() => {});
    assertions.add(() => {});
  }
}

class AllocatorContextOnlyTypeParamCapturedInBody<T> extends Test {
  Function f1;
  Function f2;
  T a;

  AllocatorContextOnlyTypeParamCapturedInBody(this.a)
      : f1 = (() => {}),
        f2 = (() => {}) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      Expect.identical(T, int);
    });
    assertions.add(() {
      Expect.identical(T, int);
    });
  }
}

class AllocatorContextTypeParamCapturedInInitializerAndTypeParamInBody<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextTypeParamCapturedInInitializerAndTypeParamInBody(int a)
      : this.a = a,
        f1 = (() {
          Expect.identical(T, int);
        }),
        f2 = (() {
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      Expect.identical(T, int);
    });
    assertions.add(() {
      Expect.identical(T, int);
    });
  }
}

class AllocatorContextNormalParamCapturedInInitializerAndTypeParamInBody<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextNormalParamCapturedInInitializerAndTypeParamInBody(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      Expect.identical(T, int);
    });
    assertions.add(() {
      Expect.identical(T, int);
    });
  }
}

class AllocatorContextTypeAndNormalParamCapturedInInitializerAndTypeParamInBody<
    T> extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextTypeAndNormalParamCapturedInInitializerAndTypeParamInBody(
      int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      Expect.identical(T, int);
    });
    assertions.add(() {
      Expect.identical(T, int);
    });
  }
}

// Combinations which should create just a constructor body context.

class BodyContextOnlyThisCaptured<T> extends Test {
  Function f1;
  Function f2;
  int a;

  BodyContextOnlyThisCaptured(this.a)
      : f1 = (() => {}),
        f2 = (() => {}) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, a);
    });
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, a);
    });
  }
}

class BodyContextOnlyNormalParamCapturedInBody<T> extends Test {
  Function f1;
  Function f2;
  int a;

  BodyContextOnlyNormalParamCapturedInBody(this.a)
      : f1 = (() => {}),
        f2 = (() => {}) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
  }
}

class BodyContextOnlyThisAndNormalParamCapturedInBody<T> extends Test {
  Function f1;
  Function f2;
  int a;

  BodyContextOnlyThisAndNormalParamCapturedInBody(this.a)
      : f1 = (() => {}),
        f2 = (() => {}) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, a);
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, a);
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
  }
}

class AllocatorContextNormalParamCapturedInBodyTypeParamInInitializer<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextNormalParamCapturedInBodyTypeParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          Expect.identical(T, int);
        }),
        f2 = (() {
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
  }
}

class AllocatorContextNormalParamCapturedInBodyAndInitializer<T> extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextNormalParamCapturedInBodyAndInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
  }
}

class AllocatorContextNormalParamCapturedInBodyAndNormalAndTypeParamInInitializer<
    T> extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextNormalParamCapturedInBodyAndNormalAndTypeParamInInitializer(
      int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
    });
  }
}

class AllocatorContextNormalParamAndTypeParamCapturedInBody<T> extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextNormalParamAndTypeParamCapturedInBody(int a)
      : this.a = a,
        f1 = (() => {}),
        f2 = (() => {}) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
  }
}

class AllocatorContextNormalParamAndTypeParamCapturedInBodyAndTypeParamInInitializer<
    T> extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextNormalParamAndTypeParamCapturedInBodyAndTypeParamInInitializer(
      int a)
      : this.a = a,
        f1 = (() {
          Expect.identical(T, int);
        }),
        f2 = (() {
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
  }
}

class AllocatorContextNormalParamAndTypeParamCapturedInBodyAndNormalParamInInitializer<
    T> extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextNormalParamAndTypeParamCapturedInBodyAndNormalParamInInitializer(
      int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
  }
}

class AllocatorContextNormalParamAndTypeParamCapturedInBodyAndInitializer<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  AllocatorContextNormalParamAndTypeParamCapturedInBodyAndInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      a++;
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
  }
}

// Combinations which create an allocator and body context.

class BothContextsThisAndTypeParamCapturedInBody<T> extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisAndTypeParamCapturedInBody(int a)
      : this.a = a,
        f1 = (() => {}),
        f2 = (() => {}) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.identical(T, int);
    });
  }
}

class BothContextsThisCapturedInBodyTypeParamInInitializer<T> extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisCapturedInBodyTypeParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          Expect.identical(T, int);
        }),
        f2 = (() {
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, this.a);
    });
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, this.a);
    });
  }
}

class BothContextsThisCapturedInBodyNormalParamInInitializer<T> extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisCapturedInBodyNormalParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      Expect.equals(expectedValueOfA - 1, this.a);
    });
    assertions.add(() {
      this.a++;
      Expect.equals(expectedValueOfA, this.a);
    });
  }
}

class BothContextsThisCapturedInBodyNormalAndTypeParamInInitializer<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisCapturedInBodyNormalAndTypeParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      Expect.equals(expectedValueOfA - 1, this.a);
    });
    assertions.add(() {
      this.a++;
      Expect.equals(expectedValueOfA, this.a);
    });
  }
}

class BothContextsThisAndNormalParamCapturedInBodyTypeParamInInitializer<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisAndNormalParamCapturedInBodyTypeParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          Expect.identical(T, int);
        }),
        f2 = (() {
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.equals(expectedValueOfA, a);
    });
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.equals(expectedValueOfA, a);
    });
  }
}

class BothContextsThisAndNormalParamCapturedInBodyNormalParamInInitializer<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisAndNormalParamCapturedInBodyNormalParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.equals(++expectedValueOfA, a);
    });
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.equals(++expectedValueOfA, a);
    });
  }
}

class BothContextsThisAndNormalParamCapturedInBodyTypeAndNormalParamInInitializer<
    T> extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisAndNormalParamCapturedInBodyTypeAndNormalParamInInitializer(
      int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.equals(++expectedValueOfA, a);
    });
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.equals(++expectedValueOfA, a);
    });
  }
}

class BothContextsThisAndTypeParamCapturedInBodyTypeParamInInitializer<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisAndTypeParamCapturedInBodyTypeParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          Expect.identical(T, int);
        }),
        f2 = (() {
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      this.a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.identical(T, int);
    });
  }
}

class BothContextsThisAndTypeParamCapturedInBodyNormalParamInInitializer<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisAndTypeParamCapturedInBodyNormalParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      this.a++;
      Expect.equals(expectedValueOfA, this.a);
      Expect.identical(T, int);
    });
  }
}

class BothContextsThisAndTypeParamCapturedInBodyTypeAndNormalParamInInitializer<
    T> extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsThisAndTypeParamCapturedInBodyTypeAndNormalParamInInitializer(
      int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      this.a++;
      Expect.equals(expectedValueOfA, this.a);
      Expect.identical(T, int);
    });
  }
}

class BothContextsEverythingCapturedInBody<T> extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsEverythingCapturedInBody(int a)
      : this.a = a,
        f1 = (() => {}),
        f2 = (() => {}) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.equals(expectedValueOfA, a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.equals(expectedValueOfA, a);
      Expect.identical(T, int);
    });
  }
}

class BothContextsEverythingCapturedInBodyAndTypeParamInInitializer<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsEverythingCapturedInBodyAndTypeParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          Expect.identical(T, int);
        }),
        f2 = (() {
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.equals(expectedValueOfA, a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(++expectedValueOfA, this.a);
      Expect.equals(expectedValueOfA, a);
      Expect.identical(T, int);
    });
  }
}

class BothContextsEverythingCapturedInBodyAndNormalParamInInitializer<T>
    extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsEverythingCapturedInBodyAndNormalParamInInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
  }
}

class BothContextsEverythingCapturedInBodyAndInitializer<T> extends Test {
  Function f1;
  Function f2;
  int a;

  BothContextsEverythingCapturedInBodyAndInitializer(int a)
      : this.a = a,
        f1 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }),
        f2 = (() {
          a++;
          Expect.equals(++expectedValueOfA, a);
          Expect.identical(T, int);
        }) {
    assertions.add(f1);
    assertions.add(f2);
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
    assertions.add(() {
      this.a++;
      a++;
      Expect.equals(expectedValueOfA - 1, this.a);
      Expect.equals(++expectedValueOfA, a);
      Expect.identical(T, int);
    });
  }
}

void main() {
  expectedValueOfA = 123;
  NoContextsNothingCaptured a =
      NoContextsNothingCaptured<int>(expectedValueOfA);
  a.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextOnlyTypeParamCapturedInInitializer b =
      AllocatorContextOnlyTypeParamCapturedInInitializer<int>(expectedValueOfA);
  b.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextOnlyNormalParamCapturedInInitializer c =
      AllocatorContextOnlyNormalParamCapturedInInitializer<int>(
          expectedValueOfA);
  c.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextTypeAndNormalParamCapturedInInitializer d =
      AllocatorContextTypeAndNormalParamCapturedInInitializer<int>(
          expectedValueOfA);
  d.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextOnlyTypeParamCapturedInBody e =
      AllocatorContextOnlyTypeParamCapturedInBody<int>(expectedValueOfA);
  e.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextTypeParamCapturedInInitializerAndTypeParamInBody f =
      AllocatorContextTypeParamCapturedInInitializerAndTypeParamInBody<int>(
          expectedValueOfA);
  f.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextNormalParamCapturedInInitializerAndTypeParamInBody g =
      AllocatorContextNormalParamCapturedInInitializerAndTypeParamInBody<int>(
          expectedValueOfA);
  g.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextTypeAndNormalParamCapturedInInitializerAndTypeParamInBody h =
      AllocatorContextTypeAndNormalParamCapturedInInitializerAndTypeParamInBody<
          int>(expectedValueOfA);
  h.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextNormalParamCapturedInBodyTypeParamInInitializer i =
      AllocatorContextNormalParamCapturedInBodyTypeParamInInitializer<int>(
          expectedValueOfA);
  i.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextNormalParamCapturedInBodyAndInitializer j =
      AllocatorContextNormalParamCapturedInBodyAndInitializer<int>(
          expectedValueOfA);
  j.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextNormalParamCapturedInBodyAndNormalAndTypeParamInInitializer
      k =
      AllocatorContextNormalParamCapturedInBodyAndNormalAndTypeParamInInitializer<
          int>(expectedValueOfA);
  k.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextNormalParamAndTypeParamCapturedInBody l =
      AllocatorContextNormalParamAndTypeParamCapturedInBody<int>(
          expectedValueOfA);
  l.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextNormalParamAndTypeParamCapturedInBodyAndTypeParamInInitializer
      m =
      AllocatorContextNormalParamAndTypeParamCapturedInBodyAndTypeParamInInitializer<
          int>(expectedValueOfA);
  m.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextNormalParamAndTypeParamCapturedInBodyAndNormalParamInInitializer
      n =
      AllocatorContextNormalParamAndTypeParamCapturedInBodyAndNormalParamInInitializer<
          int>(expectedValueOfA);
  n.runAssertions();

  expectedValueOfA = 123;
  AllocatorContextNormalParamAndTypeParamCapturedInBodyAndInitializer o =
      AllocatorContextNormalParamAndTypeParamCapturedInBodyAndInitializer<int>(
          expectedValueOfA);
  o.runAssertions();

  expectedValueOfA = 123;
  BodyContextOnlyNormalParamCapturedInBody p =
      BodyContextOnlyNormalParamCapturedInBody<int>(expectedValueOfA);
  p.runAssertions();

  expectedValueOfA = 123;
  BodyContextOnlyThisCaptured q =
      BodyContextOnlyThisCaptured<int>(expectedValueOfA);
  q.runAssertions();

  expectedValueOfA = 123;
  BodyContextOnlyThisAndNormalParamCapturedInBody r =
      BodyContextOnlyThisAndNormalParamCapturedInBody<int>(expectedValueOfA);
  r.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisCapturedInBodyTypeParamInInitializer s =
      BothContextsThisCapturedInBodyTypeParamInInitializer<int>(
          expectedValueOfA);
  s.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisCapturedInBodyNormalParamInInitializer t =
      BothContextsThisCapturedInBodyNormalParamInInitializer<int>(
          expectedValueOfA);
  t.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisCapturedInBodyNormalAndTypeParamInInitializer u =
      BothContextsThisCapturedInBodyNormalAndTypeParamInInitializer<int>(
          expectedValueOfA);
  u.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisAndTypeParamCapturedInBody v =
      BothContextsThisAndTypeParamCapturedInBody<int>(expectedValueOfA);
  v.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisAndTypeParamCapturedInBodyTypeParamInInitializer w =
      BothContextsThisAndTypeParamCapturedInBodyTypeParamInInitializer<int>(
          expectedValueOfA);
  w.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisAndTypeParamCapturedInBodyNormalParamInInitializer x =
      BothContextsThisAndTypeParamCapturedInBodyNormalParamInInitializer<int>(
          expectedValueOfA);
  x.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisAndTypeParamCapturedInBodyTypeAndNormalParamInInitializer y =
      BothContextsThisAndTypeParamCapturedInBodyTypeAndNormalParamInInitializer<
          int>(expectedValueOfA);
  y.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisAndNormalParamCapturedInBodyTypeParamInInitializer z =
      BothContextsThisAndNormalParamCapturedInBodyTypeParamInInitializer<int>(
          expectedValueOfA);
  z.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisAndNormalParamCapturedInBodyNormalParamInInitializer aa =
      BothContextsThisAndNormalParamCapturedInBodyNormalParamInInitializer<int>(
          expectedValueOfA);
  aa.runAssertions();

  expectedValueOfA = 123;
  BothContextsThisAndNormalParamCapturedInBodyTypeAndNormalParamInInitializer
      ab =
      BothContextsThisAndNormalParamCapturedInBodyTypeAndNormalParamInInitializer<
          int>(expectedValueOfA);
  ab.runAssertions();

  expectedValueOfA = 123;
  BothContextsEverythingCapturedInBody ac =
      BothContextsEverythingCapturedInBody<int>(expectedValueOfA);
  ac.runAssertions();

  expectedValueOfA = 123;
  BothContextsEverythingCapturedInBodyAndTypeParamInInitializer ad =
      BothContextsEverythingCapturedInBodyAndTypeParamInInitializer<int>(
          expectedValueOfA);
  ad.runAssertions();

  expectedValueOfA = 123;
  BothContextsEverythingCapturedInBodyAndNormalParamInInitializer ae =
      BothContextsEverythingCapturedInBodyAndNormalParamInInitializer<int>(
          expectedValueOfA);
  ae.runAssertions();

  expectedValueOfA = 123;
  BothContextsEverythingCapturedInBodyAndInitializer af =
      BothContextsEverythingCapturedInBodyAndInitializer<int>(expectedValueOfA);
  af.runAssertions();
}
