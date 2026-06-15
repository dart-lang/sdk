// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/connections/app_connection.dart';
import 'package:dwds/src/debugging/inspector.dart';
import 'package:dwds/src/debugging/libraries.dart';
import 'package:dwds/src/services/web_socket/web_socket_proxy_service.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:vm_service/vm_service.dart';

/// Provides information about the currently loaded program.
class WebSocketAppInspector extends AppInspector {
  WebSocketAppInspector._(
    super.appConnection,
    super.isolate,
    super.root,
    this._service,
  );

  static Future<WebSocketAppInspector> create(
    WebSocketProxyService service,
    AppConnection appConnection,
    String root,
  ) async {
    final id = createId();
    final time = DateTime.now().millisecondsSinceEpoch;
    final name = 'main()';
    final isolate = Isolate(
      id: id,
      number: id,
      name: name,
      startTime: time,
      runnable: true,
      pauseOnExit: false,
      livePorts: 0,
      libraries: [],
      breakpoints: [],
      isSystemIsolate: false,
      isolateFlags: [],
      extensionRPCs: [],
    );
    final inspector = WebSocketAppInspector._(
      appConnection,
      isolate,
      root,
      service,
    );

    await inspector.initialize();
    return inspector;
  }

  @override
  late final libraryHelper = LibraryHelper(this);

  final WebSocketProxyService _service;

  /// Invokes the `getExtensionRpcs` service extension, which returns the list
  /// of registered extensions.
  ///
  /// Combines this with the RPCs registered in the [isolate]. Use this over
  /// [Isolate.extensionRPCs] as this computes a live set.
  ///
  /// Updates [Isolate.extensionRPCs] to this set.
  @override
  Future<Set<String>> getExtensionRpcs() async {
    final response = await _service.callServiceExtension('getExtensionRpcs');
    final extensionRpcs = (response.json!['rpcs'] as List)
        .cast<String>()
        .toSet();
    isolate.extensionRPCs = List.of(extensionRpcs);
    return extensionRpcs;
  }
}
