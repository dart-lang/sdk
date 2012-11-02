// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:io';
import 'dart:isolate';
import 'dart:scalarlist';
import 'dart:uri';

/// Converts a URL query string (or `application/x-www-form-urlencoded` body)
/// into a [Map] from parameter names to values.
///
///     queryToMap("foo=bar&baz=bang&qux");
///     //=> {"foo": "bar", "baz": "bang", "qux": ""}
Map<String, String> queryToMap(String queryList) {
  var map = <String>{};
  for (var pair in queryList.split("&")) {
    var split = split1(pair, "=");
    if (split.isEmpty) continue;
    var key = urlDecode(split[0]);
    var value = urlDecode(split.length > 1 ? split[1] : "");
    map[key] = value;
  }
  return map;
}

/// Converts a [Map] from parameter names to values to a URL query string.
///
///     mapToQuery({"foo": "bar", "baz": "bang"});
///     //=> "foo=bar&baz=bang"
String mapToQuery(Map<String, String> map) {
  var pairs = <List<String>>[];
  map.forEach((key, value) =>
      pairs.add([encodeUriComponent(key), encodeUriComponent(value)]));
  return Strings.join(pairs.map((pair) => "${pair[0]}=${pair[1]}"), "&");
}

/// Adds all key/value pairs from [source] to [destination], overwriting any
/// pre-existing values.
///
///     var a = {"foo": "bar", "baz": "bang"};
///     mapAddAll(a, {"baz": "zap", "qux": "quux"});
///     a; //=> {"foo": "bar", "baz": "zap", "qux": "quux"}
void mapAddAll(Map destination, Map source) =>
  source.forEach((key, value) => destination[key] = value);

/// Decodes a URL-encoded string. Unlike [decodeUriComponent], this includes
/// replacing `+` with ` `.
String urlDecode(String encoded) =>
  decodeUriComponent(encoded.replaceAll("+", " "));

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

/// Returns the [Encoding] that corresponds to [charset]. Returns
/// [Encoding.ISO_8859_1] if [charset] is null or if no [Encoding] was found
/// that corresponds to [charset].
Encoding encodingForCharset(String charset) {
  if (charset == null) return Encoding.ISO_8859_1;
  var encoding = _encodingForCharset(charset);
  return encoding == null ? Encoding.ISO_8859_1 : encoding;
}

/// Returns the [Encoding] that corresponds to [charset]. Throws a [FormatException]
/// if no [Encoding] was found that corresponds to [charset]. [charset] may not
/// be null.
Encoding requiredEncodingForCharset(String charset) {
  var encoding = _encodingForCharset(charset);
  if (encoding != null) return encoding;
  throw new FormatException('Unsupported encoding "$charset".');
}

/// Returns the [Encoding] that corresponds to [charset]. Returns null if no
/// [Encoding] was found that corresponds to [charset]. [charset] may not be
/// null.
Encoding _encodingForCharset(String charset) {
  charset = charset.toLowerCase();
  if (charset == 'ascii' || charset == 'us-ascii') return Encoding.ASCII;
  if (charset == 'utf-8') return Encoding.UTF_8;
  if (charset == 'iso-8859-1') return Encoding.ISO_8859_1;
  return null;
}

/// Converts [bytes] into a [String] according to [encoding].
String decodeString(List<int> bytes, Encoding encoding) {
  // TODO(nweiz): implement this once issue 6284 is fixed.
  return new String.fromCharCodes(bytes);
}

/// Converts [string] into a byte array according to [encoding].
List<int> encodeString(String string, Encoding encoding) {
  // TODO(nweiz): implement this once issue 6284 is fixed.
  return string.charCodes;
}

/// Converts [input] into a [Uint8List]. If [input] is a [ByteArray] or
/// [ByteArrayViewable], this just returns a view on [input].
Uint8List toUint8List(List<int> input) {
  if (input is Uint8List) return input;
  if (input is ByteArrayViewable) input = input.asByteArray();
  if (input is ByteArray) return new Uint8List.view(input);
  var output = new Uint8List(input.length);
  output.setRange(0, input.length, input);
  return output;
}

/// Buffers all input from an InputStream and returns it as a future.
Future<List<int>> consumeInputStream(InputStream stream) {
  var completer = new Completer<List<int>>();
  /// TODO(nweiz): use BufferList when issue 6409 is fixed
  var buffer = <int>[];
  stream.onClosed = () => completer.complete(buffer);
  stream.onData = () => buffer.addAll(stream.read());
  stream.onError = completer.completeException;
  return completer.future;
}

/// Takes all input from [source] and writes it to [sink].
void pipeInputToInput(InputStream source, ListInputStream sink) {
  source.onClosed = () => sink.markEndOfStream();
  source.onData = () => sink.write(source.read());
  // TODO(nweiz): propagate source errors to the sink. See issue 3657.
}

/// Returns a [Future] that asynchronously completes to `null`.
Future get async {
  var completer = new Completer();
  new Timer(0, (_) => completer.complete(null));
  return completer.future;
}
