// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generic utility functions. Stuff that should possibly be in core.
library utils;

import 'dart:async';
import 'dart:crypto';
import 'dart:isolate';
import 'dart:uri';

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

/// A completer that waits until all added [Future]s complete.
// TODO(rnystrom): Copied from web_components. Remove from here when it gets
// added to dart:core. (See #6626.)
class FutureGroup<T> {
  int _pending = 0;
  Completer<List<T>> _completer = new Completer<List<T>>();
  final List<Future<T>> futures = <Future<T>>[];
  bool completed = false;

  final List<T> _values = <T>[];

  /// Wait for [task] to complete.
  Future<T> add(Future<T> task) {
    if (completed) {
      throw new StateError("The FutureGroup has already completed.");
    }

    _pending++;
    futures.add(task.then((value) {
      if (completed) return;

      _pending--;
      _values.add(value);

      if (_pending <= 0) {
        completed = true;
        _completer.complete(_values);
      }
    }).catchError((e) {
      if (completed) return;

      completed = true;
      _completer.completeError(e.error, e.stackTrace);
    }));

    return task;
  }

  Future<List> get future => _completer.future;
}

// TODO(rnystrom): Move into String?
/// Pads [source] to [length] by adding spaces at the end.
String padRight(String source, int length) {
  final result = new StringBuffer();
  result.add(source);

  while (result.length < length) {
    result.add(' ');
  }

  return result.toString();
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

/// Asserts that [iter] contains only one element, and returns it.
only(Iterable iter) {
  var iterator = iter.iterator;
  var currentIsValid = iterator.moveNext();
  assert(currentIsValid);
  var obj = iterator.current;
  assert(!iterator.moveNext());
  return obj;
}

/// Returns a set containing all elements in [minuend] that are not in
/// [subtrahend].
Set setMinus(Collection minuend, Collection subtrahend) {
  var minuendSet = new Set.from(minuend);
  minuendSet.removeAll(subtrahend);
  return minuendSet;
}

/// Replace each instance of [matcher] in [source] with the return value of
/// [fn].
String replace(String source, Pattern matcher, String fn(Match)) {
  var buffer = new StringBuffer();
  var start = 0;
  for (var match in matcher.allMatches(source)) {
    buffer.add(source.substring(start, match.start));
    start = match.end;
    buffer.add(fn(match));
  }
  buffer.add(source.substring(start));
  return buffer.toString();
}

/// Returns whether or not [str] ends with [matcher].
bool endsWithPattern(String str, Pattern matcher) {
  for (var match in matcher.allMatches(str)) {
    if (match.end == str.length) return true;
  }
  return false;
}

/// Returns the hex-encoded sha1 hash of [source].
String sha1(String source) {
  var sha = new SHA1();
  sha.add(source.charCodes);
  return CryptoUtils.bytesToHex(sha.close());
}

/// Invokes the given callback asynchronously. Returns a [Future] that completes
/// to the result of [callback].
///
/// This is also used to wrap synchronous code that may thrown an exception to
/// ensure that methods that have both sync and async code only report errors
/// asynchronously.
Future defer(callback()) {
  return new Future.immediate(null).then((_) => callback());
}

/// Returns a [Future] that completes in [milliseconds].
Future sleep(int milliseconds) {
  var completer = new Completer();
  new Timer(new Duration(milliseconds: milliseconds), completer.complete);
  return completer.future;
}

/// Configures [future] so that its result (success or exception) is passed on
/// to [completer].
void chainToCompleter(Future future, Completer completer) {
  future.then((value) => completer.complete(value),
      onError: (e) => completer.completeError(e.error, e.stackTrace));
}

// TODO(nweiz): remove this when issue 7964 is fixed.
/// Returns a [Future] that will complete to the first element of [stream].
/// Unlike [Stream.first], this is safe to use with single-subscription streams.
Future streamFirst(Stream stream) {
  var completer = new Completer();
  var subscription;
  subscription = stream.listen((value) {
    subscription.cancel();
    completer.complete(value);
  },
      onError: (e) => completer.completeError(e.error, e.stackTrace),
      onDone: () => completer.completeError(new StateError("No elements")),
      unsubscribeOnError: true);
  return completer.future;
}

/// Returns a wrapped version of [stream] along with a [StreamSubscription] that
/// can be used to control the wrapped stream.
Pair<Stream, StreamSubscription> streamWithSubscription(Stream stream) {
  var controller = stream.isBroadcast ?
      new StreamController.broadcast() :
      new StreamController();
  var subscription = stream.listen(controller.add,
      onError: controller.signalError,
      onDone: controller.close);
  return new Pair<Stream, StreamSubscription>(controller.stream, subscription);
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

/// A regular expression matching a line termination character or character
/// sequence.
final RegExp _lineRegexp = new RegExp(r"\r\n|\r|\n");

/// Converts a stream of arbitrarily chunked strings into a line-by-line stream.
/// The lines don't include line termination characters. A single trailing
/// newline is ignored.
Stream<String> streamToLines(Stream<String> stream) {
  var buffer = new StringBuffer();
  return wrapStream(stream.transform(new StreamTransformer(
      handleData: (chunk, sink) {
        var lines = chunk.split(_lineRegexp);
        var leftover = lines.removeLast();
        for (var line in lines) {
          if (!buffer.isEmpty) {
            buffer.add(line);
            line = buffer.toString();
            buffer.clear();
          }

          sink.add(line);
        }
        buffer.add(leftover);
      },
      handleDone: (sink) {
        if (!buffer.isEmpty) sink.add(buffer.toString());
        sink.close();
      })));
}

// TODO(nweiz): remove this when issue 8310 is fixed.
/// Returns a [Stream] identical to [stream], but piped through a new
/// [StreamController]. This exists to work around issue 8310.
Stream wrapStream(Stream stream) {
  var controller = stream.isBroadcast
      ? new StreamController.broadcast()
      : new StreamController();
  stream.listen(controller.add,
      onError: (e) => controller.signalError(e),
      onDone: controller.close);
  return controller.stream;
}

/// Like [Iterable.where], but allows [test] to return [Future]s and uses the
/// results of those [Future]s as the test.
Future<Iterable> futureWhere(Iterable iter, test(value)) {
  return Future.wait(iter.mappedBy((e) {
    var result = test(e);
    if (result is! Future) result = new Future.immediate(result);
    return result.then((result) => new Pair(e, result));
  }))
      .then((pairs) => pairs.where((pair) => pair.last))
      .then((pairs) => pairs.mappedBy((pair) => pair.first));
}

// TODO(nweiz): unify the following functions with the utility functions in
// pkg/http.

/// Like [String.split], but only splits on the first occurrence of the pattern.
/// This will always return an array of two elements or fewer.
List<String> split1(String toSplit, String pattern) {
  if (toSplit.isEmpty) return <String>[];

  var index = toSplit.indexOf(pattern);
  if (index == -1) return [toSplit];
  return [toSplit.substring(0, index),
    toSplit.substring(index + pattern.length)];
}

/// Adds additional query parameters to [url], overwriting the original
/// parameters if a name conflict occurs.
Uri addQueryParameters(Uri url, Map<String, String> parameters) {
  var queryMap = queryToMap(url.query);
  mapAddAll(queryMap, parameters);
  return url.resolve("?${mapToQuery(queryMap)}");
}

/// Convert a URL query string (or `application/x-www-form-urlencoded` body)
/// into a [Map] from parameter names to values.
Map<String, String> queryToMap(String queryList) {
  var map = {};
  for (var pair in queryList.split("&")) {
    var split = split1(pair, "=");
    if (split.isEmpty) continue;
    var key = urlDecode(split[0]);
    var value = split.length > 1 ? urlDecode(split[1]) : "";
    map[key] = value;
  }
  return map;
}

/// Convert a [Map] from parameter names to values to a URL query string.
String mapToQuery(Map<String, String> map) {
  var pairs = <List<String>>[];
  map.forEach((key, value) {
    key = encodeUriComponent(key);
    value = (value == null || value.isEmpty) ? null : encodeUriComponent(value);
    pairs.add([key, value]);
  });
  return Strings.join(pairs.map((pair) {
    if (pair[1] == null) return pair[0];
    return "${pair[0]}=${pair[1]}";
  }), "&");
}

/// Add all key/value pairs from [source] to [destination], overwriting any
/// pre-existing values.
void mapAddAll(Map destination, Map source) =>
  source.forEach((key, value) => destination[key] = value);

/// Decodes a URL-encoded string. Unlike [decodeUriComponent], this includes
/// replacing `+` with ` `.
String urlDecode(String encoded) =>
  decodeUriComponent(encoded.replaceAll("+", " "));
