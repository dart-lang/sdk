// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:uri';
import 'dart:isolate';
import 'dart:crypto';

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
  var map = <String>{};
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

/// Decode a URL-encoded string. Unlike [decodeUriComponent], this includes
/// replacing `+` with ` `.
String urlDecode(String encoded) =>
  decodeUriComponent(encoded.replaceAll("+", " "));

/// Like [String.split], but only splits on the first occurrence of the pattern.
/// This will always return a list of two elements or fewer.
List<String> split1(String toSplit, String pattern) {
  if (toSplit.isEmpty) return <String>[];

  var index = toSplit.indexOf(pattern);
  if (index == -1) return [toSplit];
  return [toSplit.substring(0, index),
      toSplit.substring(index + pattern.length)];
}

/// Returns a [Future] that asynchronously completes to `null`.
Future get async {
  var completer = new Completer();
  new Timer(0, (_) => completer.complete(null));
  return completer.future;
}
