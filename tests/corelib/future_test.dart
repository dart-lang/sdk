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

// Tests for [onComplete]

testCompleteWithCompleteHandlerBeforeComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  int before;
  future.onComplete((f) {
    Expect.equals(future, f);
    Expect.isTrue(f.isComplete);
    Expect.isTrue(f.hasValue);
    before = f.value;
  });
  Expect.throws(() => future.value);
  Expect.isNull(before);
  completer.complete(3);

  Expect.equals(3, future.value);
  Expect.equals(3, before);
}

testExceptionWithCompleteHandlerBeforeComplete() {
  final completer = new Completer<int>();
  final future = completer.future;
  final exception = new Exception();

  var err;
  future.onComplete((f) {
    Expect.equals(future, f);
    Expect.isTrue(f.isComplete);
    Expect.isFalse(f.hasValue);
    err = f.exception;
  });
  Expect.throws(() => future.exception);
  Expect.isNull(err);
  completer.completeException(exception);
  Expect.equals(exception, future.exception);
  Expect.equals(exception, err);
  Expect.throws(() => future.value, check: (e) => e == exception);
}

testCompleteWithCompleteHandlerAfterComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  int after;
  completer.complete(3);
  future.onComplete((f) {
    Expect.equals(future, f);
    Expect.isTrue(f.isComplete);
    Expect.isTrue(f.hasValue);
    after = f.value;
  });
  Expect.equals(3, future.value);
  Expect.equals(3, after);
}

testExceptionWithCompleteHandlerAfterComplete() {
  final completer = new Completer<int>();
  final future = completer.future;
  final exception = new Exception();

  var err;
  completer.completeException(exception);
  future.onComplete((f) {
    Expect.equals(future, f);
    Expect.isTrue(f.isComplete);
    Expect.isFalse(f.hasValue);
    err = f.exception;
  });
  Expect.equals(exception, future.exception);
  Expect.equals(exception, err);
  Expect.throws(() => future.value, check: (e) => e == exception);
}

testCompleteWithManyCompleteHandlers() {
  final completer = new Completer<int>();
  final future = completer.future;
  int before;
  int after1;
  int after2;

  future.onComplete((f) { before = f.value; });
  completer.complete(3);
  future.onComplete((f) { after1 = f.value; });
  future.onComplete((f) { after2 = f.value; });

  Expect.equals(3, future.value);
  Expect.equals(3, before);
  Expect.equals(3, after1);
  Expect.equals(3, after2);
}

testExceptionWithManyCompleteHandlers() {
  final completer = new Completer<int>();
  final future = completer.future;
  final exception = new Exception();
  var before;
  var after1;
  var after2;

  future.onComplete((f) { before = f.exception; });
  completer.completeException(exception);
  future.onComplete((f) { after1 = f.exception; });
  future.onComplete((f) { after2 = f.exception; });

  Expect.equals(exception, future.exception);
  Expect.equals(exception, before);
  Expect.equals(exception, after1);
  Expect.equals(exception, after2);
  Expect.throws(() => future.value, check: (e) => e == exception);
}

// Tests for [then]

