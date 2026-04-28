// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/src/debugging/location.dart';
import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:test/test.dart';

import 'fixtures/fakes.dart';
import 'fixtures/utilities.dart';

final sourceMapContents =
    '{"version":3,"sourceRoot":"","sources":["main.dart"],"names":[],'
    '"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAUwB,IAAtB,WAAM;AAKJ,'
    'IAHF,4BAAkB,aAAa,SAAC,GAAG;AACb,MAApB,WAAM;AACN,YAAgC,+CAAO,AAAK,oBAAO,'
    'yCAAC,WAAW;IAChE;AAC0D,IAA3D,AAAS,AAAK,0DAAO;AAAe,kBAAO;;;AAEvC,gBAAQ;'
    'AAGV,IAFI,kCAAqC,QAAC;AACX,MAA/B,WAAM,AAAwB,0BAAP,QAAF,AAAE,KAAK,GAAP;'
    ';EAEzB","file":"main.ddc.js"}';

void main() async {
  const lines = 100;
  const lineLength = 150;
  final assetReader = FakeAssetReader(sourceMap: sourceMapContents);
  final toolConfiguration = TestToolConfiguration.withLoadStrategy(
    loadStrategy: MockLoadStrategy(assetReader),
  );
  setGlobalsForTesting(toolConfiguration: toolConfiguration);
  final dartUri = DartUri('org-dartlang-app://web/main.dart');

  final modules = FakeModules(module: _module);
  final locations = Locations(assetReader, modules, '');
  await locations.initialize('fake_entrypoint');

  group('JS locations |', () {
    const fakeRuntimeScriptId = '12';

    group('location |', () {
      test('is zero based', () {
        final loc = JsLocation.fromZeroBased(
          _module,
          0,
          0,
          fakeRuntimeScriptId,
        );
        expect(loc, _matchJsLocation(0, 0));
      });

      test('can compare to other location', () {
        final loc00 = JsLocation.fromZeroBased(
          _module,
          0,
          0,
          fakeRuntimeScriptId,
        );
        final loc01 = JsLocation.fromZeroBased(
          _module,
          0,
          1,
          fakeRuntimeScriptId,
        );
        final loc10 = JsLocation.fromZeroBased(
          _module,
          1,
          0,
          fakeRuntimeScriptId,
        );
        final loc11 = JsLocation.fromZeroBased(
          _module,
          1,
          1,
          fakeRuntimeScriptId,
        );

        expect(loc00.compareTo(loc01), isNegative);
        expect(loc00.compareTo(loc10), isNegative);
        expect(loc00.compareTo(loc10), isNegative);
        expect(loc00.compareTo(loc11), isNegative);

        expect(loc00.compareTo(loc00), isZero);
        expect(loc11.compareTo(loc00), isPositive);
      });
    });

    group('best location |', () {
      test('does not return location for setup code', () async {
        final location = await locations.locationForJs(_module, 0, 0);
        expect(location, isNull);
      });

      test('prefers precise match', () async {
        final location = await locations.locationForJs(_module, 37, 0);
        expect(location, _matchLocationForJs(37, 0));
      });

      test('finds a match in the beginning of the line', () async {
        final location = await locations.locationForJs(_module, 39, 4);
        expect(location, _matchLocationForJs(39, 0));
      });

      test('finds a match in the middle of the line', () async {
        final location = await locations.locationForJs(_module, 39, 10);
        expect(location, _matchLocationForJs(39, 6));
      });

      test('finds a match on a previous line', () async {
        final location = await locations.locationForJs(_module, 44, 0);
        expect(location, _matchLocationForJs(43, 18));
      });

      test(
        'finds a match on a previous line with a closer match after',
        () async {
          final location = await locations.locationForJs(
            _module,
            44,
            lineLength - 1,
          );
          expect(location, _matchLocationForJs(43, 18));
        },
      );

      test('finds a match on the last line', () async {
        final location = await locations.locationForJs(
          _module,
          lines - 1,
          lineLength - 1,
        );
        expect(location, _matchLocationForJs(50, 2));
      });

      test('finds a match on invalid line', () async {
        final location = await locations.locationForJs(
          _module,
          lines,
          lineLength - 1,
        );
        expect(location, _matchLocationForJs(50, 2));
      });

      test('finds a match on invalid column on the same line', () async {
        final location = await locations.locationForJs(_module, 50, lineLength);
        expect(location, _matchLocationForJs(50, 2));
      });

      test('finds a match on invalid column on a previous line', () async {
        final location = await locations.locationForJs(
          _module,
          lines - 1,
          lineLength,
        );
        expect(location, _matchLocationForJs(50, 2));
      });
    });
  });

  group('Dart locations |', () {
    group('location |', () {
      test('is one based', () async {
        final loc = DartLocation.fromZeroBased(dartUri, 0, 0);
        expect(loc, _matchDartLocation(1, 1));
      });

      test('can compare to other locations', () async {
        final loc00 = DartLocation.fromZeroBased(dartUri, 0, 0);
        final loc01 = DartLocation.fromZeroBased(dartUri, 0, 1);
        final loc10 = DartLocation.fromZeroBased(dartUri, 1, 0);
        final loc11 = DartLocation.fromZeroBased(dartUri, 1, 1);

        expect(loc00.compareTo(loc01), isNegative);
        expect(loc00.compareTo(loc10), isNegative);
        expect(loc00.compareTo(loc10), isNegative);
        expect(loc00.compareTo(loc11), isNegative);

        expect(loc00.compareTo(loc00), isZero);
        expect(loc11.compareTo(loc00), isPositive);
      });
    });

    group('best location |', () {
      test(
        'does not return location for dart lines not mapped to JS',
        () async {
          final location = await locations.locationForDart(dartUri, 0, 0);
          expect(location, isNull);
        },
      );

      test('returns location after on the same line', () async {
        final location = await locations.locationForDart(dartUri, 11, 0);
        expect(location, _matchLocationForDart(11, 3));
      });

      test('return null on invalid line', () async {
        final location = await locations.locationForDart(dartUri, lines, 0);
        expect(location, isNull);
      });

      test('return null on invalid column', () async {
        final location = await locations.locationForDart(
          dartUri,
          lines - 1,
          lineLength,
        );
        expect(location, isNull);
      });
    });
  });
}

Matcher _matchLocationForDart(int line, int column) => isA<Location>().having(
  (l) => l.dartLocation,
  'dartLocation',
  _matchDartLocation(line, column),
);

Matcher _matchLocationForJs(int line, int column) => isA<Location>().having(
  (l) => l.jsLocation,
  'jsLocation',
  _matchJsLocation(line, column),
);

Matcher _matchDartLocation(int line, int column) => isA<DartLocation>()
    .having((l) => l.line, 'line', line)
    .having((l) => l.column, 'column', column);

Matcher _matchJsLocation(int line, int column) => isA<JsLocation>()
    .having((l) => l.line, 'line', line)
    .having((l) => l.column, 'column', column);

const _module = 'packages/module';
const _serverPath = 'web/main.dart';
const _sourceMapPath = 'packages/module.js.map';

class MockLoadStrategy extends FakeStrategy {
  MockLoadStrategy(super.assetReader);

  @override
  Future<String?> moduleForServerPath(
    String entrypoint,
    String serverPath,
  ) async => _module;

  @override
  Future<String> serverPathForModule(String entrypoint, String module) async =>
      _serverPath;

  @override
  Future<String> sourceMapPathForModule(
    String entrypoint,
    String module,
  ) async => _sourceMapPath;

  @override
  String serverPathForAppUri(String appUri) => _serverPath;
}
