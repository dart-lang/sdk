// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';
import 'dart:isolate';

import "package:crypto/crypto.dart";

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
            ? null
            : Uri.encodeQueryComponent(value);
    pairs.add([key, value]);
  });
  return pairs.map((pair) {
    if (pair[1] == null) return pair[0];
    return "${pair[0]}=${pair[1]}";
  }).join("&");
}

/// Decode a URL-encoded string. Unlike [Uri.decodeComponent], this includes
/// replacing `+` with ` `.
String urlDecode(String encoded) =>
  Uri.decodeComponent(encoded.replaceAll("+", " "));

/// Like [String.split], but only splits on the first occurrence of the pattern.
/// This will always return a list of two elements or fewer.
List<String> split1(String toSplit, String pattern) {
  if (toSplit.isEmpty) return <String>[];

  var index = toSplit.indexOf(pattern);
  if (index == -1) return [toSplit];
  return [toSplit.substring(0, index),
      toSplit.substring(index + pattern.length)];
}

/// A WWW-Authenticate header value, parsed as per [RFC 2617][].
///
/// [RFC 2617]: http://tools.ietf.org/html/rfc2617
class AuthenticateHeader {
  final String scheme;
  final Map<String, String> parameters;

  AuthenticateHeader(this.scheme, this.parameters);

  /// Parses a header string. Throws a [FormatException] if the header is
  /// invalid.
  factory AuthenticateHeader.parse(String header) {
    var split = split1(header, ' ');
    if (split.length == 0) {
      throw new FormatException('Invalid WWW-Authenticate header: "$header"');
    } else if (split.length == 1 || split[1].trim().isEmpty) {
      return new AuthenticateHeader(split[0].toLowerCase(), {});
    }
    var scheme = split[0].toLowerCase();
    var paramString = split[1];

    // From http://www.w3.org/Protocols/rfc2616/rfc2616-sec2.html.
    var tokenChar = r'[^\0-\x1F()<>@,;:\\"/\[\]?={} \t\x7F]';
    var quotedStringChar = r'(?:[^\0-\x1F\x7F"]|\\.)';
    var regexp = new RegExp('^ *($tokenChar+)="($quotedStringChar*)" *(, *)?');

    var parameters = {};
    var match;
    do {
      match = regexp.firstMatch(paramString);
      if (match == null) {
        throw new FormatException('Invalid WWW-Authenticate header: "$header"');
      }

      paramString = paramString.substring(match.end);
      parameters[match.group(1).toLowerCase()] = match.group(2);
    } while (match.group(3) != null);

    if (!paramString.trim().isEmpty) {
      throw new FormatException('Invalid WWW-Authenticate header: "$header"');
    }

    return new AuthenticateHeader(scheme, parameters);
  }
}

/// Returns a [Future] that asynchronously completes to `null`.
Future get async => new Future.delayed(const Duration(milliseconds: 0),
                                       () => null);
