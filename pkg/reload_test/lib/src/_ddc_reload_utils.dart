// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper functions for the hot reload test suite.
//
// The structure here reflects interfaces defined in DDC's
// `ddc_module_loader.js`.

import 'dart:convert';
import 'dart:js_interop';

import '../hot_reload_receipt.dart';

extension type _DartLoader(JSObject _) implements JSObject {
  external _DDCLoader get loader;
}

extension type _DDCLoader(JSObject _) implements JSObject {
  external JSPromise hotReload();
  external void hotRestart();
  external int get hotReloadGeneration;
  external int get hotRestartGeneration;
  external int intendedHotRestartGeneration;
}

extension type _DartDevEmbedder(JSObject _) implements JSObject {
  external JSPromise hotReload(JSArray<JSString> files, JSArray<JSString> ids);
  external JSPromise hotRestart();
  external JSNumber get hotReloadGeneration;
  external JSNumber get hotRestartGeneration;
}

@JS('dartDevEmbedder')
external _DartDevEmbedder get _dartDevEmbedder;

@JS('\$injectedFilesAndLibrariesToReload')
external JSArray<JSArray<JSString>>? injectedFilesAndLibrariesToReload(
    JSNumber requestedFileGeneration);

@JS('\$dartLoader')
external _DartLoader get _dartLoader;

final _ddcLoader = _dartLoader.loader;

int get hotRestartGeneration => _dartDevEmbedder.hotRestartGeneration.toDartInt;

Future<void> hotRestart() async {
  _ddcLoader.intendedHotRestartGeneration++;
  final restartReceipt = HotReloadReceipt(
    generation: _ddcLoader.intendedHotRestartGeneration,
    status: Status.restarted,
  );
  print('${HotReloadReceipt.hotReloadReceiptTag}'
      '${jsonEncode(restartReceipt.toJson())}');
  await _dartDevEmbedder.hotRestart().toDart;
}

/// The reload generation of the currently running application.
int get hotReloadGeneration => _dartDevEmbedder.hotReloadGeneration.toDartInt;

/// The generation of reload requests by the test application.
///
/// This could differ from [hotReloadGeneration] when file generations get
/// rejected and the running application stays in the previous "application"
/// generation.
int _hotReloadFileGeneration = 0;

Future<void> hotReload({bool expectRejection = false}) async {
  _hotReloadFileGeneration++;
  final generationFileInfo =
      injectedFilesAndLibrariesToReload(_hotReloadFileGeneration.toJS);
  final HotReloadReceipt reloadStatus = expectRejection
      ? _rejectNextGeneration(generationFileInfo)
      : await _reloadNextGeneration(generationFileInfo);
  // Write reload receipt with a leading tag to be recognized by the reload
  // suite runner and validated.
  print('${HotReloadReceipt.hotReloadReceiptTag}'
      '${jsonEncode(reloadStatus.toJson())}');
}

HotReloadReceipt _rejectNextGeneration(
    JSArray<JSArray<JSString>>? generationFileInfo) {
  if (generationFileInfo != null) {
    throw Exception(
        'Generation $_hotReloadFileGeneration was not rejected at compile '
        'time. Verify the calls of `hotReload(expectRejection: true)` in the '
        'test source match the rejected generation files.');
  }
  // This reload wasn't expected to find any files so this is OK.
  // * The correct reason for rejection was already validated at compile time
  //   so nothing to check here.
  // * Expected number and order of reloads are validated at the end of the test
  //   run.
  return HotReloadReceipt(
    generation: _hotReloadFileGeneration,
    status: Status.rejected,
    rejectionMessage: HotReloadReceipt.compileTimeErrorMessage,
  );
}

Future<HotReloadReceipt> _reloadNextGeneration(
    JSArray<JSArray<JSString>>? generationFileInfo) async {
  if (generationFileInfo == null) {
    throw Exception(
        'No compiled files found for generation $_hotReloadFileGeneration. '
        'Verify the calls of `hotReload()` in the test match the accepted '
        'generation source files.');
  }
  await (_dartDevEmbedder.hotReload(
          generationFileInfo[0], generationFileInfo[1]))
      .toDart;
  return HotReloadReceipt(
    generation: _hotReloadFileGeneration,
    status: Status.accepted,
  );
}
