// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

testTryCatch1() {
  try {
    print('danger!');
  } catch (e) {
    print('caught $e');
  }
}

testTryCatch2() {
  try {
    print('danger!');
  } on TypeError {
    print('caught type error');
  } on AssertionError catch (e) {
    print('caught assertion error $e');
  } on Error catch (e, st) {
    print('caught error $e $st');
  } catch (e, st) {
    print('caught something $e $st');
  }
}

testTryCatch3() {
  int x = 1;
  try {
    int y = 2;
    void foo() {
      try {
        print('danger foo');
      } catch (e) {
        print(x);
        y = 3;
      }
    }

    foo();
    print(y);
  } catch (e, st) {
    print('caught $e $st');

    void bar() {
      try {
        print('danger bar');
      } on Error catch (e) {
        print('error $e, captured stack trace: $st');
      }
    }

    return bar;
  }
}

testRethrow(bool cond) {
  try {
    try {
      print('try 1 > try 2');
    } catch (e) {
      try {
        print('try 1 > catch 2 > try 3');
        if (cond) {
          rethrow;
        }
      } catch (e) {
        print('try 1 > catch 2 > catch 3');
      }
    }
  } catch (e, st) {
    print('catch 1');
    print(st);
  }
}

testTryFinally1() {
  for (int i = 0; i < 10; i++) {
    try {
      if (i > 5) {
        break;
      }
    } finally {
      print(i);
    }
  }
}

testTryFinally2(int x) {
  switch (x) {
    case 1:
      try {
        print('before try 1');
        int y = 3;
        try {
          print('try');
          void foo() {
            print(x);
            print(y);
          }

          foo();
          continue L;
        } finally {
          print('finally 1');
        }
        print('after try 1');
      } finally {
        print('finally 2');
      }
      break;
    L:
    case 2:
      print('case 2');
      break;
  }
}

testTryFinally3() {
  int x = 11;
  var y;
  try {
    y = () {
      print(x);
      try {
        print('try 1');
        return 42;
      } finally {
        try {
          print('try 2');
          return 43;
        } finally {
          print(x);
        }
      }
    };
  } finally {
    print(x);
    y();
  }
}

testTryCatchFinally() {
  try {
    print('try');
  } catch (e) {
    print('catch');
  } finally {
    print('finally');
  }
}

main() {}
