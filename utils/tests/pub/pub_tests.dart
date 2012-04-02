// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../lib/unittest/unittest_vm.dart');

main() {
  group('running pub with no command', () {
    testOutput('displays usage',
      [],
      '''
      Pub is a package manager for Dart.

      Usage:

        pub command [arguments]

      The commands are:

        version   print Pub version

      Use "pub help [command]" for more information about a command.''');
  });

  group('the version command', () {
    testOutput('displays the current version',
      ['version'], 'Pub 0.0.0');
  });

  group('an unknown command', () {
    testOutput('displays an error message',
      ['quylthulg'],
      '''
      Unknown command "quylthulg".
      Run "pub help" to see available commands.''',
      exitCode: 64);
  });
}
