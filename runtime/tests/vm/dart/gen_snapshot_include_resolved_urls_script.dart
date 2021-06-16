// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:isolate' as I;

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

int fib(int n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
}

Future<void> main() async {
  // Do some work.
  fib(20);

  ServiceProtocolInfo serviceInfo = await Service.getInfo();
  while (serviceInfo.serverUri == null) {
    await Future.delayed(const Duration(milliseconds: 200));
    serviceInfo = await Service.getInfo();
  }
  final isolateId = Service.getIsolateID(I.Isolate.current)!;
  final uri = serviceInfo.serverUri!.replace(scheme: 'ws', pathSegments: [
    ...serviceInfo.serverUri!.pathSegments.where((e) => e != ''),
    'ws'
  ]);
  final service = await vmServiceConnectUri(uri.toString());
  final timeExtent = Duration(minutes: 5).inMicroseconds;
  final samples = await service.getCpuSamples(isolateId, 0, timeExtent);

  // Cleanup VM service connection as it's no longer needed.
  await service.dispose();

  final functions = samples.functions!.where((f) => f.kind! == 'Dart').toList();
  if (functions.isEmpty) {
    print('FAILED: could not find a profiled Dart function');
    return;
  }

  functions.retainWhere((f) => f.resolvedUrl!.isNotEmpty);
  if (functions.isNotEmpty) {
    print('SUCCESS');
  } else {
    print('FAILED');
  }
}
