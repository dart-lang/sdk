// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_version_rpc_lib.dart' as testee_lib;

Future<void> main([args = const <String>[]]) async => await VMTestHarness(
      'get_version_rpc_lib.dart',
      args,
    ).addTest((VmService vm) async {
      final result = await vm.getVersion();
      expect(result.major! > 0, isTrue);
      expect(result.minor! >= 0, isTrue);
    }).run(testeeMain: testee_lib.main);
