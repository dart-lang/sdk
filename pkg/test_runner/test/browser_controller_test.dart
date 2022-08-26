// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:smith/smith.dart';
import 'package:test_runner/src/browser_controller.dart';
import 'package:test_runner/src/service/web_driver_service.dart';

void main() async {
  final chromePath = Platform.environment['CHROME_PATH'];
  if (chromePath != null) {
    print('Testing Chrome');
    await testChrome(chromePath);
  }
  final firefoxPath = Platform.environment['FIREFOX_PATH'];
  if (firefoxPath != null) {
    print('Testing Firefox');
    await testFirefox(firefoxPath);
  }
  if (Platform.isMacOS) {
    print('Testing Safari');
    await testSafari();
  }
}

Future<void> testChrome(String path) {
  return testBrowser(Chrome(path));
}

Future<void> testFirefox(String path) {
  return testBrowser(Firefox(path));
}

Future<void> testSafari() async {
  var service = await WebDriverService.startServiceForRuntime(Runtime.safari);
  await testBrowser(Safari(service.port));
  service.allDone();
}

Future<void> testBrowser(Browser browser) async {
  browser.debugPrint = true;
  await browser.version;
  await testStartStop(browser);
}

Future<void> testStartStop(Browser browser) async {
  var closed = false;
  try {
    Expect.isTrue(await browser.start('about:blank'));
  } finally {
    closed = await browser.close();
  }
  Expect.isTrue(closed);
}
