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

  bool operator==(other) {
    if (other is! Pair) return false;
    return other.first == first && other.last == last;
  }

  int get hashCode => first.hashCode ^ last.hashCode;
}

/// Configures [future] so that its result (success or exception) is passed on
/// to [completer].
void chainToCompleter(Future future, Completer completer) {
  future.then((value) => completer.complete(value),
      onError: (e) => completer.completeError(e));
}

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
Future pumpEventQueue([int times=20]) {
  if (times == 0) return new Future.value();
  return new Future.value().then((_) => pumpEventQueue(times - 1));
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

// TODO(nweiz): remove this when issue 8731 is fixed.
/// Returns a [Stream] that will immediately emit [error] and then close.
Stream errorStream(error) => new Future.error(error).asStream();

/// Returns a buffered stream that will emit the same values as the stream
/// returned by [future] once [future] completes. If [future] completes to an
/// error, the return value will emit that error and then close.
Stream futureStream(Future<Stream> future) {
  var controller = new StreamController();
  future.then((stream) {
    stream.listen(
        controller.add,
        onError: (error) => controller.addError(error),
        onDone: controller.close);
  }).catchError((e) {
    controller.addError(e);
    controller.close();
  });
  return controller.stream;
}

// TODO(nweiz): remove this when issue 7964 is fixed.
/// Returns a [Future] that will complete to the first element of [stream].
/// Unlike [Stream.first], this is safe to use with single-subscription streams.
Future streamFirst(Stream stream) {
  var stackTrace;
  try {
    throw '';
  } catch (_, thrownStackTrace) {
    stackTrace = thrownStackTrace;
  }

  var completer = new Completer();
  var subscription;
  subscription = stream.listen((value) {
    subscription.cancel();
    completer.complete(value);
  }, onError: (e) {
    completer.completeError(e);
  }, onDone: () {
    completer.completeError(new StateError("No elements"), stackTrace);
  }, cancelOnError: true);
  return completer.future;
}

/// A function that can be called to cancel a [Stream] and send a done message.
typedef void StreamCanceller();

// TODO(nweiz): use a StreamSubscription when issue 9026 is fixed.
/// Returns a wrapped version of [stream] along with a function that will cancel
/// the wrapped stream. Unlike [StreamSubscription], this canceller will send a
/// "done" message to the wrapped stream.
Pair<Stream, StreamCanceller> streamWithCanceller(Stream stream) {
  var controller = new StreamController();
  var controllerStream = stream.isBroadcast ?
      controller.stream.asBroadcastStream() :
      controller.stream;
  var subscription = stream.listen((value) {
    if (!controller.isClosed) controller.add(value);
  }, onError: (error) {
    if (!controller.isClosed) controller.signalError(error);
  }, onDone: controller.close);
  return new Pair<Stream, StreamCanceller>(controllerStream, controller.close);
}

// TODO(nweiz): remove this when issue 7787 is fixed.
/// Creates two single-subscription [Stream]s that each emit all values and
/// errors from [stream]. This is useful if [stream] is single-subscription but
/// multiple subscribers are necessary.
Pair<Stream, Stream> tee(Stream stream) {
  var controller1 = new StreamController();
  var controller2 = new StreamController();
  stream.listen((value) {
    controller1.add(value);
    controller2.add(value);
  }, onError: (error) {
    controller1.signalError(error);
    controller2.signalError(error);
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
  return new Trace.from(trace).terse.foldFrames((frame) {
    return frame.package == 'scheduled_test' || frame.package == 'unittest' ||
        frame.isCore;
  }).toString().trim();
}
