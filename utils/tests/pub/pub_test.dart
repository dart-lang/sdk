// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../lib/unittest/unittest.dart');

final USAGE_STRING = """
    Pub is a package manager for Dart.

    Usage:

      pub command [arguments]

    The commands are:

      install   install the current package's dependencies
      list      print the contents of repositories
      update    update the current package's dependencies to the latest versions
      version   print Pub version

    Use "pub help [command]" for more information about a command.
    """;

final VERSION_STRING = '''
    Pub 0.0.0
    ''';

main() {
  test('running pub with no command displays usage', () =>
      runPub(args: [], output: USAGE_STRING));

  test('running pub with just --help displays usage', () =>
      runPub(args: ['--help'], output: USAGE_STRING));

  test('running pub with just -h displays usage', () =>
      runPub(args: ['-h'], output: USAGE_STRING));

  test('running pub with just --version displays version', () =>
      runPub(args: ['--version'], output: VERSION_STRING));

  group('an unknown command', () {
    test('displays an error message', () {
      runPub(args: ['quylthulg'],
          output: '''
          Unknown command "quylthulg".
          Run "pub help" to see available commands.
          ''',
          exitCode: 64);
    });
  });

  group('pub list', listCommand);
  group('pub install', installCommand);
  group('pub version', versionCommand);
}

listCommand() {
  group('cache', () {
    test('treats an empty directory as a package', () {
      dir(cachePath, [
        dir('sdk', [
          dir('apple'),
          dir('banana'),
          dir('cherry')
        ])
      ]).scheduleCreate();

      runPub(args: ['list', 'cache'],
          output: '''
          From system cache:
            apple from sdk
            banana from sdk
            cherry from sdk
          ''');
    });
  });
}

installCommand() {
  test('adds a dependent package', () {
    dir(sdkPath, [
      dir('lib', [
        dir('foo', [
          file('foo.dart', 'main() => "foo";')
        ])
      ])
    ]).scheduleCreate();

    dir(appPath, [
      file('pubspec', 'dependencies:\n  foo:')
    ]).scheduleCreate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    runPub(args: ['install'],
        output: '''
        Dependencies installed!
        ''');
  });

  test('adds a transitively dependent package', () {
    dir(sdkPath, [
      dir('lib', [
        dir('foo', [
          file('foo.dart', 'main() => "foo";'),
          file('pubspec', 'dependencies:\n  bar:')
        ]),
        dir('bar', [
          file('bar.dart', 'main() => "bar";'),
        ])
      ])
    ]).scheduleCreate();

    dir(appPath, [
      file('pubspec', 'dependencies:\n  foo:')
    ]).scheduleCreate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ]),
      dir('bar', [
        file('bar.dart', 'main() => "bar";'),
      ])
    ]).scheduleValidate();

    runPub(args: ['install'],
        output: '''
        Dependencies installed!
        ''');
  });

  test('checks out a package from Git', () {
    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    dir(appPath, [
      file('pubspec', '''
dependencies:
  foo:
    git: ../foo.git
''')
    ]).scheduleCreate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    runPub(args: ['install'],
        output: const RegExp(@"^Cloning into[\s\S]*^Dependencies installed!$",
                             multiLine: true));
  });

  test('checks out packages transitively from Git', () {
    git('foo.git', [
      file('foo.dart', 'main() => "foo";'),
      file('pubspec', '''
dependencies:
  bar:
    git: ../bar.git
''')
    ]).scheduleCreate();

    git('bar.git', [
      file('bar.dart', 'main() => "bar";')
    ]).scheduleCreate();

    dir(appPath, [
      file('pubspec', '''
dependencies:
  foo:
    git: ../foo.git
''')
    ]).scheduleCreate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ]),
      dir('bar', [
        file('bar.dart', 'main() => "bar";')
      ])
    ]).scheduleValidate();

    runPub(args: ['install'],
        output: const RegExp("^Cloning into[\\s\\S]*^Dependencies installed!\$",
                             multiLine: true));
  });
}

versionCommand() {
  test('displays the current version', () =>
    runPub(args: ['version'], output: VERSION_STRING));
}
