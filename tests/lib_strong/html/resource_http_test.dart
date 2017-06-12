// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library resource_http_test;

import 'dart:async';
import 'package:unittest/html_individual_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useHtmlIndividualConfiguration();
  // Cache blocker is a workaround for:
  // https://code.google.com/p/dart/issues/detail?id=11834
  var cacheBlocker = new DateTime.now().millisecondsSinceEpoch;
  var url = '/root_dart/tests/html/resource_data.txt?cacheBlock=$cacheBlocker';

  void validateResponse(data) {
    expect(data, equals('This file was read by a Resource!'));
  }

  group('resource', () {
    test('readAsString', () async {
      Resource r = new Resource(url);
      var data = await r.readAsString();
      validateResponse(data);
    });
    test('readAsBytes', () async {
      Resource r = new Resource(url);
      var data = await r.readAsBytes();
      validateResponse(new String.fromCharCodes(data));
    });
    test('openRead', () async {
      Resource r = new Resource(url);
      var bytes = [];
      await for (var b in r.openRead()) {
        bytes.addAll(b);
      }
      validateResponse(new String.fromCharCodes(bytes));
    });
  });
}
