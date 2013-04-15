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
      _completer.completeError(e);
    }));

    return task;
  }

  Future<List> get future => _completer.future;
}

// TODO(rnystrom): Move into String?
/// Pads [source] to [length] by adding spaces at the end.
String padRight(String source, int length) {
  final result = new StringBuffer();
  result.write(source);

  while (result.length < length) {
    result.write(' ');
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
Set setMinus(Iterable minuend, Iterable subtrahend) {
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
    buffer.write(source.substring(start, match.start));
    start = match.end;
    buffer.write(fn(match));
  }
  buffer.write(source.substring(start));
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
  sha.add(source.codeUnits);
  return CryptoUtils.bytesToHex(sha.close());
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
      onError: (e) => completer.completeError(e));
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
  }, onError: (e) {
    completer.completeError(e);
  }, onDone: () {
    completer.completeError(new StateError("No elements"));
  }, cancelOnError: true);
  return completer.future;
}

/// Returns a wrapped version of [stream] along with a [StreamSubscription] that
/// can be used to control the wrapped stream.
Pair<Stream, StreamSubscription> streamWithSubscription(Stream stream) {
  var controller = new StreamController();
  var controllerStream = stream.isBroadcast ?
      controller.stream.asBroadcastStream() :
      controller.stream;
  var subscription = stream.listen(controller.add,
      onError: controller.addError,
      onDone: controller.close);
  return new Pair<Stream, StreamSubscription>(controllerStream, subscription);
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
    controller1.addError(error);
    controller2.addError(error);
  }, onDone: () {
    controller1.close();
    controller2.close();
  });
  return new Pair<Stream, Stream>(controller1.stream, controller2.stream);
}

/// A regular expression matching a trailing CR character.
final _trailingCR = new RegExp(r"\r$");

// TODO(nweiz): Use `text.split(new RegExp("\r\n?|\n\r?"))` when issue 9360 is
// fixed.
/// Splits [text] on its line breaks in a Windows-line-break-friendly way.
List<String> splitLines(String text) =>
  text.split("\n").map((line) => line.replaceFirst(_trailingCR, "")).toList();

/// Converts a stream of arbitrarily chunked strings into a line-by-line stream.
/// The lines don't include line termination characters. A single trailing
/// newline is ignored.
Stream<String> streamToLines(Stream<String> stream) {
  var buffer = new StringBuffer();
  return stream.transform(new StreamTransformer(
      handleData: (chunk, sink) {
        var lines = splitLines(chunk);
        var leftover = lines.removeLast();
        for (var line in lines) {
          if (!buffer.isEmpty) {
            buffer.write(line);
            line = buffer.toString();
            buffer = new StringBuffer();
          }

          sink.add(line);
        }
        buffer.write(leftover);
      },
      handleDone: (sink) {
        if (!buffer.isEmpty) sink.add(buffer.toString());
        sink.close();
      }));
}

/// Like [Iterable.where], but allows [test] to return [Future]s and uses the
/// results of those [Future]s as the test.
Future<Iterable> futureWhere(Iterable iter, test(value)) {
  return Future.wait(iter.map((e) {
    var result = test(e);
    if (result is! Future) result = new Future.value(result);
    return result.then((result) => new Pair(e, result));
  }))
      .then((pairs) => pairs.where((pair) => pair.last))
      .then((pairs) => pairs.map((pair) => pair.first));
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
  return pairs.map((pair) {
    if (pair[1] == null) return pair[0];
    return "${pair[0]}=${pair[1]}";
  }).join("&");
}

// TODO(nweiz): remove this when issue 9068 has been fixed.
/// Whether [uri1] and [uri2] are equal. This consider HTTP URIs to default to
/// port 80, and HTTPs URIs to default to port 443.
bool urisEqual(Uri uri1, Uri uri2) =>
  canonicalizeUri(uri1) == canonicalizeUri(uri2);

/// Return [uri] with redundant port information removed.
Uri canonicalizeUri(Uri uri) {
  if (uri == null) return null;

  var sansPort = new Uri.fromComponents(
      scheme: uri.scheme, userInfo: uri.userInfo, domain: uri.domain,
      path: uri.path, query: uri.query, fragment: uri.fragment);
  if (uri.scheme == 'http' && uri.port == 80) return sansPort;
  if (uri.scheme == 'https' && uri.port == 443) return sansPort;
  return uri;
}

/// Add all key/value pairs from [source] to [destination], overwriting any
/// pre-existing values.
void mapAddAll(Map destination, Map source) =>
  source.forEach((key, value) => destination[key] = value);

/// Decodes a URL-encoded string. Unlike [decodeUriComponent], this includes
/// replacing `+` with ` `.
String urlDecode(String encoded) =>
  decodeUriComponent(encoded.replaceAll("+", " "));

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
