// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:io';

import 'common/expect.dart';
import 'common/test_helper.dart';

Future<int> testFunction() async {
  try {
    final client = HttpClient();
    final urlstr = 'https://www.bbc.co.uk/';
    final uri = Uri.parse(urlstr);
    final response = await client.getUrl(uri);
    Expect.equals(urlstr, response.uri.toString());
    await response.close();
    return 0;
  } catch (e) {
    print(e.toString());
    return 1;
  }
}

Future<void> testMain() async {
  debugger();
  final ret = await testFunction();
  Expect.equals(ret, 0);
  print('Done'); // LINE_A
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
