// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generic utility functions. Stuff that should possibly be in core.
library pub.utils;

import 'dart:async';
import "dart:convert";
import 'dart:io';
@MirrorsUsed(targets: 'pub.io')
import 'dart:mirrors';

import "package:crypto/crypto.dart";
import 'package:path/path.dart' as path;
import "package:stack_trace/stack_trace.dart";

import 'exceptions.dart';
import 'log.dart' as log;

export '../../asset/dart/utils.dart';

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
    }).catchError((e, stackTrace) {
      if (completed) return;

      completed = true;
      _completer.completeError(e, stackTrace);
    }));

    return task;
  }

  Future<List> get future => _completer.future;
}

/// Like [new Future], but avoids around issue 11911 by using [new Future.value]
/// under the covers.
Future newFuture(callback()) => new Future.value().then((_) => callback());

/// Like [new Future.sync], but automatically wraps the future in a
/// [Chain.track] call.
Future syncFuture(callback()) => Chain.track(new Future.sync(callback));

/// Runs [callback] in an error zone and pipes any unhandled error to the
/// returned [Future].
///
/// If the returned [Future] produces an error, its stack trace will always be a
/// [Chain]. By default, this chain will contain only the local stack trace, but
/// if [captureStackChains] is passed, it will contain the full stack chain for
/// the error.
Future captureErrors(Future callback(), {bool captureStackChains: false}) {
  var completer = new Completer();
  var wrappedCallback = () {
    new Future.sync(callback).then(completer.complete)
        .catchError((e, stackTrace) {
      // [stackTrace] can be null if we're running without [captureStackChains],
      // since dart:io will often throw errors without stack traces.
      if (stackTrace != null) {
        stackTrace = new Chain.forTrace(stackTrace);
      } else {
        stackTrace = new Chain([]);
      }
      completer.completeError(e, stackTrace);
    });
  };

  if (captureStackChains) {
    Chain.capture(wrappedCallback, onError: completer.completeError);
  } else {
    runZoned(wrappedCallback, onError: (e, stackTrace) {
      if (stackTrace == null) {
        stackTrace = new Chain.current();
      } else {
        stackTrace = new Chain([new Trace.from(stackTrace)]);
      }
      completer.completeError(e, stackTrace);
    });
  }

  return completer.future;
}

/// Like [Future.wait], but prints all errors from the futures as they occur and
/// only returns once all Futures have completed, successfully or not.
///
/// This will wrap the first error thrown in a [SilentException] and rethrow it.
Future waitAndPrintErrors(Iterable<Future> futures) {
  return Future.wait(futures.map((future) {
    return future.catchError((error, stackTrace) {
      log.exception(error, stackTrace);
      throw error;
    });
  })).catchError((error, stackTrace) {
    throw new SilentException(error, stackTrace);
  });
}

