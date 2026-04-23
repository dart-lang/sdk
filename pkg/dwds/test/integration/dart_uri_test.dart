// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fixtures/fakes.dart';
import 'fixtures/utilities.dart';

class TestStrategy extends FakeStrategy {
  TestStrategy(super.assetReader);

  @override
  String? serverPathForAppUri(String appUrl) {
    final appUri = Uri.parse(appUrl);
    if (appUri.isScheme('org-dartlang-app')) {
      return appUri.path;
    }
    if (appUri.isScheme('package')) {
      return 'packages/${appUri.path}';
    }
    if (appUri.isScheme('google3')) {
      return appUri.path;
    }
    return null;
  }
}

class G3TestStrategy extends FakeStrategy {
  G3TestStrategy(super.assetReader);

  @override
  String? g3RelativePath(String absolutePath) =>
      'g3:///${p.split(absolutePath).last}';
}

void main() {
  group('DartUri', () {
    setUpAll(() {
      final toolConfiguration = TestToolConfiguration.withLoadStrategy(
        loadStrategy: TestStrategy(FakeAssetReader()),
      );
      setGlobalsForTesting(toolConfiguration: toolConfiguration);
    });
    test('parses package : paths', () {
      final uri = DartUri('package:path/path.dart');
      expect(uri.serverPath, 'packages/path/path.dart');
    });

    test('parses package : paths with root', () {
      final uri = DartUri('package:path/path.dart', 'foo/bar/blah');
      expect(uri.serverPath, 'foo/bar/blah/packages/path/path.dart');
    });

    test('parses org-dartlang-app paths', () {
      final uri = DartUri('org-dartlang-app:///blah/main.dart');
      expect(uri.serverPath, '/blah/main.dart');
    });

    test('parses google3 paths', () {
      final uri = DartUri('google3:///blah/main.dart');
      expect(uri.serverPath, '/blah/main.dart');
    });

    test('parses packages paths', () {
      final uri = DartUri('/packages/blah/foo.dart');
      expect(uri.serverPath, 'packages/blah/foo.dart');
    });

    test('parses http paths', () {
      final uri = DartUri('http://localhost:8080/web/main.dart');
      expect(uri.serverPath, 'web/main.dart');
    });

    group('initialized with empty configuration', () {
      setUpAll(() async {
        await DartUri.initialize();
        DartUri.recordAbsoluteUris(['dart:io', 'dart:html']);
      });

      tearDownAll(DartUri.clear);
      test('cannot resolve uris', () async {
        final resolved = DartUri.toResolvedUri('dart:io');
        expect(resolved, isNull);
      });
    });

    group('initialized with current SDK directory', () {
      setUpAll(() async {
        await DartUri.initialize();
        DartUri.recordAbsoluteUris(['dart:io', 'dart:html']);
      });

      tearDownAll(DartUri.clear);

      test(
        'can resolve uris',
        () {
          final resolved = DartUri.toResolvedUri('dart:io');
          expect(resolved, 'org-dartlang-sdk:///sdk/lib/io/io.dart');
        },
        skip: 'https://github.com/dart-lang/webdev/issues/1584',
      );

      test(
        'can un-resolve uris',
        () {
          final unresolved = DartUri.toPackageUri(
            'org-dartlang-sdk:///sdk/lib/io/io.dart',
          );
          expect(unresolved, 'dart:io');
        },
        skip: 'https://github.com/dart-lang/webdev/issues/1584',
      );
    });

    group('initialized with other SDK directory', () {
      setUpAll(() async {
        await DartUri.initialize();
        DartUri.recordAbsoluteUris(['dart:io', 'dart:html']);
      });

      tearDownAll(() async {
        DartUri.clear();
      });

      test(
        'can resolve uris',
        () {
          final resolved = DartUri.toResolvedUri('dart:io');
          expect(resolved, 'org-dartlang-sdk:///sdk/lib/io/io.dart');
        },
        skip: 'https://github.com/dart-lang/webdev/issues/1584',
      );

      test(
        'can unresolve uris',
        () {
          final unresolved = DartUri.toPackageUri(
            'org-dartlang-sdk:///sdk/lib/io/io.dart',
          );
          expect(unresolved, 'dart:io');
        },
        skip: 'https://github.com/dart-lang/webdev/issues/1584',
      );
    });

    group('initialized with other SDK directory with no libraries spec', () {
      final logs = <String>[];

      void logWriter(
        Object? level,
        Object? message, {
        String? error,
        String? loggerName,
        String? stackTrace,
      }) {
        final errorMessage = error == null ? '' : ':\n$error';
        final stackMessage = stackTrace == null ? '' : ':\n$stackTrace';
        logs.add(
          '[$level] $loggerName: $message'
          '$errorMessage'
          '$stackMessage',
        );
      }

      setUpAll(() async {
        configureLogWriter(customLogWriter: logWriter);
        await DartUri.initialize();
        DartUri.recordAbsoluteUris(['dart:io', 'dart:html']);
      });

      tearDownAll(() async {
        DartUri.clear();
      });

      test(
        'cannot resolve uris',
        () {
          final resolved = DartUri.toResolvedUri('dart:io');
          expect(resolved, null);
        },
        skip: 'https://github.com/dart-lang/webdev/issues/1584',
      );

      test(
        'cannot unresolve uris',
        () {
          final unresolved = DartUri.toPackageUri(
            'org-dartlang-sdk:///sdk/lib/io/io.dart',
          );
          expect(unresolved, null);
        },
        skip: 'https://github.com/dart-lang/webdev/issues/1584',
      );
    });
  });

  group('initialized to handle g3-relative paths', () {
    setUpAll(() async {
      final toolConfiguration = TestToolConfiguration.withLoadStrategy(
        loadStrategy: G3TestStrategy(FakeAssetReader()),
        appMetadata: const TestAppMetadata.internalApp(),
      );
      setGlobalsForTesting(toolConfiguration: toolConfiguration);
      await DartUri.initialize();
      DartUri.recordAbsoluteUris(['package:path/path.dart']);
    });

    tearDownAll(DartUri.clear);

    test('can resolve g3-relative paths', () {
      final resolved = DartUri.toPackageUri('g3:///path.dart');
      expect(resolved, 'package:path/path.dart');
    });

    test('can resolve absolute file paths', () {
      final absolute = 'file:///cloud/user/workspace/project/path.dart';
      final resolved = DartUri.toPackageUri(absolute);
      expect(resolved, absolute);
    });

    test('can resolve absolute g3 paths', () {
      final absolute = 'google3:///cloud/user/workspace/project/path.dart';
      final resolved = DartUri.toPackageUri(absolute);
      expect(resolved, absolute);
    });
  });
}
