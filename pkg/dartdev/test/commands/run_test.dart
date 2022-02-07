// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

const String soundNullSafetyMessage = 'Info: Compiling with sound null safety';
const devToolsMessagePrefix =
    'The Dart DevTools debugger and profiler is available at: http://127.0.0.1:';
const observatoryMessagePrefix = 'Observatory listening on http://127.0.0.1:';

void main() {
  group('run', run, timeout: longTimeout);
}

void run() {
  late TestProject p;

  tearDown(() async => await p.dispose());

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
    final bar = TestProject(name: 'bar');
    p.file('pubspec.yaml', '''
name: foo
environment:
  sdk: '>=2.9.0<3.0.0'

dependencies: { 'bar': {'path': '${bar.dir.path}'}}
''');
    p.file('lib/foo.dart', r'''
import 'package:bar/bar.dart';
final b = "FOO $bar";
''');

    try {
      bar.file('lib/bar.dart', 'final bar = "BAR";');

      bar.file('bin/main.dart', r'''
import 'package:foo/foo.dart';
void main(List<String> args) => print("$b $args");
''');

      ProcessResult result = await p.run(['run', 'bar:main', '--arg1', 'arg2']);

      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('FOO BAR [--arg1, arg2]'));
      expect(result.exitCode, 0);
    } finally {
      await bar.dispose();
    }
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
    p = project(mainSrc: "void main() { print('Hello World'); }");

    // --observe sets the following flags by default:
    //   --enable-vm-service
    //   --pause-isolate-on-exit
    //   --pause-isolate-on-unhandled-exception
    //   --warn-on-pause-with-no-debugger
    //
    // This test ensures that allowed arguments for dart run which are valid VM
    // arguments are properly handled by the VM.
    ProcessResult result = await p.run([
      'run',
      '--observe',
      '--pause-isolates-on-start',
      // This should negate the above flag.
      '--no-pause-isolates-on-start',
      '--no-pause-isolates-on-exit',
      '--no-pause-isolates-on-unhandled-exceptions',
      '-Dfoo=bar',
      '--define=bar=foo',
      p.relativeFilePath,
    ]);
    expect(
      result.stdout,
      matches(
          r'Observatory listening on http:\/\/127.0.0.1:8181\/[a-zA-Z0-9_-]+=\/\n.*'),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);

    // Again, with --disable-service-auth-codes.
    result = await p.run([
      'run',
      '--observe',
      '--pause-isolates-on-start',
      // This should negate the above flag.
      '--no-pause-isolates-on-start',
      '--no-pause-isolates-on-exit',
      '--no-pause-isolates-on-unhandled-exceptions',
      '--disable-service-auth-codes',
      '-Dfoo=bar',
      '--define=bar=foo',
      p.relativeFilePath,
    ]);

    expect(
      result.stdout,
      contains('Observatory listening on http://127.0.0.1:8181/\n'),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);

    // Again, with IPv6.
    result = await p.run([
      'run',
      '--observe=8181/::1',
      '--pause-isolates-on-start',
      // This should negate the above flag.
      '--no-pause-isolates-on-start',
      '--no-pause-isolates-on-exit',
      '--no-pause-isolates-on-unhandled-exceptions',
      '-Dfoo=bar',
      '--define=bar=foo',
      p.relativeFilePath,
    ]);

    expect(
      result.stdout,
      matches(
          r'Observatory listening on http:\/\/\[::1\]:8181\/[a-zA-Z0-9_-]+=\/\n.*'),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
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
      contains('Could not find an option named "vm-name".'),
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
      contains('Could not find an option named "verbose_gc".'),
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

  group('DDS', () {
    group('disable', () {
      test('dart run simple', () async {
        p = project(mainSrc: "void main() { print('Hello World'); }");
        ProcessResult result = await p.run([
          'run',
          '--no-dds',
          '--enable-vm-service',
          p.relativeFilePath,
        ]);
        expect(result.stdout, isNot(contains(devToolsMessagePrefix)));
        expect(result.stdout, contains(observatoryMessagePrefix));
      });

      test('dart simple', () async {
        p = project(mainSrc: "void main() { print('Hello World'); }");
        ProcessResult result = await p.run([
          '--no-dds',
          '--enable-vm-service',
          p.relativeFilePath,
        ]);
        expect(result.stdout, isNot(contains(devToolsMessagePrefix)));
        expect(result.stdout, contains(observatoryMessagePrefix));
      });
    });

    group('explicit enable', () {
      test('dart run simple', () async {
        p = project(mainSrc: "void main() { print('Hello World'); }");
        ProcessResult result = await p.run([
          'run',
          '--dds',
          '--enable-vm-service',
          p.relativeFilePath,
        ]);
        expect(result.stdout, contains(devToolsMessagePrefix));
        expect(result.stdout, contains(observatoryMessagePrefix));
      });

      test('dart simple', () async {
        p = project(mainSrc: "void main() { print('Hello World'); }");
        ProcessResult result = await p.run([
          '--dds',
          '--enable-vm-service',
          p.relativeFilePath,
        ]);
        expect(result.stdout, contains(devToolsMessagePrefix));
        expect(result.stdout, contains(observatoryMessagePrefix));
      });
    });
  });

  group('DevTools', () {
    test('dart run simple', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = await p.run([
        'run',
        '--enable-vm-service',
        p.relativeFilePath,
      ]);
      expect(result.stdout, contains(devToolsMessagePrefix));
    });

    test('dart simple', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = await p.run([
        '--enable-vm-service',
        p.relativeFilePath,
      ]);
      expect(result.stdout, contains(devToolsMessagePrefix));
    });

    test('dart run explicit', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = await p.run([
        'run',
        '--serve-devtools',
        '--enable-vm-service',
        p.relativeFilePath,
      ]);
      expect(result.stdout, contains(devToolsMessagePrefix));
    });

    test('dart explicit', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = await p.run([
        '--serve-devtools',
        '--enable-vm-service',
        p.relativeFilePath,
      ]);
      expect(result.stdout, contains(devToolsMessagePrefix));
    });

    test('dart run disabled', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = await p.run([
        'run',
        '--enable-vm-service',
        '--no-serve-devtools',
        p.relativeFilePath,
      ]);
      expect(result.stdout, isNot(contains(devToolsMessagePrefix)));
    });

    test('dart disabled', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = await p.run([
        '--enable-vm-service',
        '--no-serve-devtools',
        p.relativeFilePath,
      ]);
      expect(result.stdout, isNot(contains(devToolsMessagePrefix)));
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
}
