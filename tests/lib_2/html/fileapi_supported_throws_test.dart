library fileapi;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';

main() {
  test('requestFileSystem', () async {
    var expectation = FileSystem.supported ? returnsNormally : throws;
    expect(() async {
      await window.requestFileSystem(100);
    }, expectation);
  });
}

