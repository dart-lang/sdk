// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_utils;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:unittest/unittest.dart';

/// A dummy URL for constructing requests that won't be sent.
Uri get dummyUrl => Uri.parse('http://dartlang.org/');

/// Removes eight spaces of leading indentation from a multiline string.
///
/// Note that this is very sensitive to how the literals are styled. They should
/// be:
///     '''
///     Text starts on own line. Lines up with subsequent lines.
///     Lines are indented exactly 8 characters from the left margin.
///     Close is on the same line.'''
///
/// This does nothing if text is only a single line.
// TODO(nweiz): Make this auto-detect the indentation level from the first
// non-whitespace line.
String cleanUpLiteral(String text) {
  var lines = text.split('\n');
  if (lines.length <= 1) return text;

  for (var j = 0; j < lines.length; j++) {
    if (lines[j].length > 8) {
      lines[j] = lines[j].substring(8, lines[j].length);
    } else {
      lines[j] = '';
    }
  }

  return lines.join('\n');
}

/// A matcher that matches JSON that parses to a value that matches the inner
/// matcher.
Matcher parse(matcher) => new _Parse(matcher);

class _Parse extends Matcher {
  final Matcher _matcher;

  _Parse(this._matcher);

  bool matches(item, Map matchState) {
    if (item is! String) return false;

    var parsed;
    try {
      parsed = JSON.decode(item);
    } catch (e) {
      return false;
    }

    return _matcher.matches(parsed, matchState);
  }

  Description describe(Description description) {
    return description.add('parses to a value that ')
      .addDescriptionOf(_matcher);
  }
}

/// A matcher that validates the body of a multipart request after finalization.
/// The string "{{boundary}}" in [pattern] will be replaced by the boundary
/// string for the request, and LF newlines will be replaced with CRLF.
/// Indentation will be normalized.
Matcher bodyMatches(String pattern) => new _BodyMatches(pattern);

class _BodyMatches extends Matcher {
  final String _pattern;

  _BodyMatches(this._pattern);

  bool matches(item, Map matchState) {
    if (item is! http.MultipartRequest) return false;

    var future = item.finalize().toBytes().then((bodyBytes) {
      var body = UTF8.decode(bodyBytes);
      var contentType = new MediaType.parse(item.headers['content-type']);
      var boundary = contentType.parameters['boundary'];
      var expected = cleanUpLiteral(_pattern)
          .replaceAll("\n", "\r\n")
          .replaceAll("{{boundary}}", boundary);

      expect(body, equals(expected));
      expect(item.contentLength, equals(bodyBytes.length));
    });

    return completes.matches(future, matchState);
  }

  Description describe(Description description) {
    return description.add('has a body that matches "$_pattern"');
  }
}

/// A matcher that matches a [http.ClientException] with the given [message].
///
/// [message] can be a String or a [Matcher].
Matcher isClientException(message) => predicate((error) {
  expect(error, new isInstanceOf<http.ClientException>());
  expect(error.message, message);
  return true;
});

/// A matcher that matches function or future that throws a
/// [http.ClientException] with the given [message].
///
/// [message] can be a String or a [Matcher].
Matcher throwsClientException(message) => throwsA(isClientException(message));
