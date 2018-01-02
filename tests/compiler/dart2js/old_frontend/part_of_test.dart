// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library part_of_test;

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/diagnostics/messages.dart' show MessageKind;
import 'mock_compiler.dart';

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
  MockCompiler compiler = new MockCompiler.internal();
  compiler.registerSource(libraryUri, LIBRARY_SOURCE);
  compiler.registerSource(partUri, PART_SOURCE);

  asyncTest(
      () => compiler.libraryLoader.loadLibrary(libraryUri).then((libraries) {
            compiler.processLoadedLibraries(libraries);
            DiagnosticCollector collector = compiler.diagnosticCollector;
            print('errors: ${collector.errors}');
            print('warnings: ${collector.warnings}');
            Expect.isTrue(collector.errors.isEmpty);
            Expect.equals(1, collector.warnings.length);
            Expect.equals(MessageKind.LIBRARY_NAME_MISMATCH,
                collector.warnings.first.messageKind);
            Expect.equals(
                'foo',
                collector.warnings.first.message.arguments['libraryName']
                    .toString());
          }));
}
