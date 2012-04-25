// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../lib/unittest/unittest.dart');

main() {
  group('running pub with no command', () {
    testPub('displays usage',
      args: [],
      output: """
      Pub is a package manager for Dart.

      Usage:

        pub command [arguments]

      The commands are:

        list      print the contents of repositories
        update    update a package's dependencies
        version   print Pub version

      Use "pub help [command]" for more information about a command.
      """);
  });

  group('an unknown command', () {
    testPub('displays an error message',
      args: ['quylthulg'],
      output: '''
      Unknown command "quylthulg".
      Run "pub help" to see available commands.
      ''',
      exitCode: 64);
  });

  group('pub list', listCommand);
  group('pub update', updateCommand);
  group('pub version', versionCommand);
}

listCommand() {
  group('cache', () {
    testPub('treats an empty directory as a package',
      cache: [
        dir('apple'),
        dir('banana'),
        dir('cherry')
      ],
      args: ['list', 'cache'],
      output: '''
      apple
      banana
      cherry
      ''');
  });
}

updateCommand() {
  testPub('adds a dependent package',
    cache: [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ],
    app: dir('myapp', [
      file('pubspec', 'foo')
    ]),
    args: ['update'],
    expectedPackageDir: [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ],
    output: '');

  testPub('adds a transitively dependent package',
    cache: [
      dir('foo', [
        file('foo.dart', 'main() => "foo";'),
        file('pubspec', 'bar')
      ]),
      dir('bar', [
        file('bar.dart', 'main() => "bar";'),
      ])
    ],
    app: dir('myapp', [
      file('pubspec', 'foo')
    ]),
    args: ['update'],
    expectedPackageDir: [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ]),
      dir('bar', [
        file('bar.dart', 'main() => "bar";'),
      ])
    ],
    output: '');
}

versionCommand() {
  testPub('displays the current version',
    args: ['version'],
    output: '''
    Pub 0.0.0
    ''');
}