testCompleteWithSuccessHandlerBeforeComplete() {
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

testCompleteWithSuccessHandlerAfterComplete() {
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

testCompleteManySuccessHandlers() {
  final completer = new Completer<int>();
  final future = completer.future;
  int before;
  int after1;
  int after2;

  future.then((int v) { before = v; });
  completer.complete(3);
  future.then((int v) { after1 = v; });
  future.then((int v) { after2 = v; });

  Expect.equals(3, future.value);
  Expect.equals(3, before);
  Expect.equals(3, after1);
  Expect.equals(3, after2);
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

testExceptionNoSuccessListeners() {
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

// Tests for accessing the exception call stack.

testCallStackThrowsIfNotComplete() {
  var exception;
  try {
    new Completer().future.stackTrace;
  } catch (ex) {
    exception = ex;
  }

  Expect.isTrue(exception is FutureNotCompleteException);
}

testCallStackIsNullIfCompletedSuccessfully() {
  Expect.isNull(new Future.immediate('blah').stackTrace);
}

testCallStackReturnsCallstackPassedToCompleteException() {
  final completer = new Completer();
  final future = completer.future;

  final stackTrace = 'fake stack trace';
  completer.completeException(new Exception(), stackTrace);
  Expect.equals(stackTrace, future.stackTrace);
}

testCallStackIsCapturedIfTransformCallbackThrows() {
  final completer = new Completer();
  final transformed = completer.future.transform((_) {
    throw 'whoops!';
  });

  final stackTrace = 'fake stack trace';
  completer.complete('blah');
  Expect.isNotNull(transformed.stackTrace);
}

testCallStackIsCapturedIfChainCallbackThrows() {
  final completer = new Completer();
  final chained = completer.future.chain((_) {
    throw 'whoops!';
  });

  final stackTrace = 'fake stack trace';
  completer.complete('blah');
  Expect.isNotNull(chained.stackTrace);
}

// Tests for mixed usage of [onComplete], [then], and [handleException]

testCompleteWithCompletionAndSuccessHandlers() {
  final completer = new Completer<int>();
  final future = completer.future;

  var valueFromSuccessHandler;
  var valueFromCompletionHandler;
  future.onComplete((f) {
    Expect.isNotNull(valueFromSuccessHandler);
    valueFromCompletionHandler = f.value;
  });
  future.then((v) {
    Expect.isNull(valueFromCompletionHandler);
    valueFromSuccessHandler = v;
  });
  completer.complete(42);
  Expect.equals(42, valueFromSuccessHandler);
  Expect.equals(42, valueFromCompletionHandler);
  Expect.equals(42, future.value);
}

testExceptionWithCompletionAndSuccessHandlers() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  var exceptionFromCompleteHandler;
  future.onComplete((f) {
    Expect.equals(future, f);
    Expect.isFalse(f.hasValue);
    exceptionFromCompleteHandler = f.exception;
  });
  future.then((v) => Expect.fail("Should not succeed"));
  Expect.throws(() => completer.completeException(ex), check: (e) => ex == e);
  Expect.equals(ex, exceptionFromCompleteHandler);
}

testExceptionWithCompletionAndSuccessAndExceptionHandlers() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  var exceptionFromCompleteHandler;
  var exceptionFromExceptionHandler;
  future.onComplete((f) {
    Expect.equals(future, f);
    Expect.isFalse(f.hasValue);
    exceptionFromCompleteHandler = f.exception;
  });
  future.handleException((e) {
    exceptionFromExceptionHandler = e;
    return true;
  });
  future.then((v) => Expect.fail("Should not succeed"));
  completer.completeException(ex);
  Expect.equals(ex, exceptionFromCompleteHandler);
  Expect.equals(ex, exceptionFromExceptionHandler);
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
  transformedFuture.then((v) => null);
  Expect.throws(() => completer.complete("42"), check: (e) => e == error);
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
  chainedFuture.then((v) => null);
  Expect.isFalse(chainedFuture.isComplete);
  Expect.throws(() => completerA.complete("42"), check: (e) => e == error);
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
  testCompleteWithCompleteHandlerBeforeComplete();
  testExceptionWithCompleteHandlerBeforeComplete();
  testCompleteWithCompleteHandlerAfterComplete();
  testExceptionWithCompleteHandlerAfterComplete();
  testCompleteWithManyCompleteHandlers();
  testExceptionWithManyCompleteHandlers();
  testCompleteWithSuccessHandlerBeforeComplete();
  testCompleteWithSuccessHandlerAfterComplete();
  testCompleteManySuccessHandlers();
  testException();
  testExceptionHandler();
  testExceptionHandlerReturnsTrue();
  testExceptionHandlerReturnsTrue2();
  testExceptionHandlerReturnsFalse();
  testExceptionHandlerReturnsFalse2();
  testExceptionHandlerAfterCompleteThenNotCalled();
  testExceptionHandlerAfterCompleteReturnsFalseThenThrows();
  testCallStackThrowsIfNotComplete();
  testCallStackIsNullIfCompletedSuccessfully();
  testCallStackReturnsCallstackPassedToCompleteException();
  testCallStackIsCapturedIfTransformCallbackThrows();
  testCallStackIsCapturedIfChainCallbackThrows();
  testCompleteWithCompletionAndSuccessHandlers();
  testExceptionWithCompletionAndSuccessHandlers();
  testExceptionWithCompletionAndSuccessAndExceptionHandlers();
  testTransformSuccess();
  testTransformFutureFails();
  testTransformTransformerFails();
  testChainSuccess();
  testChainFirstFutureFails();
  testChainTransformerFails();
  testChainSecondFutureFails();
}
