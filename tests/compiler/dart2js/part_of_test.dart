// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library part_of_test;

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'mock_compiler.dart';
import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
    show MessageKind;

final libraryUri = Uri.parse('test:library.dart');
const String LIBRARY_SOURCE = '''
library foo;
part 'part.dart';
''';

final partUri = Uri.parse('test:part.dart');
const String PART_SOURCE = '''
part of bar;
''';

void main() {
  var compiler = new MockCompiler.internal();
  compiler.registerSource(libraryUri, LIBRARY_SOURCE);
  compiler.registerSource(partUri, PART_SOURCE);

  asyncTest(() =>
      compiler.libraryLoader.loadLibrary(libraryUri, null, libraryUri).
      then((_) {
    print('errors: ${compiler.errors}');
    print('warnings: ${compiler.warnings}');
    Expect.isTrue(compiler.errors.isEmpty);
    Expect.equals(1, compiler.warnings.length);
    Expect.equals(MessageKind.LIBRARY_NAME_MISMATCH,
                  compiler.warnings[0].message.kind);
    Expect.equals('foo',
        compiler.warnings[0].message.arguments['libraryName'].toString());
  }));
}
