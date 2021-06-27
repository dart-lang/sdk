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

void main() {
  group('run', run, timeout: longTimeout);
}

void run() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();
    var result = p.runSync(['run', '--help']);

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

  test('--help --verbose', () {
    p = project();
    var result = p.runSync(['run', '--help', '--verbose']);

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

  test("'Hello World'", () {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    ProcessResult result = p.runSync(['run', p.relativeFilePath]);

    expect(result.stdout, contains('Hello World'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('no such file', () {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    ProcessResult result =
        p.runSync(['run', 'no/such/file/${p.relativeFilePath}']);

    expect(result.stderr, isNotEmpty);
    expect(result.exitCode, isNot(0));
  });

  test('implicit packageName.dart', () {
    // TODO(jwren) circle back to reimplement this test if possible, the file
    // name (package name) will be the name of the temporary directory on disk
    p = project(mainSrc: "void main() { print('Hello World'); }");
    p.file('bin/main.dart', "void main() { print('Hello main.dart'); }");
    ProcessResult result = p.runSync(['run']);

    expect(result.stdout, contains('Hello main.dart'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  }, skip: true);

  // Could not find the implicit file to run: bin
  test('missing implicit packageName.dart', () {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    p.file('bin/foo.dart', "void main() { print('Hello main.dart'); }");
    ProcessResult result = p.runSync(['run']);

    expect(result.stdout, isEmpty);
    expect(
        result.stderr,
        contains('Could not find `bin${path.separator}dartdev_temp.dart` in '
            'package `dartdev_temp`.'));
    expect(result.exitCode, 255);
  });

  test('arguments are properly passed', () {
    p = project();
    p.file('main.dart', 'void main(args) { print(args); }');
    ProcessResult result = p.runSync([
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

  test('from path-dependency with cyclic dependency', () {
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

      ProcessResult result = p.runSync(['run', 'bar:main', '--arg1', 'arg2']);

      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('FOO BAR [--arg1, arg2]'));
      expect(result.exitCode, 0);
    } finally {
      bar.dispose();
    }
  });

  test('with absolute file path', () async {
    p = project();
    p.file('main.dart', 'void main(args) { print(args); }');
    // Test with absolute path
    final name = path.join(p.dirPath, 'main.dart');
    final result = p.runSync([
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
    final result = p.runSync([
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
    ProcessResult result = p.runSync([
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
    result = p.runSync([
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
    result = p.runSync([
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
    ProcessResult result = p.runSync([
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
    ProcessResult result = p.runSync([
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
    ProcessResult result = p.runSync([
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
    ProcessResult result = p.runSync([
      'run',
      p.relativeFilePath,
      '--enable-asserts',
    ]);

    expect(result.stdout, isEmpty);
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('without verbose CFE info', () {
    final p = project(mainSrc: '''void main() {}''');

    var result = p.runSync(
      [
        'run',
        '--verbosity=warning',
        p.relativeFilePath,
      ],
    );

    expect(result.stdout,
        predicate((o) => !'$o'.contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  group('DevTools', () {
    const devToolsMessagePrefix =
        'The Dart DevTools debugger and profiler is available at: http://127.0.0.1:';

    test('dart run simple', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = p.runSync([
        'run',
        '--enable-vm-service',
        p.relativeFilePath,
      ]);
      expect(result.stdout, contains(devToolsMessagePrefix));
    });

    test('dart simple', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = p.runSync([
        '--enable-vm-service',
        p.relativeFilePath,
      ]);
      expect(result.stdout, contains(devToolsMessagePrefix));
    });

    test('dart run explicit', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = p.runSync([
        'run',
        '--serve-devtools',
        '--enable-vm-service',
        p.relativeFilePath,
      ]);
      expect(result.stdout, contains(devToolsMessagePrefix));
    });

    test('dart explicit', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = p.runSync([
        '--serve-devtools',
        '--enable-vm-service',
        p.relativeFilePath,
      ]);
      expect(result.stdout, contains(devToolsMessagePrefix));
    });

    test('dart run disabled', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = p.runSync([
        'run',
        '--enable-vm-service',
        '--no-serve-devtools',
        p.relativeFilePath,
      ]);
      expect(result.stdout, isNot(contains(devToolsMessagePrefix)));
    });

    test('dart disabled', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = p.runSync([
        '--enable-vm-service',
        '--no-serve-devtools',
        p.relativeFilePath,
      ]);
      expect(result.stdout, isNot(contains(devToolsMessagePrefix)));
    });

    test('dart run VM service not enabled', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = p.runSync([
        'run',
        '--serve-devtools',
        p.relativeFilePath,
      ]);
      expect(result.stdout, isNot(contains(devToolsMessagePrefix)));
    });

    test('dart VM service not enabled', () async {
      p = project(mainSrc: "void main() { print('Hello World'); }");
      ProcessResult result = p.runSync([
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

        StreamSubscription sub;
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
