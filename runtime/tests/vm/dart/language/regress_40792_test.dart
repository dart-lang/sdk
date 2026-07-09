// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --deterministic

// Regression test for https://dartbug.com/40792 and https://dartbug.com/40795.
// Verifies that non-nullability is not inferred from 'is' tests which
// accept null.

import "package:expect/expect.dart";

dynamic result;

// Use separate functions so their parameter types can be inferred separately.
setResult1(x) {
  result = (x == null) ? 'null' : 'not null';
}

setResult2(x) {
  result = (x == null) ? 'null' : 'not null';
}

setResult3(x) {
  result = (x == null) ? 'null' : 'not null';
}

setResult4(x) {
  result = (x == null) ? 'null' : 'not null';
}

setResult5(x) {
  result = (x == null) ? 'null' : 'not null';
}

setResult6(x) {
  result = (x == null) ? 'null' : 'not null';
}

setResult7(x) {
  result = (x == null) ? 'null' : 'not null';
}

class A<S, T extends S> {
  @pragma('vm:never-inline')
  test1(S x) {
    if (x is T) {
      setResult1(x);
    }
  }

  @pragma('vm:never-inline')
  test2(S x) {
    if (x is T) {
      setResult2(x);
    }
  }

  @pragma('vm:never-inline')
  test3(S x) {
    if (x is T) {
      setResult2(x);
    }
  }

  @pragma('vm:never-inline')
  test4(S x) {
    if (x is T) {
      setResult2(x);
    }
  }
}

@pragma('vm:never-inline')
test5(x) {
  if (x is Null) {
    setResult5(x);
  }
}

@pragma('vm:never-inline')
test6(x) {
  if (x is Object?) {
    setResult6(x);
  }
}

@pragma('vm:never-inline')
test7(x) {
  if (x is dynamic) {
    setResult7(x);
  }
}

void doTests() {
  result = 'unexpected';
  new A<Null, Null>().test1(null);
  Expect.equals('null', result);

  result = 'unexpected';
  new A<Object?, Object?>().test2(null);
  Expect.equals('null', result);

  result = 'unexpected';
  new A<dynamic, dynamic>().test3(null);
  Expect.equals('null', result);

  result = 'unexpected';
  new A<void, void>().test4(null);
  Expect.equals('null', result);

  result = 'unexpected';
  test5(null);
  Expect.equals('null', result);

  result = 'unexpected';
  test6(null);
  Expect.equals('null', result);

  result = 'unexpected';
  test7(null);
  Expect.equals('null', result);
}

main(List<String> args) {
  for (int i = 0; i < 20; ++i) {
    doTests();
  }
}
