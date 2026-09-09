// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:native_api_lint/src/deployment_target_resolver.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('native_api_lint_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Podfile parsing
  // ---------------------------------------------------------------------------
  group('DeploymentTargetResolver.resolve (Podfile)', () {
    test('parses iOS target from Podfile with single quotes', () {
      _writePodfile(tempDir, 'ios', "platform :ios, '14.0'");
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.ios), '14.0');
    });

    test('parses iOS target from Podfile with double quotes', () {
      _writePodfile(tempDir, 'ios', 'platform :ios, "13.0"');
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.ios), '13.0');
    });

    test('parses iOS target from Podfile with leading spaces', () {
      _writePodfile(tempDir, 'ios', "  platform :ios, '15.0'");
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.ios), '15.0');
    });

    test('parses macOS target from Podfile', () {
      _writePodfile(tempDir, 'macos', "platform :osx, '11.0'");
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.macos), '11.0');
    });

    test('returns null when Podfile is missing', () {
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.ios), isNull);
    });

    test('returns null when Podfile has no platform line', () {
      _writePodfile(tempDir, 'ios', '# No platform line here');
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.ios), isNull);
    });

    test('ignores commented-out platform lines', () {
      _writePodfile(tempDir, 'ios', "# platform :ios, '9.0'\nuse_frameworks!");
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.ios), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // project.pbxproj parsing
  // ---------------------------------------------------------------------------
  group('DeploymentTargetResolver.resolve (pbxproj)', () {
    test('parses iOS deployment target from pbxproj', () {
      _writePbxproj(tempDir, 'ios', 'IPHONEOS_DEPLOYMENT_TARGET', '14.0');
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.ios), '14.0');
    });

    test('parses macOS deployment target from pbxproj', () {
      _writePbxproj(tempDir, 'macos', 'MACOSX_DEPLOYMENT_TARGET', '11.0');
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.macos), '11.0');
    });

    test('uses minimum when pbxproj has multiple entries', () {
      _writePbxprojMultiple(tempDir, 'ios', 'IPHONEOS_DEPLOYMENT_TARGET', [
        '14.0', // Debug
        '13.0', // Release — lower, so this wins
        '14.0', // Profile
      ]);
      final resolver = DeploymentTargetResolver(tempDir.path);
      expect(resolver.resolve(ApplePlatform.ios), '13.0');
    });

    test('Podfile takes precedence over pbxproj', () {
      _writePodfile(tempDir, 'ios', "platform :ios, '14.0'");
      _writePbxproj(tempDir, 'ios', 'IPHONEOS_DEPLOYMENT_TARGET', '12.0');
      final resolver = DeploymentTargetResolver(tempDir.path);
      // Podfile is checked first — should return 14.0.
      expect(resolver.resolve(ApplePlatform.ios), '14.0');
    });
  });

  // ---------------------------------------------------------------------------
  // Override from analysis_options.yaml
  // ---------------------------------------------------------------------------
  group('DeploymentTargetResolver with overrides', () {
    test('override takes precedence over Podfile', () {
      _writePodfile(tempDir, 'ios', "platform :ios, '13.0'");
      final resolver = DeploymentTargetResolver(
        tempDir.path,
        overrides: {'ios': '16.0'},
      );
      expect(resolver.resolve(ApplePlatform.ios), '16.0');
    });

    test('override works without any project files', () {
      final resolver = DeploymentTargetResolver(
        tempDir.path,
        overrides: {'ios': '15.0', 'macos': '12.0'},
      );
      expect(resolver.resolve(ApplePlatform.ios), '15.0');
      expect(resolver.resolve(ApplePlatform.macos), '12.0');
    });
  });

  // ---------------------------------------------------------------------------
  // parseAnalysisOptionsOverrides
  // ---------------------------------------------------------------------------
  group('parseAnalysisOptionsOverrides', () {
    test('parses known platform keys', () {
      final result = parseAnalysisOptionsOverrides({
        'ios_min': '14.0',
        'macos_min': '11.0',
        'tvos_min': '14.0',
      });
      expect(result, {'ios': '14.0', 'macos': '11.0', 'tvos': '14.0'});
    });

    test('ignores unknown keys', () {
      final result = parseAnalysisOptionsOverrides({
        'ios_min': '14.0',
        'android_min': '21', // not a supported Apple platform
      });
      expect(result, {'ios': '14.0'});
    });

    test('ignores empty values', () {
      final result = parseAnalysisOptionsOverrides({'ios_min': ''});
      expect(result, isEmpty);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _writePodfile(Directory dir, String platform, String content) {
  final file = File(p.join(dir.path, platform, 'Podfile'));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void _writePbxproj(
  Directory dir,
  String platform,
  String key,
  String version,
) {
  _writePbxprojMultiple(dir, platform, key, [version]);
}

void _writePbxprojMultiple(
  Directory dir,
  String platform,
  String key,
  List<String> versions,
) {
  final lines = [
    '// !\$*UTF8*\$!',
    '{ archiveVersion = 1; }',
    'buildSettings = {',
    for (final v in versions) '\t\t\t$key = $v;',
    '};',
  ];
  final file = File(
    p.join(dir.path, platform, 'Runner.xcodeproj', 'project.pbxproj'),
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(lines.join('\n'));
}
