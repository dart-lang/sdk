// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/src/dap/protocol_generated.dart';
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  group('debug mode', () {
    late DapTestSession dap;
    setUp(() async {
      dap = await DapTestSession.setUp();
    });
    tearDown(() => dap.tearDown());

    test('runs a simple script', () async {
      final testFile = dap.createTestFile(r'''
void main(List<String> args) async {
  print('Hello!');
  print('World!');
  print('args: $args');
}
    ''');

      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.launch(
          testFile.path,
          args: ['one', 'two'],
        ),
      );

      // Expect a "console" output event that prints the URI of the VM Service
      // the debugger connects to.
      final vmConnection = outputEvents.first;
      expect(vmConnection.output,
          startsWith('Connecting to VM Service at ws://127.0.0.1:'));
      expect(vmConnection.category, equals('console'));

      // Expect the normal applications output.
      final output = outputEvents.skip(1).map((e) => e.output).join();
      expectLines(output, [
        'Hello!',
        'World!',
        'args: [one, two]',
        '',
        'Exited.',
      ]);
    });

    test('provides a list of threads', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, '// BREAKPOINT');

      await client.hitBreakpoint(testFile, breakpointLine);
      final response = await client.getValidThreads();

      expect(response.threads, hasLength(1));
      expect(response.threads.first.name, equals('main'));
    });

    test('runs with DDS by default', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, '// BREAKPOINT');

      await client.hitBreakpoint(testFile, breakpointLine);
      expect(await client.ddsAvailable, isTrue);
    });

    test('runs with auth codes enabled by default', () async {
      final testFile = dap.createTestFile(emptyProgram);

      final outputEvents = await dap.client.collectOutput(file: testFile);
      final vmServiceUri = _extractVmServiceUri(outputEvents.first);
      expect(vmServiceUri.path, matches(vmServiceAuthCodePathPattern));
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);

  group('debug mode', () {
    test('can run without DDS', () async {
      final dap = await DapTestSession.setUp(additionalArgs: ['--no-dds']);
      addTearDown(dap.tearDown);

      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, '// BREAKPOINT');

      await client.hitBreakpoint(testFile, breakpointLine);

      expect(await client.ddsAvailable, isFalse);
    });

    test('can run without auth codes', () async {
      final dap =
          await DapTestSession.setUp(additionalArgs: ['--no-auth-codes']);
      addTearDown(dap.tearDown);

      final testFile = dap.createTestFile(emptyProgram);
      final outputEvents = await dap.client.collectOutput(file: testFile);
      final vmServiceUri = _extractVmServiceUri(outputEvents.first);
      expect(vmServiceUri.path, isNot(matches(vmServiceAuthCodePathPattern)));
    });

    test('can run with ipv6', () async {
      final dap = await DapTestSession.setUp(additionalArgs: ['--ipv6']);
      addTearDown(dap.tearDown);

      final testFile = dap.createTestFile(emptyProgram);
      final outputEvents = await dap.client.collectOutput(file: testFile);
      final vmServiceUri = _extractVmServiceUri(outputEvents.first);

      expect(vmServiceUri.host, equals('::1'));
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}

/// Extracts the VM Service URI from the "Connecting to ..." banner output by
/// the DAP server upon connection.
Uri _extractVmServiceUri(OutputEventBody vmConnectionBanner) {
  // TODO(dantup): Change this to use the dart.debuggerUris custom event
  //   if implemented (whch VS Code also needs).
  final match = vmServiceUriPattern.firstMatch(vmConnectionBanner.output);
  return Uri.parse(match!.group(1)!);
}
