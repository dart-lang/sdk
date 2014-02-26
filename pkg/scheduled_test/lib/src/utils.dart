// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

/// A pair of values.
class Pair<E, F> {
  E first;
  F last;

  Pair(this.first, this.last);

  String toString() => '($first, $last)';

  bool operator ==(other) {
    if (other is! Pair) return false;
    return other.first == first && other.last == last;
  }

  int get hashCode => first.hashCode ^ last.hashCode;
}

/// A class that represents a value or an error.
class Fallible<E> {
  /// Whether [this] has a [value], as opposed to an [error].
  final bool hasValue;

  /// Whether [this] has an [error], as opposed to a [value].
  bool get hasError => !hasValue;

  /// The value.
  ///
  /// This will be `null` if [this] has an [error].
  final E _value;

  /// The value.
  ///
  /// This will throw a [StateError] if [this] has an [error].
  E get value {
    if (hasValue) return _value;
    throw new StateError("Fallible has no value.\n"
        "$_error$_stackTraceSuffix");
  }

  /// The error.
  ///
  /// This will be `null` if [this] has a [value].
  final _error;

  /// The error.
  ///
  /// This will throw a [StateError] if [this] has a [value].
  get error {
    if (hasError) return _error;
    throw new StateError("Fallible has no error.");
  }

  /// The stack trace for [_error].
  ///
  /// This will be `null` if [this] has a [value], or if no stack trace was
  /// provided.
  final StackTrace _stackTrace;

  /// The stack trace for [error].
  ///
  /// This will throw a [StateError] if [this] has a [value].
  StackTrace get stackTrace {
    if (hasError) return _stackTrace;
    throw new StateError("Fallible has no error.");
  }

  Fallible.withValue(this._value)
      : _error = null,
        _stackTrace = null,
        hasValue = true;

  Fallible.withError(this._error, [this._stackTrace])
      : _value = null,
        hasValue = false;

  /// Returns a completed Future with the same value or error as [this].
  Future toFuture() {
    if (hasValue) return new Future.value(value);
    return new Future.error(error, stackTrace);
  }

  String toString() {
    if (hasValue) return "Fallible value: $value";
    return "Fallible error: $error$_stackTraceSuffix";
  }

  String get _stackTraceSuffix {
    if (stackTrace == null) return "";
    return "\nStack trace:\n${new Chain.forTrace(_stackTrace).terse}";
  }
}

/// Configures [future] so that its result (success or exception) is passed on
/// to [completer].
void chainToCompleter(Future future, Completer completer) {
  future.then(completer.complete, onError: completer.completeError);
}

/// Like [Future.sync], but wraps the Future in [Chain.track] as well.
Future syncFuture(callback()) => Chain.track(new Future.sync(callback));

/// Prepends each line in [text] with [prefix]. If [firstPrefix] is passed, the
/// first line is prefixed with that instead.
String prefixLines(String text, {String prefix: '| ', String firstPrefix}) {
  var lines = text.split('\n');
  if (firstPrefix == null) {
    return lines.map((line) => '$prefix$line').join('\n');
  }

  var firstLine = "$firstPrefix${lines.first}";
  lines = lines.skip(1).map((line) => '$prefix$line').toList();
  lines.insert(0, firstLine);
  return lines.join('\n');
}

/// Returns a [Future] that completes after pumping the event queue [times]
/// times. By default, this should pump the event queue enough times to allow
/// any code to run, as long as it's not waiting on some external event.
Future pumpEventQueue([int times = 20]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}

/// Returns whether [iterable1] has the same elements in the same order as
/// [iterable2]. The elements are compared using `==`.
bool orderedIterableEquals(Iterable iterable1, Iterable iterable2) {
  var iter1 = iterable1.iterator;
  var iter2 = iterable2.iterator;

  while (true) {
    var hasNext1 = iter1.moveNext();
    var hasNext2 = iter2.moveNext();
    if (hasNext1 != hasNext2) return false;
    if (!hasNext1) return true;
    if (iter1.current != iter2.current) return false;
  }
}

