// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ajohnsen): This test needs to be updated.
//                 Can Dart2JS on V8 somehow run it?

// Tests for Future.immediate
library future2_test;

import 'dart:async';
import 'dart:isolate';

testImmediate() {
  final future = new Future<String>.immediate("42");
  future.then((x) => Expect.equals("42", x));
}

// Tests for getters (value, exception, isComplete, isValue)

testNeverComplete() {
  final completer = new Completer<int>();
  final future = completer.future;
  future.then((v) => Except.fails("Value not expected"));
  future.catchError((e) => Except.fails("Value not expected"));
}

testComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  completer.complete(3);

  future.then((v) => Expect.equals(3, v));
}

// Tests for [then]

testCompleteWithSuccessHandlerBeforeComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  int before;
  future.then((int v) { before = v; });
  Expect.isNull(before);
  completer.complete(3);

  Expect.equals(3, before);
}

testCompleteWithSuccessHandlerAfterComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  int after;
  completer.complete(3);
  Expect.isNull(after);

  future.then((int v) { after = v; });

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

  Expect.equals(3, before);
  Expect.equals(3, after1);
  Expect.equals(3, after2);
}

// Tests for [handleException]

testException() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();
//  future.catchError((e) => print("got error"));//Expect.equals(e, ex));
  future.then((v) {print(v);})
        .catchError((e) => Expect.equals(e.error, ex));
  completer.completeError(ex);
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
  future.catchError((e) { ex2 = e.error; });
  completer.completeError(ex);
  Expect.equals(ex, ex2);
}

testExceptionHandlerReturnsTrue() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;
  future.catchError((e) { });
  future.catchError((e) { reached = true; }, test: (e) => false)
        .catchError((e) {});
  completer.completeError(ex);
  Expect.isFalse(reached);
}

testExceptionHandlerReturnsTrue2() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;
  future.catchError((e) { }, test: (e) => false)
        .catchError((e) { reached = true; });
  completer.completeError(ex);
  Expect.isTrue(reached);
}

