// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:checks/context.dart';
import 'package:dartpad/dartpad.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'asset_server/asset_server_client.dart';

export 'package:test/test.dart' show TestOn, printOnFailure;
export 'checks_ext.dart';

final class TestContext {
  final AssetServerClient server;
  final DartPad dartpad;
  final Workspace ws;
  final Sandbox sandbox;
  final consoleLog = <String>[];

  TestContext._(this.server, this.dartpad, this.ws, this.sandbox) {
    sandbox.onConsole.listen((event) {
      consoleLog.add(event.message);
      printOnFailure('[sandbox] console.${event.level.name}: ${event.message}');
    });
  }

  /// Check that console has emitted or will emit a message satisfying
  /// [condition].
  Future<void> checkConsole(
    Condition<String> condition, {
    Duration timeLimit = const Duration(seconds: 5),
  }) async {
    if (consoleLog.any((line) => softCheck(line, condition) == null)) {
      return;
    }

    await sandbox.onConsole
        .firstWhere((event) => softCheck(event.message, condition) == null)
        .timeout(
          timeLimit,
          onTimeout: () => throw TestFailure(
            'Expected console message with $timeLimit that '
            '${describe(condition).join('\n')}',
          ),
        );
  }
}

void testDartIntegration(
  String description,
  Future<void> Function(TestContext ctx) fn,
) {
  test(description, () async {
    final server = await AssetServerClient.spawnHybrid(stayAlive: false);

    // Initialize DartPad Worker
    printOnFailure('# Creating worker');
    final sdk = DartPadSdk(assetBaseUrl: server.baseUrl.resolve('dart/'));
    final dartpad = await sdk.dedicatedWorker(pubHostedUrl: server.baseUrl);

    printOnFailure('# Creating workspace');
    final workspace = await dartpad.createWorkspace();

    // Initialize Sandbox
    printOnFailure('# Initializing sandbox');
    final sandbox = await Sandbox.createIFrame(
      web.document.body!,
      assetBaseUrl: server.baseUrl.resolve('dart/'),
    );

    try {
      await fn(TestContext._(server, dartpad, workspace, sandbox));
    } finally {
      try {
        sandbox.dispose();
      } finally {
        try {
          await workspace.dispose();
        } finally {
          await dartpad.dispose();
        }
      }
    }
  });
}

void testFlutterIntegration(
  String description,
  Future<void> Function(TestContext ctx) fn,
) {
  test(description, timeout: const Timeout(Duration(seconds: 120)), () async {
    final server = await AssetServerClient.spawnHybrid(stayAlive: false);

    if (!server.hasFlutter) {
      markTestSkipped(
        'Run pkg/dartpad_worker/tool/setup_local_flutter.dart to '
        'enable flutter tests',
      );
      return;
    }

    // Initialize DartPad Worker
    printOnFailure('# Creating worker');
    final sdk = DartPadSdk(assetBaseUrl: server.baseUrl.resolve('flutter/'));
    final dartpad = await sdk.dedicatedWorker(pubHostedUrl: server.baseUrl);

    printOnFailure('# Creating workspace');
    final workspace = await dartpad.createWorkspace();

    // Initialize Sandbox
    printOnFailure('# Initializing sandbox');
    final sandbox = await Sandbox.createIFrame(
      web.document.body!,
      assetBaseUrl: server.baseUrl.resolve('flutter/'),
    );

    try {
      await fn(TestContext._(server, dartpad, workspace, sandbox));
    } finally {
      try {
        sandbox.dispose();
      } finally {
        try {
          await workspace.dispose();
        } finally {
          await dartpad.dispose();
        }
      }
    }
  });
}
