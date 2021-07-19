// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/src/dap/protocol_generated.dart';
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  testDap((dap) async {
    group('debug mode', () {
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

      test('runs with DDS', () async {
        final client = dap.client;
        final testFile = dap.createTestFile(simpleBreakpointProgram);
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        await client.hitBreakpoint(testFile, breakpointLine);
        expect(await client.ddsAvailable, isTrue);
      });
      // These tests can be slow due to starting up the external server process.
    }, timeout: Timeout.none);

    test('runs with auth codes enabled', () async {
      final testFile = dap.createTestFile(emptyProgram);

      final outputEvents = await dap.client.collectOutput(file: testFile);
      expect(_hasAuthCode(outputEvents.first), isTrue);
    });
  });

  testDap((dap) async {
    group('debug mode', () {
      test('runs without DDS', () async {
        final client = dap.client;
        final testFile = dap.createTestFile(simpleBreakpointProgram);
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        await client.hitBreakpoint(testFile, breakpointLine);

        expect(await client.ddsAvailable, isFalse);
      });

      test('runs with auth tokens disabled', () async {
        final testFile = dap.createTestFile(emptyProgram);

        final outputEvents = await dap.client.collectOutput(file: testFile);
        expect(_hasAuthCode(outputEvents.first), isFalse);
      });
      // These tests can be slow due to starting up the external server process.
    }, timeout: Timeout.none);
  }, additionalArgs: ['--no-dds', '--no-auth-codes']);

  testDap((dap) async {
    group('debug mode', () {
      test('can run with ipv6', () async {
        final testFile = dap.createTestFile(emptyProgram);

        final outputEvents = await dap.client.collectOutput(file: testFile);
        final vmServiceUri = _extractVmServiceUri(outputEvents.first);

        // Check DAP server host.
        expect(dap.server.host, equals('::1'));
        // Check VM Service/DDS host.
        expect(vmServiceUri.host, equals('::1'));
      });
      // These tests can be slow due to starting up the external server process.
    }, timeout: Timeout.none);
  }, additionalArgs: ['--ipv6']);
}

/// Extracts the VM Service URI from the "Connecting to ..." banner output by
/// the DAP server upon connection.
Uri _extractVmServiceUri(OutputEventBody vmConnectionBanner) {
  // TODO(dantup): Change this to use the dart.debuggerUris custom event
  //   if implemented (whch VS Code also needs).
  final vmServiceUriPattern = RegExp(r'Connecting to VM Service at ([^\s]+)\s');
  final match = vmServiceUriPattern.firstMatch(vmConnectionBanner.output);
  return Uri.parse(match!.group(1)!);
}

/// Checks for the presence of an auth token in a VM Service URI in the
/// "Connecting to VM Service" [OutputEvent].
bool _hasAuthCode(OutputEventBody vmConnectionBanner) {
  final vmServiceUri = _extractVmServiceUri(vmConnectionBanner);
  final authCodePattern = RegExp(r'^/[\w=]{5,15}/ws');
  return authCodePattern.hasMatch(vmServiceUri.path);
}
