// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.io;

//import 'package:linter/src/io.dart';
//import 'package:linter/src/linter.dart';
//import 'package:mockito/mockito.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';

  defineTests();
}

defineTests() {
  // TODO: redefine tests

//  group('commandline args', () {
//    var mockFile = new MockFile();
//    when(mockFile.path).thenReturn('foo.dart');
//    when(mockFile.absolute).thenReturn(mockFile);
//
//    var options = new LinterOptions(() => []);
//    var mockLinter = new MockLinter();
//    when(mockLinter.options).thenReturn(options);
//
//    lintFile(mockFile,
//        dartSdkPath: '/path/to/sdk',
//        packageRoot: '/my/pkgs',
//        linter: mockLinter);
//
//    test('dartSdkPath', () {
//      expect(options.dartSdkPath, equals('/path/to/sdk'));
//      expect(options.packageRootPath, equals('/my/pkgs'));
//    });
//
//    test('packageRoot', () {
//      expect(options.dartSdkPath, equals('/path/to/sdk'));
//      expect(options.packageRootPath, equals('/my/pkgs'));
//    });
//
//    test('exception handling', () {
//      var mockErr = new MockIOSink();
//      std_err = mockErr;
//      when(mockLinter.lintFiles(any)).thenAnswer((_) => throw 'err');
//      expect(lintFiles([mockFile], linter: mockLinter), isFalse);
//      verify(std_err.writeln(any)).called(1);
//    });
//  });
}
