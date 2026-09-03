// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:native_api_lint/src/ffigen/availability_data.dart';
import 'package:native_api_lint/src/ffigen/availability_emitter.dart';

void main() {
  group('emitAvailabilityAnnotation', () {
    test('returns empty string for null info', () {
      expect(emitAvailabilityAnnotation(null), isEmpty);
    });

    test('returns empty string for empty platforms map', () {
      final info = AvailabilityInfo({});
      expect(emitAvailabilityAnnotation(info), isEmpty);
    });

    test('emits single platform with min only', () {
      final info = AvailabilityInfo({
        'ios': PlatformAvailabilityData(platform: 'ios', min: '14.0'),
      });
      final output = emitAvailabilityAnnotation(info);
      expect(output, contains("@ExternalVersions({"));
      expect(output, contains("'ios': ExternalVersion(min: '14.0')"));
    });

    test('emits single platform with min and max', () {
      final info = AvailabilityInfo({
        'macos': PlatformAvailabilityData(
          platform: 'macos',
          min: '10.14',
          max: '12.0',
        ),
      });
      final output = emitAvailabilityAnnotation(info);
      expect(output, contains("min: '10.14'"));
      expect(output, contains("max: '12.0'"));
    });

    test('emits deprecation message', () {
      final info = AvailabilityInfo({
        'macos': PlatformAvailabilityData(
          platform: 'macos',
          min: '10.14',
          max: '12.0',
          deprecationMessage: 'use bar instead',
        ),
      });
      final output = emitAvailabilityAnnotation(info);
      expect(output, contains("deprecationMessage: 'use bar instead'"));
    });

    test('escapes single quotes in deprecation message', () {
      final info = AvailabilityInfo({
        'ios': PlatformAvailabilityData(
          platform: 'ios',
          min: '14.0',
          deprecationMessage: "use foo's API instead",
        ),
      });
      final output = emitAvailabilityAnnotation(info);
      expect(output, contains(r"deprecationMessage: 'use foo\'s API instead'"));
    });

    test('emits multiple platforms sorted alphabetically', () {
      final info = AvailabilityInfo({
        'macos': PlatformAvailabilityData(platform: 'macos', min: '11.0'),
        'ios': PlatformAvailabilityData(platform: 'ios', min: '14.0'),
        'tvos': PlatformAvailabilityData(platform: 'tvos', min: '14.0'),
      });
      final output = emitAvailabilityAnnotation(info);

      final iosIdx = output.indexOf("'ios'");
      final macosIdx = output.indexOf("'macos'");
      final tvosIdx = output.indexOf("'tvos'");

      // Alphabetical order: ios < macos < tvos
      expect(iosIdx, lessThan(macosIdx));
      expect(macosIdx, lessThan(tvosIdx));
    });

    test('emits valid Dart syntax (closes brace)', () {
      final info = AvailabilityInfo({
        'ios': PlatformAvailabilityData(platform: 'ios', min: '14.0'),
      });
      final output = emitAvailabilityAnnotation(info);
      expect(output.trim(), endsWith('})'));
    });
  });
}
