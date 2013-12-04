// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.utils;

import 'dart:async';
import 'dart:typed_data';

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

/// A class that represents one and only one of two types of values.
class Either<E, F> {
  /// Whether this is a value of type `E`.
  final bool isFirst;

  /// Whether this is a value of type `F`.
  bool get isSecond => !isFirst;

  /// The value, either of type `E` or `F`.
  final _value;

  /// The value of type `E`.
  ///
  /// It's an error to access this is this is of type `F`.
  E get first {
    assert(isFirst);
    return _value;
  }

  /// The value of type `F`.
  ///
  /// It's an error to access this is this is of type `E`.
  F get second {
    assert(isSecond);
    return _value;
  }

  /// Creates an [Either] with type `E`.
  Either.withFirst(this._value)
      : isFirst = true;

  /// Creates an [Either] with type `F`.
  Either.withSecond(this._value)
      : isFirst = false;

  /// Runs [whenFirst] or [whenSecond] depending on the type of [this].
  ///
  /// Returns the result of whichvever function was run.
  match(whenFirst(E value), whenSecond(F value)) {
    if (isFirst) return whenFirst(first);
    return whenSecond(second);
  }

  String toString() => "$_value (${isFirst? 'first' : 'second'})";
}

/// Converts a number in the range [0-255] to a two digit hex string.
///
/// For example, given `255`, returns `ff`.
String byteToHex(int byte) {
  assert(byte >= 0 && byte <= 255);

  const DIGITS = "0123456789abcdef";
  return DIGITS[(byte ~/ 16) % 16] + DIGITS[byte % 16];
}

/// Converts [input] into a [Uint8List].
///
/// If [input] is a [TypedData], this just returns a view on [input].
Uint8List toUint8List(List<int> input) {
  if (input is Uint8List) return input;
  if (input is TypedData) {
    // TODO(nweiz): remove "as" when issue 11080 is fixed.
    return new Uint8List.view((input as TypedData).buffer);
  }
  return new Uint8List.fromList(input);
}

/// Group the elements in [iter] by the value returned by [fn].
///
/// This returns a map whose keys are the return values of [fn] and whose values
/// are lists of each element in [iter] for which [fn] returned that key.
Map<Object, List> groupBy(Iterable iter, fn(element)) {
  var map = {};
  for (var element in iter) {
    var list = map.putIfAbsent(fn(element), () => []);
    list.add(element);
  }
  return map;
}

/// Flattens nested lists inside an iterable into a single list containing only
/// non-list elements.
List flatten(Iterable nested) {
  var result = [];
  helper(list) {
    for (var element in list) {
      if (element is List) {
        helper(element);
      } else {
        result.add(element);
      }
    }
  }
  helper(nested);
  return result;
}

/// Returns the union of all elements in each set in [sets].
Set unionAll(Iterable<Set> sets) =>
  sets.fold(new Set(), (union, set) => union.union(set));

/// Passes each key/value pair in [map] to [fn] and returns a new [Map] whose
/// values are the return values of [fn].
Map mapMapValues(Map map, fn(key, value)) =>
  new Map.fromIterable(map.keys, value: (key) => fn(key, map[key]));

/// Returns whether [set1] has exactly the same elements as [set2].
bool setEquals(Set set1, Set set2) =>
  set1.length == set2.length && set1.containsAll(set2);

/// Merges [streams] into a single stream that emits events from all sources.
///
/// If [broadcast] is true, this will return a broadcast stream; otherwise, it
/// will return a buffered stream.
Stream mergeStreams(Iterable<Stream> streams, {bool broadcast: false}) {
  streams = streams.toList();
  var doneCount = 0;
  // Use a sync stream to preserve the synchrony behavior of the input streams.
  // If the inputs are sync, then this will be sync as well; if the inputs are
  // async, then the events we receive will also be async, and forwarding them
  // sync won't change that.
  var controller = broadcast ? new StreamController.broadcast(sync: true)
      : new StreamController(sync: true);

  for (var stream in streams) {
    stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
      doneCount++;
      if (doneCount == streams.length) controller.close();
    });
  }

  return controller.stream;
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
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}

/// Like `new Future`, but avoids issue 11911 by using `new Future.value` under
/// the covers.
// TODO(jmesserly): doc comment changed to due 14601.
Future newFuture(callback()) => new Future.value().then((_) => callback());

/// Like [Future.sync], but wraps the Future in [Chain.track] as well.
Future syncFuture(callback()) => Chain.track(new Future.sync(callback));

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

/// Returns a [Stream] that will emit the same values as the stream returned by
/// [callback].
///
/// [callback] will only be called when the returned [Stream] gets a subscriber.
Stream callbackStream(Stream callback()) {
  var subscription;
  var controller;
  controller = new StreamController(onListen: () {
    subscription = callback().listen(controller.add,
        onError: controller.addError,
        onDone: controller.close);
  },
      onCancel: () => subscription.cancel(),
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      sync: true);
  return controller.stream;
}
