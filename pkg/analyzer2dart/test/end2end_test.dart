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

  test('Literals', () {
    checkResult('''
main() {
  return 0;
}
''', '''
main() $NEW_BACKEND_COMMENT
  {
    return 0;
  }

''');

    checkResult('''
main() {
  return 1.5;
}
''', '''
main() $NEW_BACKEND_COMMENT
  {
    return 1.5;
  }

''');

    checkResult('''
main() {
  return true;
}
''', '''
main() $NEW_BACKEND_COMMENT
  {
    return true;
  }

''');

    checkResult('''
main() {
  return false;
}
''', '''
main() $NEW_BACKEND_COMMENT
  {
    return false;
  }

''');

    checkResult('''
main() {
  return "a";
}
''', '''
main() $NEW_BACKEND_COMMENT
  {
    return "a";
  }

''');

    checkResult('''
main() {
  return "a" "b";
}
''', '''
main() $NEW_BACKEND_COMMENT
  {
    return "ab";
  }

''');
  });

  test('Parameters', () {
    checkResult('''
main(args) {
}
''', '''
main(args) $NEW_BACKEND_COMMENT
  {}

''');

    checkResult('''
main(a, b) {
}
''', '''
main(a, b) $NEW_BACKEND_COMMENT
  {}

''');
  });

  test('Typed parameters', () {
    checkResult('''
void main(args) {
}
''', '''
void main(args) $NEW_BACKEND_COMMENT
  {}

''');

    checkResult('''
main(int a, String b) {
}
''', '''
main(int a, String b) $NEW_BACKEND_COMMENT
  {}

''');

    checkResult('''
main(Comparator a, List b) {
}
''', '''
main(Comparator a, List b) $NEW_BACKEND_COMMENT
  {}

''');

    checkResult('''
main(Comparator<dynamic> a, List<dynamic> b) {
}
''', '''
main(Comparator a, List b) $NEW_BACKEND_COMMENT
  {}

''');

    checkResult('''
main(Map a, Map<dynamic, List<int>> b) {
}
''', '''
main(Map a, Map<dynamic, List<int>> b) $NEW_BACKEND_COMMENT
  {}

''');
  });

  test('Pass arguments', () {
    checkResult('''
foo(a) {}
main() {
  foo(null);
}
''', '''
foo(a) $NEW_BACKEND_COMMENT
  {}

main() $NEW_BACKEND_COMMENT
  {
    foo(null);
  }

''');

    checkResult('''
bar(b, c) {}
foo(a) {}
main() {
  foo(null);
  bar(0, "");
}
''', '''
bar(b, c) $NEW_BACKEND_COMMENT
  {}

foo(a) $NEW_BACKEND_COMMENT
  {}

main() $NEW_BACKEND_COMMENT
  {
    foo(null);
    bar(0, "");
  }

''');

    checkResult('''
bar(b) {}
foo(a) {
  bar(a);
}
main() {
  foo(null);
}
''', '''
bar(b) $NEW_BACKEND_COMMENT
  {}

foo(a) $NEW_BACKEND_COMMENT
  {
    bar(a);
  }

main() $NEW_BACKEND_COMMENT
  {
    foo(null);
  }

''');
  });

  test('Top level field access', () {
    checkResult('''
main(args) {
  return deprecated;
}
''', '''
main(args) $NEW_BACKEND_COMMENT
  {
    return deprecated;
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

