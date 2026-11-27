// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/web/serve/dart_sources.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'test_utils.dart';

/// Tests that [DartSources] finds the app's, packages' and SDK's `.dart`
/// files by decoded URL path segments, and nothing else.
void main() {
  late DartSources sources;

  setUp(() async {
    sources = await createServeProject();
  });

  String? contents(List<String> segments) =>
      sources.resolve(segments)?.readAsStringSync();

  test("finds the app's files under web/", () {
    expect(contents(['web', 'main.dart']), 'main.dart');
    expect(contents(['web', 'my file.dart']), 'my file.dart');
  });

  test("finds the app's own package library under packages/", () {
    expect(contents(['packages', 'app', 'greeting.dart']), 'greeting.dart');
    expect(contents(['packages', 'app', 'my lib.dart']), 'my lib.dart');
  });

  test("finds a dependency's library under packages/", () {
    expect(contents(['packages', 'dep', 'src', 'impl.dart']), 'impl.dart');
  });

  test("finds the SDK's libraries under dart-sdk/lib/", () {
    expect(contents(['dart-sdk', 'lib', 'core', 'core.dart']), 'core.dart');
  });

  test('allows symlinks staying inside root and rejects symlinks escaping', () {
    final webDir = p.join(d.sandbox, 'app', 'web');
    final appDir = p.join(d.sandbox, 'app');

    // Directory symlinks work on all platforms (including Windows junctions).
    Link(p.join(webDir, 'linked_sub')).createSync(p.join(webDir, 'sub'));
    Link(p.join(webDir, 'escaped_app')).createSync(appDir);
    Link(p.join(appDir, 'lib', 'escaped_app')).createSync(appDir);

    expect(contents(['web', 'linked_sub', 'nested.dart']), 'sub/nested.dart');
    expect(sources.resolve(['web', 'escaped_app', 'secret.dart']), isNull);
    expect(
      sources.resolve(['packages', 'app', 'escaped_app', 'secret.dart']),
      isNull,
    );

    if (!Platform.isWindows) {
      Link(
        p.join(webDir, 'inside_link.dart'),
      ).createSync(p.join(webDir, 'main.dart'));
      Link(
        p.join(webDir, 'escape_link.dart'),
      ).createSync(p.join(appDir, 'secret.dart'));

      expect(contents(['web', 'inside_link.dart']), 'main.dart');
      expect(sources.resolve(['web', 'escape_link.dart']), isNull);
    }
  });

  test('rejects packages whose packageUri is the package root', () {
    expect(
      sources.resolve(['packages', 'root_pkg', 'bin', 'server.dart']),
      isNull,
    );
    expect(
      sources.resolve(['packages', 'root_pkg', 'lib', 'inside.dart']),
      isNull,
    );
    expect(
      sources.resolve(['packages', 'omitted_pkg', 'tool', 'gen.dart']),
      isNull,
    );
  });

  test('ignores non-Dart, missing, invalid-package, and unsafe segments', () {
    for (final segments in <List<String>>[
      [],
      ['web'],
      ['web', 'style.css'], // Not a .dart file.
      ['web', 'missing.dart'], // Doesn't exist.
      ['web', '.hidden.dart'], // Hidden dotfile.
      ['web', '.', 'main.dart'], // Dot segment.
      ['web', '..', 'secret.dart'], // Outside web/.
      ['web', '', 'main.dart'], // Empty segment.
      ['web', 'sub/nested.dart'], // Embedded forward slash.
      ['web', r'sub\nested.dart'], // Embedded backslash.
      [r'\\attacker.example\share', 'x.dart'], // Windows UNC segment.
      ['web', 'C:main.dart'], // Windows drive colon.
      ['web', 'main\x00.dart'], // NUL byte.
      ['packages', 'app', '..', 'secret.dart'], // Outside lib/.
      ['packages', 'unknown', 'a.dart'], // Not in the package config.
      ['packages', 'bad:name', 'a.dart'], // Invalid package name (no throw).
      ['packages', ' ', 'a.dart'], // Whitespace package name (no throw).
      ['packages', '', 'a.dart'], // Empty package name.
      ['dart-sdk', 'lib', '..', '..', 'app', 'secret.dart'], // Outside SDK.
      ['secret.dart'], // No known prefix.
    ]) {
      expect(sources.resolve(segments), isNull, reason: '$segments');
    }
  });
}
