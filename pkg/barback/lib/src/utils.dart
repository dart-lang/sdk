// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.utils;

import 'dart:async';

/// Converts a number in the range [0-255] to a two digit hex string.
///
/// For example, given `255`, returns `ff`.
String byteToHex(int byte) {
  assert(byte >= 0 && byte <= 255);

  const DIGITS = "0123456789abcdef";
  return DIGITS[(byte ~/ 16) % 16] + DIGITS[byte % 16];
}

/// Group the elements in [iter] by the value returned by [fn].
///
/// This returns a map whose keys are the return values of [fn] and whose values
/// are lists of each element in [iter] for which [fn] returned that key.
Map groupBy(Iterable iter, fn(element)) {
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

/// Passes each key/value pair in [map] to [fn] and returns a new [Map] whose
/// values are the return values of [fn].
Map mapMapValues(Map map, fn(key, value)) =>
  new Map.fromIterable(map.keys, value: (key) => fn(key, map[key]));

/// Merges [streams] into a single stream that emits events from all sources.
Stream mergeStreams(Iterable<Stream> streams) {
  streams = streams.toList();
  var doneCount = 0;
  // Use a sync stream to preserve the synchrony behavior of the input streams.
  // If the inputs are sync, then this will be sync as well; if the inputs are
  // async, then the events we receive will also be async, and forwarding them
  // sync won't change that.
  var controller = new StreamController(sync: true);

  for (var stream in streams) {
    stream.listen((value) {
      controller.add(value);
    }, onError: (error) {
      controller.addError(error);
    }, onDone: () {
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
  // We use a delayed future to allow runAsync events to finish. The
  // Future.value or Future() constructors use runAsync themselves and would
  // therefore not wait for runAsync callbacks that are scheduled after invoking
  // this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}

