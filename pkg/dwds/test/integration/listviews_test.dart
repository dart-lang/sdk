// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 2))
library;

import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';

void main() {
  final provider = TestSdkConfigurationProvider();
  tearDownAll(provider.dispose);

  final context = TestContext(TestProject.test, provider);

  setUpAll(() async {
    await context.setUp();
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  test('_flutter.listViews', () async {
    final serviceMethod = '_flutter.listViews';
    final service = context.debugConnection.vmService;
    final vm = await service.getVM();
    final isolates = vm.isolates!;

    final expected = <String, Object>{
      'views': <Object>[
        for (final isolate in isolates)
          <String, Object?>{'id': isolate.id, 'isolate': isolate.toJson()},
      ],
    };

    final result = await service.callServiceExtension(serviceMethod, args: {});

    expect(result.json, expected);
  });
}
