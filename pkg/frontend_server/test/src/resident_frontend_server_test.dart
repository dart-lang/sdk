// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:frontend_server/src/resident_frontend_server.dart';
import 'package:frontend_server/starter.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() async {
  // Files are considered to be modified if the modification timestamp is
  // during the same second of the last compile time due to the
  // granularity of file stat on windows.
  // Waiting for this number of milliseconds guarantees that the files in
  // the unit tests will not be counted as modified.
  const statGranularity = 1100;

  group('Resident Frontend Server: invalid input: ', () {
    test('no command given', () async {
      final jsonResponse = await ResidentFrontendServer.handleRequest(
          jsonEncode(<String, Object>{"no": "command"}));
      expect(
          jsonResponse,
          equals(jsonEncode(<String, Object>{
            "success": false,
            "errorMessage": "Unsupported command: null."
          })));
    });

    test('invalid command', () async {
      final jsonResponse = await ResidentFrontendServer.handleRequest(
          jsonEncode(<String, Object>{"command": "not a command"}));
      expect(
          jsonResponse,
          equals(jsonEncode(<String, Object>{
            "success": false,
            "errorMessage": "Unsupported command: not a command."
          })));
    });

    test('not a JSON request', () async {
      final jsonResponse = await ResidentFrontendServer.handleRequest("hello");
      expect(
          jsonResponse,
          equals(jsonEncode(<String, Object>{
            "success": false,
            "errorMessage": "hello is not valid JSON."
          })));
    });

    test('missing files for compile command', () async {
      final jsonResponse = await ResidentFrontendServer.handleRequest(
          jsonEncode(<String, Object>{"command": "compile"}));
      expect(
          jsonResponse,
          equals(jsonEncode(<String, Object>{
            "success": false,
            "errorMessage":
                "compilation requests must include an executable and an output-dill path."
          })));
    });
  });

  group('Resident Frontend Server: compile tests: ', () {
    late Directory d;
    late File executable, package, cachedDill;

    setUp(() async {
      d = Directory.systemTemp.createTempSync();
      executable = File(path.join(d.path, 'src1.dart'))
        ..createSync()
        ..writeAsStringSync('void main() {print("hello " "there");}');
      package = File(path.join(d.path, '.dart_tool', 'package_config.json'))
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
      cachedDill = File(path.join(d.path, 'src1.dart.dill'));
    });

    tearDown(() async {
      d.deleteSync(recursive: true);
      ResidentFrontendServer.compilers.clear();
    });

    test('initial compile, basic', () async {
      final compileResult = jsonDecode(
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
      final compileResult1 = jsonDecode(
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
      final compileResult1 = jsonDecode(
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
      final compileResult = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path, outputDill: cachedDill.path)));

      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      expect(compileResult['output-dill'], equals(cachedDill.path));
    });

    test('incremental compilation', () async {
      await Future.delayed(Duration(milliseconds: statGranularity));
      final compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
      )));
      executable.writeAsStringSync(
          executable.readAsStringSync().replaceFirst('there', 'world'));

      final compileResults2 = jsonDecode(
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
          equals(Uri.file(executable.path)));
      expect(
          ResidentFrontendServer
              .compilers[executable.path]!.trackedSources.length,
          1);
    });

    test(
        'compiling twice with no modifications returns cached kernel without invoking compiler',
        () async {
      await Future.delayed(Duration(milliseconds: statGranularity));
      final compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final compileResults2 = jsonDecode(
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
      final executable2 = File(path.join(d.path, 'src2.dart'))
        ..writeAsStringSync('void main() {}');
      final entryPointDill = File(path.join(d.path, 'src2.dart.dill'));

      final compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final compileResults2 = jsonDecode(
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
          equals(Uri.file(executable.path)));
      expect(
          ResidentFrontendServer
              .compilers[executable2.path]!.trackedSources.length,
          1);
      expect(
          ResidentFrontendServer
              .compilers[executable2.path]!.trackedSources.first,
          equals(Uri.file(executable2.path)));
      expect(ResidentFrontendServer.compilers.length, 2);
    });

    test('Cached kernel is removed between compilation requests', () async {
      await Future.delayed(Duration(milliseconds: statGranularity));
      final compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));

      executable.writeAsStringSync(
          executable.readAsStringSync().replaceFirst('there', 'world'));
      cachedDill.deleteSync();
      expect(cachedDill.existsSync(), false);

      final compileResults2 = jsonDecode(
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
      await Future.delayed(Duration(milliseconds: statGranularity));
      final executable2 = File(path.join(d.path, 'src2.dart'))
        ..createSync()
        ..writeAsStringSync('''
            import 'src3.dart';
            void main() {}''');
      final executable3 = File(path.join(d.path, 'src3.dart'))
        ..createSync()
        ..writeAsStringSync('''
            void fn() {}''');

      // adding or removing package_config.json while maintaining the same entrypoint
      // should not alter tracked sources
      await ResidentFrontendServer.handleRequest(
          ResidentFrontendServer.createCompileJSON(
              executable: executable.path, outputDill: cachedDill.path));
      await ResidentFrontendServer.handleRequest(
          ResidentFrontendServer.createCompileJSON(
              executable: executable.path,
              packages: package.path,
              outputDill: cachedDill.path));
      final compileResult1 = jsonDecode(
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
          equals(Uri.file(executable.path)));

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
      await Future.delayed(Duration(milliseconds: statGranularity));

      final compileResult2 = jsonDecode(
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
          containsAll(
              <Uri>{Uri.file(executable2.path), Uri.file(executable3.path)}));

      // remove a source
      executable2.writeAsStringSync('void main() {}');
      final compileResult3 = jsonDecode(
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
          containsAll(<Uri>{Uri.file(executable2.path)}));
    });

    test('continues to work after compiler error is produced', () async {
      final originalContent = executable.readAsStringSync();
      final newContent = originalContent.replaceAll(';', '@');
      await Future.delayed(Duration(milliseconds: statGranularity));

      executable.writeAsStringSync(newContent);
      final compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));

      executable.writeAsStringSync(originalContent);
      final compileResults2 = jsonDecode(
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
          equals(Uri.file(executable.path)));
    });

    test('using cached kernel maintains error messages', () async {
      final originalContent = executable.readAsStringSync();
      executable.writeAsStringSync(originalContent.replaceFirst(';', ''));
      await Future.delayed(Duration(milliseconds: statGranularity));

      final compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
      )));
      final compileResults2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
        executable: executable.path,
        packages: package.path,
        outputDill: cachedDill.path,
      )));
      executable.writeAsStringSync(originalContent);
      final compileResults3 = jsonDecode(
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
      final executable2 = File(path.join(d.path, 'src2.dart'))
        ..createSync()
        ..writeAsStringSync('''
            import 'src3.dart';
            void main() {}''');
      final executable3 = File(path.join(d.path, 'src3.dart'))
        ..createSync()
        ..writeAsStringSync('''
            void main() {}''');
      final executable4 = File(path.join(d.path, 'src4.dart'))
        ..createSync()
        ..writeAsStringSync('''
            void main() {}''');
      final compileResults1 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final compileResults2 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable2.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final compileResults3 = jsonDecode(
          await ResidentFrontendServer.handleRequest(
              ResidentFrontendServer.createCompileJSON(
                  executable: executable3.path,
                  packages: package.path,
                  outputDill: cachedDill.path)));
      final compileResults4 = jsonDecode(
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
      serverInfo = File(path.join(d.path, 'info.txt'));
    });
    tearDown(() {
      d.deleteSync(recursive: true);
    });

    test('ServerSocket fails to bind', () async {
      final result = await residentListenAndCompile(
          InternetAddress.loopbackIPv4, -1, serverInfo);

      expect(serverInfo.existsSync(), false);
      expect(result, null);
    });

    test('socket passes messages properly and shutsdown properly', () async {
      await residentListenAndCompile(
          InternetAddress.loopbackIPv4, 0, serverInfo);

      expect(serverInfo.existsSync(), true);
      final info = serverInfo.readAsStringSync();
      final address = InternetAddress(
          info.substring(info.indexOf(':') + 1, info.indexOf(' ')));
      final port = int.parse(info.substring(info.lastIndexOf(':') + 1));

      final shutdownResult = await sendAndReceiveResponse(
          address, port, ResidentFrontendServer.shutdownCommand);

      expect(shutdownResult, equals(<String, dynamic>{"shutdown": true}));
      expect(serverInfo.existsSync(), false);
    });

    test('timed shutdown', () async {
      await residentListenAndCompile(
          InternetAddress.loopbackIPv4, 0, serverInfo,
          inactivityTimeout: Duration(milliseconds: 100));

      expect(serverInfo.existsSync(), true);
      final info = serverInfo.readAsStringSync();
      final address = InternetAddress(
          info.substring(info.indexOf(':') + 1, info.indexOf(' ')));
      final port = int.parse(info.substring(info.lastIndexOf(':') + 1));

      await Future.delayed(Duration(milliseconds: 150));
      expect(serverInfo.existsSync(), false);

      final shutdownResult = await sendAndReceiveResponse(
          address, port, ResidentFrontendServer.shutdownCommand);
      expect(shutdownResult['errorMessage'], contains('SocketException'));
    });

    test('concurrent startup requests', () async {
      final serverSubscription = await residentListenAndCompile(
        InternetAddress.loopbackIPv4,
        0,
        serverInfo,
      );
      final startWhileAlreadyRunning = await residentListenAndCompile(
        InternetAddress.loopbackIPv4,
        0,
        serverInfo,
      );

      expect(serverSubscription, isNot(null));
      expect(startWhileAlreadyRunning, null);
      expect(serverInfo.existsSync(), true);

      final info = serverInfo.readAsStringSync();
      final address = InternetAddress(
          info.substring(info.indexOf(':') + 1, info.indexOf(' ')));
      final port = int.parse(info.substring(info.lastIndexOf(':') + 1));

      final shutdownResult = await sendAndReceiveResponse(
          address, port, ResidentFrontendServer.shutdownCommand);
      expect(shutdownResult, equals(<String, dynamic>{"shutdown": true}));
      expect(serverInfo.existsSync(), false);
    });

    test('resident server starter', () async {
      final returnValue =
          starter(['--resident-info-file-name=${serverInfo.path}']);
      expect(await returnValue, 0);
      expect(serverInfo.existsSync(), true);
      final info = serverInfo.readAsStringSync();
      final address = InternetAddress(
          info.substring(info.indexOf(':') + 1, info.indexOf(' ')));
      final port = int.parse(info.substring(info.lastIndexOf(':') + 1));

      var result = await sendAndReceiveResponse(
          address, port, ResidentFrontendServer.shutdownCommand);
      expect(result, equals(<String, dynamic>{"shutdown": true}));
      expect(serverInfo.existsSync(), false);

      result = await sendAndReceiveResponse(
          address, port, ResidentFrontendServer.shutdownCommand);
      expect(result['errorMessage'], contains('SocketException'));
    });
  });
}
