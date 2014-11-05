// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'mock_sdk.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:compiler/implementation/dart2jslib.dart' show NullSink;
import 'package:unittest/unittest.dart';

import '../lib/src/closed_world.dart';
import '../lib/src/driver.dart';

main() {
  MemoryResourceProvider provider;
  Driver driver;
  setUp(() {
    provider = new MemoryResourceProvider();
    DartSdk sdk = new MockSdk();
    driver = new Driver(provider, sdk, NullSink.outputProvider);
  });

  Source setFakeRoot(String contents) {
    String path = '/root.dart';
    provider.newFile(path, contents);
    return driver.setRoot(path);
  }

  test('resolveEntryPoint', () {
    String contents = 'main() {}';
    Source source = setFakeRoot(contents);
    FunctionElement element = driver.resolveEntryPoint(source);
    expect(element.name, equals('main'));
  });

  test('computeWorld', () {
    String contents = '''
main() {
  foo();
}

foo() {
}

bar() {
}
''';
    Source source = setFakeRoot(contents);
    FunctionElement entryPoint = driver.resolveEntryPoint(source);
    ClosedWorld world = driver.computeWorld(entryPoint);
    expect(world.executableElements, hasLength(2));
    CompilationUnitElement compilationUnit =
        entryPoint.getAncestor((e) => e is CompilationUnitElement);
    Map<String, FunctionElement> functions = {};
    for (FunctionElement functionElement in compilationUnit.functions) {
      functions[functionElement.name] = functionElement;
    }
    FunctionElement mainElement = functions['main'];
    expect(world.executableElements.keys, contains(mainElement));
    FunctionDeclaration mainAst = world.executableElements[mainElement];
    expect(mainAst.element, equals(mainElement));
    FunctionElement fooElement = functions['foo'];
    expect(world.executableElements.keys, contains(fooElement));
    FunctionDeclaration fooAst = world.executableElements[fooElement];
    expect(fooAst.element, equals(fooElement));
    FunctionElement barElement = functions['bar'];
    expect(
        world.executableElements.keys,
        isNot(contains(functions[barElement])));
  });
}
