// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/resident_frontend_constants.dart';
import 'package:dartdev/src/resident_frontend_utils.dart';
import 'package:frontend_server/resident_frontend_server_utils.dart'
    show computeCachedDillPath, ResidentCompilerInfo, sendAndReceiveResponse;
import 'package:kernel/binary/tag.dart' show sdkHashNull;
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../utils.dart';

const String soundNullSafetyMessage = 'Info: Compiling with sound null safety.';
const devToolsMessagePrefix =
    'The Dart DevTools debugger and profiler is available at: http://127.0.0.1:';
const dartVMServiceMessagePrefix =
    'The Dart VM service is listening on http://127.0.0.1:';
final dartVMServiceRegExp =
    RegExp(r'The Dart VM service is listening on (http://127.0.0.1:.*)');
const residentFrontendCompilerPrefix =
    'The Resident Frontend Compiler is listening at 127.0.0.1:';
const dtdMessagePrefix = 'The Dart Tooling Daemon (DTD) is available at:';

final observeScript = r'''
void main() async {
  print('Observe smoke test!');
  int i = 0;
  while(true) {
    await Future.delayed(Duration(milliseconds: 10));
    i++;
  }
}
''';

final ffiScript = r'''
import "dart:ffi";

void main() {
  print('ffi native callback test!');
  final function = NativeCallable<Void Function()>.isolateLocal(() {})
    ..keepIsolateAlive = false;
  final asDart = function.nativeFunction.asFunction<void Function()>();
  asDart();
  print('Done: ffi native callback test!');
}
''';

void Function(String) onVmServicesData(
  TestProject p, {
  bool expectDevtoolsMsg = true,
  bool expectDtdMsg = false,
}) {
  bool sawDevtoolsMsg = false;
  bool sawVmServiceMsg = false;
  bool sawProgramMsg = false;
  bool sawDtdMsg = false;
  void onDataImpl(event) {
    if (event.contains(devToolsMessagePrefix)) {
      sawDevtoolsMsg = true;
    } else if (event.contains(dartVMServiceMessagePrefix)) {
      sawVmServiceMsg = true;
    } else if (event.contains('Observe smoke test!')) {
      sawProgramMsg = true;
    } else if (event.contains(dtdMessagePrefix)) {
      sawDtdMsg = true;
    }
    if (sawProgramMsg &&
        sawVmServiceMsg &&
        (sawDtdMsg || !expectDtdMsg) &&
        (sawDevtoolsMsg || !expectDevtoolsMsg)) {
      expect(sawDtdMsg, expectDtdMsg);
      expect(sawDevtoolsMsg, expectDevtoolsMsg);
      p.kill();
    }
  }

  return onDataImpl;
}

void main() async {
  ensureRunFromSdkBinDart();

  group('run', run, timeout: longTimeout);
  group('run --resident', residentRun, timeout: longTimeout);
}

