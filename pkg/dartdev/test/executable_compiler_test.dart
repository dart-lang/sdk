// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/executable_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:pub/pub.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('ExecutableCompiler', () {
    test('pathOfSnapshot returns expected path format', () {
      final snapshotPath = ExecutableCompiler.pathOfSnapshot(
        workspaceRoot: '/my/workspace',
        packageName: 'foo',
        relativeScriptPath: p.join('bin', 'bar.dart'),
      );

      expect(
        snapshotPath,
        p.join(
          '/my/workspace',
          '.dart_tool',
          'dartdev',
          'bin',
          'foo',
          'bin',
          'bar.dart.snapshot',
        ),
      );
    });

    test('parseDepfile parses Ninja/Makefile depfiles', () {
      expect(ExecutableCompiler.parseDepfile('target: '), isEmpty);
      expect(ExecutableCompiler.parseDepfile('target:   '), isEmpty);
      expect(ExecutableCompiler.parseDepfile('no colon'), isNull);
      expect(ExecutableCompiler.parseDepfile(r'target: foo.dart\'), isNull);
      expect(
        ExecutableCompiler.parseDepfile('target: foo.dart bar.dart\n'),
        ['foo.dart', 'bar.dart'],
      );
      expect(
        ExecutableCompiler.parseDepfile(r'target: /path\ with/space.dart'),
        ['/path with/space.dart'],
      );
      expect(
        ExecutableCompiler.parseDepfile(r'target: /path\\\ with/space.dart'),
        [r'/path\ with/space.dart'],
      );
      expect(
        ExecutableCompiler.parseDepfile(r'target: c:\\foo\\bar.dart'),
        [r'c:\foo\bar.dart'],
      );
    });

    test(
      'compiles executable and reuses snapshot when fresh via depfile',
      () async {
        final pDir = Directory.systemTemp.createTempSync('exec_compiler_test');
        addTearDown(() => pDir.deleteSync(recursive: true));

        final workspaceDir = p.join(pDir.path, 'workspace');
        final pkgDir = p.join(pDir.path, 'pkg');
        Directory(p.join(pkgDir, 'bin')).createSync(recursive: true);
        Directory(p.join(pkgDir, 'lib')).createSync(recursive: true);

        final helperFile = File(p.join(pkgDir, 'lib', 'helper.dart'));
        helperFile.writeAsStringSync(
          'String get message => "Hello from dep!";',
        );

        final scriptFile = File(p.join(pkgDir, 'bin', 'hello.dart'));
        scriptFile.writeAsStringSync('''
import 'package:dep/helper.dart';
void main() => print(message);
''');

        final dotDartTool = Directory(p.join(workspaceDir, '.dart_tool'));
        dotDartTool.createSync(recursive: true);
        final packageConfigFile = File(
          p.join(dotDartTool.path, 'package_config.json'),
        );
        packageConfigFile.writeAsStringSync(
          jsonEncode({
            'configVersion': 2,
            'packages': [
              {
                'name': 'dep',
                'rootUri': p.toUri(pkgDir).toString(),
                'packageUri': 'lib/',
                'languageVersion': '3.0',
              },
            ],
          }),
        );

        final resolved = DartExecutableWithPackageConfig(
          executable: scriptFile.path,
          packageConfig: packageConfigFile.path,
        );

        // First compilation creates snapshot and depfile
        final firstResult = await ExecutableCompiler.compile(
          resolvedExecutable: resolved,
        );

        final expectedSnapshot = ExecutableCompiler.pathOfSnapshot(
          workspaceRoot: workspaceDir,
          packageName: 'dep',
          relativeScriptPath: p.join('bin', 'hello.dart'),
        );
        expect(File(expectedSnapshot).existsSync(), isTrue);

        final depfile = File(
          '$expectedSnapshot${ExecutableCompiler.depfileExtension}',
        );
        expect(depfile.existsSync(), isTrue);
        final deps = ExecutableCompiler.parseDepfile(
          depfile.readAsStringSync(),
        );
        expect(deps, contains(p.canonicalize(scriptFile.path)));
        expect(deps, contains(p.canonicalize(helperFile.path)));

        final firstModified = File(expectedSnapshot).lastModifiedSync();

        // Second call reuses cached snapshot because no sources or config changed
        final secondResult = await ExecutableCompiler.compile(
          resolvedExecutable: resolved,
        );
        expect(firstResult.executable, secondResult.executable);
        final secondModified = File(expectedSnapshot).lastModifiedSync();
        expect(firstModified, equals(secondModified));

        // Modifying an imported helper file causes recompilation!
        // Backdate the snapshot timestamp so helperFile is strictly newer.
        File(expectedSnapshot).setLastModifiedSync(
          DateTime.now().subtract(const Duration(seconds: 10)),
        );
        helperFile.setLastModifiedSync(DateTime.now());

        await ExecutableCompiler.compile(
          resolvedExecutable: resolved,
        );
        final thirdModified = File(expectedSnapshot).lastModifiedSync();
        expect(thirdModified.isAfter(firstModified), isTrue);

        // Updating package_config.json also causes recompilation
        File(expectedSnapshot).setLastModifiedSync(
          DateTime.now().subtract(const Duration(seconds: 10)),
        );
        packageConfigFile.setLastModifiedSync(DateTime.now());

        await ExecutableCompiler.compile(
          resolvedExecutable: resolved,
        );
        final fourthModified = File(expectedSnapshot).lastModifiedSync();
        expect(fourthModified.isAfter(thirdModified), isTrue);

        // The metadata records the configuration the snapshot was built with.
        final metadataFile = File(
          '$expectedSnapshot${ExecutableCompiler.metadataExtension}',
        );
        expect(metadataFile.existsSync(), isTrue);
        expect(jsonDecode(metadataFile.readAsStringSync()), {
          'version': ExecutableCompiler.metadataVersion,
          'sdkVersion': ExecutableCompiler.sdkVersion,
          'enabledExperiments': <String>[],
        });

        // Asking for a different set of experiments recompiles, even though
        // nothing on disk changed.
        File(expectedSnapshot).setLastModifiedSync(
          DateTime.now().subtract(const Duration(seconds: 10)),
        );
        final fourthModifiedBackdated = File(
          expectedSnapshot,
        ).lastModifiedSync();
        await ExecutableCompiler.compile(
          resolvedExecutable: resolved,
          enabledExperiments: ['native-assets'],
        );
        final fifthModified = File(expectedSnapshot).lastModifiedSync();
        expect(fifthModified.isAfter(fourthModifiedBackdated), isTrue);
        expect(jsonDecode(metadataFile.readAsStringSync()), {
          'version': ExecutableCompiler.metadataVersion,
          'sdkVersion': ExecutableCompiler.sdkVersion,
          'enabledExperiments': ['native-assets'],
        });

        // ... and asking for them again reuses the snapshot.
        await ExecutableCompiler.compile(
          resolvedExecutable: resolved,
          enabledExperiments: ['native-assets'],
        );
        expect(
          File(expectedSnapshot).lastModifiedSync(),
          equals(fifthModified),
        );

        // A snapshot built by another SDK is not reused.
        File(expectedSnapshot).setLastModifiedSync(
          DateTime.now().subtract(const Duration(seconds: 10)),
        );
        final fifthModifiedBackdated = File(
          expectedSnapshot,
        ).lastModifiedSync();
        metadataFile.writeAsStringSync(
          jsonEncode({
            'version': ExecutableCompiler.metadataVersion,
            'sdkVersion': 'some-other-sdk-version',
            'enabledExperiments': ['native-assets'],
          }),
        );
        await ExecutableCompiler.compile(
          resolvedExecutable: resolved,
          enabledExperiments: ['native-assets'],
        );
        expect(
          File(expectedSnapshot).lastModifiedSync().isAfter(
            fifthModifiedBackdated,
          ),
          isTrue,
        );
      },
    );

    test(
      'sweepStaleTempDirs only removes aged-out temp directories',
      () async {
        final dir = Directory.systemTemp.createTempSync('exec_compiler_sweep');
        addTearDown(() => dir.deleteSync(recursive: true));

        Directory tempDir(String name) =>
            Directory(p.join(dir.path, name))..createSync();

        final abandoned = tempDir('tmpAbandoned');
        File(p.join(abandoned.path, 'leftover.dill')).writeAsStringSync('junk');
        final alsoAbandoned = tempDir('tmpOther');
        // Directories not created by the compiler must never be touched, even
        // though they sit next to the snapshots.
        final unrelated = tempDir('bar');
        final snapshot = File(p.join(dir.path, 'hello.dart.snapshot'))
          ..writeAsStringSync('dill');

        // Nothing is old enough to be swept yet.
        ExecutableCompiler.sweepStaleTempDirs(
          dir,
          maxAge: const Duration(days: 365),
        );
        expect(abandoned.existsSync(), isTrue);
        expect(alsoAbandoned.existsSync(), isTrue);

        // Wait briefly so file modification timestamps are strictly in the past.
        await Future.delayed(const Duration(milliseconds: 50));

        // Everything has now aged out, but only the temp directories go.
        ExecutableCompiler.sweepStaleTempDirs(dir, maxAge: Duration.zero);
        expect(abandoned.existsSync(), isFalse);
        expect(alsoAbandoned.existsSync(), isFalse);
        expect(unrelated.existsSync(), isTrue);
        expect(snapshot.existsSync(), isTrue);
      },
    );

    test('compile removes the temp directory it created', () async {
      final pDir = Directory.systemTemp.createTempSync('exec_compiler_tmp');
      addTearDown(() => pDir.deleteSync(recursive: true));

      final workspaceDir = p.join(pDir.path, 'workspace');
      final fakePubCache = p.join(pDir.path, 'cache');
      final pkgDir = p.join(fakePubCache, 'hosted', 'pub.dev', 'dep-1.0.0');
      Directory(p.join(pkgDir, 'bin')).createSync(recursive: true);

      final scriptFile = File(p.join(pkgDir, 'bin', 'hello.dart'));
      scriptFile.writeAsStringSync('void main() => print("Hello from dep!");');

      final dotDartTool = Directory(p.join(workspaceDir, '.dart_tool'));
      dotDartTool.createSync(recursive: true);
      final packageConfigFile = File(
        p.join(dotDartTool.path, 'package_config.json'),
      );
      packageConfigFile.writeAsStringSync(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'dep',
              'rootUri': p.toUri(pkgDir).toString(),
              'packageUri': 'lib/',
              'languageVersion': '3.0',
            },
          ],
        }),
      );

      final snapshotPath = ExecutableCompiler.pathOfSnapshot(
        workspaceRoot: workspaceDir,
        packageName: 'dep',
        relativeScriptPath: p.join('bin', 'hello.dart'),
      );

      await ExecutableCompiler.compile(
        resolvedExecutable: DartExecutableWithPackageConfig(
          executable: scriptFile.path,
          packageConfig: packageConfigFile.path,
        ),
      );

      expect(File(snapshotPath).existsSync(), isTrue);
      final tempParentDir = Directory(
        ExecutableCompiler.pathOfTempDir(workspaceRoot: workspaceDir),
      );
      expect(tempParentDir.existsSync(), isTrue);
      expect(tempParentDir.listSync(), isEmpty);
    });

    test(
      'throws CompilationException when compilation fails and cleans up stale snapshot',
      () async {
        final pDir = Directory.systemTemp.createTempSync(
          'exec_compiler_err_test',
        );
        addTearDown(() => pDir.deleteSync(recursive: true));

        final workspaceDir = p.join(pDir.path, 'workspace');
        final fakePubCache = p.join(pDir.path, 'cache');
        final pkgDir = p.join(fakePubCache, 'hosted', 'pub.dev', 'dep-1.0.0');
        Directory(p.join(pkgDir, 'bin')).createSync(recursive: true);

        final scriptFile = File(p.join(pkgDir, 'bin', 'broken.dart'));
        scriptFile.writeAsStringSync('void main() => print("working");');

        final dotDartTool = Directory(p.join(workspaceDir, '.dart_tool'));
        dotDartTool.createSync(recursive: true);
        final packageConfigFile = File(
          p.join(dotDartTool.path, 'package_config.json'),
        );
        packageConfigFile.writeAsStringSync(
          jsonEncode({
            'configVersion': 2,
            'packages': [
              {
                'name': 'dep',
                'rootUri': p.toUri(pkgDir).toString(),
                'packageUri': 'lib/',
                'languageVersion': '3.0',
              },
            ],
          }),
        );

        final resolved = DartExecutableWithPackageConfig(
          executable: scriptFile.path,
          packageConfig: packageConfigFile.path,
        );

        // First compile succeeds and creates snapshot, depfile, and metadata.
        await ExecutableCompiler.compile(resolvedExecutable: resolved);
        final snapshotPath = ExecutableCompiler.pathOfSnapshot(
          workspaceRoot: workspaceDir,
          packageName: 'dep',
          relativeScriptPath: p.join('bin', 'broken.dart'),
        );
        final snapshotFile = File(snapshotPath);
        final depfile = File(
          '$snapshotPath${ExecutableCompiler.depfileExtension}',
        );
        final metadataFile = File(
          '$snapshotPath${ExecutableCompiler.metadataExtension}',
        );
        expect(snapshotFile.existsSync(), isTrue);
        expect(depfile.existsSync(), isTrue);
        expect(metadataFile.existsSync(), isTrue);

        // Break the script and backdate the snapshot so recompilation runs.
        snapshotFile.setLastModifiedSync(
          DateTime.now().subtract(const Duration(seconds: 10)),
        );
        scriptFile.writeAsStringSync('void main() { this is syntax error }');

        await expectLater(
          () => ExecutableCompiler.compile(
            resolvedExecutable: resolved,
          ),
          throwsA(
            isA<CompilationException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains("Error: 'syntax' isn't a type."),
                isNot(contains('.snapshot.dill')),
              ),
            ),
          ),
        );

        // Stale snapshot, depfile, and metadata should be removed, and no tempDir left.
        expect(snapshotFile.existsSync(), isFalse);
        expect(depfile.existsSync(), isFalse);
        expect(metadataFile.existsSync(), isFalse);
        expect(
          Directory(p.dirname(snapshotPath)).listSync().whereType<Directory>(),
          isEmpty,
        );
      },
    );

    test('end-to-end dart run precompiles and executes dependency', () async {
      final pProject = project(name: 'foo');
      final bar = project(name: 'bar');
      pProject.file('pubspec.yaml', '''
name: foo
environment:
  sdk: '^3.0.0'
dependencies:
  bar:
    path: ${bar.dir.path}
''');
      bar.file('bin/hello.dart', '''
void main(List<String> args) {
  print("Hello from bar:hello \${args.join(' ')}");
}
''');

      final result = await pProject.run(['run', 'bar:hello', 'arg1', 'arg2']);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('Hello from bar:hello arg1 arg2'));
      final snapshot = File(
        ExecutableCompiler.pathOfSnapshot(
          workspaceRoot: pProject.dirPath,
          packageName: 'bar',
          relativeScriptPath: p.join('bin', 'hello.dart'),
        ),
      );
      expect(snapshot.existsSync(), isTrue);
    });

    test('end-to-end dart run respects --verbosity=error', () async {
      final pProject = project(name: 'foo');
      final bar = project(name: 'bar');
      pProject.file('pubspec.yaml', '''
name: foo
environment:
  sdk: '^3.0.0'
dependencies:
  bar:
    path: ${bar.dir.path}
''');
      bar.file('bin/hello.dart', '''
void main(List<String> args) {
  print("Hello from bar:hello");
}
''');
      final result = await pProject.run([
        'run',
        '--verbosity=error',
        'bar:hello',
      ]);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(result.stdout, equals('Hello from bar:hello\n'));
    });

    test(
      'end-to-end dart run preserves Platform.script with spaces in path',
      () async {
        final pProject = project(name: 'foo');
        final barDirWithSpace = Directory(
          p.join(pProject.dirPath, 'deps with space', 'bar'),
        )..createSync(recursive: true);
        File(p.join(barDirWithSpace.path, 'pubspec.yaml')).writeAsStringSync('''
name: bar
environment:
  sdk: '^3.0.0'
''');
        Directory(
          p.join(barDirWithSpace.path, 'bin'),
        ).createSync(recursive: true);
        final scriptProbeFile = File(
          p.join(barDirWithSpace.path, 'bin', 'script_probe.dart'),
        );
        scriptProbeFile.writeAsStringSync('''
import 'dart:io';

void main() {
  print("SCRIPT: \${Platform.script.toFilePath()}");
}
''');

        pProject.file('pubspec.yaml', '''
name: foo
environment:
  sdk: '^3.0.0'
dependencies:
  bar:
    path: ${barDirWithSpace.path}
''');

        final result = await pProject.run([
          'run',
          '--verbosity=error',
          'bar:script_probe',
        ]);
        expect(result.exitCode, 0);
        final expectedPath = p.canonicalize(scriptProbeFile.path);
        expect(result.stdout, contains('SCRIPT: $expectedPath'));
        expect(result.stdout, isNot(contains('.snapshot')));
        expect(result.stdout, isNot(contains('"')));
      },
    );

    test(
      'incremental recompilation reuses existing snapshot when source is modified',
      () async {
        final pProject = project(name: 'foo');
        final bar = project(name: 'bar');
        pProject.file('pubspec.yaml', '''
name: foo
environment:
  sdk: '^3.0.0'
dependencies:
  bar:
    path: ${bar.dir.path}
''');
        bar.file('bin/hello.dart', '''
void main() {
  print("Hello 1");
}
''');

        var result = await pProject.run([
          'run',
          '--verbosity=error',
          'bar:hello',
        ]);
        expect(result.exitCode, 0);
        expect(result.stdout, equals('Hello 1\n'));

        final snapshot = File(
          ExecutableCompiler.pathOfSnapshot(
            workspaceRoot: pProject.dirPath,
            packageName: 'bar',
            relativeScriptPath: p.join('bin', 'hello.dart'),
          ),
        );
        expect(snapshot.existsSync(), isTrue);

        // Backdate snapshot before modifying source so timestamp is strictly newer.
        snapshot.setLastModifiedSync(
          DateTime.now().subtract(const Duration(seconds: 10)),
        );

        // Modify the source code
        bar.file('bin/hello.dart', '''
void main() {
  print("Hello 2");
}
''');

        result = await pProject.run(['run', '--verbosity=error', 'bar:hello']);
        expect(result.exitCode, 0);
        expect(result.stdout, equals('Hello 2\n'));
      },
    );

    test(
      'dart --enable-experiment=<exp> run caches and reuses experiment metadata',
      () async {
        final pProject = project(name: 'foo');
        final bar = project(name: 'bar');
        pProject.file('pubspec.yaml', '''
name: foo
environment:
  sdk: '^3.0.0'
dependencies:
  bar:
    path: ${bar.dir.path}
''');
        bar.file('bin/hello.dart', '''
void main() {
  print("Hello experiment");
}
''');

        // Pass --enable-experiment as a global/VM flag before 'run'
        final result = await pProject.run([
          '--enable-experiment=test-experiment',
          'run',
          '--verbosity=error',
          'bar:hello',
        ]);
        expect(result.exitCode, 0);
        expect(result.stdout, equals('Hello experiment\n'));

        final snapshotPath = ExecutableCompiler.pathOfSnapshot(
          workspaceRoot: pProject.dirPath,
          packageName: 'bar',
          relativeScriptPath: p.join('bin', 'hello.dart'),
        );
        final metadataFile = File(
          '$snapshotPath${ExecutableCompiler.metadataExtension}',
        );
        expect(metadataFile.existsSync(), isTrue);
        expect(jsonDecode(metadataFile.readAsStringSync()), {
          'version': ExecutableCompiler.metadataVersion,
          'sdkVersion': ExecutableCompiler.sdkVersion,
          'enabledExperiments': ['test-experiment'],
        });
      },
    );

    test(
      'scripts with the same basename in different subdirectories do not collide',
      () async {
        final pDir = Directory.systemTemp.createTempSync(
          'exec_compiler_collision_test',
        );
        addTearDown(() => pDir.deleteSync(recursive: true));

        final workspaceDir = p.join(pDir.path, 'workspace');
        final pkgDir = p.join(pDir.path, 'pkg');
        Directory(p.join(pkgDir, 'bin')).createSync(recursive: true);
        Directory(p.join(pkgDir, 'tool')).createSync(recursive: true);

        final binScript = File(p.join(pkgDir, 'bin', 'main.dart'))
          ..writeAsStringSync('void main() => print("From bin/main.dart");');
        final toolScript = File(p.join(pkgDir, 'tool', 'main.dart'))
          ..writeAsStringSync('void main() => print("From tool/main.dart");');

        final dotDartTool = Directory(p.join(workspaceDir, '.dart_tool'))
          ..createSync(recursive: true);
        final packageConfigFile = File(
          p.join(dotDartTool.path, 'package_config.json'),
        );
        packageConfigFile.writeAsStringSync(
          jsonEncode({
            'configVersion': 2,
            'packages': [
              {
                'name': 'foo',
                'rootUri': p.toUri(pkgDir).toString(),
                'packageUri': 'lib/',
                'languageVersion': '3.0',
              },
            ],
          }),
        );

        final resBin = await ExecutableCompiler.compile(
          resolvedExecutable: DartExecutableWithPackageConfig(
            executable: binScript.path,
            packageConfig: packageConfigFile.path,
          ),
          quiet: true,
        );
        final resTool = await ExecutableCompiler.compile(
          resolvedExecutable: DartExecutableWithPackageConfig(
            executable: toolScript.path,
            packageConfig: packageConfigFile.path,
          ),
          quiet: true,
        );

        expect(resBin.executable, isNot(equals(resTool.executable)));

        final binSnapshot = File(
          ExecutableCompiler.pathOfSnapshot(
            workspaceRoot: workspaceDir,
            packageName: 'foo',
            relativeScriptPath: p.join('bin', 'main.dart'),
          ),
        );
        final toolSnapshot = File(
          ExecutableCompiler.pathOfSnapshot(
            workspaceRoot: workspaceDir,
            packageName: 'foo',
            relativeScriptPath: p.join('tool', 'main.dart'),
          ),
        );
        expect(binSnapshot.existsSync(), isTrue);
        expect(toolSnapshot.existsSync(), isTrue);
      },
    );
  });
}
