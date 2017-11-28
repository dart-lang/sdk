// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library filereader_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:typed_data';

main() {
  useHtmlConfiguration();

  test('readAsText', () {
    var reader = new FileReader();
    reader.onLoad.listen(expectAsync((event) {
      var result = reader.result;
      expect(result, equals('hello world'));
    }));
    reader.readAsText(new Blob(['hello ', 'world']));
  });

  test('readAsArrayBuffer', () {
    var reader = new FileReader();
    reader.onLoad.listen(expectAsync((event) {
      var result = reader.result;
      expect(result is Uint8List, isTrue);
      expect(result, orderedEquals([65, 66, 67]));
    }));
    reader.readAsArrayBuffer(new Blob(['ABC']));
  });

  test('readDataUrl', () {
    var reader = new FileReader();
    reader.onLoad.listen(expectAsync((event) {
      String result = reader.result;
      expect(result is String, isTrue);
      expect(result.startsWith('data:'), isTrue);
    }));
    reader.readAsDataUrl(new Blob(['ABC']));
  });
}
