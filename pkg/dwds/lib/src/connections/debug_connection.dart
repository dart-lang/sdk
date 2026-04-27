// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dwds/src/services/app_debug_services.dart';
import 'package:dwds/src/services/chrome/chrome_proxy_service.dart';
import 'package:vm_service/vm_service.dart';

/// A debug connection between the application in the browser and DWDS.
///
/// Supports debugging your running application through the Dart VM Service
/// Protocol.
class DebugConnection {
  final AppDebugServices _appDebugServices;
  final _onDoneCompleter = Completer<void>();

  /// Null until [close] is called.
  ///
  /// All subsequent calls to [close] will return this future.
  Future<void>? _closed;

  DebugConnection(this._appDebugServices) {
    // Only setup Chrome-specific close handling if we have a ChromeProxyService
    final proxyService = _appDebugServices.proxyService;
    if (proxyService is ChromeProxyService) {
      proxyService.remoteDebugger.onClose.first.then((_) => close());
    }
  }

  /// The port of the host Dart VM Service.
  int get port => _appDebugServices.debugService.port;

  /// The endpoint of the Dart VM Service.
  String get uri => _appDebugServices.debugService.uri;

  /// The endpoint of the Dart Development Service (DDS).
  String? get ddsUri => _appDebugServices.ddsUri?.toString();

  /// The endpoint of the Dart DevTools instance.
  String? get devToolsUri => _appDebugServices.devToolsUri?.toString();

  /// The endpoint of the Dart Tooling Daemon (DTD).
  String? get dtdUri => _appDebugServices.dtdUri?.toString();

  /// A client of the Dart VM Service with DWDS specific extensions.
  VmService get vmService => _appDebugServices.dwdsVmClient.client;

  Future<void> close() => _closed ??= () async {
    final proxyService = _appDebugServices.proxyService;
    if (proxyService is ChromeProxyService) {
      await proxyService.remoteDebugger.close();
    }
    await _appDebugServices.close();
    _onDoneCompleter.complete();
  }();

  Future<void> get onDone => _onDoneCompleter.future;
}

/// [ChromeProxyService] of a [DebugConnection] for internal use only.
ChromeProxyService fetchChromeProxyService(DebugConnection debugConnection) {
  final service = debugConnection._appDebugServices.proxyService;
  if (service is ChromeProxyService) {
    return service;
  }
  throw StateError('ChromeProxyService not available in this debug connection');
}
