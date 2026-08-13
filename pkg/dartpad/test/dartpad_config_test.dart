// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:checks/checks.dart';
import 'package:dartpad/src/dartpad_config.dart';
import 'package:test/test.dart';

void main() {
  group('DartPadConfig', () {
    test('.fromJson(.toJson())', () {
      final config = DartPadConfig(
        dartSdkPath: '/sdk/path',
        summaryModules: {'/flutter.dill': 'flutter_web'},
        bootstrapCode: 'void main() => {{entrypoint}}.main();',
        flutterSdkPath: '/flutter/sdk',
        trackCreationLocations: true,
      );

      final json = config.toJson();
      final decoded = DartPadConfig.fromJson(json);

      check(decoded.dartSdkPath).equals('/sdk/path');
      check(
        decoded.summaryModules,
      ).deepEquals({'/flutter.dill': 'flutter_web'});
      check(
        decoded.bootstrapCode,
      ).equals('void main() => {{entrypoint}}.main();');
      check(decoded.flutterSdkPath).equals('/flutter/sdk');
      check(decoded.trackCreationLocations).isTrue();
    });

    test('.fromJson({})', () {
      final config = DartPadConfig.fromJson({});

      check(config.dartSdkPath).equals('/sdk');
      check(config.summaryModules).isEmpty();
      check(config.bootstrapCode).isNull();
      check(config.flutterSdkPath).isNull();
      check(config.trackCreationLocations).isFalse();
    });

    test('.copyWith()', () {
      final original = DartPadConfig(
        dartSdkPath: '/original/sdk',
        flutterSdkPath: '/original/flutter',
        pubHostedUrl: 'https://pub.dev',
      );

      final copy = original.copyWith(
        flutterSdkPath: '/new/flutter',
        pubHostedUrl: 'https://custom-pub.com',
      );

      // Verifies the specified fields were updated
      check(copy.flutterSdkPath).equals('/new/flutter');
      check(copy.pubHostedUrl).equals('https://custom-pub.com');

      // Verifies the unspecified field was retained
      check(copy.dartSdkPath).equals('/original/sdk');

      // Verifies defaults are also kept intact
      check(copy.summaryModules).isEmpty();
    });
  });
}
