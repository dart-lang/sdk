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
      final Stream<String> inStream = process!.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter());

      final line = await inStream.first;
      final json = jsonDecode(line);

      // {"event":"server.started","method":"server.started","params":{
      //   "host":"127.0.0.1","port":9100,"pid":93508,"protocolVersion":"1.1.0"
      // }}
      expect(json['event'], 'server.started');
      expect(json['params'], isNotNull);

      final host = json['params']['host'];
      final port = json['params']['port'];
      expect(host, isA<String>());
      expect(port, isA<int>());

      // Connect to the port and confirm we can load a devtools resource.
      HttpClient client = HttpClient();
      final httpRequest = await client.get(host, port, 'index.html');
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

  group('spawns DDS integration', () {
    late TestProject targetProject;
    Process? targetProjectInstance;
    Process? process;

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
      process?.kill();
      targetProjectInstance = null;
      process = null;
      targetProject.dispose();
      p.dispose();
    });

    Future<String> startTargetProject({
      required bool disableServiceAuthCodes,
    }) async {
      targetProjectInstance = await targetProject.start(
        [
          '--disable-dart-dev',
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

    Future<void> startDevTools({
      required String vmServiceUri,
      required bool shouldStartDds,
    }) async {
      process = await p.start([
        'devtools',
        '--no-launch-browser',
        vmServiceUri,
      ]);
      process!.stderr.transform(utf8.decoder).listen(print);

      bool startedDds = false;
      final devToolsServedCompleter = Completer<void>();
      late StreamSubscription sub;
      sub = process!.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((event) async {
        if (event.contains(ddsStartedRegExp)) {
          startedDds = true;
        } else if (event.contains(servingDevToolsRegExp)) {
          await sub.cancel();
          devToolsServedCompleter.complete();
        }
      });

      await devToolsServedCompleter.future;
      expect(startedDds, shouldStartDds);

      // kill the process
      process!.kill();
      process = null;
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
