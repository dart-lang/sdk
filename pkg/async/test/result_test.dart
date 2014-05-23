// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:collection";
import "package:async/result.dart";
import "package:unittest/unittest.dart";

void main() {
  StackTrace stack;
  try { throw 0; } catch (e, s) { stack = s; }

  test("create result value", () {
    Result<int> result = new Result<int>.value(42);
    expect(result.isValue, isTrue);
    expect(result.isError, isFalse);
    ValueResult value = result.asValue;
    expect(value.value, equals(42));
  });

  test("create result value 2", () {
    Result<int> result = new ValueResult<int>(42);
    expect(result.isValue, isTrue);
    expect(result.isError, isFalse);
    ValueResult<int> value = result.asValue;
    expect(value.value, equals(42));
  });

  test("create result error", () {
    Result<bool> result = new Result<bool>.error("BAD", stack);
    expect(result.isValue, isFalse);
    expect(result.isError, isTrue);
    ErrorResult error = result.asError;
    expect(error.error, equals("BAD"));
    expect(error.stackTrace, same(stack));
  });

  test("create result error 2", () {
    Result<bool> result = new ErrorResult<bool>("BAD", stack);
    expect(result.isValue, isFalse);
    expect(result.isError, isTrue);
    ErrorResult error = result.asError;
    expect(error.error, equals("BAD"));
    expect(error.stackTrace, same(stack));
  });

  test("create result error no stack", () {
    Result<bool> result = new Result<bool>.error("BAD");
    expect(result.isValue, isFalse);
    expect(result.isError, isTrue);
    ErrorResult error = result.asError;
    expect(error.error, equals("BAD"));
    expect(error.stackTrace, isNull);
  });

  test("complete with value", () {
    Result<int> result = new ValueResult<int>(42);
    Completer c = new Completer<int>();
    c.future.then(expectAsync((int v) { expect(v, equals(42)); }),
                  onError: (e, s) { fail("Unexpected error"); });
    result.complete(c);
  });

  test("complete with error", () {
    Result<bool> result = new ErrorResult("BAD", stack);
    Completer c = new Completer<bool>();
    c.future.then((bool v) { Expect.fail("Unexpected value $v"); },
                  onError: expectAsync((e, s) {
                    expect(e, equals("BAD"));
                    expect(s, same(stack));
                  }));
    result.complete(c);
  });

  test("add sink value", () {
    Result<int> result = new ValueResult<int>(42);
    EventSink<int> sink = new TestSink(
        onData: expectAsync((v) { expect(v, equals(42)); })
    );
    result.addTo(sink);
  });

  test("add sink error", () {
    Result<bool> result = new ErrorResult("BAD", stack);
    EventSink<bool> sink = new TestSink(
        onError: expectAsync((e, s) {
          expect(e, equals("BAD"));
          expect(s, same(stack));
        })
    );
    result.addTo(sink);
  });

  test("value as future", () {
    Result<int> result = new ValueResult<int>(42);
    result.asFuture.then(expectAsync((int v) { expect(v, equals(42)); }),
                         onError: (e, s) { fail("Unexpected error"); });
  });

  test("error as future", () {
    Result<bool> result = new ErrorResult("BAD", stack);
    result.asFuture.then((bool v) { Expect.fail("Unexpected value $v"); },
                         onError: expectAsync((e, s) {
                           expect(e, equals("BAD"));
                           expect(s, same(stack));
                         }));
  });

  test("capture future value", () {
    Future<int> value = new Future<int>.value(42);
    Result.capture(value).then(expectAsync((Result result) {
      expect(result.isValue, isTrue);
      expect(result.isError, isFalse);
      ValueResult value = result.asValue;
      expect(value.value, equals(42));
    }), onError: (e, s) {
      Expect.fail("Unexpected error: $e");
    });
  });

  test("capture future error", () {
    Future<bool> value = new Future<bool>.error("BAD", stack);
    Result.capture(value).then(expectAsync((Result result) {
      expect(result.isValue, isFalse);
      expect(result.isError, isTrue);
      ErrorResult error = result.asError;
      expect(error.error, equals("BAD"));
      expect(error.stackTrace, same(stack));
    }), onError: (e, s) {
      Expect.fail("Unexpected error: $e");
    });
  });

  test("release future value", () {
    Future<Result<int>> future =
        new Future<Result<int>>.value(new Result<int>.value(42));
    Result.release(future).then(expectAsync((v) {
      expect(v, equals(42));
    }), onError: (e, s) {
      Expect.fail("Unexpected error: $e");
    });
  });

  test("release future error", () {
    // An error in the result is unwrapped and reified by release.
    Future<Result<bool>> future =
        new Future<Result<bool>>.value(new Result<bool>.error("BAD", stack));
    Result.release(future).then((v) {
      Expect.fail("Unexpected value: $v");
    }, onError: expectAsync((e, s) {
      expect(e, equals("BAD"));
      expect(s, same(stack));
    }));
  });

  test("release future real error", () {
    // An error in the error lane is passed through by release.
    Future<Result<bool>> future = new Future<Result<bool>>.error("BAD", stack);
    Result.release(future).then((v) {
      Expect.fail("Unexpected value: $v");
    }, onError: expectAsync((e, s) {
      expect(e, equals("BAD"));
      expect(s, same(stack));
    }));
  });

  test("capture stream", () {
    StreamController<int> c = new StreamController<int>();
    Stream<Result> stream = Result.captureStream(c.stream);
    var expectedList = new Queue.from([new Result.value(42),
                                       new Result.error("BAD", stack),
                                       new Result.value(37)]);
    void listener(Result actual) {
      expect(expectedList.isEmpty, isFalse);
      expectResult(actual, expectedList.removeFirst());
    }
    stream.listen(expectAsync(listener, count: 3),
                  onError: (e, s) { fail("Unexpected error: $e"); },
                  onDone: expectAsync((){}),
                  cancelOnError: true);
    c.add(42);
    c.addError("BAD", stack);
    c.add(37);
    c.close();
  });

  test("release stream", () {
    StreamController<Result<int>> c = new StreamController<Result<int>>();
    Stream<int> stream = Result.releaseStream(c.stream);
    List events = [new Result<int>.value(42),
                   new Result<int>.error("BAD", stack),
                   new Result<int>.value(37)];
    // Expect the data events, and an extra error event.
    var expectedList = new Queue.from(events)..add(new Result.error("BAD2"));
    void dataListener(int v) {
      expect(expectedList.isEmpty, isFalse);
      Result expected = expectedList.removeFirst();
      expect(expected.isValue, isTrue);
      expect(v, equals(expected.asValue.value));
    }
    void errorListener(error, StackTrace stackTrace) {
      expect(expectedList.isEmpty, isFalse);
      Result expected = expectedList.removeFirst();
      expect(expected.isError, isTrue);
      expect(error, equals(expected.asError.error));
      expect(stackTrace, same(expected.asError.stackTrace));
    }
    stream.listen(expectAsync(dataListener, count: 2),
                  onError: expectAsync(errorListener, count: 2),
                  onDone: expectAsync((){}));
    for (Result<int> result in events) {
      c.add(result);  // Result value or error in data line.
    }
    c.addError("BAD2");  // Error in error line.
    c.close();
  });

  test("release stream cancel on error", () {
    StreamController<Result<int>> c = new StreamController<Result<int>>();
    Stream<int> stream = Result.releaseStream(c.stream);
    stream.listen(expectAsync((v) { expect(v, equals(42)); }),
                  onError: expectAsync((e, s) {
                    expect(e, equals("BAD"));
                    expect(s, same(stack));
                  }),
                  onDone: () { fail("Unexpected done event"); },
                  cancelOnError: true);
    c.add(new Result.value(42));
    c.add(new Result.error("BAD", stack));
    c.add(new Result.value(37));
    c.close();
  });
}

void expectResult(Result actual, Result expected) {
  expect(actual.isValue, equals(expected.isValue));
  expect(actual.isError, equals(expected.isError));
  if (actual.isValue) {
    expect(actual.asValue.value, equals(expected.asValue.value));
  } else {
    expect(actual.asError.error, equals(expected.asError.error));
    expect(actual.asError.stackTrace, same(expected.asError.stackTrace));
  }
}

class TestSink<T> implements EventSink<T> {
  final Function onData;
  final Function onError;
  final Function onDone;

  TestSink({void this.onData(T data) : _nullData,
            void this.onError(e, StackTrace s) : _nullError,
            void this.onDone() : _nullDone });

  void add(T value) { onData(value); }
  void addError(error, [StackTrace stack]) { onError(error, stack); }
  void close() { onDone(); }

  static void _nullData(value) { Expect.fail("Unexpected sink add: $value"); }
  static void _nullError(e, StackTrace s) {
    Expect.fail("Unexpected sink addError: $e");
  }
  static void _nullDone() { Expect.fail("Unepxected sink close"); }
}
