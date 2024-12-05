// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/commands/devtools.dart';
import 'package:dds/devtools_server.dart';
import 'package:test/test.dart';

import '../utils.dart';

final dartVMServiceRegExp = RegExp(
  r'The Dart VM service is listening on (http://127.0.0.1:.*)',
);
final ddsStartedRegExp = RegExp(
  r'Started the Dart Development Service \(DDS\) at (http://127.0.0.1:.*)',
);
final dtdStartedRegExp = RegExp(
  r'Serving the Dart Tooling Daemon at (ws://127.0.0.1:.*)',
);
final servingDevToolsRegExp = RegExp(
  r'Serving DevTools at (http://127.0.0.1:.*)',
);

void main() {
  group('devtools', devtools, timeout: longTimeout);
}

void devtools() {
  late TestProject p;

  test('--help', () async {
    p = project();
    var result = await p.run(['devtools', '--help']);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Open DevTools'));
    expect(result.stdout,
        contains('Usage: dart devtools [arguments] [service protocol uri]'));

    // Does not show verbose help.
    expect(result.stdout.contains('--try-ports'), isFalse);
  });

  test('--help --verbose', () async {
    p = project();
    var result = await p.run(['devtools', '--help', '--verbose']);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Open DevTools'));
    expect(
        result.stdout,
        contains(
            'Usage: dart [vm-options] devtools [arguments] [service protocol uri]'));

    // Shows verbose help.
    expect(result.stdout, contains('--try-ports'));
  });

  group('integration', () {
    Process? process;

    tearDown(() {
      process?.kill();
    });

    test('serves resources', () async {
      p = project();

      // start the devtools server
      process = await p.start(['devtools', '--no-launch-browser', '--machine']);
      process!.stderr.transform(utf8.decoder).listen(print);

      String? devToolsHost;
      int? devToolsPort;
      final devToolsServedCompleter = Completer<void>();
      final dtdServedCompleter = Completer<void>();

      late StreamSubscription sub;
      sub = process!.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((line) async {
        final json = jsonDecode(line);
        final eventName = json['event'] as String?;
        final params = (json['params'] as Map?)?.cast<String, Object?>();
        switch (eventName) {
          case 'server.dtdStarted':
            // {"event":"server.dtdStarted","params":{
            //   "uri":"ws://127.0.0.1:50882/nQf49D0YcbONeKVq"
            // }}
            expect(params!['uri'], isA<String>());
            dtdServedCompleter.complete();
          case 'server.started':
            // {"event":"server.started","method":"server.started","params":{
            //   "host":"127.0.0.1","port":9100,"pid":93508,"protocolVersion":"1.1.0"
            // }}
            expect(params!['host'], isA<String>());
            expect(params['port'], isA<int>());
            devToolsHost = params['host'] as String;
            devToolsPort = params['port'] as int;

            // We can cancel the subscription because the 'server.started' event
            // is expected after the 'server.dtdStarted' event.
            await sub.cancel();
            devToolsServedCompleter.complete();
          default:
        }
      });

      await Future.wait([
        dtdServedCompleter.future,
        devToolsServedCompleter.future,
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception(
          'Expected DTD and DevTools to be served, but one or both were not.',
        ),
      );

      // Connect to the port and confirm we can load a devtools resource.
      HttpClient client = HttpClient();
      expect(devToolsHost, isNotNull);
      expect(devToolsPort, isNotNull);
      final httpRequest =
          await client.get(devToolsHost!, devToolsPort!, 'index.html');
      final httpResponse = await httpRequest.close();

      final contents =
          (await httpResponse.transform(utf8.decoder).toList()).join();
      client.close();

      expect(contents, contains('DevTools'));

      // kill the process
      process!.kill();
      process = null;
    });
  });

  Future<void> startDevTools({
    String? vmServiceUri,
    bool shouldStartDds = false,
    bool shouldPrintDtd = false,
  }) async {
    final process = await p.start([
      'devtools',
      '--no-launch-browser',
      if (shouldPrintDtd) '--print-dtd',
      if (vmServiceUri != null) vmServiceUri,
    ]);
    process.stderr.transform(utf8.decoder).listen(print);

    bool startedDds = false;
    bool startedDtd = false;
    final devToolsServedCompleter = Completer<void>();
    late StreamSubscription sub;
    sub = process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((event) async {
      print(event);
      if (event.contains(ddsStartedRegExp)) {
        startedDds = true;
      } else if (event.contains(dtdStartedRegExp)) {
        startedDtd = true;
      } else if (event.contains(servingDevToolsRegExp)) {
        await sub.cancel();
        devToolsServedCompleter.complete();
      }
    });

    await devToolsServedCompleter.future;
    expect(startedDds, shouldStartDds);
    expect(startedDtd, shouldPrintDtd);

    // kill the process
    process.kill();
  }

  test('prints DTD URI', () async {
    p = project();
    await startDevTools(shouldPrintDtd: true);
  });

  group('spawns DDS integration', () {
    late TestProject targetProject;
    Process? targetProjectInstance;

    setUp(() {
      // NOTE: we don't use `project()` here since it registers a tear-down
      // which can be called before the target process is killed. This can be
      // problematic on Windows, which won't let us delete directories while a
      // process is actively accessing it. Manually disposing the projects is
      // the easiest way to work around this.
      targetProject = TestProject(
        mainSrc: '''
Future<void> main() async {
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
  }
}
''',
      );
      p = TestProject();
    });

    tearDown(() {
      targetProjectInstance?.kill();
      targetProjectInstance = null;
      targetProject.dispose();
      p.dispose();
    });

    Future<String> startTargetProject({
      required bool disableServiceAuthCodes,
    }) async {
      targetProjectInstance = await targetProject.start(
        [
          '--no-dds',
          '--observe=0',
          if (disableServiceAuthCodes) '--disable-service-auth-codes',
          targetProject.relativeFilePath,
        ],
      );

      final serviceUriCompleter = Completer<String>();
      late StreamSubscription sub;
      sub = targetProjectInstance!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((event) async {
        if (event.contains(dartVMServiceRegExp)) {
          await sub.cancel();
          serviceUriCompleter.complete(
            dartVMServiceRegExp.firstMatch(event)!.group(1),
          );
        }
      });

      return await serviceUriCompleter.future;
    }

    for (final disableAuthCodes in const [true, false]) {
      final authCodesEnabledStr = disableAuthCodes ? 'disabled' : 'enabled';
      test('with auth codes $authCodesEnabledStr', () async {
        final vmServiceUri = await startTargetProject(
          disableServiceAuthCodes: disableAuthCodes,
        );

        // The first run should cause DDS to be started.
        await startDevTools(vmServiceUri: vmServiceUri, shouldStartDds: true);

        // The second run should not since DDS is already running.
        await startDevTools(vmServiceUri: vmServiceUri, shouldStartDds: false);
      });

      test('check for redirect with auth codes $authCodesEnabledStr', () async {
        final vmServiceUri = Uri.parse(
          await startTargetProject(
            disableServiceAuthCodes: disableAuthCodes,
          ),
        );
        var updatedUri =
            await DevToolsCommand.checkForRedirectToExistingDDSInstance(
          vmServiceUri,
        );
        // We should not have followed a redirect since DDS isn't running.
        expect(vmServiceUri, updatedUri);

        // Start DDS for this VM service instance.
        final ddsUri = await DevToolsCommand.maybeStartDDS(
          uri: vmServiceUri,
          ddsHost: DevToolsServer.defaultDdsHost,
          ddsPort: DevToolsServer.defaultDdsPort.toString(),
        );

        // Ensure that navigating to the VM service URI will redirect us to the
        // DDS URI.
        updatedUri =
            await DevToolsCommand.checkForRedirectToExistingDDSInstance(
          vmServiceUri,
        );
        expect(updatedUri, ddsUri);
      });
    }
  });
}
