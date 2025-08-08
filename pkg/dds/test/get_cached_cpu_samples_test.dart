// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';
import 'common/test_helper.dart';

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    process = await spawnDartProcess(
      'get_cached_cpu_samples_script.dart',
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test(
    'getAvailableCachedCpuSamples and getCachedCpuSamples are deprecated',
    () async {
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      expect(dds.isRunning, true);
      final service = await vmServiceConnectUri(dds.wsUri.toString());

      // We have deprecated `getAvailableCachedCpuSamples`, so now it always
      // returns an [AvailableCachedCpuSamples] object containing a single
      // property named `cacheNames` with an empty array as its value.
      final availableCachedCpuSamples =
          // ignore: deprecated_member_use
          await service.getAvailableCachedCpuSamples();
      expect(availableCachedCpuSamples.cacheNames.length, 0);

      // We have deprecated `getCachedCpuSamples_, so now it always returns a
      // _CachedCpuSamples_ object containing properties with meaningless
      // placeholder values.
      final cachedCpuSamples =
          // ignore: deprecated_member_use
          await service.getCachedCpuSamples('fake', 'fake');
      expect(cachedCpuSamples.userTag, '');
      expect(cachedCpuSamples.samplePeriod, -1);
      expect(cachedCpuSamples.maxStackDepth, -1);
      expect(cachedCpuSamples.sampleCount, -1);
      expect(cachedCpuSamples.timeOriginMicros, -1);
      expect(cachedCpuSamples.timeExtentMicros, -1);
      expect(cachedCpuSamples.pid, -1);
      expect(cachedCpuSamples.functions!.length, 0);
      expect(cachedCpuSamples.samples!.length, 0);
    },
    timeout: Timeout.none,
  );
}
