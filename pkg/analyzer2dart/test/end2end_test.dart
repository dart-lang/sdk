// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// End-to-end test of the analyzer2dart compiler.

import 'dart:async';

import 'mock_sdk.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:compiler/implementation/dart_backend/backend_ast_to_frontend_ast.dart';
import 'package:unittest/unittest.dart';

import '../lib/src/closed_world.dart';
import '../lib/src/driver.dart';
import '../lib/src/converted_world.dart';
import '../lib/src/dart_backend.dart';

main() {
  test('Empty main', () {
    String expectedResult =  '''
main() $NEW_BACKEND_COMMENT
  {}

''';
    checkResult('''
main() {}''',
        expectedResult);

    checkResult('''
main() {}
foo() {}''',
        expectedResult);
  });

  test('Simple call-chains', () {
    checkResult('''
foo() {}
main() {
  foo();
}
''', '''
foo() $NEW_BACKEND_COMMENT
  {}

main() $NEW_BACKEND_COMMENT
  {
    foo();
  }

''');

    checkResult('''
bar() {}
foo() {
  bar();
}
main() {
  foo();
}
''', '''
bar() $NEW_BACKEND_COMMENT
  {}

foo() $NEW_BACKEND_COMMENT
  {
    bar();
  }

main() $NEW_BACKEND_COMMENT
  {
    foo();
  }

''');

    checkResult('''
bar() {
  main();
}
foo() {
  bar();
}
main() {
  foo();
}
''', '''
bar() $NEW_BACKEND_COMMENT
  {
    main();
  }

foo() $NEW_BACKEND_COMMENT
  {
    bar();
  }

main() $NEW_BACKEND_COMMENT
  {
    foo();
  }

''');
  });
}

checkResult(String input, String expectedOutput) {
  CollectingOutputProvider outputProvider = new CollectingOutputProvider();
  MemoryResourceProvider provider = new MemoryResourceProvider();
  DartSdk sdk = new MockSdk();
  Driver driver = new Driver(provider, sdk, outputProvider);
  String rootFile = '/root.dart';
  provider.newFile(rootFile, input);
  Source rootSource = driver.setRoot(rootFile);
  FunctionElement entryPoint = driver.resolveEntryPoint(rootSource);
  ClosedWorld world = driver.computeWorld(entryPoint);
  ConvertedWorld convertedWorld = convertWorld(world);
  compileToDart(driver, convertedWorld);
  String output = outputProvider.output.text;
  expect(output, equals(expectedOutput));
}

class CollectingOutputProvider {
  StringBufferSink output;

  EventSink<String> call(String name, String extension) {
    print('outputProvider($name,$extension)');
    return output = new StringBufferSink();
  }
}

class StringBufferSink implements EventSink<String> {
  StringBuffer sb = new StringBuffer();

  void add(String text) {
    sb.write(text);
  }

  void addError(errorEvent, [StackTrace stackTrace]) {}

  void close() {}

  String get text => sb.toString();
}

