// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

main() {
  // Values used.
  var error = StateError("test");
  var stack = StackTrace.fromString("for testing");
  var expectedError = AsyncError(error, stack);

  var otherError = ArgumentError("Other error");
  var expectedOtherError = AsyncError(otherError, StackTrace.empty);

  var errorFuture = Future<int?>.error(error, stack)..ignore();
  var nonNativeErrorFuture = NonNativeFuture<int?>._(errorFuture);

  asyncStart();

  /// Perform `onError` on [future] with arguments, and expect [result].
  ///
  /// If [result] is [AsyncError], expect an error result with
  /// that error and stack trace.
  /// If [result.stackTrace] is [StackTrace.empty],
  /// check that the stack trace is *not* the original [stack].
  ///
  /// Otherwise expect the future to complete with value equal to [result].
  void test<E extends Object, T>(
    String testName,
    Future<T> future,
    FutureOr<T> Function(E, StackTrace) onError, {
    bool Function(E)? test,
    Object? result,
  }) {
    asyncStart();
    var resultFuture = future.onError(onError, test: test);

    if (result is AsyncError) {
      resultFuture.then((value) {
        Expect.fail("$testName: Did not throw, value: $value");
      }, onError: (Object error, StackTrace stackTrace) {
        Expect.identical(result.error, error, testName);
        if (result.stackTrace != StackTrace.empty) {
          Expect.identical(result.stackTrace, stackTrace, testName);
        } else {
          Expect.notEquals(stack, stackTrace, testName);
        }
        asyncEnd();
      });
    } else {
      resultFuture.then((value) {
        Expect.equals(result, value);
        asyncEnd();
      }, onError: (error, stackTrace) {
        Expect.fail("$testName: Threw $error");
      });
    }
  }

  // Go through all the valid permutations of the following options:
  //
  // * Native future or non-native future.
  // * The error type parameter matches the error or not.
  // * If type matches, test function is provided or not.
  // * If test function provided, it returns either true or false.
  // * If type and test both succeeds,
  //     * Error handler is synchronous or asynchronous
  //     * Error handler returns a value, throws new error,
  //       or rethrows same error.
  // * The future is up-cast to a supertype or not when `onError` is called.
  //   (Since `onError` is an extension method, it affects the method.)
  //
  // The expected result is computed for each combination,
  // and checked against the behavior:
  // * If type or test fails to match,
  //   the original error and stack is the error result
  // * If type matches and test doesn't reject,
  //   the error handler is invoked.
  //     * If it returns a value, that becomes the result.
  //         * If upcast, a return value of the supertype is accepted.
  //     * If it throws a new error, that is the error result.
  //     * If it throws the original error *synchronously*,
  //       the original stack trace is retained.
  //     * If it throws the original error *asynchronously*,
  //       the original stack trace is not expected to be retained.
  for (var native in [true, false]) {
    var nativity = native ? "native" : "non-native";
    var future = native ? errorFuture : nonNativeErrorFuture;
    for (var upcast in [true, false]) {
      var upcastText = upcast ? " as Future<num?>" : "";
      // "fails" means not to match type parameter.
      // Rest means match type parameter, a bool is what `test` returns,
      // `null` means no test function.
      for (var testKind in ["fails", true, false, null]) {
        var matches = testKind == true || testKind == null;
        // If `matches` is false, the error handler should not be invoked.
        // Don't bother with creating sync/async versions of it then,
        // just one which fails if called.
        for (var async in [if (matches) true, false]) {
          var asyncText = async ? "async" : "sync";
          // Action of the handler body. If test doesn't match, it will fail.
          for (var action
              in matches ? ["return", "throw", "rethrow"] : ["fail"]) {
            // Called to provide the necessary types as type parameters.
            void doTest<E extends Object, T>() {
              String testName =
                  "$nativity Future<int?>.error(StateError(..))$upcastText ";

              bool Function(E)? testFunction;
              switch (testKind) {
                case "fails":
                  testFunction = (E value) {
                    Expect.fail("$testName: Matched error");
                    throw "unreachable"; // Expect.fail throws.
                  };
                  break;
                case true:
                case false:
                  var testResult = testKind == true;
                  testFunction = (E value) => testResult;
                  testName +=
                      "matches type $E ${testResult ? "and test" : "but not test"}";
                  break;
                default:
                  testName += "matches type with no test";
              }
              Object? expectation = expectedError;
              FutureOr<T> Function(E, StackTrace) onError;
              switch (action) {
                case "return":
                  expectation = upcast ? 3.14 : 42;
                  testName += " and returns $expectation";
                  onError = (E e, StackTrace s) {
                    return expectation as T;
                  };
                  break;
                case "throw":
                  expectation = expectedOtherError;
                  onError = (E e, StackTrace s) {
                    throw otherError;
                  };
                  testName += " and throws new error";
                  break;
                case "rethrow":
                  onError = (E e, StackTrace s) {
                    throw e;
                  };
                  testName += " and rethrows";
                  // Asynchronous callbacks rethrowing the error
                  // doesn't count as a rethrow, only synchronous throws.
                  if (async) expectation = AsyncError(error, StackTrace.empty);
                  break;
                case "fail":
                  onError = (E e, StackTrace s) {
                    Expect.fail("$testName: Matched error");
                    throw "unreachable"; // Expect.fail throws.
                  };
                  testName += " and rethrows original error";
                  break;
                default:
                  throw "unreachable";
              }
              if (async) {
                testName += " asynchronously";
                var originalOnError = onError;
                onError = (E e, StackTrace s) async => originalOnError(e, s);
              }
              test<E, T>(testName, future as Future<T>, onError,
                  test: testFunction, result: expectation);
            }

            // Find the types to use.
            if (testKind == "fails") {
              if (upcast) {
                doTest<Exception, num?>();
              } else {
                doTest<Exception, int?>();
              }
            } else {
              if (upcast) {
                doTest<StateError, num?>();
              } else {
                doTest<StateError, int?>();
              }
            }
          }
        }
      }
    }
  }

  asyncEnd();
}

class NonNativeFuture<T> implements Future<T> {
  Future<T> _original;
  NonNativeFuture.value(T value) : _original = Future<T>.value(value);
  NonNativeFuture.error(Object error, [StackTrace? stack])
      : _original = Future<T>.error(error, stack)..ignore();
  NonNativeFuture._(this._original);
  Future<R> then<R>(FutureOr<R> Function(T) handleValue, {Function? onError}) =>
      NonNativeFuture<R>._(_original.then(handleValue, onError: onError));
  Future<T> catchError(Function handleError, {bool Function(Object)? test}) =>
      NonNativeFuture<T>._(_original.catchError(handleError, test: test));
  Future<T> whenComplete(FutureOr<void> Function() onDone) =>
      NonNativeFuture<T>._(_original.whenComplete(onDone));
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      NonNativeFuture<T>._(_original.timeout(timeLimit, onTimeout: onTimeout));
  Stream<T> asStream() => _original.asStream();
}