testExceptionHandlerReturnsFalse() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;

  future.catchError((e) { });

  future.catchError((e) { reached = true; }, test: (e) => false)
        .catchError((e) { });

  completer.completeError(ex);

  Expect.isFalse(reached);
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
  final transformed = completer.future.then((_) {
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

testCallStackIsPreservedIfExceptionIsRethrownInTransformException() {
  final completer = new Completer();
  var chained = completer.future.chain((_) {
    throw 'whoops!';
  });
  var transformed = chained.transformException((e) {
    throw e;
  });

  completer.complete('blah');
  Expect.equals(transformed.stackTrace, chained.stackTrace);
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
  Expect.throws(() => completer.completeException(ex), (e) => e.source == ex);
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
  final transformedFuture = completer.future.then((x) => "** $x **");
  Expect.isFalse(transformedFuture.isComplete);
  completer.complete("42");
  Expect.equals("** 42 **", transformedFuture.value);
}

testTransformFutureFails() {
  final completer = new Completer<String>();
  final error = new Exception("Oh no!");
  final transformedFuture = completer.future.then((x) {
    Expect.fail("transformer shouldn't be called");
  });
  Expect.isFalse(transformedFuture.isComplete);
  completer.completeException(error);
  Expect.equals(error, transformedFuture.exception);
}

testTransformTransformerFails() {
  final completer = new Completer<String>();
  final error = new Exception("Oh no!");
  final transformedFuture = completer.future.then((x) { throw error; });
  Expect.isFalse(transformedFuture.isComplete);
  transformedFuture.then((v) => null);
  Expect.throws(() => completer.complete("42"), (e) => e.source == error);
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
  Expect.throws(() => completerA.complete("42"), (e) => e.source == error);
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

// Tests for Future.transformException

testTransformExceptionCompletesNormally() {
  final completer = new Completer<String>();
  var called = false;

  final transformedFuture = completer.future.transformException((ex) {
    Expect.fail("should not get here");
  });

  completer.complete("value");
  Expect.isTrue(transformedFuture.isComplete);
  Expect.equals("value", transformedFuture.value);
}

testTransformExceptionThrows() {
  final completer = new Completer<String>();
  var called = false;

  final transformedFuture = completer.future.transformException((ex) {
    Expect.equals("original error", ex);
    called = true;
    throw "transformed error";
  });

  completer.completeException("original error");
  Expect.isTrue(called);
  Expect.isTrue(transformedFuture.isComplete);
  Expect.equals("transformed error", transformedFuture.exception);
}

testTransformExceptionReturns() {
  final completer = new Completer<String>();
  var called = false;

  final transformedFuture = completer.future.transformException((ex) {
    Expect.equals("original error", ex);
    called = true;
    return "transformed value";
  });

  completer.completeException("original error");
  Expect.isTrue(called);
  Expect.isTrue(transformedFuture.isComplete);
  Expect.equals("transformed value", transformedFuture.value);
}

testTransformExceptionReturnsAFuture() {
  final completer = new Completer<String>();
  var called = false;

  final returnedCompleter = new Completer<String>();

  final transformedFuture = completer.future.transformException((ex) {
    Expect.equals("original error", ex);
    called = true;
    return returnedCompleter.future;
  });

  completer.completeException("original error");
  Expect.isTrue(called);
  Expect.isFalse(transformedFuture.isComplete);

  returnedCompleter.complete("transformed value");
  Expect.isTrue(transformedFuture.isComplete);
  Expect.equals("transformed value", transformedFuture.value);
}

// Tests for branching exceptions

testExceptionTravelsAlongBothBranches() {
  var results = <int>[];

  var completer = new Completer();
  var branch1 = completer.future.then((_) => null);
  var branch2 = completer.future.then((_) => null);

  branch1.handleException((e) {
    results.add(1);
    return true;
  });

  branch2.handleException((e) {
    results.add(2);
    return true;
  });

  completer.completeException("error");
  Expect.setEquals([1, 2], results);
}

testExceptionTravelsAlongBothBranchesAfterComplete() {
  var results = <int>[];

  var completer = new Completer();
  completer.completeException("error");

  var branch1 = completer.future.then((_) => null);
  var branch2 = completer.future.then((_) => null);

  branch1.handleException((e) {
    results.add(1);
    return true;
  });

  branch2.handleException((e) {
    results.add(2);
    return true;
  });

  Expect.setEquals([1, 2], results);
}

testExceptionIsHandledInBaseAndBranch() {
  var results = <String>[];

  var completer = new Completer();
  var branch = completer.future.then((_) => null);

  completer.future.handleException((e) {
    results.add("base");
    return true;
  });

  branch.handleException((e) {
    results.add("branch");
    return true;
  });

  completer.completeException("error");
  Expect.setEquals(["base", "branch"], results);
}

testExceptionIsHandledInBaseAndBranchAfterComplete() {
  var results = <String>[];

  var completer = new Completer();
  completer.completeException("error");

  var branch = completer.future.then((_) => null);

  completer.future.handleException((e) {
    results.add("base");
    return true;
  });

  branch.handleException((e) {
    results.add("branch");
    return true;
  });

  Expect.setEquals(["base", "branch"], results);
}

main() {
//  /*
  testImmediate();
  testNeverComplete();
  testComplete();
  testCompleteWithSuccessHandlerBeforeComplete();
  testCompleteWithSuccessHandlerAfterComplete();
  testCompleteManySuccessHandlers();
  testException();
  testExceptionHandler();
  testExceptionHandlerReturnsTrue();
  testExceptionHandlerReturnsTrue2();
  testExceptionHandlerReturnsFalse();
//  */
  /*
  */
  /*
  testExceptionHandlerReturnsFalse2();
  testExceptionHandlerAfterCompleteThenNotCalled();
  testExceptionHandlerAfterCompleteReturnsFalseThenThrows();
  testCallStackThrowsIfNotComplete();
  testCallStackIsNullIfCompletedSuccessfully();
  testCallStackReturnsCallstackPassedToCompleteException();
  testCallStackIsCapturedIfTransformCallbackThrows();
  testCallStackIsCapturedIfChainCallbackThrows();
  testCallStackIsPreservedIfExceptionIsRethrownInTransformException();
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
  testTransformExceptionCompletesNormally();
  testTransformExceptionThrows();
  testTransformExceptionReturns();
  testTransformExceptionReturnsAFuture();
  testExceptionTravelsAlongBothBranches();
  testExceptionTravelsAlongBothBranchesAfterComplete();
  testExceptionIsHandledInBaseAndBranch();
  testExceptionIsHandledInBaseAndBranchAfterComplete();
  */
}
