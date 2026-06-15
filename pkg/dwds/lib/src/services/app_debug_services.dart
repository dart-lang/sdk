// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/dds_launcher.dart';
import 'package:dwds/src/dwds_vm_client.dart';
import 'package:dwds/src/events.dart';
import 'package:dwds/src/services/debug_service.dart';
import 'package:dwds/src/services/proxy_service.dart';

/// Common interface for debug service containers.
class AppDebugServices<
  T extends DebugService<U>,
  U extends ProxyService,
  V extends DwdsVmClient<U, T>
> {
  final T debugService;
  final V dwdsVmClient;
  final DartDevelopmentServiceLauncher? _dds;
  Uri? get ddsUri => _dds?.wsUri;
  Uri? get devToolsUri => _dds?.devToolsUri;
  Uri? get dtdUri => _dds?.dtdUri;
  final DwdsStats? dwdsStats;
  String? connectedInstanceId;

  Future<void>? _closed;

  AppDebugServices({
    required this.debugService,
    required this.dwdsVmClient,
    required this._dds,
    this.dwdsStats,
  });

  ProxyService get proxyService => debugService.proxyService;

  Future<void> close() {
    return _closed ??= Future.wait([
      debugService.close(),
      dwdsVmClient.close(),
    ]);
  }
}
