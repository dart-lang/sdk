// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend_server/src/resident_frontend_server.dart';
import 'package:frontend_server/resident_frontend_server_utils.dart'
    show sendAndReceiveResponse;
import 'package:frontend_server/starter.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() async {
  // Files are considered to be modified if the modification timestamp is
  // during the same second of the last compile time due to the
  // granularity of file stat on windows.
  // Waiting for this number of milliseconds guarantees that the files in
  // the unit tests will not be counted as modified.
  const int statGranularity = 1100;

  group('Resident Frontend Server: invalid input: ', () {
    test('no command given', () async {
      final String jsonResponse = await ResidentFrontendServer.handleRequest(
          jsonEncode(<String, Object>{"no": "command"}));
      expect(
          jsonResponse,
          equals(jsonEncode(<String, Object>{
            "success": false,
            "errorMessage": "Unsupported command: null."
          })));
    });

    test('invalid command', () async {
      final String jsonResponse = await ResidentFrontendServer.handleRequest(
          jsonEncode(<String, Object>{"command": "not a command"}));
      expect(
          jsonResponse,
          equals(jsonEncode(<String, Object>{
            "success": false,
            "errorMessage": "Unsupported command: not a command."
          })));
    });

    test('not a JSON request', () async {
      final String jsonResponse =
          await ResidentFrontendServer.handleRequest("hello");
      expect(
          jsonResponse,
          equals(jsonEncode(<String, Object>{
            "success": false,
            "errorMessage": "hello is not valid JSON."
          })));
    });

    test('missing files for compile command', () async {
      final String jsonResponse = await ResidentFrontendServer.handleRequest(
          jsonEncode(<String, Object>{"command": "compile"}));
      expect(
          jsonResponse,
          equals(jsonEncode(<String, Object>{
            "success": false,
            "errorMessage":
                "compilation requests must include an executable and an "
                    "output-dill path."
          })));
    });
  });

  group('Resident Frontend Server: compile tests: ', () {
    late Directory d;
    late File executable, package, cachedDill;

    setUp(() async {
      d = Directory.systemTemp.createTempSync();
      executable = new File(path.join(d.path, 'src1.dart'))
        ..createSync()
        ..writeAsStringSync('void main() {print("hello " "there");}');
      package = new File(path.join(d.path, '.dart_tool', 'package_config.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');
      cachedDill = new File(path.join(d.path, 'src1.dart.dill'));
    });

    tearDown(() async {
      d.deleteSync(recursive: true);
      ResidentFrontendServer.compilers.clear();
    });

    test('initial compile, basic', () async {
      final Map<String, dynamic> compileResult = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));

      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      expect(compileResult['output-dill'], equals(cachedDill.path));
    });

    test('compile options', () async {
      executable.writeAsStringSync('void main() { int x = 1; }');
      final Map<String, dynamic> compileResult1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
        supportMirrors: true,
        enableAsserts: true,
        soundNullSafety: true,
        verbosity: 'all',
        define: <String>['-Dvar=2'],
        enableExperiment: <String>['experimental-flag=vm_name'],
      )));

      expect(compileResult1['success'], true);
      expect(compileResult1['errorCount'], 0);
    });

    test('produces aot kernel', () async {
      final Map<String, dynamic> compileResult1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
        soundNullSafety: true,
        verbosity: 'all',
        aot: true,
        tfa: true,
        rta: true,
        treeShakeWriteOnlyFields: true,
        protobufTreeShakerV2: true,
      )));

      expect(compileResult1['success'], true);
      expect(compileResult1['errorCount'], 0);
    });

    test('no package_config.json provided', () async {
      final Map<String, dynamic> compileResult = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path, outputDill: cachedDill.path)));

      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      expect(compileResult['output-dill'], equals(cachedDill.path));
    });

    test('incremental compilation', () async {
      await new Future.delayed(const Duration(milliseconds: statGranularity));
      final Map<String, dynamic> compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
      )));
      executable.writeAsStringSync(
          executable.readAsStringSync().replaceFirst('there', 'world'));

      final Map<String, dynamic> compileResults2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
      )));

      expect(compileResults1['success'], true);
      expect(compileResults1['errorCount'],
          allOf(0, equals(compileResults2['errorCount'])));
      expect(compileResults2['output-dill'],
          equals(compileResults1['output-dill']));
      expect(compileResults2['incremental'], true);
      expect(
          ResidentFrontendServer
              .compilers[executable.path]!.trackedSources.first,
          equals(new Uri.file(executable.path)));
      expect(
          ResidentFrontendServer
              .compilers[executable.path]!.trackedSources.length,
          1);
    });

    test(
        'compiling twice with no modifications returns cached kernel without '
        'invoking compiler', () async {
      await new Future.delayed(const Duration(milliseconds: statGranularity));
      final Map<String, dynamic> compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final Map<String, dynamic> compileResults2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));

      expect(compileResults1['errorCount'],
          allOf(0, equals(compileResults2['errorCount'])));
      expect(compileResults1['output-dill'],
          equals(compileResults2['output-dill']));
      expect(compileResults2['returnedStoredKernel'], true);
      expect(ResidentFrontendServer.compilers.length, 1);
    });

    test('switch entrypoints gracefully', () async {
      final File executable2 = new File(path.join(d.path, 'src2.dart'))
        ..writeAsStringSync('void main() {}');
      final File entryPointDill = new File(path.join(d.path, 'src2.dart.dill'));

      final Map<String, dynamic> compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final Map<String, dynamic> compileResults2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable2.path,
                  packages: package.path,
                  outputDill: entryPointDill.path)));

      expect(compileResults1['success'],
          allOf(true, equals(compileResults2['success'])));
      expect(
          ResidentFrontendServer
              .compilers[executable.path]!.trackedSources.length,
          1);
      expect(
          ResidentFrontendServer
              .compilers[executable.path]!.trackedSources.first,
          equals(new Uri.file(executable.path)));
      expect(
          ResidentFrontendServer
              .compilers[executable2.path]!.trackedSources.length,
          1);
      expect(
          ResidentFrontendServer
              .compilers[executable2.path]!.trackedSources.first,
          equals(new Uri.file(executable2.path)));
      expect(ResidentFrontendServer.compilers.length, 2);
    });

    test('Cached kernel is removed between compilation requests', () async {
      await new Future.delayed(const Duration(milliseconds: statGranularity));
      final Map<String, dynamic> compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));

      executable.writeAsStringSync(
          executable.readAsStringSync().replaceFirst('there', 'world'));
      cachedDill.deleteSync();
      expect(cachedDill.existsSync(), false);

      final Map<String, dynamic> compileResults2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));

      expect(compileResults1['success'], true);
      expect(compileResults1['errorCount'],
          allOf(equals(compileResults2['errorCount']), 0));
      expect(compileResults2['returnedStoredKernel'], null);
      expect(compileResults2['incremental'], true);
      expect(cachedDill.existsSync(), true);
      expect(ResidentFrontendServer.compilers.length, 1);
    });

    test('maintains tracked sources', () async {
      await new Future.delayed(const Duration(milliseconds: statGranularity));
      final File executable2 = new File(path.join(d.path, 'src2.dart'))
        ..createSync()
        ..writeAsStringSync('''
            import 'src3.dart';
            void main() {}''');
      final File executable3 = new File(path.join(d.path, 'src3.dart'))
        ..createSync()
        ..writeAsStringSync('''
            void fn() {}''');

      // adding or removing package_config.json while maintaining the same
      // entrypoint should not alter tracked sources
      await ResidentFrontendServer.handleRequest(
          ResidentFrontendServer.createCompileJSON(
              executable: executable.path, outputDill: cachedDill.path));
      await ResidentFrontendServer.handleRequest(
          ResidentFrontendServer.createCompileJSON(
              executable: executable.path,
              packages: package.path,
              outputDill: cachedDill.path));
      final Map<String, dynamic> compileResult1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path, outputDill: cachedDill.path)));

      expect(compileResult1['success'], true);
      expect(compileResult1['returnedStoredKernel'], null);
      expect(compileResult1['incremental'], null);
      expect(
          ResidentFrontendServer
              .compilers[executable.path]!.trackedSources.length,
          1);
      expect(
          ResidentFrontendServer
              .compilers[executable.path]!.trackedSources.first,
          equals(new Uri.file(executable.path)));

      // switching entrypoints, packages, and modifying packages
      await ResidentFrontendServer.handleRequest(
          ResidentFrontendServer.createCompileJSON(
              executable: executable2.path, outputDill: cachedDill.path));
      await ResidentFrontendServer.handleRequest(
          ResidentFrontendServer.createCompileJSON(
              executable: executable2.path,
              packages: package.path,
              outputDill: cachedDill.path));

      package.writeAsStringSync(package.readAsStringSync());
      // Forces package to be behind the next computed kernel by 1 second
      // so that the final compilation will be incremental
      await new Future.delayed(const Duration(milliseconds: statGranularity));

      final Map<String, dynamic> compileResult2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable2.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      expect(compileResult2['success'], true);
      expect(compileResult2['incremental'], null);
      expect(compileResult2['returnedStoredKernel'], null);
      expect(
          ResidentFrontendServer
              .compilers[executable2.path]!.trackedSources.length,
          greaterThanOrEqualTo(2));
      expect(
          ResidentFrontendServer.compilers[executable2.path]!.trackedSources,
          containsAll(<Uri>{
            new Uri.file(executable2.path),
            new Uri.file(executable3.path)
          }));

      // remove a source
      executable2.writeAsStringSync('void main() {}');
      final Map<String, dynamic> compileResult3 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable2.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      expect(compileResult3['success'], true);
      expect(compileResult3['incremental'], true);
      expect(
          ResidentFrontendServer
              .compilers[executable2.path]!.trackedSources.length,
          greaterThanOrEqualTo(1));
      expect(ResidentFrontendServer.compilers[executable2.path]!.trackedSources,
          containsAll(<Uri>{new Uri.file(executable2.path)}));
    });

    test('continues to work after compiler error is produced', () async {
      final String originalContent = executable.readAsStringSync();
      final String newContent = originalContent.replaceAll(';', '@');
      await new Future.delayed(const Duration(milliseconds: statGranularity));

      executable.writeAsStringSync(newContent);
      final Map<String, dynamic> compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));

      executable.writeAsStringSync(originalContent);
      final Map<String, dynamic> compileResults2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));

      expect(compileResults1['success'], false);
      expect(compileResults1['errorCount'], greaterThan(1));
      expect(compileResults2['success'], true);
      expect(compileResults2['errorCount'], 0);
      expect(compileResults2['incremental'], true);
      expect(
          ResidentFrontendServer
              .compilers[executable.path]!.trackedSources.length,
          1);
      expect(
          ResidentFrontendServer
              .compilers[executable.path]!.trackedSources.first,
          equals(new Uri.file(executable.path)));
    });

    test('using cached kernel maintains error messages', () async {
      final String originalContent = executable.readAsStringSync();
      executable.writeAsStringSync(originalContent.replaceFirst(';', ''));
      await new Future.delayed(const Duration(milliseconds: statGranularity));

      final Map<String, dynamic> compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
      )));
      final Map<String, dynamic> compileResults2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
      )));
      executable.writeAsStringSync(originalContent);
      final Map<String, dynamic> compileResults3 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
      )));

      expect(compileResults2['returnedStoredKernel'], true);
      expect(compileResults1['errorCount'],
          allOf(1, equals(compileResults2['errorCount'])));
      expect(
          compileResults2['compilerOutputLines'] as List<dynamic>,
          containsAllInOrder(
              compileResults1['compilerOutputLines'] as List<dynamic>));
      expect(compileResults3['errorCount'], 0);
      expect(compileResults3['incremental'], true);
    });

    test('enforces compiler limit', () async {
      final File executable2 = new File(path.join(d.path, 'src2.dart'))
        ..createSync()
        ..writeAsStringSync('''
            import 'src3.dart';
            void main() {}''');
      final File executable3 = new File(path.join(d.path, 'src3.dart'))
        ..createSync()
        ..writeAsStringSync('''
            void main() {}''');
      final File executable4 = new File(path.join(d.path, 'src4.dart'))
        ..createSync()
        ..writeAsStringSync('''
            void main() {}''');
      final Map<String, dynamic> compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final Map<String, dynamic> compileResults2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable2.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final Map<String, dynamic> compileResults3 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable3.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final Map<String, dynamic> compileResults4 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable4.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      expect(
          compileResults1['success'],
          allOf(
              true,
              equals(compileResults2['success']),
              equals(compileResults3['success']),
              equals(compileResults4['success'])));
      expect(ResidentFrontendServer.compilers.length, 3);
      expect(
          ResidentFrontendServer.compilers.containsKey(executable4.path), true);
    });
  });

  group('Resident Frontend Server: socket tests: ', () {
    late Directory d;
    late File serverInfo;

    setUp(() {
      d = Directory.systemTemp.createTempSync();
      serverInfo = new File(path.join(d.path, 'info.txt'));
    });
    tearDown(() {
      d.deleteSync(recursive: true);
    });

    test('ServerSocket fails to bind', () async {
      final StreamSubscription<Socket>? result = await residentListenAndCompile(
          InternetAddress.loopbackIPv4, -1, serverInfo);

      expect(serverInfo.existsSync(), false);
      expect(result, null);
    });

    test('socket passes messages properly and shutsdown properly', () async {
      await residentListenAndCompile(
          InternetAddress.loopbackIPv4, 0, serverInfo);

      expect(serverInfo.existsSync(), true);

      final Map<String, dynamic> shutdownResult = await sendAndReceiveResponse(
        ResidentFrontendServer.shutdownCommand,
        serverInfo,
      );

      expect(shutdownResult, equals(<String, dynamic>{"shutdown": true}));
      expect(serverInfo.existsSync(), false);
    });

    test('timed shutdown', () async {
      await residentListenAndCompile(
          InternetAddress.loopbackIPv4, 0, serverInfo,
          inactivityTimeout: const Duration(milliseconds: 100));

      expect(serverInfo.existsSync(), true);

      await new Future.delayed(const Duration(milliseconds: 150));
      expect(serverInfo.existsSync(), false);

      try {
        await sendAndReceiveResponse(
          ResidentFrontendServer.shutdownCommand,
          serverInfo,
        );
        fail('Expected to catch PathNotFoundException');
      } on PathNotFoundException catch (e) {
        expect(e.message, contains('Cannot open file'));
      }
    });

    test('concurrent startup requests', () async {
      final StreamSubscription<Socket>? serverSubscription =
          await residentListenAndCompile(
        InternetAddress.loopbackIPv4,
        0,
        serverInfo,
      );
      final StreamSubscription<Socket>? startWhileAlreadyRunning =
          await residentListenAndCompile(
        InternetAddress.loopbackIPv4,
        0,
        serverInfo,
      );

      expect(serverSubscription, isNot(null));
      expect(startWhileAlreadyRunning, null);
      expect(serverInfo.existsSync(), true);

      final Map<String, dynamic> shutdownResult = await sendAndReceiveResponse(
        ResidentFrontendServer.shutdownCommand,
        serverInfo,
      );
      expect(shutdownResult, equals(<String, dynamic>{"shutdown": true}));
      expect(serverInfo.existsSync(), false);
    });

    test('resident server starter', () async {
      final Future<int> returnValue =
          starter(['--resident-info-file-name=${serverInfo.path}']);
      expect(await returnValue, 0);
      expect(serverInfo.existsSync(), true);

      Map<String, dynamic> result = await sendAndReceiveResponse(
        ResidentFrontendServer.shutdownCommand,
        serverInfo,
      );
      expect(result, equals(<String, dynamic>{"shutdown": true}));
      expect(serverInfo.existsSync(), false);

      try {
        await sendAndReceiveResponse(
          ResidentFrontendServer.shutdownCommand,
          serverInfo,
        );
        fail('Expected to catch PathNotFoundException');
      } on PathNotFoundException catch (e) {
        expect(e.message, contains('Cannot open file'));
      }
    });
  });
}
