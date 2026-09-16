// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend_server/src/resident_frontend_server.dart';
import 'package:frontend_server/resident_frontend_server_utils.dart'
    show computeCachedDillAndCompilerOptionsPaths, sendAndReceiveResponse;
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

  group('Resident Frontend Server utility functions: ', () {
    test('computeCachedDillAndCompilerOptionsPaths', () async {
      // [computeCachedDillAndCompilerOptionsPaths] is implemented using
      // [path.dirname] and [path.basename], and those functions are platform-
      // sensitive, so we test with an example of a Windows path on Windows, and
      // an example of a POSIX path on other platforms.
      if (Platform.isWindows) {
        const String exampleCanonicalizedLibraryPath =
            r'C:\Users\user\directory\file.dart';
        final (
          :cachedDillPath,
          :cachedCompilerOptionsPath,
        ) = computeCachedDillAndCompilerOptionsPaths(
          exampleCanonicalizedLibraryPath,
        );

        expect(
          cachedDillPath,
          path.join(
            Directory.systemTemp.path,
            'dart_resident_compiler_kernel_cache',
            'C__Users_user_directory_file',
            'file.dart.dill',
          ),
        );
        expect(
          cachedCompilerOptionsPath,
          path.join(
            Directory.systemTemp.path,
            'dart_resident_compiler_kernel_cache',
            'C__Users_user_directory_file',
            'file.dart_options.json',
          ),
        );
      } else {
        const String exampleCanonicalizedLibraryPath =
            '/home/user/directory/file.dart';
        final (
          :cachedDillPath,
          :cachedCompilerOptionsPath,
        ) = computeCachedDillAndCompilerOptionsPaths(
          exampleCanonicalizedLibraryPath,
        );

        expect(
          cachedDillPath,
          path.join(
            Directory.systemTemp.path,
            'dart_resident_compiler_kernel_cache',
            '_home_user_directory',
            'file.dart.dill',
          ),
        );
        expect(
          cachedCompilerOptionsPath,
          path.join(
            Directory.systemTemp.path,
            'dart_resident_compiler_kernel_cache',
            '_home_user_directory',
            'file.dart_options.json',
          ),
        );
      }
    });
  });

  group('Resident Frontend Server: invalid input: ', () {
    test('no command given', () async {
      final String jsonResponse = await ResidentFrontendServer.handleRequest(
        jsonEncode(<String, Object>{"no": "command"}),
      );
      expect(
        jsonResponse,
        equals(
          jsonEncode(<String, Object>{
            "success": false,
            "errorMessage": "Unsupported command: null.",
          }),
        ),
      );
    });

    test('invalid command', () async {
      final String jsonResponse = await ResidentFrontendServer.handleRequest(
        jsonEncode(<String, Object>{"command": "not a command"}),
      );
      expect(
        jsonResponse,
        equals(
          jsonEncode(<String, Object>{
            "success": false,
            "errorMessage": "Unsupported command: not a command.",
          }),
        ),
      );
    });

    test('not a JSON request', () async {
      final String jsonResponse = await ResidentFrontendServer.handleRequest(
        "hello",
      );
      expect(
        jsonResponse,
        equals(
          jsonEncode(<String, Object>{
            "success": false,
            "errorMessage": "hello is not valid JSON.",
          }),
        ),
      );
    });

    test('missing files for compile command', () async {
      final String jsonResponse = await ResidentFrontendServer.handleRequest(
        jsonEncode(<String, Object>{"command": "compile"}),
      );
      expect(
        jsonResponse,
        equals(
          jsonEncode(<String, Object>{
            "success": false,
            "errorMessage":
                "'compile' requests must include an 'executable' property and "
                "an 'output-dill' property.",
          }),
        ),
      );
    });
  });

  group("Resident Frontend Server: 'replaceCachedDill' command tests: ", () {
    late Directory d;
    late File executable, outputDill;

    setUp(() async {
      d = Directory.systemTemp.createTempSync();
      executable = new File(path.join(d.path, 'src.dart'))
        ..createSync()
        ..writeAsStringSync('void main() {print("hello " "there");}');
      outputDill = new File(path.join(d.path, 'src.dart.dill'));
    });

    tearDown(() async {
      d.deleteSync(recursive: true);
      ResidentFrontendServer.compilers.clear();
    });

    test('basic', () async {
      final File cachedDillFile = new File(
        computeCachedDillAndCompilerOptionsPaths(executable.path)
            .cachedDillPath,
      );
      expect(cachedDillFile.existsSync(), false);

      final Map<String, dynamic> compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      expect(compileResult['success'], true);

      expect(cachedDillFile.existsSync(), true);
      // Delete the kernel file associated with [executable.path] from the
      // resident frontend compiler kernel cache.
      cachedDillFile.deleteSync();

      final Map<String, dynamic> replaceCachedDillResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          jsonEncode({
            'command': 'replaceCachedDill',
            'replacementDillPath': outputDill.path,
          }),
        ),
      );
      expect(replaceCachedDillResult['success'], true);
      // Calling 'replaceCachedDill' with [outputDill] as the replacement dill
      // should make [outputDill] the kernel file associated with
      // [executable.path] in the resident frontend compiler kernel cache.
      expect(cachedDillFile.existsSync(), true);
      cachedDillFile.deleteSync();
    });

    test("invalid 'replacementDillPath' property in request", () async {
      final Map<String, dynamic> replaceCachedDillResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          jsonEncode({
            'command': 'replaceCachedDill',
            'replacementDillPath': path.join(d.path, 'nonexistent'),
          }),
        ),
      );
      expect(replaceCachedDillResult['success'], false);
    });
  });

  group("Resident Frontend Server: 'compile' command tests: ", () {
    late Directory d;
    late File executable, package, outputDill;

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
      outputDill = new File(path.join(d.path, 'src1.dart.dill'));
    });

    tearDown(() async {
      d.deleteSync(recursive: true);
      ResidentFrontendServer.compilers.clear();
    });

    void executeDillExpectStdout(
      Map<String, dynamic> compileResult,
      String expectedStdOut,
    ) {
      expect(outputDill.path, equals(compileResult['output-dill']));
      ProcessResult runResult = Process.runSync(Platform.resolvedExecutable, [
        outputDill.path,
      ], workingDirectory: d.path);
      String stderr = runResult.stderr.toString();
      expect(stderr, isEmpty);
      String stdout = runResult.stdout.toString().trim();
      expect(stdout, expectedStdOut.trim());
    }

    test('initial compile, basic', () async {
      final Map<String, dynamic> compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      expect(compileResult['output-dill'], equals(outputDill.path));
    });

    test('compile options', () async {
      executable.writeAsStringSync('void main() { int x = 1; }');
      final Map<String, dynamic> compileResult1 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
            supportMirrors: true,
            enableAsserts: true,
            soundNullSafety: true,
            verbosity: 'all',
            define: <String>['-Dvar=2'],
            enableExperiment: <String>['--enable-experiment=test-experiment'],
          ),
        ),
      );

      expect(compileResult1['success'], true);
      expect(compileResult1['errorCount'], 0);

      List<String> savedOptions = getCachedCompilerOptions(executable.path);
      expect(savedOptions, contains('--define=var=2'));
      expect(savedOptions, contains('--enable-experiment=test-experiment'));
    });

    test('can run compiled dill', () async {
      executable.writeAsStringSync('void main() { print("hello world"); }');
      final Map<String, dynamic> compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
            supportMirrors: true,
            enableAsserts: true,
            soundNullSafety: true,
          ),
        ),
      );

      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);

      executeDillExpectStdout(compileResult, "hello world");
    });

    test('Works with -D', () async {
      executable.writeAsStringSync(
        'void main() { print(const String.fromEnvironment("foo")); }',
      );
      final Map<String, dynamic> compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
            supportMirrors: true,
            enableAsserts: true,
            soundNullSafety: true,
            define: ['--define=foo=bar'],
          ),
        ),
      );

      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      executeDillExpectStdout(compileResult, "bar");
    });

    test('Works with changing -D on same entry', () async {
      executable.writeAsStringSync(
        'void main() { print(const String.fromEnvironment("foo")); }',
      );
      // Let everything be old.
      await new Future.delayed(const Duration(milliseconds: statGranularity));

      // First compile.
      for (int i = 0; i < 2; i++) {
        Map<String, dynamic> compileResult = jsonDecode(
          await ResidentFrontendServer.handleRequest(
            createCompileJSON(
              executable: executable.path,
              packages: package.path,
              outputDill: outputDill.path,
              supportMirrors: true,
              enableAsserts: true,
              soundNullSafety: true,
              define: ['--define=foo=bar'],
            ),
          ),
        );
        expect(compileResult['success'], true);
        expect(compileResult['errorCount'], 0);
        executeDillExpectStdout(compileResult, "bar");
        if (i == 1) {
          // Compiling with the same settings again (with data in memory) should
          // reuse existing.
          expect(compileResult['returnedStoredKernel'], true);
        }
      }

      // Second compile with other define. The compiler is in memory.
      Map<String, dynamic> compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
            supportMirrors: true,
            enableAsserts: true,
            soundNullSafety: true,
            define: ['--define=foo=baz'],
          ),
        ),
      );
      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      executeDillExpectStdout(compileResult, "baz");

      // TODO(jensj): Find a way to do the second compile again - with cleared
      // compilers - where we can verify that it didn't actually compile
      // anything.

      // Third compile with other define. The compiler is removed from memory
      // before calling.
      ResidentFrontendServer.compilers.clear();
      compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
            supportMirrors: true,
            enableAsserts: true,
            soundNullSafety: true,
            define: ['--define=foo=qux'],
          ),
        ),
      );
      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      executeDillExpectStdout(compileResult, "qux");

      // Fourth compile with other define. The compiler is removed from memory
      // before calling. The cached compiler options have been removed from disk
      // too.
      ResidentFrontendServer.compilers.clear();
      new File(
        computeCachedDillAndCompilerOptionsPaths(executable.path)
            .cachedCompilerOptionsPath,
      ).deleteSync();
      compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
            supportMirrors: true,
            enableAsserts: true,
            soundNullSafety: true,
            define: ['--define=foo=quux'],
          ),
        ),
      );
      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      executeDillExpectStdout(compileResult, "quux");

      // Fifth compile with other define. The compiler is removed from memory
      // before calling. The cached compiler options have been overwritten with
      // nonsense.
      ResidentFrontendServer.compilers.clear();
      new File(
        computeCachedDillAndCompilerOptionsPaths(executable.path)
            .cachedCompilerOptionsPath,
      ).writeAsStringSync("æbler");
      compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
            supportMirrors: true,
            enableAsserts: true,
            soundNullSafety: true,
            define: ['--define=foo=corge'],
          ),
        ),
      );
      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      executeDillExpectStdout(compileResult, "corge");
    });

    test('produces aot kernel', () async {
      final Map<String, dynamic> compileResult1 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
            soundNullSafety: true,
            verbosity: 'all',
            aot: true,
            tfa: true,
            rta: true,
            treeShakeWriteOnlyFields: true,
            protobufTreeShakerV2: true,
          ),
        ),
      );

      expect(compileResult1['success'], true);
      expect(compileResult1['errorCount'], 0);
    });

    test('no package_config.json provided', () async {
      final Map<String, dynamic> compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      expect(compileResult['success'], true);
      expect(compileResult['errorCount'], 0);
      expect(compileResult['output-dill'], equals(outputDill.path));
    });

    test('incremental compilation', () async {
      await new Future.delayed(const Duration(milliseconds: statGranularity));
      final Map<String, dynamic> compileResults1 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      executable.writeAsStringSync(
        executable.readAsStringSync().replaceFirst('there', 'world'),
      );

      final Map<String, dynamic> compileResults2 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      expect(compileResults1['success'], true);
      expect(
        compileResults1['errorCount'],
        allOf(0, equals(compileResults2['errorCount'])),
      );
      expect(
        compileResults2['output-dill'],
        equals(compileResults1['output-dill']),
      );
      expect(compileResults2['incremental'], true);
      expect(
        ResidentFrontendServer.compilers[executable.path]!.trackedSources.first,
        equals(new Uri.file(executable.path)),
      );
      expect(
        ResidentFrontendServer
            .compilers[executable.path]!
            .trackedSources
            .length,
        1,
      );
    });

    test('compiling twice with no modifications returns cached kernel without '
        'invoking compiler', () async {
      await new Future.delayed(const Duration(milliseconds: statGranularity));
      final Map<String, dynamic> compileResults1 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      final Map<String, dynamic> compileResults2 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      expect(
        compileResults1['errorCount'],
        allOf(0, equals(compileResults2['errorCount'])),
      );
      expect(
        compileResults1['output-dill'],
        equals(compileResults2['output-dill']),
      );
      expect(compileResults2['returnedStoredKernel'], true);
      expect(ResidentFrontendServer.compilers.length, 1);
    });

    test('switch entrypoints gracefully', () async {
      final File executable2 = new File(path.join(d.path, 'src2.dart'))
        ..writeAsStringSync('void main() {}');
      final File entryPointDill = new File(path.join(d.path, 'src2.dart.dill'));

      final Map<String, dynamic> compileResults1 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      final Map<String, dynamic> compileResults2 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable2.path,
            packages: package.path,
            outputDill: entryPointDill.path,
          ),
        ),
      );

      expect(
        compileResults1['success'],
        allOf(true, equals(compileResults2['success'])),
      );
      expect(
        ResidentFrontendServer
            .compilers[executable.path]!
            .trackedSources
            .length,
        1,
      );
      expect(
        ResidentFrontendServer.compilers[executable.path]!.trackedSources.first,
        equals(new Uri.file(executable.path)),
      );
      expect(
        ResidentFrontendServer
            .compilers[executable2.path]!
            .trackedSources
            .length,
        1,
      );
      expect(
        ResidentFrontendServer
            .compilers[executable2.path]!
            .trackedSources
            .first,
        equals(new Uri.file(executable2.path)),
      );
      expect(ResidentFrontendServer.compilers.length, 2);
    });

    test('Cached kernel is removed between compilation requests', () async {
      await new Future.delayed(const Duration(milliseconds: statGranularity));
      final Map<String, dynamic> compileResults1 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      executable.writeAsStringSync(
        executable.readAsStringSync().replaceFirst('there', 'world'),
      );
      outputDill.deleteSync();
      expect(outputDill.existsSync(), false);

      final Map<String, dynamic> compileResults2 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      expect(compileResults1['success'], true);
      expect(
        compileResults1['errorCount'],
        allOf(equals(compileResults2['errorCount']), 0),
      );
      expect(compileResults2['returnedStoredKernel'], null);
      expect(compileResults2['incremental'], true);
      expect(outputDill.existsSync(), true);
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
        createCompileJSON(
          executable: executable.path,
          outputDill: outputDill.path,
        ),
      );
      await ResidentFrontendServer.handleRequest(
        createCompileJSON(
          executable: executable.path,
          packages: package.path,
          outputDill: outputDill.path,
        ),
      );
      final Map<String, dynamic> compileResult1 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      expect(compileResult1['success'], true);
      expect(compileResult1['returnedStoredKernel'], null);
      expect(compileResult1['incremental'], null);
      expect(
        ResidentFrontendServer
            .compilers[executable.path]!
            .trackedSources
            .length,
        1,
      );
      expect(
        ResidentFrontendServer.compilers[executable.path]!.trackedSources.first,
        equals(new Uri.file(executable.path)),
      );

      // switching entrypoints, packages, and modifying packages
      await ResidentFrontendServer.handleRequest(
        createCompileJSON(
          executable: executable2.path,
          outputDill: outputDill.path,
        ),
      );
      await ResidentFrontendServer.handleRequest(
        createCompileJSON(
          executable: executable2.path,
          packages: package.path,
          outputDill: outputDill.path,
        ),
      );

      package.writeAsStringSync(package.readAsStringSync());
      // Forces package to be behind the next computed kernel by 1 second
      // so that the final compilation will be incremental
      await new Future.delayed(const Duration(milliseconds: statGranularity));

      final Map<String, dynamic> compileResult2 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable2.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      expect(compileResult2['success'], true);
      expect(compileResult2['incremental'], null);
      expect(compileResult2['returnedStoredKernel'], null);
      expect(
        ResidentFrontendServer
            .compilers[executable2.path]!
            .trackedSources
            .length,
        greaterThanOrEqualTo(2),
      );
      expect(
        ResidentFrontendServer.compilers[executable2.path]!.trackedSources,
        containsAll(<Uri>{
          new Uri.file(executable2.path),
          new Uri.file(executable3.path),
        }),
      );

      // remove a source
      executable2.writeAsStringSync('void main() {}');
      final Map<String, dynamic> compileResult3 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable2.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      expect(compileResult3['success'], true);
      expect(compileResult3['incremental'], true);
      expect(
        ResidentFrontendServer
            .compilers[executable2.path]!
            .trackedSources
            .length,
        greaterThanOrEqualTo(1),
      );
      expect(
        ResidentFrontendServer.compilers[executable2.path]!.trackedSources,
        containsAll(<Uri>{new Uri.file(executable2.path)}),
      );
    });

    test('continues to work after compiler error is produced', () async {
      final String originalContent = executable.readAsStringSync();
      final String newContent = originalContent.replaceAll(';', '@');
      await new Future.delayed(const Duration(milliseconds: statGranularity));

      executable.writeAsStringSync(newContent);
      final Map<String, dynamic> compileResults1 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      executable.writeAsStringSync(originalContent);
      final Map<String, dynamic> compileResults2 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      expect(compileResults1['success'], false);
      expect(compileResults1['errorCount'], greaterThan(1));
      expect(compileResults2['success'], true);
      expect(compileResults2['errorCount'], 0);
      expect(compileResults2['incremental'], true);
      expect(
        ResidentFrontendServer
            .compilers[executable.path]!
            .trackedSources
            .length,
        1,
      );
      expect(
        ResidentFrontendServer.compilers[executable.path]!.trackedSources.first,
        equals(new Uri.file(executable.path)),
      );
    });

    test('using cached kernel maintains error messages', () async {
      final String originalContent = executable.readAsStringSync();
      executable.writeAsStringSync(originalContent.replaceFirst(';', ''));
      await new Future.delayed(const Duration(milliseconds: statGranularity));

      final Map<String, dynamic> compileResults1 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      final Map<String, dynamic> compileResults2 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      executable.writeAsStringSync(originalContent);
      final Map<String, dynamic> compileResults3 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );

      expect(compileResults2['returnedStoredKernel'], true);
      expect(
        compileResults1['errorCount'],
        allOf(1, equals(compileResults2['errorCount'])),
      );
      expect(
        compileResults2['compilerOutputLines'] as List<dynamic>,
        containsAllInOrder(
          compileResults1['compilerOutputLines'] as List<dynamic>,
        ),
      );
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
          createCompileJSON(
            executable: executable.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      final Map<String, dynamic> compileResults2 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable2.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      final Map<String, dynamic> compileResults3 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable3.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      final Map<String, dynamic> compileResults4 = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable4.path,
            packages: package.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      expect(
        compileResults1['success'],
        allOf(
          true,
          equals(compileResults2['success']),
          equals(compileResults3['success']),
          equals(compileResults4['success']),
        ),
      );
      expect(ResidentFrontendServer.compilers.length, 3);
      expect(
        ResidentFrontendServer.compilers.containsKey(executable4.path),
        true,
      );
    });
  });

  group("Resident Frontend Server: 'compileExpression' command tests: ", () {
    late Directory d;
    late File executable, outputDill;

    setUp(() async {
      d = Directory.systemTemp.createTempSync();
      executable = new File(path.join(d.path, 'src.dart'))
        ..createSync()
        ..writeAsStringSync('void main() {print("hello " "there");}');
      outputDill = new File(path.join(d.path, 'src.dart.dill'));
    });

    tearDown(() async {
      d.deleteSync(recursive: true);
      ResidentFrontendServer.compilers.clear();
    });

    test('basic', () async {
      final Map<String, dynamic> compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      expect(compileResult['success'], true);

      final Map<String, dynamic> compileExpressionResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          jsonEncode({
            'command': 'compileExpression',
            'expression': '101 + 22',
            'definitions': [],
            'definitionTypes': [],
            'typeDefinitions': [],
            'typeBounds': [],
            'typeDefaults': [],
            'libraryUri': executable.uri.toString(),
            'offset': 0,
            'isStatic': true,
            'method': 'main',
          }),
        ),
      );

      expect(compileExpressionResult['success'], true);
      expect(compileExpressionResult['errorCount'], 0);
      expect(compileExpressionResult['kernelBytes'], isA<String>());
    });

    test("when the 'libraryUri' argument begins with 'dart:'", () async {
      final Map<String, dynamic> compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      expect(compileResult['success'], true);

      final Map<String, dynamic> compileExpressionResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          jsonEncode({
            'command': 'compileExpression',
            'expression': 'this + 5',
            'definitions': [],
            'definitionTypes': [],
            'typeDefinitions': [],
            'typeBounds': [],
            'typeDefaults': [],
            'libraryUri': 'dart:core',
            'offset': -1,
            'isStatic': false,
            'class': 'int',
            'rootLibraryUri': executable.uri.toString(),
          }),
        ),
      );

      expect(compileExpressionResult['success'], true);
      expect(compileExpressionResult['errorCount'], 0);
      expect(compileExpressionResult['kernelBytes'], isA<String>());
    });

    test('invalid expression', () async {
      final Map<String, dynamic> compileResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: executable.path,
            outputDill: outputDill.path,
          ),
        ),
      );
      expect(compileResult['success'], true);

      final Map<String, dynamic> compileExpressionResult = jsonDecode(
        await ResidentFrontendServer.handleRequest(
          jsonEncode({
            'command': 'compileExpression',
            'expression': '101 ++ "abc"',
            'definitions': [],
            'definitionTypes': [],
            'typeDefinitions': [],
            'typeBounds': [],
            'typeDefaults': [],
            'libraryUri': executable.uri.toString(),
            'offset': 0,
            'isStatic': true,
            'method': 'main',
          }),
        ),
      );

      expect(compileExpressionResult['success'], false);
      expect(compileExpressionResult['errorCount'], isPositive);
      expect(compileExpressionResult['compilerOutputLines'], [
        "org-dartlang-debug:synthetic_debug_expression:1:1: Error: Can't "
            'assign to this.\n'
            '101 ++ "abc"\n'
            '^',
        'org-dartlang-debug:synthetic_debug_expression:1:8: Error: Expected '
            'one expression, but found additional input.\n'
            '101 ++ "abc"\n'
            '       ^^^^^',
      ]);
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
        InternetAddress.loopbackIPv4,
        -1,
        serverInfo,
      );

      expect(serverInfo.existsSync(), false);
      expect(result, null);
    });

    test('socket passes messages properly and shutsdown properly', () async {
      await residentListenAndCompile(
        InternetAddress.loopbackIPv4,
        0,
        serverInfo,
      );

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
        InternetAddress.loopbackIPv4,
        0,
        serverInfo,
        inactivityTimeout: const Duration(milliseconds: 100),
      );

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
      final Future<int> returnValue = starter([
        '--resident-info-file-name=${serverInfo.path}',
      ]);
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

  group("Resident Frontend Server: 'record-uses' property tests: ", () {
    test('record-uses is rejected in JIT mode', () async {
      final String jsonResponse = await ResidentFrontendServer.handleRequest(
        createCompileJSON(
          executable: 'a.dart',
          outputDill: 'a.dart.dill',
          recordUses: 'out.json',
        ),
      );
      expect(
        jsonDecode(jsonResponse)['errorMessage'],
        equals(
          "The 'record-uses' property is only supported for AOT compilation.",
        ),
      );
    });

    test('record-uses in AOT mode', () async {
      final Directory d = Directory.systemTemp.createTempSync();
      try {
        final File metaFile = new File(
          path.join(d.path, 'meta', 'lib', 'meta.dart'),
        );
        metaFile.createSync(recursive: true);
        metaFile.writeAsStringSync('''
library meta;
class RecordUse {
  const RecordUse();
}
''');

        final File fooFile = new File(
          path.join(d.path, 'foo', 'lib', 'foo.dart'),
        );
        fooFile.createSync(recursive: true);
        fooFile.writeAsStringSync('''
import 'package:meta/meta.dart';
class Foo {
  @RecordUse()
  static void bar() {
    print(42);
  }
}
''');

        final File mainFile = new File(path.join(d.path, 'a.dart'));
        mainFile.writeAsStringSync('''
import 'package:foo/foo.dart';
void main() {
  Foo.bar();
}
''');

        final File packageConfigFile = new File(
          path.join(d.path, '.dart_tool', 'package_config.json'),
        );
        packageConfigFile.createSync(recursive: true);
        packageConfigFile.writeAsStringSync(
          jsonEncode({
            "configVersion": 2,
            "packages": [
              {
                "name": "meta",
                "rootUri": "../meta",
                "packageUri": "lib/",
                "languageVersion": "3.0",
              },
              {
                "name": "foo",
                "rootUri": "../foo",
                "packageUri": "lib/",
                "languageVersion": "3.0",
              },
            ],
          }),
        );

        final File recordedUsesFile = new File(
          path.join(d.path, 'recorded_uses.json'),
        );
        final File outputDill = new File(path.join(d.path, 'app.dill'));

        final String jsonResponse = await ResidentFrontendServer.handleRequest(
          createCompileJSON(
            executable: mainFile.path,
            outputDill: outputDill.path,
            packages: packageConfigFile.path,
            aot: true,
            tfa: true,
            recordUses: recordedUsesFile.path,
            enableExperiment: ['--enable-experiment=record-use'],
          ),
        );
        final Map<String, dynamic> response = jsonDecode(jsonResponse);
        expect(response['success'], true);
        expect(recordedUsesFile.existsSync(), true);
        expect(recordedUsesFile.readAsStringSync(), contains('bar'));

        List<String> savedOptions = getCachedCompilerOptions(mainFile.path);
        expect(savedOptions, contains('--enable-experiment=record-use'));
      } finally {
        d.deleteSync(recursive: true);
        ResidentFrontendServer.compilers.clear();
      }
    });
  });
}

