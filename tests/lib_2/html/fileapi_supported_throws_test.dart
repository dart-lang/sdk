library fileapi;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';
import 'package:expect/minitest.dart' as minitest;

main() {
  test('requestFileSystem', () async {
    var expectation = FileSystem.supported ? minitest.returnsNormally : throws;
    minitest.expect(() async {
      await window.requestFileSystem(100);
    }, expectation);
  });
}

