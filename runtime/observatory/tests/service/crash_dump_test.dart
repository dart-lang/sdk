// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library crash_dump_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:observatory/service_io.dart';

import 'test_helper.dart';

Future warmup() async {
  print('hi');
}

var tests = [
  (VM vm) async {
    HttpClient client = new HttpClient();
    print('Requesting uri ${serviceHttpAddress}/_getCrashDump');
    var request =
        await client.getUrl(Uri.parse('$serviceHttpAddress/_getCrashDump'));
    var response = await request.close();
    print('Received response');
    Completer completer = new Completer();
    StringBuffer sb = new StringBuffer();
    response.transform(UTF8.decoder).listen((chunk) {
      sb.write(chunk);
    }, onDone: () => completer.complete(sb.toString()));
    var responseString = await completer.future;
    JSON.decode(responseString);
  }
];

main(args) async => runVMTests(args, tests, testeeBefore: warmup);
