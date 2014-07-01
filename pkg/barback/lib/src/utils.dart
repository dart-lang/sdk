// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.utils;

import 'dart:async';
import 'dart:typed_data';

import 'package:stack_trace/stack_trace.dart';

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

/// Converts a number in the range [0-255] to a two digit hex string.
///
/// For example, given `255`, returns `ff`.
String byteToHex(int byte) {
  assert(byte >= 0 && byte <= 255);

  const DIGITS = "0123456789abcdef";
  return DIGITS[(byte ~/ 16) % 16] + DIGITS[byte % 16];
}

/// Returns a sentence fragment listing the elements of [iter].
///
/// This converts each element of [iter] to a string and separates them with
/// commas and/or "and" where appropriate.
String toSentence(Iterable iter) {
  if (iter.length == 1) return iter.first.toString();
  return iter.take(iter.length - 1).join(", ") + " and ${iter.last}";
}

/// Returns [name] if [number] is 1, or the plural of [name] otherwise.
///
/// By default, this just adds "s" to the end of [name] to get the plural. If
/// [plural] is passed, that's used instead.
String pluralize(String name, int number, {String plural}) {
  if (number == 1) return name;
  if (plural != null) return plural;
  return '${name}s';
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

/// Creates a new map from [map] with new keys and values.
///
/// The return values of [keyFn] are used as the keys and the return values of
/// [valueFn] are used as the values for the new map.
Map mapMap(Map map, keyFn(key, value), valueFn(key, value)) =>
  new Map.fromIterable(map.keys,
      key: (key) => keyFn(key, map[key]),
      value: (key) => valueFn(key, map[key]));

/// Creates a new map from [map] with the same keys.
///
/// The return values of [fn] are used as the values for the new map.
Map mapMapValues(Map map, fn(key, value)) => mapMap(map, (key, _) => key, fn);

/// Creates a new map from [map] with the same keys.
///
/// The return values of [fn] are used as the keys for the new map.
Map mapMapKeys(Map map, fn(key, value)) => mapMap(map, fn, (_, value) => value);

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

/// Creates a single-subscription stream from a broadcast stream.
///
/// The returned stream will enqueue events from [broadcast] until a listener is
/// attached, then pipe events to that listener.
Stream broadcastToSingleSubscription(Stream broadcast) {
  if (!broadcast.isBroadcast) return broadcast;

  // TODO(nweiz): Implement this using a transformer when issues 18588 and 18586
  // are fixed.
  var subscription;
  var controller = new StreamController(onCancel: () => subscription.cancel());
  subscription = broadcast.listen(controller.add,
      onError: controller.addError,
      onDone: controller.close);
  return controller.stream;
}

/// A regular expression to match the exception prefix that some exceptions'
/// [Object.toString] values contain.
final _exceptionPrefix = new RegExp(r'^([A-Z][a-zA-Z]*)?(Exception|Error): ');

/// Get a string description of an exception.
///
/// Many exceptions include the exception class name at the beginning of their
/// [toString], so we remove that if it exists.
String getErrorMessage(error) =>
  error.toString().replaceFirst(_exceptionPrefix, '');

/// Returns a human-friendly representation of [duration].
String niceDuration(Duration duration) {
  var result = duration.inMinutes > 0 ? "${duration.inMinutes}:" : "";

  var s = duration.inSeconds % 59;
  var ms = (duration.inMilliseconds % 1000) ~/ 100;
  return result + "$s.${ms}s";
}
