// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'mocks.dart';

main() {
  group('dart base adapter', () {
    final vmPath = Platform.resolvedExecutable;
    final sdkRoot = path.dirname(path.dirname(vmPath));

    final sdkCorePath = path.join(sdkRoot, 'lib', 'core.dart');
    final defaultCoreUri = Uri.parse('org-dartlang-sdk:///sdk/lib/core.dart');

    group('default org-dartlang-sdk', () {
      final adapter = MockDartCliDebugAdapter();

      test('can SDK paths to org-dartlang-sdk:///', () async {
        expect(
          adapter.convertPathToOrgDartlangSdk(sdkCorePath),
          defaultCoreUri,
        );
      });

      test('converts org-dartlang-sdk:/// to SDK paths', () async {
        expect(
          adapter.convertOrgDartlangSdkToPath(defaultCoreUri),
          sdkCorePath,
        );
      });
    });

    group('custom org-dartlang-sdk', () {
      final adapter = MockDartCliDebugAdapter()
        ..dartlangSdkRootUriOverride =
            Uri.parse('org-dartlang-sdk:///custom/sdk');
      final customCoreUri =
          Uri.parse('org-dartlang-sdk:///custom/sdk/lib/core.dart');

      test('converts SDK paths to custom org-dartlang-sdk:///', () async {
        expect(
          adapter.convertPathToOrgDartlangSdk(sdkCorePath),
          customCoreUri,
        );
      });

      test('converts custom org-dartlang-sdk:/// to SDK paths', () async {
        expect(
          adapter.convertOrgDartlangSdkToPath(customCoreUri),
          sdkCorePath,
        );
      });

      test('does not convert default org-dartlang-sdk:///', () async {
        expect(
          adapter.convertOrgDartlangSdkToPath(defaultCoreUri),
          isNull,
        );
      });
    });
  });
}