List<String> getCachedCompilerOptions(String mainPath) {
  List cachedCompilerOptionsFileContents = jsonDecode(
    new File(
      computeCachedDillAndCompilerOptionsPaths(mainPath)
          .cachedCompilerOptionsPath,
    ).readAsStringSync(),
  );
  return [...cachedCompilerOptionsFileContents];
}

/// Used to create compile requests for the ResidentFrontendServer.
/// Returns a JSON string that the resident compiler will be able to
/// interpret.
String createCompileJSON({
  required String executable,
  String? packages,
  required String outputDill,
  bool? supportMirrors,
  bool? enableAsserts,
  bool? soundNullSafety,
  String? verbosity,
  bool? aot,
  bool? tfa,
  bool? rta,
  bool? treeShakeWriteOnlyFields,
  bool? protobufTreeShakerV2,
  List<String>? define,
  List<String>? enableExperiment,
  bool verbose = false,
  String? nativeAssetsYaml,
  String? recordUses,
}) {
  assert(
    define == null ||
        define.every((s) => s.startsWith("--define=")) ||
        define.every((s) => s.startsWith("-D")),
  );
  assert(
    enableExperiment == null ||
        enableExperiment.every((s) => s.startsWith("--")),
  );
  return jsonEncode(<String, Object>{
    "command": "compile",
    "executable": executable,
    "output-dill": outputDill,
    "aot": ?aot,
    "define": ?define,
    "enable-asserts": ?enableAsserts,
    "enable-experiment": ?enableExperiment,
    "packages": ?packages,
    "protobuf-tree-shaker-v2": ?protobufTreeShakerV2,
    "rta": ?rta,
    "sound-null-safety": ?soundNullSafety,
    "support-mirrors": ?supportMirrors,
    "tfa": ?tfa,
    "tree-shaker-write-only-fields": ?treeShakeWriteOnlyFields,
    "verbosity": ?verbosity,
    "verbose": verbose,
    "native-assets": ?nativeAssetsYaml,
    "record-uses": ?recordUses,
  });
}
