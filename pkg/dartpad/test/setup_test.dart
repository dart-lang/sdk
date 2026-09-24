// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:checks/checks.dart';
import 'package:dartpad/src/setup/dart.dart';
import 'package:dartpad/src/setup/flutter.dart';
import 'package:test/test.dart';

void main() {
  group('resolveDartPadZipUrl', () {
    test('resolves latest on main from raw/latest', () {
      final url = resolveDartPadZipUrl(channel: 'main');
      check(url.toString()).equals(
        'https://storage.googleapis.com/dart-archive/channels/'
        'main/raw/latest/dartpad/dartpad.zip',
      );
    });

    test('resolves latest on stable/beta/dev from release/latest', () {
      for (final channel in ['stable', 'beta', 'dev']) {
        final url = resolveDartPadZipUrl(channel: channel);
        check(url.toString()).equals(
          'https://storage.googleapis.com/dart-archive/channels/'
          '$channel/release/latest/dartpad/dartpad.zip',
        );
      }
    });

    test('resolves specific version on dev/beta/stable', () {
      final url = resolveDartPadZipUrl(
        channel: 'dev',
        version: '3.14.0-264.0.dev',
      );
      check(url.toString()).equals(
        'https://storage.googleapis.com/dart-archive/channels/'
        'dev/release/3.14.0-264.0.dev/dartpad/dartpad.zip',
      );
    });

    test('resolves specific 40-char revision from raw/hash/<sha>', () {
      const sha = 'f081daa6f970968bd90a1514aa086abcf110274c';
      final url = resolveDartPadZipUrl(channel: 'dev', revision: sha);
      check(url.toString()).equals(
        'https://storage.googleapis.com/dart-archive/channels/'
        'dev/raw/hash/$sha/dartpad/dartpad.zip',
      );
    });

    test('rejects --version on main channel', () {
      check(
        () => resolveDartPadZipUrl(channel: 'main', version: '3.14.0'),
      ).throws<FormatException>();
    });

    test('rejects invalid revision SHA', () {
      check(
        () => resolveDartPadZipUrl(channel: 'main', revision: 'not-a-sha'),
      ).throws<FormatException>();
    });
  });

  group('inferDartChannelFromVersion', () {
    test('maps edge/dev/beta/stable version strings to archive channels', () {
      check(
        inferDartChannelFromVersion('3.14.0-edge.6a318e4f37b'),
      ).equals('main');
      check(inferDartChannelFromVersion('3.14.0-262.0.dev')).equals('dev');
      check(inferDartChannelFromVersion('3.14.0-211.1.beta')).equals('beta');
      check(inferDartChannelFromVersion('3.13.4')).equals('stable');
    });
  });
}
