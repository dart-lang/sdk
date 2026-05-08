// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart'
    as protocol;
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

class FakeChannel implements PluginCommunicationChannel {
  final _completers = <String, Completer<protocol.Response>>{};

  final StreamController<protocol.Notification> _notificationsController =
      StreamController();

  void Function(protocol.Request)? _onRequest;

  int _idCounter = 0;

  Stream<protocol.Notification> get notifications =>
      _notificationsController.stream;

  @override
  void close() {}

  @override
  void listen(
    void Function(protocol.Request request)? onRequest, {
    void Function()? onDone,
    Function? onError,
    Function? onNotification,
  }) {
    _onRequest = onRequest;
  }

  @override
  void sendNotification(protocol.Notification notification) {
    _notificationsController.add(notification);
  }

  Future<protocol.Response> sendRequest(protocol.RequestParams params) {
    if (_onRequest == null) {
      fail(
        '_onReuest is null! `listen` has not yet been called on this channel.',
      );
    }
    var id = (_idCounter++).toString();
    var request = params.toRequest(id);
    var completer = Completer<protocol.Response>();
    _completers[request.id] = completer;
    _onRequest!(request);
    return completer.future;
  }

  @override
  void sendResponse(protocol.Response response) {
    var completer = _completers.remove(response.id);
    completer?.complete(response);
  }
}

class PluginServerTestBase with ResourceProviderMixin {
  final channel = FakeChannel();

  late final PluginServer pluginServer;

  Folder get byteStoreRoot => getFolder('/byteStore');

  Folder get sdkRoot => getFolder('/sdk');

  @mustCallSuper
  Future<void> setUp() async {
    createMockSdk(resourceProvider: resourceProvider, root: sdkRoot);
  }

  Future<void> startPlugin() async {
    await pluginServer.initialize();
    pluginServer.start(channel);

    await pluginServer.handlePluginVersionCheck(
      protocol.PluginVersionCheckParams(
        byteStoreRoot.path,
        sdkRoot.path,
        '0.0.1',
      ),
    );
  }

  void tearDown() {
    registeredFixGenerators.clearLintProducers();
    registeredFixGenerators.clearWarningProducers();
  }
}
