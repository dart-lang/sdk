// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import 'restarter.dart';

@JS(r'dart_library')
external DartLibrary dartLibrary;

extension type DartLibrary._(JSObject _) implements JSObject {
  external void reload(ReloadConfiguration configuration);
}

@anonymous
@JS()
@staticInterop
class ReloadConfiguration {
  external factory ReloadConfiguration({
    String? runId,
    JSPromise? readyToRunMain,
  });
}

class DdcRestarter implements Restarter {
  @override
  Future<(bool, JSArray<JSObject>?)> restart({
    String? runId,
    Future? readyToRunMain,
    String? reloadedSourcesPath,
  }) async {
    assert(
      reloadedSourcesPath == null,
      "'reloadedSourcesPath' should not be used for the DDC module format.",
    );
    dartLibrary.reload(
      ReloadConfiguration(runId: runId, readyToRunMain: readyToRunMain?.toJS),
    );
    final reloadCompleter = Completer<bool>();
    final sub = window.onMessage.listen((event) {
      final message = event.data?.dartify();
      if (message is Map &&
          message['type'] == 'DDC_STATE_CHANGE' &&
          message['state'] == 'restart_end') {
        reloadCompleter.complete(true);
      }
    });
    return (
      await reloadCompleter.future.then((value) {
        sub.cancel();
        return value;
      }),
      null,
    );
  }

  @override
  Future<void> hotReloadEnd() => throw UnimplementedError(
    'Hot reload is not supported for the DDC module format.',
  );

  @override
  Future<JSArray<JSObject>> hotReloadStart(String reloadedSourcesPath) =>
      throw UnimplementedError(
        'Hot reload is not supported for the DDC module format.',
      );
}