/// Returns a buffered stream that will emit the same values as the stream
/// returned by [future] once [future] completes.
///
/// If [future] completes to an error, the return value will emit that error and
/// then close.
///
/// If [broadcast] is true, a broadcast stream is returned. This assumes that
/// the stream returned by [future] will be a broadcast stream as well.
/// [broadcast] defaults to false.
Stream futureStream(Future<Stream> future, {bool broadcast: false}) {
  var subscription;
  var controller;

  future = future.catchError((e, stackTrace) {
    // Since [controller] is synchronous, it's likely that emitting an error
    // will cause it to be cancelled before we call close.
    if (controller != null) controller.addError(e, stackTrace);
    if (controller != null) controller.close();
    controller = null;
  });

  onListen() {
    future.then((stream) {
      if (controller == null) return;
      subscription = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close);
    });
  }

  onCancel() {
    if (subscription != null) subscription.cancel();
    subscription = null;
    controller = null;
  }

  if (broadcast) {
    controller = new StreamController.broadcast(
        sync: true, onListen: onListen, onCancel: onCancel);
  } else {
    controller = new StreamController(
        sync: true, onListen: onListen, onCancel: onCancel);
  }
  return controller.stream;
}

/// Returns the first element of a [StreamIterator].
///
/// If the [StreamIterator] has no elements, the result is a state error.
Future<String> streamIteratorFirst(StreamIterator<String> streamIterator) {
  return streamIterator.moveNext().then((hasNext) {
    if (hasNext) {
      return streamIterator.current;
    } else {
      throw new StateError("No elements");
    }
  });
}

/// Collects all remaining lines from a [StreamIterator] of lines.
///
/// Returns the concatenation of the collected lines joined by newlines.
Future<String> concatRest(StreamIterator<String> streamIterator) {
  var completer = new Completer<String>();
  var buffer = new StringBuffer();
  void collectAll() {
    streamIterator.moveNext().then((hasNext) {
      if (hasNext) {
        if (!buffer.isEmpty) buffer.write('\n');
        buffer.write(streamIterator.current);
        collectAll();
      } else {
        completer.complete(buffer.toString());
      }
    }, onError: completer.completeError);
  }
  collectAll();
  return completer.future;
}

/// A function that can be called to cancel a [Stream] and send a done message.
typedef void StreamCanceller();

// TODO(nweiz): use a StreamSubscription when issue 9026 is fixed.
/// Returns a wrapped version of [stream] along with a function that will cancel
/// the wrapped stream. Unlike [StreamSubscription], this canceller will send a
/// "done" message to the wrapped stream.
Pair<Stream, StreamCanceller> streamWithCanceller(Stream stream) {
  var controller =
      stream.isBroadcast ? new StreamController.broadcast(sync: true)
                         : new StreamController(sync: true);
  var controllerStream = controller.stream;
  var subscription = stream.listen((value) {
    if (!controller.isClosed) controller.add(value);
  }, onError: (error, [stackTrace]) {
    if (!controller.isClosed) controller.addError(error, stackTrace);
  }, onDone: controller.close);
  return new Pair<Stream, StreamCanceller>(controllerStream, controller.close);
}

// TODO(nweiz): remove this when issue 7787 is fixed.
/// Creates two single-subscription [Stream]s that each emit all values and
/// errors from [stream]. This is useful if [stream] is single-subscription but
/// multiple subscribers are necessary.
Pair<Stream, Stream> tee(Stream stream) {
  var controller1 = new StreamController(sync: true);
  var controller2 = new StreamController(sync: true);
  stream.listen((value) {
    controller1.add(value);
    controller2.add(value);
  }, onError: (error, [stackTrace]) {
    controller1.addError(error, stackTrace);
    controller2.addError(error, stackTrace);
  }, onDone: () {
    controller1.close();
    controller2.close();
  });
  return new Pair<Stream, Stream>(controller1.stream, controller2.stream);
}

/// Takes a simple data structure (composed of [Map]s, [Iterable]s, scalar
/// objects, and [Future]s) and recursively resolves all the [Future]s contained
/// within. Completes with the fully resolved structure.
Future awaitObject(object) {
  // Unroll nested futures.
  if (object is Future) return object.then(awaitObject);
  if (object is Iterable) {
    return Future.wait(object.map(awaitObject).toList());
  }
  if (object is! Map) return new Future.value(object);

  var pairs = <Future<Pair>>[];
  object.forEach((key, value) {
    pairs.add(awaitObject(value)
        .then((resolved) => new Pair(key, resolved)));
  });
  return Future.wait(pairs).then((resolvedPairs) {
    var map = {};
    for (var pair in resolvedPairs) {
      map[pair.first] = pair.last;
    }
    return map;
  });
}

/// Returns whether [pattern] matches all of [string].
bool fullMatch(String string, Pattern pattern) {
  var matches = pattern.allMatches(string);
  if (matches.isEmpty) return false;
  return matches.first.start == 0 && matches.first.end == string.length;
}

/// Returns a string representation of [trace] that has the core and test frames
/// folded together.
String terseTraceString(StackTrace trace) {
  return new Chain.forTrace(trace).terse.toString().trim();
}
