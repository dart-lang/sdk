// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory/service_io.dart';
import 'service_test_common.dart';

const String clientName = 'TestClient';
const String otherClientName = 'OtherTestClient';

Future<void> setClientName(WebSocketVM client, String name) async =>
    await client.invokeRpc('setClientName', {'name': name});

Future<WebSocketVM> createClient(WebSocketVM vm,
    {String clientName: clientName}) async {
  final client = WebSocketVM(vm.target);
  await client.load();
  await setClientName(client, clientName);
  return client;
}

Future<void> setRequireApprovalForResume(
  WebSocketVM vm,
  Isolate isolate, {
  bool pauseOnStart: false,
  bool pauseOnExit: false,
  bool pauseOnReload: false,
}) async {
  int pauseTypeMask = 0;
  if (pauseOnStart) {
    pauseTypeMask |= 1;
  }
  if (pauseOnReload) {
    pauseTypeMask |= 2;
  }
  if (pauseOnExit) {
    pauseTypeMask |= 4;
  }
  await vm.invokeRpc('requirePermissionToResume', {
    'isolateId': isolate.id,
    'pauseTypeMask': pauseTypeMask,
    'onPauseStart': pauseOnStart,
    'onPauseReload': pauseOnReload,
    'onPauseExit': pauseOnExit,
  });
}

Future<void> resume(WebSocketVM vm, Isolate isolate) async =>
    await vm.invokeRpc('resume', {
      'isolateId': isolate.id,
    });

Future<bool> isPausedAtStart(Isolate isolate) async {
  await isolate.reload();
  return ((isolate.pauseEvent != null) &&
      isEventOfKind(isolate.pauseEvent, ServiceEvent.kPauseStart));
}

Future<bool> isPausedAtExit(Isolate isolate) async {
  await isolate.reload();
  return ((isolate.pauseEvent != null) &&
      isEventOfKind(isolate.pauseEvent, ServiceEvent.kPauseExit));
}

Future<bool> isPausedPostRequest(Isolate isolate) async {
  await isolate.reload();
  return ((isolate.pauseEvent != null) &&
      isEventOfKind(isolate.pauseEvent, ServiceEvent.kPausePostRequest));
}

Future<void> waitForResume(Isolate isolate) async {
  final completer = Completer<bool>();
  isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kResume) {
        subscription.cancel();
        completer.complete();
      }
    });
  });
  await completer.future;
}
