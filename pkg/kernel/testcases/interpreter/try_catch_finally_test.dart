// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  try {
    print('hello1');
  } catch (e, _) {} finally {
    print('hello2');
  }
  print('hello3');
  print(fReturns());
  print(fFinalizes());
  print(fThrows());
}

/// Tests that the return in finally is executed.
int fReturns() {
  try {
    print('foo 1');
    return 1;
  } catch (e, _) {} finally {
    print('foo 2');
    return 2;
  }
}

/// Tests that finally is executed before returning.
int fFinalizes() {
  try {
    print('bar 1');
    return 1;
  } catch (e, _) {} finally {
    print('bar 2');
  }
  return 0;
}

/// Tests that the exception is caught.
int fThrows() {
  try {
    print(37);
    throw 'Error';
  } catch (e, _) {
    print('Caught $e');
  } finally {
    print("Finalizer");
  }
  return 34;
}
