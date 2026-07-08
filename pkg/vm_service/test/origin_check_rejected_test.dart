// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<void> testeeMain(List<String> args) => startServiceTest();

Future<void> main([args = const <String>[]]) async => await VMTestHarness(
      'origin_check_rejected_test.dart',
      args,
    ).addTest((VmService vm) async {
      final uri = Uri.parse(vm.wsUri!);
      await expectLater(
        WebSocket.connect(
          uri.toString(),
          headers: {'Origin': 'http://malicious-unauthorized-site.com'},
        ),
        throwsA(isA<WebSocketException>()),
      );
    }).run(testeeMain: testeeMain, extraArgs: ['--no-dds']);
