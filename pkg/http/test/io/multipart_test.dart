// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http.test.io.multipart_test;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
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
}
