library fileapi;

import 'dart:async';
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:async_helper/async_helper.dart';

main() {
  useHtmlConfiguration();

  test('requestFileSystem', () async {
    var expectation = FileSystem.supported ? returnsNormally : throws;
    expect(() async {
      await window.requestFileSystem(100);
    }, expectation);
  });
}

