// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'file_service_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('file_service_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      try {
        await service.callServiceExtension(
          'ext.dart.io.setup',
          isolateId: isolateId,
        );
        final result = await service.getOpenFiles(isolateId);
        expect(result.files.length, 2);

        final writing = await service.getOpenFileById(
          isolateId,
          result.files[0].id,
        );
        expect(writing.readBytes, 0);
        expect(writing.readCount, 0);
        expect(writing.writeCount, 3);
        expect(writing.writeBytes, 3);
        expect(writing.lastWriteTime.millisecondsSinceEpoch, greaterThan(0));
        expect(writing.lastReadTime.millisecondsSinceEpoch, 0);

        final reading = await service.getOpenFileById(
          isolateId,
          result.files[1].id,
        );

        expect(reading.readBytes, 5);
        expect(reading.readCount, 5);
        expect(reading.writeCount, 0);
        expect(reading.writeBytes, 0);
        expect(reading.lastWriteTime.millisecondsSinceEpoch, 0);
        expect(reading.lastReadTime.millisecondsSinceEpoch, greaterThan(0));
      } finally {
        await service.callServiceExtension(
          'ext.dart.io.cleanup',
          isolateId: isolateId,
        );
      }
    }).run(testeeMain: testee_lib.main);
