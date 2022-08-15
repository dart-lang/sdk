// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--observe --no-pause-isolates-on-exit

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

main() {
  late VmService service;
  setUp(() async {
    ServiceProtocolInfo serviceInfo = await Service.getInfo();
    // Wait for VM service to publish its connection info.
    while (serviceInfo.serverUri == null) {
      await Future.delayed(Duration(milliseconds: 10));
      serviceInfo = await Service.getInfo();
    }
    service =
        await vmServiceConnectUri(serviceInfo.serverWebSocketUri!.toString());
  });

  tearDown(() => service.dispose());

  test('Check default timeline streams set by --observe', () async {
    final flags = await service.getVMTimelineFlags();
    expect(flags.recordedStreams, containsAll(['Compiler', 'Dart', 'GC']));
  });
}
