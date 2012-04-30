// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for Future.immediate

testImmediate() {
  final future = new Future<String>.immediate("42");
  Expect.isTrue(future.isComplete);
  Expect.isTrue(future.hasValue);
  var value = null;
  future.then((x) => value = x);
  Expect.equals("42", value);
}

// Tests for getters (value, exception, isComplete, isValue)

testNeverComplete() {
  final completer = new Completer<int>();
  final future = completer.future;
  Expect.isFalse(future.isComplete);
  Expect.isFalse(future.hasValue);
  Expect.throws(() { future.value; });
  Expect.throws(() { future.exception; });
}

testComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  completer.complete(3);

  Expect.isTrue(future.isComplete);
  Expect.isTrue(future.hasValue);
  Expect.equals(3, future.value);
  Expect.isNull(future.exception);
}

// Tests for [then]

testCompleteWithHandlerBeforeComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  int before;
  future.then((int v) { before = v; });
  Expect.throws(() { future.value; });
  Expect.isNull(before);
  completer.complete(3);

  Expect.equals(3, future.value);
  Expect.equals(3, before);
}

testCompleteWithHandlerAfterComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  int after;
  completer.complete(3);
  Expect.equals(3, future.value);
  Expect.isNull(after);

  future.then((int v) { after = v; });

  Expect.equals(3, future.value);
  Expect.equals(3, after);
}

testCompleteManyHandlers() {
  final completer = new Completer<int>();
  final future = completer.future;
  int after1;
  int after2;
  int after3;

  future.then((int v) { after1 = v; });
  completer.complete(3);
  future.then((int v) { after2 = v; });
  future.then((int v) { after3 = v; });

  Expect.equals(3, future.value);
  Expect.equals(3, after1);
  Expect.equals(3, after2);
  Expect.equals(3, after3);
}

// Tests for [handleException]

testException() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();
  future.then((_) {}); // exception is thrown if we plan to use the value
  Expect.throws(
      () { completer.completeException(ex); }, 
      check: (e) => e == ex);
}

testExceptionNoListeners() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();
  completer.completeException(ex); // future.then is not called, so no exception
}

testExceptionHandler() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  var ex2;
  future.handleException((e) { ex2 = e; return true; });
  completer.completeException(ex);
  Expect.equals(ex, ex2);
}

testExceptionHandlerReturnsTrue() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;
  future.handleException((e) { return true; });
  future.handleException((e) { reached = true; return false; }); // overshadowed
  completer.completeException(ex);
  Expect.isFalse(reached);
}

testExceptionHandlerReturnsTrue2() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;
  future.handleException((e) { return false; });
  future.handleException((e) { reached = true; return true; });
  completer.completeException(ex);
  Expect.isTrue(reached);
}

testExceptionHandlerReturnsFalse() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;
  future.then((_) {}); // ensure exception is thrown...
  future.handleException((e) { return false; });
  future.handleException((e) { reached = true; return false; }); // overshadowed
  Expect.throws(
      () { completer.completeException(ex); }, 
      check: (e) => e == ex);
  Expect.isTrue(reached);
}

testExceptionHandlerReturnsFalse2() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;
  future.handleException((e) { return false; });
  future.handleException((e) { reached = true; return false; }); // overshadowed
  completer.completeException(ex); // future.then is not called, so no exception
  Expect.isTrue(reached);
}

testExceptionHandlerAfterCompleteThenNotCalled() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  var ex2;
  completer.completeException(ex);
  future.handleException((e) { ex2 = e; return true; });
  future.then((e) { });
  Expect.equals(ex, ex2);
}

testExceptionHandlerAfterCompleteReturnsFalseThenThrows() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  var ex2;
  completer.completeException(ex);
  future.handleException((e) { ex2 = e; return false; });
  Expect.throws(() { future.then((e) { }); });
  Expect.equals(ex, ex2);
}

// Tests for Future.transform

testTransformSuccess() {
  final completer = new Completer<String>();
  final transformedFuture = completer.future.transform((x) => "** $x **");
  Expect.isFalse(transformedFuture.isComplete);
  completer.complete("42");
  Expect.equals("** 42 **", transformedFuture.value);
}

testTransformFutureFails() {
  final completer = new Completer<String>();
  final error = new Exception("Oh no!");
  final transformedFuture = completer.future.transform((x) {
    Expect.fail("transformer shouldn't be called");
  });
  Expect.isFalse(transformedFuture.isComplete);
  completer.completeException(error);
  Expect.equals(error, transformedFuture.exception);
}

testTransformTransformerFails() {
  final completer = new Completer<String>();
  final error = new Exception("Oh no!");
  final transformedFuture = completer.future.transform((x) { throw error; });
  Expect.isFalse(transformedFuture.isComplete);
  completer.complete("42");
  Expect.equals(error, transformedFuture.exception);
}

// Tests for Future.chain

testChainSuccess() {
  final completerA = new Completer<String>();
  final completerB = new Completer<String>();
  final chainedFuture = completerA.future.chain((x) {
    Expect.equals("42", x);
    return completerB.future;
  });
  Expect.isFalse(chainedFuture.isComplete);
  completerA.complete("42");
  Expect.isFalse(chainedFuture.isComplete);
  completerB.complete("43");
  Expect.equals("43", chainedFuture.value);
}

testChainFirstFutureFails() {
  final completerA = new Completer<String>();
  final error = new Exception("Oh no!");
  final chainedFuture = completerA.future.chain((x) {
    Expect.fail("transformer shouldn't be called");
  });
  Expect.isFalse(chainedFuture.isComplete);
  completerA.completeException(error);
  Expect.equals(error, chainedFuture.exception);
}

testChainTransformerFails() {
  final completerA = new Completer<String>();
  final error = new Exception("Oh no!");
  final chainedFuture = completerA.future.chain((x) {
    Expect.equals("42", x);
    throw error;
  });
  Expect.isFalse(chainedFuture.isComplete);
  completerA.complete("42");
  Expect.equals(error, chainedFuture.exception);
}

testChainSecondFutureFails() {
  final completerA = new Completer<String>();
  final completerB = new Completer<String>();
  final error = new Exception("Oh no!");
  final chainedFuture = completerA.future.chain((x) {
    Expect.equals("42", x);
    return completerB.future;
  });
  Expect.isFalse(chainedFuture.isComplete);
  completerA.complete("42");
  Expect.isFalse(chainedFuture.isComplete);
  completerB.completeException(error);
  Expect.equals(error, chainedFuture.exception);
}

main() {
  testImmediate();
  testNeverComplete();
  testComplete();
  testCompleteWithHandlerBeforeComplete();
  testCompleteWithHandlerAfterComplete();
  testCompleteManyHandlers();
  testException();
  testExceptionHandler();
  testExceptionHandlerReturnsTrue();
  testExceptionHandlerReturnsTrue2();
  testExceptionHandlerReturnsFalse();
  testExceptionHandlerReturnsFalse2();
  testExceptionHandlerAfterCompleteThenNotCalled();
  testExceptionHandlerAfterCompleteReturnsFalseThenThrows();
  testTransformSuccess();
  testTransformFutureFails();
  testTransformTransformerFails();
  testChainSuccess();
  testChainFirstFutureFails();
  testChainTransformerFails();
  testChainSecondFutureFails();
}
