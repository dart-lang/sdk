// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'byte_stream.dart';

/// Converts a URL query string (or `application/x-www-form-urlencoded` body)
/// into a [Map] from parameter names to values.
///
///     queryToMap("foo=bar&baz=bang&qux");
///     //=> {"foo": "bar", "baz": "bang", "qux": ""}
Map<String, String> queryToMap(String queryList, {Encoding encoding}) {
  var map = {};
  for (var pair in queryList.split("&")) {
    var split = split1(pair, "=");
    if (split.isEmpty) continue;
    var key = Uri.decodeQueryComponent(split[0], decode: encoding.decode);
    var value = Uri.decodeQueryComponent(split.length > 1 ? split[1] : "",
        decode: encoding.decode);
    map[key] = value;
  }
  return map;
}

/// Converts a [Map] from parameter names to values to a URL query string.
///
///     mapToQuery({"foo": "bar", "baz": "bang"});
///     //=> "foo=bar&baz=bang"
String mapToQuery(Map<String, String> map, {Encoding encoding}) {
  var pairs = <List<String>>[];
  map.forEach((key, value) =>
      pairs.add([urlEncode(key, encoding: encoding),
                 urlEncode(value, encoding: encoding)]));
  return pairs.map((pair) => "${pair[0]}=${pair[1]}").join("&");
}

// TODO(nweiz): get rid of this when issue 12780 is fixed.
/// URL-encodes [source] using [encoding].
String urlEncode(String source, {Encoding encoding}) {
  if (encoding == null) encoding = UTF8;
  return encoding.encode(source).map((byte) {
    // Convert spaces to +, like encodeQueryComponent.
    if (byte == 0x20) return '+';
    // Pass through digits.
    if ((byte >= 0x30 && byte < 0x3A) ||
        // Pass through uppercase letters.
        (byte >= 0x41 && byte < 0x5B) ||
        // Pass through lowercase letters.
        (byte >= 0x61 && byte < 0x7B) ||
        // Pass through `-._~`.
        (byte == 0x2D || byte == 0x2E || byte == 0x5F || byte == 0x7E)) {
      return new String.fromCharCode(byte);
    }
    return '%' + byte.toRadixString(16).toUpperCase();
  }).join();
}

/// Like [String.split], but only splits on the first occurrence of the pattern.
/// This will always return an array of two elements or fewer.
///
///     split1("foo,bar,baz", ","); //=> ["foo", "bar,baz"]
///     split1("foo", ","); //=> ["foo"]
///     split1("", ","); //=> []
List<String> split1(String toSplit, String pattern) {
  if (toSplit.isEmpty) return <String>[];

  var index = toSplit.indexOf(pattern);
  if (index == -1) return [toSplit];
  return [
    toSplit.substring(0, index),
    toSplit.substring(index + pattern.length)
  ];
}

/// Returns the [Encoding] that corresponds to [charset]. Returns [fallback] if
/// [charset] is null or if no [Encoding] was found that corresponds to
/// [charset].
Encoding encodingForCharset(
    String charset, [Encoding fallback = LATIN1]) {
  if (charset == null) return fallback;
  var encoding = Encoding.getByName(charset);
  return encoding == null ? fallback : encoding;
}


/// Returns the [Encoding] that corresponds to [charset]. Throws a
/// [FormatException] if no [Encoding] was found that corresponds to [charset].
/// [charset] may not be null.
Encoding requiredEncodingForCharset(String charset) {
  var encoding = Encoding.getByName(charset);
  if (encoding != null) return encoding;
  throw new FormatException('Unsupported encoding "$charset".');
}

/// A regular expression that matches strings that are composed entirely of
/// ASCII-compatible characters.
final RegExp _ASCII_ONLY = new RegExp(r"^[\x00-\x7F]+$");

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
bool isPlainAscii(String string) => _ASCII_ONLY.hasMatch(string);

/// Converts [input] into a [Uint8List]. If [input] is a [TypedData], this just
/// returns a view on [input].
Uint8List toUint8List(List<int> input) {
  if (input is Uint8List) return input;
  if (input is TypedData) {
    // TODO(nweiz): remove this "as" check when issue 11080 is fixed.
    return new Uint8List.view((input as TypedData).buffer);
  }
  var output = new Uint8List(input.length);
  output.setRange(0, input.length, input);
  return output;
}

/// If [stream] is already a [ByteStream], returns it. Otherwise, wraps it in a
/// [ByteStream].
ByteStream toByteStream(Stream<List<int>> stream) {
  if (stream is ByteStream) return stream;
  return new ByteStream(stream);
}

/// Calls [onDone] once [stream] (a single-subscription [Stream]) is finished.
/// The return value, also a single-subscription [Stream] should be used in
/// place of [stream] after calling this method.
Stream onDone(Stream stream, void onDone()) {
  var pair = tee(stream);
  pair.first.listen((_) {}, onError: (_) {}, onDone: onDone);
  return pair.last;
}

// TODO(nweiz): remove this when issue 7786 is fixed.
/// Pipes all data and errors from [stream] into [sink]. When [stream] is done,
/// [sink] is closed and the returned [Future] is completed.
Future store(Stream stream, EventSink sink) {
  var completer = new Completer();
  stream.listen(sink.add,
      onError: sink.addError,
      onDone: () {
        sink.close();
        completer.complete();
      });
  return completer.future;
}

/// Pipes all data and errors from [stream] into [sink]. Completes [Future] once
/// [stream] is done. Unlike [store], [sink] remains open after [stream] is
/// done.
Future writeStreamToSink(Stream stream, EventSink sink) {
  var completer = new Completer();
  stream.listen(sink.add,
      onError: sink.addError,
      onDone: () => completer.complete());
  return completer.future;
}

/// Returns a [Future] that asynchronously completes to `null`.
Future get async => new Future.value();

/// Returns a closed [Stream] with no elements.
Stream get emptyStream => streamFromIterable([]);

/// Creates a single-subscription stream that emits the items in [iter] and then
/// ends.
Stream streamFromIterable(Iterable iter) {
  var controller = new StreamController(sync: true);
  iter.forEach(controller.add);
  controller.close();
  return controller.stream;
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
  }, onError: (error) {
    controller1.addError(error);
    controller2.addError(error);
  }, onDone: () {
    controller1.close();
    controller2.close();
  });
  return new Pair<Stream, Stream>(controller1.stream, controller2.stream);
}

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
  future.then((v) => completer.complete(v)).catchError((error) {
    completer.completeError(error);
  });
}

// TOOD(nweiz): Get rid of this once https://codereview.chromium.org/11293132/
// is in.
/// Runs [fn] for each element in [input] in order, moving to the next element
/// only when the [Future] returned by [fn] completes. Returns a [Future] that
/// completes when all elements have been processed.
///
/// The return values of all [Future]s are discarded. Any errors will cause the
/// iteration to stop and will be piped through the return value.
Future forEachFuture(Iterable input, Future fn(element)) {
  var iterator = input.iterator;
  Future nextElement(_) {
    if (!iterator.moveNext()) return new Future.value();
    return fn(iterator.current).then(nextElement);
  }
  return nextElement(null);
}
