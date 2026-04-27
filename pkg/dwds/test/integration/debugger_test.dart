// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:dwds/src/debugging/debugger.dart';
import 'package:dwds/src/debugging/frame_computer.dart';
import 'package:dwds/src/debugging/location.dart';
import 'package:dwds/src/debugging/skip_list.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide LogRecord;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    show CallFrame, DebuggerPausedEvent, StackTrace, WipCallFrame, WipScript;

import 'fixtures/debugger_data.dart';
import 'fixtures/fakes.dart';
import 'fixtures/utilities.dart';

late FakeChromeAppInspector inspector;
late Debugger debugger;
late FakeWebkitDebugger webkitDebugger;
late StreamController<DebuggerPausedEvent> pausedController;
late Locations locations;
late SkipLists skipLists;

class TestStrategy extends FakeStrategy {
  TestStrategy(super.assetReader);

  @override
  Future<String> moduleForServerPath(String entrypoint, String appUri) async =>
      'foo.ddc.js';

  @override
  Future<String> serverPathForModule(String entrypoint, String module) async =>
      'foo/ddc';
}

final sourceMapContents =
    '{"version":3,"sourceRoot":"","sources":["main.dart"],"names":[],'
    '"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAUwB,IAAtB,WAAM;AAKJ,'
    'IAHF,4BAAkB,aAAa,SAAC,GAAG;AACb,MAApB,WAAM;AACN,YAAgC,+CAAO,AAAK,oBAAO,'
    'yCAAC,WAAW;IAChE;AAC0D,IAA3D,AAAS,AAAK,0DAAO;AAAe,kBAAO;;;AAEvC,gBAAQ;'
    'AAGV,IAFI,kCAAqC,QAAC;AACX,MAA/B,WAAM,AAAwB,0BAAP,QAAF,AAAE,KAAK,GAAP;'
    ';EAEzB","file":"main.ddc.js"}';

final sampleSyncFrame = WipCallFrame({
  'callFrameId': '{"ordinal":0,"injectedScriptId":2}',
  'functionName': '',
  'functionLocation': {'scriptId': '69', 'lineNumber': 88, 'columnNumber': 72},
  'location': {'scriptId': '69', 'lineNumber': 37, 'columnNumber': 0},
  'url': '',
  'scopeChain': <Map<String, dynamic>>[],
  'this': {'type': 'undefined'},
});

final sampleAsyncFrame = CallFrame({
  'functionName': 'myFunc',
  'url': '',
  'scriptId': '71',
  'lineNumber': 40,
  'columnNumber': 1,
});

final Map<String, WipScript> scripts = {
  '69': WipScript(<String, dynamic>{'url': 'http://127.0.0.1:8081/foo.ddc.js'}),
  '71': WipScript(<String, dynamic>{'url': 'http://127.0.0.1:8081/bar.ddc.js'}),
};

void main() async {
  setUpAll(() async {
    webkitDebugger = FakeWebkitDebugger(scripts: scripts);
    pausedController = StreamController<DebuggerPausedEvent>();
    webkitDebugger.onPaused = pausedController.stream;
    final toolConfiguration = TestToolConfiguration.withLoadStrategy(
      loadStrategy: TestStrategy(FakeAssetReader()),
    );
    setGlobalsForTesting(toolConfiguration: toolConfiguration);
    final root = 'fakeRoot';
    locations = Locations(
      FakeAssetReader(sourceMap: sourceMapContents),
      FakeModules(),
      root,
    );
    await locations.initialize('fake_entrypoint');
    skipLists = SkipLists(root);
    debugger = await Debugger.create(
      webkitDebugger,
      (_, _) {},
      locations,
      skipLists,
      root,
    );
    inspector = FakeChromeAppInspector(
      webkitDebugger,
      fakeIsolate: simpleIsolate,
    );
    debugger.updateInspector(inspector);
  });

  /// Test that we get expected variable values from a hard-coded
  /// stack frame.
  test('frames 1', () async {
    final stackComputer = FrameComputer(debugger, frames1);
    final frames = await stackComputer.calculateFrames();
    expect(frames, isNotNull);
    expect(frames, isNotEmpty);

    final firstFrameVars = frames[0].vars!;
    final frame1Variables = firstFrameVars.map((each) => each.name).toList();
    expect(frame1Variables, ['a', 'b']);
  });

  test('creates async frames', () async {
    final stackComputer = FrameComputer(
      debugger,
      [sampleSyncFrame],
      asyncStackTrace: StackTrace({
        'callFrames': [sampleAsyncFrame.json],
        'parent': StackTrace({
          'callFrames': [sampleAsyncFrame.json],
        }).json,
      }),
    );

    final frames = await stackComputer.calculateFrames();
    expect(frames, hasLength(5));

    expect(frames[0].kind, FrameKind.kRegular);
    expect(frames[1].kind, FrameKind.kAsyncSuspensionMarker);
    expect(frames[2].kind, FrameKind.kAsyncCausal);
    expect(frames[3].kind, FrameKind.kAsyncSuspensionMarker);
    expect(frames[4].kind, FrameKind.kAsyncCausal);
  });

  test('elides multiple async frames', () async {
    final stackComputer = FrameComputer(
      debugger,
      [sampleSyncFrame],
      asyncStackTrace: StackTrace({
        'callFrames': [sampleAsyncFrame.json],
        'parent': StackTrace({
          'callFrames': <Map<String, dynamic>>[],
          'parent': StackTrace({
            'callFrames': [sampleAsyncFrame.json],
            'parent': StackTrace({'callFrames': <Map<String, dynamic>>[]}).json,
          }).json,
        }).json,
      }),
    );

    final frames = await stackComputer.calculateFrames();
    expect(frames, hasLength(5));

    expect(frames[0].kind, FrameKind.kRegular);
    expect(frames[1].kind, FrameKind.kAsyncSuspensionMarker);
    expect(frames[2].kind, FrameKind.kAsyncCausal);
    expect(frames[3].kind, FrameKind.kAsyncSuspensionMarker);
    expect(frames[4].kind, FrameKind.kAsyncCausal);
  });

  setUp(() {
    // We need to provide an Isolate so that the code doesn't bail out on a null
    // check before it has a chance to throw.
    inspector = FakeChromeAppInspector(
      webkitDebugger,
      fakeIsolate: simpleIsolate,
    );
    debugger.updateInspector(inspector);
  });

  group('errors', () {
    setUp(() {
      // We need to provide an Isolate so that the code doesn't bail out on a
      // null check before it has a chance to throw.
      inspector = FakeChromeAppInspector(
        webkitDebugger,
        fakeIsolate: simpleIsolate,
      );
      debugger.updateInspector(inspector);
    });

    test('errors in the zone are caught and logged', () async {
      // Add a DebuggerPausedEvent with a null parameter to provoke an error.
      pausedController.sink.add(
        DebuggerPausedEvent({
          'method': '',
          'params': {
            'reason': 'other',
            'callFrames': [
              {'callFrameId': '', 'functionName': ''},
            ],
          },
        }),
      );
      expect(
        Debugger.logger.onRecord,
        emitsThrough(
          predicate(
            (LogRecord log) =>
                log.message.contains('Error calculating sync frame'),
          ),
        ),
      );
    });
  });
}
