// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dap/dap.dart';
import 'package:dds/src/dap/adapters/dart.dart';
import 'package:dds/src/dap/protocol_stream.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'mocks.dart';

main() {
  group('dart base adapter', () {
    final vmPath = Platform.resolvedExecutable;
    final sdkRoot = path.dirname(path.dirname(vmPath));

    group('default Dart SDK', () {
      final testPath = path.join(sdkRoot, 'lib', 'core.dart');
      final testUri = Uri.parse('org-dartlang-sdk:///sdk/lib/core.dart');
      final adapter = MockDartCliDebugAdapter();

      test('converts SDK paths to org-dartlang-sdk:///', () async {
        expect(
          adapter.convertUriToOrgDartlangSdk(Uri.file(testPath)),
          testUri,
        );
      });

      test('converts org-dartlang-sdk:/// to SDK paths', () async {
        expect(
          adapter.convertOrgDartlangSdkToPath(testUri),
          Uri.file(testPath),
        );
      });
    });

    group('custom Dart SDK', () {
      final testPath = path.join(sdkRoot, 'lib', 'core.dart');
      final testUri =
          Uri.parse('org-dartlang-sdk:///custom-dart/sdk/lib/core.dart');
      final defaultSdkTestUri =
          Uri.parse('org-dartlang-sdk:///sdk/lib/core.dart');
      final adapter = MockCustomDartCliDebugAdapter(
          {sdkRoot: Uri.parse('org-dartlang-sdk:///custom-dart/sdk')});

      test('converts SDK paths to custom org-dartlang-sdk:///', () async {
        expect(
          adapter.convertUriToOrgDartlangSdk(Uri.file(testPath)),
          testUri,
        );
      });

      test('converts custom org-dartlang-sdk:/// to SDK paths', () async {
        expect(
          adapter.convertOrgDartlangSdkToPath(testUri),
          Uri.file(testPath),
        );
      });

      test('does not convert default org-dartlang-sdk:/// to SDK paths',
          () async {
        expect(
          adapter.convertOrgDartlangSdkToPath(defaultSdkTestUri),
          isNull,
        );
      });
    });

    group('additional SDKs', () {
      final customSdkRootPath = path.join('/my', 'flutter', 'sdk');
      final customSdkRootUri = Uri.parse('org-dartlang-sdk:///flutter/sdk');
      final testPath = path.join(customSdkRootPath, 'lib', 'ui.dart');
      final testUri = Uri.parse('org-dartlang-sdk:///flutter/sdk/lib/ui.dart');
      final adapter = MockCustomDartCliDebugAdapter({
        customSdkRootPath: customSdkRootUri,
      });

      test('converts additional SDK paths to custom org-dartlang-sdk:///',
          () async {
        expect(
          adapter.convertUriToOrgDartlangSdk(Uri.file(testPath)),
          testUri,
        );
      });

      test('converts additional SDK org-dartlang-sdk:/// to paths', () async {
        expect(
          adapter.convertOrgDartlangSdkToPath(testUri),
          Uri.file(testPath),
        );
      });
    });

    group('handles DebugAdapterExceptions', () {
      final request = MockRequest();

      test('launch errors are shown to the user', () async {
        final adapter = MockCustomDartCliDebugAdapter();
        await adapter.configurationDoneRequest(request, null, () {});

        final args = DartLaunchRequestArguments(
          program: 'foo.dart',
          vmAdditionalArgs: ['vm_arg'],
          noDebug: true,
        );

        try {
          await adapter.launchRequest(request, args, () {});
          fail('Did not catch expected DebugAdapterException!');
        } on DebugAdapterException catch (e) {
          expect(e.showToUser, isTrue);
        }
      });

      test('attach errors are shown to the user', () async {
        final adapter = MockCustomDartCliDebugAdapter();
        await adapter.configurationDoneRequest(request, null, () {});

        final args = DartAttachRequestArguments(
          vmServiceUri: 'phony-uri',
        );

        try {
          await adapter.attachRequest(request, args, () {});
          fail('Did not catch expected DebugAdapterException!');
        } on DebugAdapterException catch (e) {
          expect(e.showToUser, isTrue);
        }
      });
    });
  });
}

class MockCustomDartCliDebugAdapter extends MockDartCliDebugAdapter {
  factory MockCustomDartCliDebugAdapter([Map<String, Uri>? customMappings]) {
    final stdinController = StreamController<List<int>>();
    final stdoutController = StreamController<List<int>>();
    final channel = ByteStreamServerChannel(
        stdinController.stream, stdoutController.sink, null);

    return MockCustomDartCliDebugAdapter._(
        customMappings, stdinController.sink, stdoutController.stream, channel);
  }

  MockCustomDartCliDebugAdapter._(
      Map<String, Uri>? customMappings,
      StreamSink<List<int>> stdin,
      Stream<List<int>> stdout,
      ByteStreamServerChannel channel)
      : super.withStreams(stdin, stdout, channel) {
    if (customMappings != null) {
      orgDartlangSdkMappings
        ..clear()
        ..addAll(customMappings);
    }
  }

  @override
  Future<void> attachImpl() {
    throw DebugAdapterException('Unexpected attach error!', showToUser: false);
  }

  @override
  Future<void> launchAndRespond(void Function() _) {
    throw DebugAdapterException('Unexpected launch error!', showToUser: false);
  }
}
