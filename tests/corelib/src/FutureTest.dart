// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

testImmediate() {
  final future = new Future<String>.immediate("42");
  Expect.isTrue(future.isComplete);
  var value = null;
  future.then((x) => value = x);
  Expect.equals("42", value);
}

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
  testTransformSuccess();
  testTransformFutureFails();
  testTransformTransformerFails();
  testChainSuccess();
  testChainFirstFutureFails();
  testChainTransformerFails();
  testChainSecondFutureFails();
}