/// Returns a [StreamTransformer] that will call [onDone] when the stream
/// completes.
///
/// The stream will be passed through unchanged.
StreamTransformer onDoneTransformer(void onDone()) {
  return new StreamTransformer.fromHandlers(handleDone: (sink) {
    onDone();
    sink.close();
  });
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

/// Escapes any regex metacharacters in [string] so that using as a [RegExp]
/// pattern will match the string literally.
// TODO(rnystrom): Remove when #4706 is fixed.
String quoteRegExp(String string) {
  // Note: make sure "\" is done first so that we don't escape the other
  // escaped characters. We could do all of the replaces at once with a regexp
  // but string literal for regex that matches all regex metacharacters would
  // be a bit hard to read.
  for (var metacharacter in r"\^$.*+?()[]{}|".split("")) {
    string = string.replaceAll(metacharacter, "\\$metacharacter");
  }

  return string;
}

/// Creates a URL string for [address]:[port].
///
/// Handles properly formatting IPv6 addresses.
Uri baseUrlForAddress(InternetAddress address, int port) {
  if (address.isLoopback) {
    return new Uri(scheme: "http", host: "localhost", port: port);
  }

  // IPv6 addresses in URLs need to be enclosed in square brackets to avoid
  // URL ambiguity with the ":" in the address.
  if (address.type == InternetAddressType.IP_V6) {
    return new Uri(scheme: "http", host: "[${address.address}]", port: port);
  }

  return new Uri(scheme: "http", host: address.address, port: port);
}

/// Returns whether [host] is a host for a localhost or loopback URL.
///
/// Unlike [InternetAddress.isLoopback], this hostnames from URLs as well as
/// from [InternetAddress]es, including "localhost".
bool isLoopback(String host) {
  if (host == 'localhost') return true;

  // IPv6 hosts in URLs are surrounded by square brackets.
  if (host.startsWith("[") && host.endsWith("]")) {
    host = host.substring(1, host.length - 1);
  }

  try {
    return new InternetAddress(host).isLoopback;
  } on ArgumentError catch (_) {
    // The host isn't an IP address and isn't "localhost', so it's almost
    // certainly not a loopback host.
    return false;
  }
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

/// Returns a set containing all elements in [minuend] that are not in
/// [subtrahend].
Set setMinus(Iterable minuend, Iterable subtrahend) {
  var minuendSet = new Set.from(minuend);
  minuendSet.removeAll(subtrahend);
  return minuendSet;
}

/// Returns a list containing the sorted elements of [iter].
List ordered(Iterable<Comparable> iter) {
  var list = iter.toList();
  list.sort();
  return list;
}

/// Returns the element of [iter] for which [f] returns the minimum value.
minBy(Iterable iter, Comparable f(element)) {
  var min = null;
  var minComparable = null;
  for (var element in iter) {
    var comparable = f(element);
    if (minComparable == null ||
        comparable.compareTo(minComparable) < 0) {
      min = element;
      minComparable = comparable;
    }
  }
  return min;
}

/// Returns every pair of consecutive elements in [iter].
///
/// For example, if [iter] is `[1, 2, 3, 4]`, this will return `[(1, 2), (2, 3),
/// (3, 4)]`.
Iterable<Pair> pairs(Iterable iter) {
  var previous = iter.first;
  return iter.skip(1).map((element) {
    var oldPrevious = previous;
    previous = element;
    return new Pair(oldPrevious, element);
  });
}

/// Creates a new map from [map] with new keys and values.
///
/// The return values of [key] are used as the keys and the return values of
/// [value] are used as the values for the new map.
///
/// [key] defaults to returning the original key and [value] defaults to
/// returning the original value.
Map mapMap(Map map, {key(key, value), value(key, value)}) {
  if (key == null) key = (key, _) => key;
  if (value == null) value = (_, value) => value;

  var result = {};
  map.forEach((mapKey, mapValue) {
    result[key(mapKey, mapValue)] = value(mapKey, mapValue);
  });
  return result;
}

/// Like [Map.fromIterable], but [key] and [value] may return [Future]s.
Future<Map> mapFromIterableAsync(Iterable iter, {key(element),
    value(element)}) {
  if (key == null) key = (element) => element;
  if (value == null) value = (element) => element;

  var map = new Map();
  return Future.wait(iter.map((element) {
    return Future.wait([
      syncFuture(() => key(element)),
      syncFuture(() => value(element))
    ]).then((results) {
      map[results[0]] = results[1];
    });
  })).then((_) => map);
}

/// Given a list of filenames, returns a set of patterns that can be used to
/// filter for those filenames.
///
/// For a given path, that path ends with some string in the returned set if
/// and only if that path's basename is in [files].
Set<String> createFileFilter(Iterable<String> files) {
  return files.expand((file) {
    var result = ["/$file"];
    if (Platform.operatingSystem == 'windows') result.add("\\$file");
    return result;
  }).toSet();
}

/// Given a blacklist of directory names, returns a set of patterns that can
/// be used to filter for those directory names.
///
/// For a given path, that path contains some string in the returned set if
/// and only if one of that path's components is in [dirs].
Set<String> createDirectoryFilter(Iterable<String> dirs) {
  return dirs.expand((dir) {
    var result = ["/$dir/"];
    if (Platform.operatingSystem == 'windows') {
      result..add("/$dir\\")..add("\\$dir/")..add("\\$dir\\");
    }
    return result;
  }).toSet();
}

/// Returns the maximum value in [iter] by [compare].
///
/// [compare] defaults to [Comparable.compare].
maxAll(Iterable iter, [int compare(element1, element2)]) {
  if (compare == null) compare = Comparable.compare;
  return iter.reduce((max, element) =>
      compare(element, max) > 0 ? element : max);
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

/// Configures [future] so that its result (success or exception) is passed on
/// to [completer].
void chainToCompleter(Future future, Completer completer) {
  future.then(completer.complete, onError: completer.completeError);
}

/// Ensures that [stream] can emit at least one value successfully (or close
/// without any values).
///
/// For example, reading asynchronously from a non-existent file will return a
/// stream that fails on the first chunk. In order to handle that more
/// gracefully, you may want to check that the stream looks like it's working
/// before you pipe the stream to something else.
///
/// This lets you do that. It returns a [Future] that completes to a [Stream]
/// emitting the same values and errors as [stream], but only if at least one
/// value can be read successfully. If an error occurs before any values are
/// emitted, the returned Future completes to that error.
Future<Stream> validateStream(Stream stream) {
  var completer = new Completer<Stream>();
  var controller = new StreamController(sync: true);

  StreamSubscription subscription;
  subscription = stream.listen((value) {
    // We got a value, so the stream is valid.
    if (!completer.isCompleted) completer.complete(controller.stream);
    controller.add(value);
  }, onError: (error, [stackTrace]) {
    // If the error came after values, it's OK.
    if (completer.isCompleted) {
      controller.addError(error, stackTrace);
      return;
    }

    // Otherwise, the error came first and the stream is invalid.
    completer.completeError(error, stackTrace);

    // We don't be returning the stream at all in this case, so unsubscribe
    // and swallow the error.
    subscription.cancel();
  }, onDone: () {
    // It closed with no errors, so the stream is valid.
    if (!completer.isCompleted) completer.complete(controller.stream);
    controller.close();
  });

  return completer.future;
}

// TODO(nweiz): remove this when issue 7964 is fixed.
/// Returns a [Future] that will complete to the first element of [stream].
///
/// Unlike [Stream.first], this is safe to use with single-subscription streams.
Future streamFirst(Stream stream) {
  var completer = new Completer();
  var subscription;
  subscription = stream.listen((value) {
    subscription.cancel();
    completer.complete(value);
  }, onError: (e, [stackTrace]) {
    completer.completeError(e, stackTrace);
  }, onDone: () {
    completer.completeError(new StateError("No elements"), new Chain.current());
  }, cancelOnError: true);
  return completer.future;
}

/// Returns a wrapped version of [stream] along with a [StreamSubscription] that
/// can be used to control the wrapped stream.
Pair<Stream, StreamSubscription> streamWithSubscription(Stream stream) {
  var controller =
      stream.isBroadcast ? new StreamController.broadcast(sync: true)
                         : new StreamController(sync: true);
  var subscription = stream.listen(controller.add,
      onError: controller.addError,
      onDone: controller.close);
  return new Pair<Stream, StreamSubscription>(controller.stream, subscription);
}

// TODO(nweiz): remove this when issue 7787 is fixed.
/// Creates two single-subscription [Stream]s that each emit all values and
/// errors from [stream].
///
/// This is useful if [stream] is single-subscription but multiple subscribers
/// are necessary.
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

/// Merges [stream1] and [stream2] into a single stream that emits events from
/// both sources.
Stream mergeStreams(Stream stream1, Stream stream2) {
  var doneCount = 0;
  var controller = new StreamController(sync: true);

  for (var stream in [stream1, stream2]) {
    stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
      doneCount++;
      if (doneCount == 2) controller.close();
    });
  }

  return controller.stream;
}

/// A regular expression matching a trailing CR character.
final _trailingCR = new RegExp(r"\r$");

// TODO(nweiz): Use `text.split(new RegExp("\r\n?|\n\r?"))` when issue 9360 is
// fixed.
/// Splits [text] on its line breaks in a Windows-line-break-friendly way.
List<String> splitLines(String text) =>
  text.split("\n").map((line) => line.replaceFirst(_trailingCR, "")).toList();

/// Converts a stream of arbitrarily chunked strings into a line-by-line stream.
///
/// The lines don't include line termination characters. A single trailing
/// newline is ignored.
Stream<String> streamToLines(Stream<String> stream) {
  var buffer = new StringBuffer();
  return stream.transform(new StreamTransformer.fromHandlers(
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
///
/// This always returns an array of two elements or fewer.
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
  queryMap.addAll(parameters);
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
    key = Uri.encodeQueryComponent(key);
    value = (value == null || value.isEmpty)
       ? null : Uri.encodeQueryComponent(value);
    pairs.add([key, value]);
  });
  return pairs.map((pair) {
    if (pair[1] == null) return pair[0];
    return "${pair[0]}=${pair[1]}";
  }).join("&");
}

/// Returns the union of all elements in each set in [sets].
Set unionAll(Iterable<Set> sets) =>
  sets.fold(new Set(), (union, set) => union.union(set));

// TODO(nweiz): remove this when issue 9068 has been fixed.
/// Whether [uri1] and [uri2] are equal.
///
/// This consider HTTP URIs to default to port 80, and HTTPs URIs to default to
/// port 443.
bool urisEqual(Uri uri1, Uri uri2) =>
  canonicalizeUri(uri1) == canonicalizeUri(uri2);

/// Return [uri] with redundant port information removed.
Uri canonicalizeUri(Uri uri) {
  return uri;
}

/// Returns a human-friendly representation of [inputPath].
///
/// If [inputPath] isn't too distant from the current working directory, this
/// will return the relative path to it. Otherwise, it will return the absolute
/// path.
String nicePath(String inputPath) {
  var relative = path.relative(inputPath);
  var split = path.split(relative);
  if (split.length > 1 && split[0] == '..' && split[1] == '..') {
    return path.absolute(inputPath);
  }
  return relative;
}

/// Returns a human-friendly representation of [duration].
String niceDuration(Duration duration) {
  var result = duration.inMinutes > 0 ? "${duration.inMinutes}:" : "";

  var s = duration.inSeconds % 59;
  var ms = (duration.inMilliseconds % 1000) ~/ 100;
  return result + "$s.${ms}s";
}

/// Decodes a URL-encoded string.
///
/// Unlike [Uri.decodeComponent], this includes replacing `+` with ` `.
String urlDecode(String encoded) =>
  Uri.decodeComponent(encoded.replaceAll("+", " "));

/// Takes a simple data structure (composed of [Map]s, [Iterable]s, scalar
/// objects, and [Future]s) and recursively resolves all the [Future]s contained
/// within.
///
/// Completes with the fully resolved structure.
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

/// Returns the path to the library named [libraryName].
///
/// The library name must be globally unique, or the wrong library path may be
/// returned. Any libraries accessed must be added to the [MirrorsUsed]
/// declaration in the import above.
String libraryPath(String libraryName) {
  var lib = currentMirrorSystem().findLibrary(new Symbol(libraryName));
  return path.fromUri(lib.uri);
}

/// Whether "special" strings such as Unicode characters or color escapes are
/// safe to use.
///
/// On Windows or when not printing to a terminal, only printable ASCII
/// characters should be used.
bool get canUseSpecialChars => !runningAsTest &&
    Platform.operatingSystem != 'windows' &&
    stdioType(stdout) == StdioType.TERMINAL;

/// Gets a "special" string (ANSI escape or Unicode).
///
/// On Windows or when not printing to a terminal, returns something else since
/// those aren't supported.
String getSpecial(String special, [String onWindows = '']) =>
    canUseSpecialChars ? special : onWindows;

/// Prepends each line in [text] with [prefix].
///
/// If [firstPrefix] is passed, the first line is prefixed with that instead.
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

/// Whether pub is running as a subprocess in an integration test or in a unit
/// test that has explicitly set this.
bool runningAsTest = Platform.environment.containsKey('_PUB_TESTING');

/// Whether today is April Fools' day.
bool get isAprilFools {
  // Tests should never see April Fools' output.
  if (runningAsTest) return false;

  var date = new DateTime.now();
  return date.month == 4 && date.day == 1;
}

/// Wraps [fn] to guard against several different kinds of stack overflow
/// exceptions:
///
/// * A sufficiently long [Future] chain can cause a stack overflow if there are
///   no asynchronous operations in it (issue 9583).
/// * A recursive function that recurses too deeply without an asynchronous
///   operation can cause a stack overflow.
/// * Even if the former is guarded against by adding asynchronous operations,
///   returning a value through the [Future] chain can still cause a stack
///   overflow.
Future resetStack(fn()) {
  // Using a [Completer] breaks the [Future] chain for the return value and
  // avoids the third case described above.
  var completer = new Completer();

  // Using [new Future] adds an asynchronous operation that works around the
  // first and second cases described above.
  newFuture(fn).then((val) {
    scheduleMicrotask(() => completer.complete(val));
  }).catchError((err, stackTrace) {
    scheduleMicrotask(() => completer.completeError(err, stackTrace));
  });
  return completer.future;
}

/// The subset of strings that don't need quoting in YAML.
///
/// This pattern does not strictly follow the plain scalar grammar of YAML,
/// which means some strings may be unnecessarily quoted, but it's much simpler.
final _unquotableYamlString = new RegExp(r"^[a-zA-Z_-][a-zA-Z_0-9-]*$");

/// Converts [data], which is a parsed YAML object, to a pretty-printed string,
/// using indentation for maps.
String yamlToString(data) {
  var buffer = new StringBuffer();

  _stringify(bool isMapValue, String indent, data) {
    // TODO(nweiz): Serialize using the YAML library once it supports
    // serialization.

    // Use indentation for (non-empty) maps.
    if (data is Map && !data.isEmpty) {
      if (isMapValue) {
        buffer.writeln();
        indent += '  ';
      }

      // Sort the keys. This minimizes deltas in diffs.
      var keys = data.keys.toList();
      keys.sort((a, b) => a.toString().compareTo(b.toString()));

      var first = true;
      for (var key in keys) {
        if (!first) buffer.writeln();
        first = false;

        var keyString = key;
        if (key is! String || !_unquotableYamlString.hasMatch(key)) {
          keyString = JSON.encode(key);
        }

        buffer.write('$indent$keyString:');
        _stringify(true, indent, data[key]);
      }

      return;
    }

    // Everything else we just stringify using JSON to handle escapes in
    // strings and number formatting.
    var string = data;

    // Don't quote plain strings if not needed.
    if (data is! String || !_unquotableYamlString.hasMatch(data)) {
      string = JSON.encode(data);
    }

    if (isMapValue) {
      buffer.write(' $string');
    } else {
      buffer.write('$indent$string');
    }
  }

  _stringify(false, '', data);
  return buffer.toString();
}

/// Throw a [ApplicationException] with [message].
void fail(String message, [innerError, StackTrace innerTrace]) {
  if (innerError != null) {
    throw new WrappedException(message, innerError, innerTrace);
  } else {
    throw new ApplicationException(message);
  }
}

/// Throw a [DataException] with [message] to indicate that the command has
/// failed because of invalid input data.
///
/// This will report the error and cause pub to exit with [exit_codes.DATA].
void dataError(String message) => throw new DataException(message);
