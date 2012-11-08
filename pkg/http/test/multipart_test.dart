// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multipart_test;

import 'dart:io';
import 'dart:utf';

// TODO(nweiz): get rid of this import before packaging this
import '../../../tests/utils/test_utils.dart';
// TODO(nweiz): make these package: imports
import '../../unittest/lib/unittest.dart';
import '../lib/http.dart' as http;
import '../lib/src/utils.dart';

import 'utils.dart';

/// A matcher that validates the body of a multipart request after finalization.
/// The string "{{boundary}}" in [pattern] will be replaced by the boundary
/// string for the request, and LF newlines will be replaced with CRLF.
/// Indentation will be normalized.
Matcher bodyMatches(String pattern) => new _BodyMatches(pattern);

class _BodyMatches extends BaseMatcher {
  final String _pattern;

  _BodyMatches(this._pattern);

  bool matches(item, MatchState matchState) {
    if (item is! http.MultipartRequest) return false;

    var future = consumeInputStream(item.finalize()).transform((bodyBytes) {
      var body = decodeUtf8(bodyBytes);
      var contentType = new ContentType.fromString(
          item.headers['content-type']);
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

void main() {
  test('empty', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    expect(request, bodyMatches('''
        --{{boundary}}--
        '''));
  });

  test('with fields and files', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    request.fields['field1'] = 'value1';
    request.fields['field2'] = 'value2';
    request.files.add(new http.MultipartFile.fromString("file1", "contents1",
        filename: "filename1.txt"));
    request.files.add(new http.MultipartFile.fromString("file2", "contents2"));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-disposition: form-data; name="field1"

        value1
        --{{boundary}}
        content-disposition: form-data; name="field2"

        value2
        --{{boundary}}
        content-type: text/plain; charset=UTF-8
        content-disposition: form-data; name="file1"; filename="filename1.txt"

        contents1
        --{{boundary}}
        content-type: text/plain; charset=UTF-8
        content-disposition: form-data; name="file2"

        contents2
        --{{boundary}}--
        '''));
  });

  test('with a unicode field name', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    request.fields['fïēld'] = 'value';

    expect(request, bodyMatches('''
        --{{boundary}}
        content-disposition: form-data; name="f%C3%AF%C4%93ld"

        value
        --{{boundary}}--
        '''));
  });

  test('with a unicode field value', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    request.fields['field'] = 'vⱥlūe';

    expect(request, bodyMatches('''
        --{{boundary}}
        content-disposition: form-data; name="field"
        content-type: text/plain; charset=UTF-8

        vⱥlūe
        --{{boundary}}--
        '''));
  });

  test('with a unicode filename', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    request.files.add(new http.MultipartFile.fromString('file', 'contents',
        filename: 'fïlēname.txt'));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: text/plain; charset=UTF-8
        content-disposition: form-data; name="file"; filename="f%C3%AFl%C4%93name.txt"

        contents
        --{{boundary}}--
        '''));
  });

  test('with a string file with a content-type but no charset', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    var file = new http.MultipartFile.fromString('file', '{"hello": "world"}',
        contentType: new ContentType('application', 'json'));
    request.files.add(file);

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/json; charset=UTF-8
        content-disposition: form-data; name="file"

        {"hello": "world"}
        --{{boundary}}--
        '''));
  });

  // TODO(nweiz): test creating a multipart file with a charset other than UTF-8
  // once issue 6284 is fixed.

  // TODO(nweiz): test creating a string with a unicode body once issue 6284 is
  // fixed.

  test('with a stream file', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    var stream = new ListInputStream();
    request.files.add(new http.MultipartFile('file', stream, 5));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"

        hello
        --{{boundary}}--
        '''));

    stream.write([104, 101, 108, 108, 111]);
    stream.markEndOfStream();
  });

  test('with an empty stream file', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    var stream = new ListInputStream();
    stream.markEndOfStream();
    request.files.add(new http.MultipartFile('file', stream, 0));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"

        
        --{{boundary}}--
        '''));
  });

  test('with a byte file', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    var file = new http.MultipartFile.fromBytes(
        'file', [104, 101, 108, 108, 111]);
    request.files.add(file);

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"

        hello
        --{{boundary}}--
        '''));
  });
}
