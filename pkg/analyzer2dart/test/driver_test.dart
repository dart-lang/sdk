// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';
import 'package:analyzer/src/generated/ast.dart';

import '../lib/src/closed_world.dart';
import '../lib/src/driver.dart';

main() {
  test('setFakeRoot', () {
    Driver driver = new Driver();
    var contents = 'main() {}';
    Source source = driver.setFakeRoot(contents);
    expect(driver.context.getContents(source).data, equals(contents));
  });

  test('resolveEntryPoint', () {
    Driver driver = new Driver();
    String contents = 'main() {}';
    FunctionElement element =
        driver.resolveEntryPoint(driver.setFakeRoot(contents));
    expect(element.name, equals('main'));
  });

  test('computeWorld', () {
    Driver driver = new Driver();
    String contents = '''
main() {
  foo();
}

foo() {
}

bar() {
}
''';
    FunctionElement entryPoint =
        driver.resolveEntryPoint(driver.setFakeRoot(contents));
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
