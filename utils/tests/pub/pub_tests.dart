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
      output: '''
      Pub is a package manager for Dart.

      Usage:

        pub command [arguments]

      The commands are:

        list      print the contents of repositories
        version   print Pub version

      Use "pub help [command]" for more information about a command.''');
  });

  group('an unknown command', () {
    testPub('displays an error message',
      args: ['quylthulg'],
      output: '''
      Unknown command "quylthulg".
      Run "pub help" to see available commands.''',
      exitCode: 64);
  });

  listCommand();
  versionCommand();
}

listCommand() {
  group('list cache', () {
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
      cherry''');
  });
}

versionCommand() {
  group('the version command', () {
    testPub('displays the current version',
      args: ['version'],
      output: 'Pub 0.0.0');
  });
}