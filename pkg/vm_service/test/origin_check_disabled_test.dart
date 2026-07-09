// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--disable-service-origin-check

import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<void> testeeMain(List<String> args) => startServiceTest();

Future<void> main([args = const <String>[]]) async => await VMTestHarness(
      'origin_check_disabled_test.dart',
      args,
    ).addTest((VmService vm) async {
      final uri = Uri.parse(vm.wsUri!);
      final ws = await WebSocket.connect(
        uri.toString(),
        headers: {'Origin': 'http://malicious-unauthorized-site.com'},
      );
      expect(ws.readyState, equals(WebSocket.open));
      await ws.close();
    }).run(testeeMain: testeeMain, extraArgs: ['--no-dds']);
