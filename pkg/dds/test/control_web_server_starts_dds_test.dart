// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main() {
  HttpClient? client;
  VmService? service;

  tearDown(() async {
    client?.close();
    await service?.dispose();
  });

  test('Enabling the VM service starts DDS and serves DevTools', () async {
    var serviceInfo = await Service.getInfo();
    expect(serviceInfo.serverUri, isNull);

    serviceInfo = await Service.controlWebServer(
      enable: true,
      silenceOutput: true,
    );
    print('VM service started');
    expect(serviceInfo.serverUri, isNotNull);
    final serverWebSocketUri = serviceInfo.serverWebSocketUri!;
    service = await vmServiceConnectUri(
      serverWebSocketUri.toString(),
    );

    // Check that DDS has been launched.
    final supportedProtocols =
        (await service!.getSupportedProtocols()).protocols!;
    expect(supportedProtocols.length, 2);
    expect(supportedProtocols.map((e) => e.protocolName), contains('DDS'));

    // Check that DevTools assets are accessible.
    client = HttpClient();
    final devtoolsRequest = await client!.getUrl(serviceInfo.serverUri!);
    final devtoolsResponse = await devtoolsRequest.close();
    expect(devtoolsResponse.statusCode, 200);
    final devtoolsContent =
        await devtoolsResponse.transform(utf8.decoder).join();
    expect(devtoolsContent, startsWith('<!DOCTYPE html>'));
  });
}