void run() {
  late TestProject p;

  test('--help', () async {
    p = project();
    var result = await p.run(['run', '--help']);

    expect(result.stdout, contains('Run a Dart program.'));
    expect(result.stdout, contains('Debugging options:'));
    expect(
      result.stdout,
      contains(
        'Usage: dart run [arguments] [<dart-file|package-target> [args]]',
      ),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('--help --verbose', () async {
    p = project();
    var result = await p.run(['run', '--help', '--verbose']);

    expect(result.stdout, contains('Run a Dart program.'));
    expect(result.stdout, contains('Debugging options:'));
    expect(
      result.stdout,
      contains(
        'Usage: dart [vm-options] run [arguments] [<dart-file|package-target> [args]]',
      ),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test("'Hello World'", () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    ProcessResult result = await p.run(['run', p.relativeFilePath]);

    expect(result.stdout, contains('Hello World'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('no such file', () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    ProcessResult result =
        await p.run(['run', 'no/such/file/${p.relativeFilePath}']);

    expect(result.stderr, isNotEmpty);
    expect(result.exitCode, isNot(0));
  });

  test('implicit packageName.dart', () async {
    // TODO(jwren) circle back to reimplement this test if possible, the file
    // name (package name) will be the name of the temporary directory on disk
    p = project(mainSrc: "void main() { print('Hello World'); }");
    p.file('bin/main.dart', "void main() { print('Hello main.dart'); }");
    ProcessResult result = await p.run(['run']);

    expect(result.stdout, contains('Hello main.dart'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  }, skip: true);

  // Could not find the implicit file to run: bin
  test('missing implicit packageName.dart', () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    p.file('bin/foo.dart', "void main() { print('Hello main.dart'); }");
    ProcessResult result = await p.run(['run']);

    expect(result.stdout, isEmpty);
    expect(
        result.stderr,
        contains('Could not find `bin${path.separator}dartdev_temp.dart` in '
            'package `dartdev_temp`.'));
    expect(result.exitCode, 255);
  });

  test('experiments are enabled correctly', () async {
    // TODO(bkonyi): find a more robust way to test experiments by exposing
    // enabled experiments for an isolate (e.g., through dart:developer or the
    // VM service).
    //
    // See https://github.com/dart-lang/sdk/issues/50230
    p = project(sdkConstraint: VersionConstraint.parse('>=3.0.0-0 <4.0.0'));
    p.file('main.dart', 'void main(args) { print("Record: \${(1, 2)}"); }');
    ProcessResult result = await p.run([
      'run',
      '--enable-experiment=records',
      'main.dart',
    ]);

    // The records experiment should be enabled.
    expect(result.stdout, contains('Record: '));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);

    // Run again with the experiment disabled to make sure the test is actually
    // working as expected.
    result = await p.run([
      'run',
      'main.dart',
    ]);

    // The records experiment should not be enabled and the program should fail
    // to run.
    expect(result.stdout, isEmpty);
    expect(result.stderr, isNotEmpty);
    expect(result.exitCode, 254);

    p.file('bin/main.dart', 'void main(args) { print("Record: \${(1, 2)}"); }');
    // Run again with the package-syntax
    result = await p.run([
      'run',
      '--enable-experiment=records',
      ':main',
    ]);

    // The records experiment should not be enabled and the program should fail
    // to run.
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Record: '));
    expect(result.exitCode, 0);
  }, skip: 'records are enabled by default in 3.0');

  test('arguments are properly passed', () async {
    p = project();
    p.file('main.dart', 'void main(args) { print(args); }');
    ProcessResult result = await p.run([
      'run',
      '--enable-experiment=test-experiment',
      'main.dart',
      'argument1',
      'argument2',
    ]);

    // --enable-experiment and main.dart should not be passed.
    expect(result.stdout, equals('[argument1, argument2]\n'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('from path-dependency with cyclic dependency', () async {
    p = project(name: 'foo');
    final bar = project(name: 'bar');
    p.file('pubspec.yaml', '''
name: foo
environment:
  sdk: '>=2.12.0<3.0.0'

dependencies: { 'bar': {'path': '${bar.dir.path}'}}
''');
    p.file('lib/foo.dart', r'''
import 'package:bar/bar.dart';
final b = "FOO $bar";
''');

    bar.file('lib/bar.dart', 'final bar = "BAR";');

    bar.file('bin/main.dart', r'''
import 'package:foo/foo.dart';
void main(List<String> args) => print("$b $args");
''');

    ProcessResult result = await p.run(['run', 'bar:main', '--arg1', 'arg2']);

    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('FOO BAR [--arg1, arg2]'));
    expect(result.exitCode, 0);
  });

  test('with absolute file path', () async {
    p = project();
    p.file('main.dart', 'void main(args) { print(args); }');
    // Test with absolute path
    final name = path.join(p.dirPath, 'main.dart');
    final result = await p.run([
      'run',
      '--enable-experiment=test-experiment',
      name,
      '--argument1',
      'argument2',
    ]);

    // --enable-experiment and main.dart should not be passed.
    expect(result.stderr, isEmpty);
    expect(result.stdout, equals('[--argument1, argument2]\n'));
    expect(result.exitCode, 0);
  });

  test('with file uri', () async {
    p = project();
    p.file('main.dart', 'void main(args) { print(args); }');
    // Test with File uri
    final name = path.join(p.dirPath, 'main.dart');
    final result = await p.run([
      'run',
      Uri.file(name).toString(),
      '--argument1',
      'argument2',
    ]);

    // --enable-experiment and main.dart should not be passed.
    expect(result.stderr, isEmpty);
    expect(result.stdout, equals('[--argument1, argument2]\n'));
    expect(result.exitCode, 0);
  });

  test('with accepted VM flags', () async {
    p = project(mainSrc: observeScript);
    // --observe sets the following flags by default:
    //   --enable-vm-service
    //   --pause-isolate-on-exit
    //   --pause-isolate-on-unhandled-exception
    //   --warn-on-pause-with-no-debugger
    //
    // This test ensures that allowed arguments for dart run which are valid VM
    // arguments are properly handled by the VM.
    void onData1(event) {
      if (event.contains('The Dart VM service is listening on')) {
        final re = RegExp(
            r'The Dart VM service is listening on http:\/\/127.0.0.1:\d+\/[a-zA-Z0-9_-]+=\/.*');
        expect(re.hasMatch(event), true);
        p.kill();
      }
    }

    await p.runWithVmService([
      'run',
      '--observe=0',
      '--pause-isolates-on-start',
      // This should negate the above flag.
      '--no-pause-isolates-on-start',
      '--no-pause-isolates-on-exit',
      '--no-pause-isolates-on-unhandled-exceptions',
      '-Dfoo=bar',
      '--define=bar=foo',
      p.relativeFilePath,
    ], onData1);

    // Again, with --disable-service-auth-codes.
    void onData2(event) {
      if (event.contains('The Dart VM service is listening on')) {
        final re = RegExp(
            r'The Dart VM service is listening on http:\/\/127.0.0.1:\d+\/');
        expect(re.hasMatch(event), true);
        p.kill();
      }
    }

    await p.runWithVmService([
      'run',
      '--observe=0',
      '--pause-isolates-on-start',
      // This should negate the above flag.
      '--no-pause-isolates-on-start',
      '--no-pause-isolates-on-exit',
      '--no-pause-isolates-on-unhandled-exceptions',
      '--disable-service-auth-codes',
      '-Dfoo=bar',
      '--define=bar=foo',
      p.relativeFilePath,
    ], onData2);

    // Again, with IPv6.
    void onData3(event) {
      if (event.contains('The Dart VM service is listening on')) {
        final re = RegExp(
            r'The Dart VM service is listening on http:\/\/\[::1\]:\d+\/[a-zA-Z0-9_-]+=\/.*');
        expect(re.hasMatch(event), true);
        p.kill();
      }
    }

    await p.runWithVmService([
      'run',
      '--observe=0/::1',
      '--pause-isolates-on-start',
      // This should negate the above flag.
      '--no-pause-isolates-on-start',
      '--no-pause-isolates-on-exit',
      '--no-pause-isolates-on-unhandled-exceptions',
      '-Dfoo=bar',
      '--define=bar=foo',
      p.relativeFilePath,
    ], onData3);
  });

  test('with accepted VM flags related to the timeline', () async {
    p = project(
        mainSrc: 'import "dart:developer";'
            'void main() {'
            'Timeline.startSync("sync");'
            'Timeline.finishSync();'
            '}');

    final result = await p.run([
      'run',
      '--timeline-recorder=file',
      '--timeline-streams=Dart',
      p.relativeFilePath
    ]);

    expect(result.stderr, isEmpty);
    expect(result.stdout, isEmpty);
    expect(result.exitCode, 0);
    expect(p.findFile('dart-timeline.json')!.readAsStringSync(),
        contains('"name":"sync","cat":"Dart"'));
  });

  test('fails when provided verbose VM flags', () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");

    // Any VM flags not listed under 'dart run help --verbose' should be passed
    // before a dartdev command.
    ProcessResult result = await p.run([
      'run',
      '--vm-name=foo',
      p.relativeFilePath,
    ]);

    expect(result.stdout, isEmpty);
    expect(
      result.stderr,
      contains('Could not find an option named "--vm-name".'),
    );
    expect(result.exitCode, 64);
  });

  test('fails when provided unlisted VM flags', () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");

    // Any VM flags not listed under 'dart run help --verbose' should be passed
    // before a dartdev command.
    ProcessResult result = await p.run([
      'run',
      '--verbose_gc',
      p.relativeFilePath,
    ]);

    expect(result.stdout, isEmpty);
    expect(
      result.stderr,
      contains('Could not find an option named "--verbose_gc".'),
    );
    expect(result.exitCode, 64);
  });

  test('--enable-asserts', () async {
    p = project(mainSrc: 'void main() { assert(false); }');

    // Ensure --enable-asserts doesn't cause the dartdev isolate to fail to
    // load. Regression test for: https://github.com/dart-lang/sdk/issues/42831
    ProcessResult result = await p.run([
      'run',
      '--enable-asserts',
      p.relativeFilePath,
    ]);

    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('Unhandled exception'));
    expect(result.exitCode, 255);
  });

  test('does not interpret VM flags provided after script', () async {
    p = project(mainSrc: 'void main() { assert(false); }');

    // Any VM flags passed after the script shouldn't be interpreted by the VM.
    ProcessResult result = await p.run([
      'run',
      p.relativeFilePath,
      '--enable-asserts',
    ]);

    expect(result.stdout, isEmpty);
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('--enable-service-port-fallback', () async {
    final p = project(mainSrc: observeScript);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final regexp = RegExp(
      r'The Dart VM service is listening on http:\/\/127.0.0.1:(\d*)\/[a-zA-Z0-9_-]+=\/.*',
    );
    void onData(event) {
      if (event.contains('The Dart VM service is listening on')) {
        final vmServicePort = int.parse(regexp.firstMatch(event)!.group(1)!);
        expect(server.port != vmServicePort, isTrue);
        p.kill();
      }
    }

    await p.runWithVmService([
      'run',
      '--enable-vm-service=${server.port}',
      '--enable-service-port-fallback',
      p.relativeFilePath,
    ], onData);
    await server.close();
  });

  test('regression test for dartbug.com/55185', () async {
    final p = project(mainSrc: observeScript);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    void onData(event) {
      if (event.contains('The Dart VM service is listening on')) {
        p.kill();
      }
    }

    await p.runWithVmService([
      'run',
      '--enable-service-port-fallback',
      // This argument must be the final option before the script name to
      // correctly reproduce the failure. Without the fix, dart run's argument
      // parser will assume the argument after --observe is the value for
      // --observe, causing the script path to be swallowed, resulting in Pub
      // trying to resolve the package path for the empty string.
      '--observe',
      p.relativeFilePath,
    ], onData);
    await server.close();
  });

  test('regression test for dartbug.com/56064', () async {
    final p = project(mainSrc: ffiScript);
    Process process = await p.start([
      'run',
      '--enable-vm-service',
      '--no-dds',
      '--disable-service-auth-codes',
      '--pause-isolates-on-unhandled-exceptions',
      p.relativeFilePath,
    ]);
    final completer = Completer<void>();
    late StreamSubscription sub;
    sub = process.stdout.transform(utf8.decoder).listen((event) async {
      if (event.contains(dartVMServiceRegExp)) {
        await sub.cancel();
        completer.complete();
      }
    });
    // Wait for process to start and print VM service message.
    await completer.future;
    // Now wait for the process to terminate, if the issue is not fixed
    // the process will not terminate as it will be paused on the exception,
    // we timeout and return 255 in that case.
    int exitCode = await process.exitCode.timeout(const Duration(seconds: 5),
        onTimeout: () {
      process.kill();
      return 255;
    });
    expect(exitCode, 0);
  });

  test('without verbose CFE info', () async {
    final p = project(mainSrc: '''void main() {}''');

    var result = await p.run(
      [
        'run',
        '--verbosity=warning',
        p.relativeFilePath,
      ],
    );

    expect(result.stdout,
        predicate((dynamic o) => !'$o'.contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('Handles invalid package_config.json', () async {
    // Regression test for https://github.com/dart-lang/sdk/issues/55490
    p = project(mainSrc: "void main() { print('Hello World'); }");
    final packageConfig = File(p.packageConfigPath);
    final contents = jsonDecode(packageConfig.readAsStringSync());
    // Fail fast if the config version changes to make sure this test is kept
    // up to date with package config format changes.
    expect(contents['configVersion'], 2);

    // Duplicate an entry from the package config's package list and overwrite
    // the existing config.
    final packages = contents['packages'] as List;
    expect(packages, isNotEmpty);
    final duplicatePackage = packages.first;
    packages.add(duplicatePackage);
    packageConfig.writeAsStringSync(jsonEncode(contents));

    final result = await p.run(['run', p.relativeFilePath]);
    expect(result.stdout, isEmpty);
    expect(
      result.stderr,
      contains(
        'Error encountered while parsing package_config.json: Duplicate package name',
      ),
    );
    expect(result.exitCode, 255);
  });

  test('workspace', () async {
    final p = project(
        sdkConstraint: VersionConstraint.parse('^3.5.0-0'),
        pubspecExtras: {
          'workspace': ['pkgs/a', 'pkgs/b']
        });
    p.file('pkgs/a/pubspec.yaml', '''
name: a
environment:
  sdk: ^3.5.0-0
resolution: workspace
dependencies:
  b:
''');
    p.file('pkgs/b/pubspec.yaml', '''
name: b
environment:
  sdk: ^3.5.0-0
resolution: workspace
''');
    p.file('pkgs/a/bin/a.dart', '''
main() => print('a:a');
''');
    p.file('pkgs/a/bin/tool.dart', '''
main() => print('a:tool');
''');
    p.file('pkgs/b/bin/b.dart', '''
main() => print('b:b');
''');
    expect(
        await p
            .run(['run', 'a'], workingDir: path.join(p.dirPath, 'pkgs', 'a')),
        isA<ProcessResult>()
            .having((r) => r.exitCode, 'exitCode', 0)
            .having((r) => r.stdout, 'stdout', 'a:a\n'));
    expect(
        await p
            .run(['run', 'a:a'], workingDir: path.join(p.dirPath, 'pkgs', 'a')),
        isA<ProcessResult>()
            .having((r) => r.exitCode, 'exitCode', 0)
            .having((r) => r.stdout, 'stdout', 'a:a\n'));
    expect(
        await p.run(['run', ':tool'],
            workingDir: path.join(p.dirPath, 'pkgs', 'a')),
        isA<ProcessResult>()
            .having((r) => r.exitCode, 'exitCode', 0)
            .having((r) => r.stdout, 'stdout', 'a:tool\n'));
    expect(
        await p
            .run(['run', 'b'], workingDir: path.join(p.dirPath, 'pkgs', 'a')),
        isA<ProcessResult>()
            .having((r) => r.exitCode, 'exitCode', 0)
            .having((r) => r.stdout, 'stdout', 'b:b\n'));
  });

  group('DDS', () {
    group('disable', () {
      test('dart run simple', () async {
        p = project(mainSrc: observeScript);
        await p.runWithVmService(
          [
            'run',
            '--no-dds',
            '--enable-vm-service=0',
            p.relativeFilePath,
          ],
          onVmServicesData(
            p,
            expectDevtoolsMsg: false,
          ),
        );
      });

      test('dart simple', () async {
        p = project(mainSrc: observeScript);
        await p.runWithVmService(
          [
            '--no-dds',
            '--enable-vm-service=0',
            p.relativeFilePath,
          ],
          onVmServicesData(
            p,
            expectDevtoolsMsg: false,
          ),
        );
      });
    });

    group('explicit enable', () {
      test('dart run simple', () async {
        p = project(mainSrc: observeScript);
        final tempDir = Directory.systemTemp.createTempSync('a');
        final serviceInfo = path.join(tempDir.path, 'service.json');
        await p.runWithVmService(
          [
            'run',
            '--dds',
            '--enable-vm-service=0',
            '--write-service-info=$serviceInfo',
            p.relativeFilePath,
          ],
          onVmServicesData(p),
        );
        expect(File(serviceInfo).existsSync(), true);
      });

      test('dart simple', () async {
        p = project(mainSrc: observeScript);
        final tempDir = Directory.systemTemp.createTempSync('a');
        final serviceInfo = path.join(tempDir.path, 'service.json');
        await p.runWithVmService(
          [
            '--dds',
            '--enable-vm-service=0',
            '--write-service-info=$serviceInfo',
            p.relativeFilePath,
          ],
          onVmServicesData(p),
        );
        expect(File(serviceInfo).existsSync(), true);
      });
    });
  });

  group('DevTools', () {
    test('dart run simple', () async {
      p = project(mainSrc: observeScript);
      await p.runWithVmService([
        'run',
        '--enable-vm-service=0',
        p.relativeFilePath,
      ], onVmServicesData(p));
    });

    test('dart simple', () async {
      p = project(mainSrc: observeScript);
      await p.runWithVmService(
        [
          '--enable-vm-service=0',
          p.relativeFilePath,
        ],
        onVmServicesData(p),
      );
    });

    test('dart run explicit', () async {
      p = project(mainSrc: observeScript);
      await p.runWithVmService(
        [
          'run',
          '--serve-devtools',
          '--enable-vm-service=0',
          p.relativeFilePath,
        ],
        onVmServicesData(p),
      );
    });

    test('dart explicit', () async {
      p = project(mainSrc: observeScript);
      await p.runWithVmService([
        '--serve-devtools',
        '--enable-vm-service=0',
        p.relativeFilePath,
      ], onVmServicesData(p));
    });

    test('dart run disabled', () async {
      p = project(mainSrc: observeScript);
      await p.runWithVmService(
        [
          'run',
          '--enable-vm-service=0',
          '--no-serve-devtools',
          p.relativeFilePath,
        ],
        onVmServicesData(
          p,
          expectDevtoolsMsg: false,
        ),
      );
    });

    test('dart disabled', () async {
      p = project(mainSrc: observeScript);
      await p.runWithVmService(
        [
          '--enable-vm-service=0',
          '--no-serve-devtools',
          p.relativeFilePath,
        ],
        onVmServicesData(
          p,
          expectDevtoolsMsg: false,
        ),
      );
    });

    test('dart run VM service not enabled', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = await p.run([
        'run',
        '--serve-devtools',
        p.relativeFilePath,
      ]);
      expect(result.stdout, isNot(contains(devToolsMessagePrefix)));
    });

    test('dart VM service not enabled', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = await p.run([
        '--serve-devtools',
        p.relativeFilePath,
      ]);
      expect(result.stdout, isNot(contains(devToolsMessagePrefix)));
    });

    test(
      'spawn via SIGQUIT',
      () async {
        p = project(
          mainSrc:
              'void main() { print("ready"); int i = 0; while(true) { i++; } }',
        );
        Process process = await p.start([
          p.relativeFilePath,
        ]);

        final readyCompleter = Completer<void>();
        final completer = Completer<void>();

        late StreamSubscription sub;
        sub = process.stdout.transform(utf8.decoder).listen((event) async {
          if (event.contains('ready')) {
            readyCompleter.complete();
          } else if (event.contains(devToolsMessagePrefix)) {
            await sub.cancel();
            completer.complete();
          }
        });
        // Wait for process to start.
        await readyCompleter.future;
        process.kill(ProcessSignal.sigquit);
        await completer.future;
        process.kill();
      },
      // No support for SIGQUIT on Windows.
      skip: Platform.isWindows,
    );
  });

  group('--print-dtd', () {
    test('dart', () async {
      p = project(mainSrc: observeScript);
      await p.runWithVmService(
          [
            '--enable-vm-service=0',
            '--print-dtd',
            p.relativeFilePath,
          ],
          onVmServicesData(
            p,
            expectDtdMsg: true,
          ));
    });

    test('dart run', () async {
      p = project(mainSrc: observeScript);
      await p.runWithVmService(
        [
          'run',
          '--enable-vm-service=0',
          '--print-dtd',
          p.relativeFilePath,
        ],
        onVmServicesData(
          p,
          expectDtdMsg: true,
        ),
      );
    });
  });

  group('Observatory', () {
    void generateServedTest({
      required bool serve,
      required bool enableAuthCodes,
      required bool explicitRun,
      required bool withDds,
    }) {
      test(
        '${serve ? 'served by default' : 'not served'} ${enableAuthCodes ? "with" : "without"} '
        'auth codes, ${explicitRun ? 'explicit' : 'implicit'} run,${withDds ? ' ' : 'no'} DDS',
        () async {
          p = project(
            mainSrc:
                'void main() { print("ready"); int i = 0; while(true) { i++; } }',
          );
          Process process = await p.start([
            if (explicitRun) 'run',
            '--enable-vm-service=0',
            if (!withDds) '--no-dds',
            if (!enableAuthCodes) '--disable-service-auth-codes',
            if (serve) '--serve-observatory',
            p.relativeFilePath,
          ]);

          final completer = Completer<void>();

          late StreamSubscription sub;
          late String uri;
          sub = process.stdout.transform(utf8.decoder).listen((event) async {
            if (event.contains(dartVMServiceRegExp)) {
              uri = dartVMServiceRegExp.firstMatch(event)!.group(1)!;
              await sub.cancel();
              completer.complete();
            }
          });

          // Wait for process to start.
          await completer.future;
          final client = HttpClient();

          Future<String> makeServiceHttpRequest({String method = ''}) async {
            var request = await client.getUrl(Uri.parse('$uri$method'));
            var response = await request.close();
            return await response.transform(utf8.decoder).join();
          }

          var content = await makeServiceHttpRequest();
          const observatoryText = 'Dart VM Observatory';
          expect(content.contains(observatoryText), serve);
          if (!serve) {
            if (withDds) {
              expect(content.contains('DevTools'), true);
            } else {
              expect(
                content,
                'This VM does not have a registered Dart '
                'Development Service (DDS) instance and is not currently serving '
                'Dart DevTools.',
              );
            }
          }

          // Ensure we can always make VM service requests via HTTP.
          content = await makeServiceHttpRequest(method: 'getVM');
          expect(content.contains('"jsonrpc":"2.0"'), true);

          // If Observatory isn't being served, ensure we can enable it.
          if (!serve) {
            content = await makeServiceHttpRequest(method: '_serveObservatory');
            expect(content.contains('"type":"Success"'), true);

            // Ensure Observatory is now being served.
            content = await makeServiceHttpRequest();
            expect(content.contains(observatoryText), true);
          }

          process.kill();
        },
      );
    }

    const flags = <bool>[true, false];
    // TODO(jcollins):  Disabling serving no longer seems to produce
    // the expected output.  Maybe this is because the web interface has
    // changed?
    for (final serve in [true]) {
      for (final enableAuthCodes in flags) {
        for (final explicitRun in flags) {
          for (final withDds in flags) {
            generateServedTest(
              serve: serve,
              enableAuthCodes: enableAuthCodes,
              explicitRun: explicitRun,
              withDds: withDds,
            );
          }
        }
      }
    }
  });
}

void residentRun() {
  late TestProject serverInfoDirectory, p;
  late String serverInfoFile;

  setUp(() async {
    serverInfoDirectory = project(mainSrc: 'void main() {}');
    serverInfoFile = path.join(serverInfoDirectory.dirPath, 'info');

    final cachedDillFile =
        File(computeCachedDillPath(serverInfoDirectory.mainPath));
    expect(cachedDillFile.existsSync(), false);

    final result = await serverInfoDirectory.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      serverInfoDirectory.relativeFilePath,
    ]);

    expect(result.exitCode, 0);
    expect(File(serverInfoFile).existsSync(), true);
    expect(cachedDillFile.existsSync(), true);
    cachedDillFile.deleteSync();

    // [TestProject] uses [addTearDown] to register cleanup code that will
    // delete the project, and due to ordering guarantees of callbacks
    // registered using [addTearDown] (refer to [addTearDown]'s doc comment), we
    // need to use [addTearDown] here to ensure that the resident frontend
    // compiler we started above will be shut down before the project is
    // deleted.
    addTearDown(() async {
      await serverInfoDirectory.run([
        'compilation-server',
        'shutdown',
        '--$residentCompilerInfoFileOption=$serverInfoFile',
      ]);
    });
  });

  test(
      'passing --resident is a prerequisite for passing --resident-compiler-info-file',
      () async {
    p = project(mainSrc: 'void main() {}');
    final result = await p.run([
      'run',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      p.relativeFilePath,
    ]);

    expect(result.exitCode, 255);
    expect(
      result.stderr,
      contains(
        'Error: the --resident flag must be passed whenever the --resident-compiler-info-file option is passed.',
      ),
    );
  });

  test("'Hello World'", () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");

    final cachedDillFile = File(computeCachedDillPath(p.mainPath));
    expect(cachedDillFile.existsSync(), false);

    final result = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      p.relativeFilePath,
    ]);

    expect(result.exitCode, 0);
    expect(
      result.stdout,
      allOf(
        contains('Hello World'),
        isNot(contains(residentFrontendCompilerPrefix)),
      ),
    );
    expect(result.stderr, isEmpty);
    expect(cachedDillFile.existsSync(), true);
    cachedDillFile.deleteSync();
  });

  test('standalone dart program (i.e. no pubspec.yaml)', () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    p.deleteFile('.dart_tool/package_config.json');

    final cachedDillFile = File(computeCachedDillPath(p.mainPath));
    expect(cachedDillFile.existsSync(), false);

    final result = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      p.relativeFilePath,
    ]);

    expect(result.exitCode, 0);
    expect(
      result.stdout,
      allOf(
        contains('Hello World'),
        isNot(contains(residentFrontendCompilerPrefix)),
      ),
    );
    expect(result.stderr, isEmpty);
    expect(cachedDillFile.existsSync(), true);
    cachedDillFile.deleteSync();
  });

  test("'Hello World' with legacy --resident-server-info-file option",
      () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");

    final cachedDillFile = File(computeCachedDillPath(p.mainPath));
    expect(cachedDillFile.existsSync(), false);

    final result = await p.run([
      'run',
      '--resident',
      '--resident-server-info-file=$serverInfoFile',
      p.relativeFilePath,
    ]);

    expect(result.exitCode, 0);
    expect(
      result.stdout,
      allOf(
        contains('Hello World'),
        isNot(contains(residentFrontendCompilerPrefix)),
      ),
    );
    expect(result.stderr, isEmpty);
    expect(cachedDillFile.existsSync(), true);
    cachedDillFile.deleteSync();
  });

  test('--resident-compiler-info-file handles relative paths correctly',
      () async {
    p = project(mainSrc: "void main() { print('Hello World'); }");

    final cachedDillFile = File(computeCachedDillPath(p.mainPath));
    expect(cachedDillFile.existsSync(), false);

    final result = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption',
      path.relative(serverInfoFile, from: p.dirPath),
      p.relativeFilePath,
    ]);

    expect(result.exitCode, 0);
    expect(
      result.stdout,
      allOf(
        contains('Hello World'),
        isNot(contains(residentFrontendCompilerPrefix)),
      ),
    );
    expect(result.stderr, isEmpty);
    expect(cachedDillFile.existsSync(), true);
    cachedDillFile.deleteSync();
  });

  test(
      'a running resident compiler is restarted if the Dart SDK was '
      'upgraded or downgraded since it was started', () async {
    p = project(mainSrc: 'void main() {}');

    final residentCompilerInfo = ResidentCompilerInfo.fromFile(
      File(serverInfoFile),
    );
    if (residentCompilerInfo.sdkHash != null &&
        residentCompilerInfo.sdkHash == sdkHashNull) {
      // dartdev does not consider the SDK hash changing from [sdkHashNull] to a
      // different SDK hash to be an SDK upgrade or downgrade. So, if an SDK
      // of [sdkHashNull] was recorded into [serverInfoFile], the test logic
      // below will not work as intended. For local developement, we make the
      // test fail in this situation, alerting the developer that the test is
      // only meaningful when run from an SDK built with --verify-sdk-hash. The
      // SDK can only be built with --no-verify-sdk-hash on CI, so we just skip
      // this test on CI.
      if (Platform.environment.containsKey('BUILDBOT_BUILDERNAME') ||
          Platform.environment.containsKey('SWARMING_TASK_ID')) {
        return;
      } else {
        fail(
          'This test is guaranteed to pass, and thus is not meaningful, when '
          'run from an SDK built with --no-verify-sdk-hash',
        );
      }
    }

    // Replace the SDK hash in [serverInfoFile] to make dartdev think the Dart
    // SDK version has changed since the resident compiler was started.
    File(serverInfoFile).writeAsStringSync(
      'address:${residentCompilerInfo.address.address} '
      'sdkHash:${'1' * residentCompilerInfo.sdkHash!.length} '
      'port:${residentCompilerInfo.port} ',
    );
    final result = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      p.relativeFilePath,
    ]);

    expect(result.exitCode, 0);
    expect(result.stdout, contains(residentFrontendCompilerPrefix));
    expect(
      result.stderr,
      'The Dart SDK has been upgraded or downgraded since the Resident '
      'Frontend Compiler was started, so the Resident Frontend Compiler will '
      'now be restarted for compatibility reasons.\n',
    );
    expect(File(serverInfoFile).existsSync(), true);
  });

  test('when a connection to a running resident compiler cannot be established',
      () async {
    // When this occurs, the user should be informed that the resident frontend
    // compiler will be restarted, and compilation will be retried.
    p = project(mainSrc: 'void main() {}');
    // Create a [testServerInfoFile] that contains an invalid port to guarantee
    // that a connection will not be established.
    final testServerInfoFile = File(path.join(p.dirPath, 'info'));
    testServerInfoFile.createSync();
    testServerInfoFile.writeAsStringSync(
      'address:127.0.0.1 sdkHash:$sdkHashNull port:-12 ',
    );
    final result = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=${testServerInfoFile.path}',
      p.relativeFilePath,
    ]);

    expect(result.exitCode, 0);
    expect(result.stdout, contains(residentFrontendCompilerPrefix));
    expect(
      result.stderr,
      'Error: A connection to the Resident Frontend Compiler could not be '
      'established. Restarting the Resident Frontend Compiler and retrying '
      'compilation.\n',
    );
    expect(testServerInfoFile.existsSync(), true);

    await p.run([
      'compilation-server',
      'shutdown',
      '--$residentCompilerInfoFileOption=${testServerInfoFile.path}',
    ]);
  });

  test('Handles experiments', () async {
    p = project(
      mainSrc: r"void main() { print(('hello','world').$1); }",
      sdkConstraint: VersionConstraint.parse(
        '^3.0.0',
      ),
    );

    final cachedDillFile = File(computeCachedDillPath(p.mainPath));
    expect(cachedDillFile.existsSync(), false);

    final result = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      '--enable-experiment=test-experiment',
      p.relativeFilePath,
    ]);

    expect(result.stderr, isEmpty);
    expect(
      result.stdout,
      allOf(
        contains('hello'),
        isNot(contains(residentFrontendCompilerPrefix)),
      ),
    );
    expect(result.exitCode, 0);
    expect(cachedDillFile.existsSync(), true);
    cachedDillFile.deleteSync();
  });

  test('same server used from different directories', () async {
    p = project(mainSrc: "void main() { print('1'); }");
    TestProject p2 = project(mainSrc: "void main() { print('2'); }");

    final runResult1 = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      p.relativeFilePath,
    ]);
    final runResult2 = await p2.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      p2.relativeFilePath,
    ]);

    expect(runResult1.exitCode, allOf(0, equals(runResult2.exitCode)));
    expect(
      runResult1.stdout,
      allOf(
        contains('1'),
        isNot(contains(residentFrontendCompilerPrefix)),
      ),
    );
    expect(
      runResult2.stdout,
      allOf(
        contains('2'),
        isNot(contains(residentFrontendCompilerPrefix)),
      ),
    );
  });

  test('kernel cache respects directory structure', () async {
    p = project(name: 'foo');
    p.file('lib/main.dart', 'void main() {}');
    p.file('bin/main.dart', 'void main() {}');

    final cachedDillForLibMain =
        File(computeCachedDillPath(path.join(p.dirPath, 'lib/main.dart')));
    expect(cachedDillForLibMain.existsSync(), false);

    final cachedDillForBinMain =
        File(computeCachedDillPath(path.join(p.dirPath, 'bin/main.dart')));
    expect(cachedDillForBinMain.existsSync(), false);

    final runResult1 = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      path.join(p.dirPath, 'lib/main.dart'),
    ]);
    expect(runResult1.exitCode, 0);
    expect(runResult1.stdout, isEmpty);
    expect(runResult1.stderr, isEmpty);

    final runResult2 = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      path.join(p.dirPath, 'bin/main.dart'),
    ]);
    expect(runResult2.exitCode, 0);
    expect(runResult2.stdout, isEmpty);
    expect(runResult2.stderr, isEmpty);

    expect(cachedDillForLibMain.existsSync(), true);
    expect(cachedDillForLibMain.parent.path, endsWith('lib'));
    cachedDillForLibMain.deleteSync();

    expect(cachedDillForBinMain.existsSync(), true);
    expect(cachedDillForBinMain.parent.path, endsWith('bin'));
    cachedDillForBinMain.deleteSync();
  });

  test('directory that the server is started in is deleted', () async {
    // The first command will start the server process in the p2
    // project directory.
    // This directory is deleted. The second command will attempt to run again
    // The server process should not fail on this second attempt. If it does,
    // the 3rd command will result in a new server starting.
    Directory tempServerInfoDir = Directory.systemTemp.createTempSync('a');
    String tempServerInfoFile = path.join(tempServerInfoDir.path, 'info');
    addTearDown(() async {
      try {
        await sendAndReceiveResponse(
          residentServerShutdownCommand,
          File(tempServerInfoFile),
        );
      } catch (_) {}
      await deleteDirectory(tempServerInfoDir);
    });
    p = project(mainSrc: 'void main() {}');
    TestProject p2 = project(mainSrc: 'void main() {}');
    final runResult1 = await p2.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$tempServerInfoFile',
      p2.relativeFilePath,
    ]);
    await deleteDirectory(p2.dir);
    expect(runResult1.exitCode, 0);
    expect(runResult1.stdout, contains(residentFrontendCompilerPrefix));

    await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$tempServerInfoFile',
      p.relativeFilePath,
    ]);
    final runResult2 = await p.run([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$tempServerInfoFile',
      p.relativeFilePath,
    ]);

    expect(runResult2.exitCode, 0);
    expect(runResult2.stderr, isEmpty);
    expect(runResult2.stdout, isNot(contains(residentFrontendCompilerPrefix)));
  });

  test('VM flags are passed properly', () async {
    p = project(mainSrc: observeScript);
    var sawVmServiceMsg = false;
    var sawCFEMsg = false;
    var sawProgramMsg = false;

    // --observe sets the following flags by default:
    //   --enable-vm-service
    //   --pause-isolate-on-exit
    //   --pause-isolate-on-unhandled-exception
    //   --warn-on-pause-with-no-debugger
    //
    // This test ensures that allowed arguments for dart run which are valid VM
    // arguments are properly handled by the VM.
    void onData1(event) {
      if (event.contains('The Dart VM service is listening on')) {
        final re = RegExp(
            r'The Dart VM service is listening on http:\/\/127.0.0.1:[0-9+]');
        expect(re.hasMatch(event), true);
        sawVmServiceMsg = true;
      }
      if (event.contains('Observe smoke test!')) {
        sawProgramMsg = true;
      }
      if (event.contains('The Resident Frontend Compiler is listening')) {
        final re = RegExp(
            r'The Resident Frontend Compiler is listening at 127.0.0.1:[0-9]+');
        expect(re.hasMatch(event), true);
        sawCFEMsg = true;
      }
      if (sawVmServiceMsg && sawProgramMsg) {
        p.kill();
      }
    }

    await p.runWithVmService([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      '--observe=0',
      '--pause-isolates-on-start',
      // This should negate the above flag.
      '--no-pause-isolates-on-start',
      '--no-pause-isolates-on-exit',
      '--no-pause-isolates-on-unhandled-exceptions',
      '-Dfoo=bar',
      '--define=bar=foo',
      p.relativeFilePath,
    ], onData1);
    expect(sawVmServiceMsg, true);
    expect(sawProgramMsg, true);
    expect(sawCFEMsg, false);

    // Again, with --disable-service-auth-codes.
    sawVmServiceMsg = false;
    sawProgramMsg = false;
    sawCFEMsg = false;
    await p.runWithVmService([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      '--observe=0',
      '--pause-isolates-on-start',
      // This should negate the above flag.
      '--no-pause-isolates-on-start',
      '--no-pause-isolates-on-exit',
      '--no-pause-isolates-on-unhandled-exceptions',
      '--disable-service-auth-codes',
      '-Dfoo=bar',
      '--define=bar=foo',
      p.relativeFilePath,
    ], onData1);
    expect(sawVmServiceMsg, true);
    expect(sawProgramMsg, true);
    expect(sawCFEMsg, false);

    // Again, with IPv6.
    sawVmServiceMsg = false;
    sawProgramMsg = false;
    sawCFEMsg = false;
    void onData2(event) {
      if (event.contains('The Dart VM service is listening on')) {
        final re = RegExp(
            r'The Dart VM service is listening on http:\/\/\[::1\]:\d+\/[a-zA-Z0-9_-]+=\/.*');
        expect(re.hasMatch(event), true);
        sawVmServiceMsg = true;
      }
      if (event.contains('Observe smoke test!')) {
        sawProgramMsg = true;
      }
      if (event.contains('The Resident Frontend Compiler is listening')) {
        final re = RegExp(
            r'The Resident Frontend Compiler is listening at 127.0.0.1:[0-9]+');
        expect(re.hasMatch(event), true);
        sawCFEMsg = true;
      }
      if (sawVmServiceMsg && sawProgramMsg) {
        p.kill();
      }
    }

    await p.runWithVmService([
      'run',
      '--resident',
      '--$residentCompilerInfoFileOption=$serverInfoFile',
      '--observe=0/::1',
      '--pause-isolates-on-start',
      // This should negate the above flag.
      '--no-pause-isolates-on-start',
      '--no-pause-isolates-on-exit',
      '--no-pause-isolates-on-unhandled-exceptions',
      '-Dfoo=bar',
      '--define=bar=foo',
      p.relativeFilePath,
    ], onData2);
    expect(sawVmServiceMsg, true);
    expect(sawProgramMsg, true);
    expect(sawCFEMsg, false);
  });

  test('custom package_config path', () async {
    p = project(name: 'foo', mainSrc: '''
import 'package:bar/main.dart';
void main() {
  cmd();
}
''');
    final bar1 = project(name: 'bar1', mainSrc: '''
cmd() {
  print('hi');
}
''');
    final bar2 = project(name: 'bar2', mainSrc: '''
cmd() {
  print('bye');
}
''');

    p.file('custom_packages1.json', '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "bar",
      "rootUri": "${Uri.file(bar1.dirPath)}",
      "packageUri": "${Uri.file(path.join(bar1.dirPath, 'lib'))}"
    }
  ]
}
''');
    p.file('custom_packages2.json', '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "bar",
      "rootUri": "${Uri.file(bar2.dirPath)}",
      "packageUri": "${Uri.file(path.join(bar2.dirPath, 'lib'))}"
    }
  ]
}
''');
    final runResult1 = await p.run([
      'run',
      '--packages=${path.join(p.dirPath, 'custom_packages1.json')}',
      p.relativeFilePath,
    ]);
    expect(runResult1.stderr, isEmpty);
    expect(runResult1.stdout, contains('hi'));
    expect(runResult1.exitCode, 0);
    // Test that --packages can precede the command name
    final runResult2 = await p.run([
      '--packages=${path.join(p.dirPath, 'custom_packages2.json')}',
      'run',
      p.relativeFilePath,
    ]);

    expect(runResult2.stderr, isEmpty);
    expect(runResult2.stdout, contains('bye'));
    expect(runResult2.exitCode, 0);
  });
}
