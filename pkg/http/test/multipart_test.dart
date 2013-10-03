// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multipart_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import 'utils.dart';

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
      var contentType = ContentType.parse(item.headers['content-type']);
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
        content-type: text/plain; charset=utf-8
        content-disposition: form-data; name="file1"; filename="filename1.txt"

        contents1
        --{{boundary}}
        content-type: text/plain; charset=utf-8
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
        content-type: text/plain; charset=utf-8

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
        content-type: text/plain; charset=utf-8
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
        content-type: application/json; charset=utf-8
        content-disposition: form-data; name="file"

        {"hello": "world"}
        --{{boundary}}--
        '''));
  });

  test('with a file with a iso-8859-1 body', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    // "Ã¥" encoded as ISO-8859-1 and then read as UTF-8 results in "å".
    var file = new http.MultipartFile.fromString('file', 'non-ascii: "Ã¥"',
        contentType: new ContentType('text', 'plain', charset: 'iso-8859-1'));
    request.files.add(file);

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: text/plain; charset=iso-8859-1
        content-disposition: form-data; name="file"

        non-ascii: "å"
        --{{boundary}}--
        '''));
  });

  test('with a stream file', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    var controller = new StreamController(sync: true);
    request.files.add(new http.MultipartFile('file', controller.stream, 5));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"

        hello
        --{{boundary}}--
        '''));

    controller.add([104, 101, 108, 108, 111]);
    controller.close();
  });

  test('with an empty stream file', () {
    var request = new http.MultipartRequest('POST', dummyUrl);
    var controller = new StreamController(sync: true);
    request.files.add(new http.MultipartFile('file', controller.stream, 0));

    expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"


        --{{boundary}}--
        '''));

    controller.close();
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

  group('in a temp directory', () {
    var tempDir;
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('http_test_');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('with a file from disk', () {
      expect(new Future.sync(() {
        var filePath = path.join(tempDir.path, 'test-file');
        new File(filePath).writeAsStringSync('hello');
        return http.MultipartFile.fromPath('file', filePath);
      }).then((file) {
        var request = new http.MultipartRequest('POST', dummyUrl);
        request.files.add(file);

        expect(request, bodyMatches('''
        --{{boundary}}
        content-type: application/octet-stream
        content-disposition: form-data; name="file"; filename="test-file"

        hello
        --{{boundary}}--
        '''));
      }), completes);
    });
  });
}
