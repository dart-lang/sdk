// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test of element diff.
library trydart.diff_test;

import 'dart:async' show
    Future;

import 'package:expect/expect.dart' show
    Expect;

import 'package:async_helper/async_helper.dart' show
    asyncTest;

import 'package:compiler/implementation/dart2jslib.dart' show
    Compiler,
    Script;

import 'package:compiler/implementation/source_file.dart' show
    StringSourceFile;

import 'package:compiler/implementation/elements/elements.dart' show
    Element,
    LibraryElement;

import 'package:try/poi/diff.dart' show
    Difference,
    computeDifference;

import '../../compiler/dart2js/compiler_helper.dart' show
    MockCompiler,
    compilerFor;

final TEST_DATA = [
    {
      'beforeSource': 'main() {}',
      'afterSource': 'main() { var x; }',
      'expectations': [['main', 'main']],
    },
    {
      'beforeSource': 'main() {}',
      'afterSource': 'main() { /* ignored */ }',
      'expectations': [],
    },
    {
      'beforeSource': 'main() {}',
      'afterSource': 'main() { }',
      'expectations': [],
    },
    {
      'beforeSource': 'var i; main() {}',
      'afterSource': 'main() { } var i;',
      'expectations': [],
    },
    {
      'beforeSource': 'main() {}',
      'afterSource': '',
      'expectations': [['main', null]],
    },
    {
      'beforeSource': '',
      'afterSource': 'main() {}',
      'expectations': [[null, 'main']],
    },
];

const String SCHEME = 'org.trydart.diff-test';

Uri customUri(String path) => Uri.parse('$SCHEME://$path');

Future<List<Difference>> testDifference(
    String beforeSource,
    String afterSource) {
  Uri scriptUri = customUri('main.dart');
  MockCompiler compiler = compilerFor(beforeSource, scriptUri);

  Future<LibraryElement> future = compiler.libraryLoader.loadLibrary(scriptUri);
  return future.then((LibraryElement library) {
    Script sourceScript = new Script(
        scriptUri, scriptUri, new StringSourceFile('$scriptUri', afterSource));
    var dartPrivacyIsBroken = compiler.libraryLoader;
    LibraryElement newLibrary = dartPrivacyIsBroken.createLibrarySync(
        null, sourceScript, scriptUri);
    return computeDifference(library, newLibrary);
  });
}

Future testData(Map data) {
  String beforeSource = data['beforeSource'];
  String afterSource = data['afterSource'];
  List expectations = data['expectations'];

  validate(List<Difference> differences) {
    return checkExpectations(expectations, differences);
  }

  return testDifference(beforeSource, afterSource).then(validate);
}

String elementNameOrNull(Element element) {
  return element == null ? null : element.name;
}

checkExpectations(List expectations, List<Difference> differences) {
  Iterator iterator = expectations.iterator;
  for (Difference difference in differences) {
    Expect.isTrue(iterator.moveNext());
    List expectation = iterator.current;
    String expectedBeforeName = expectation[0];
    String expectedAfterName = expectation[1];
    Expect.stringEquals(
        expectedBeforeName, elementNameOrNull(difference.before));
    Expect.stringEquals(expectedAfterName, elementNameOrNull(difference.after));
    print(difference);
  }
  Expect.isFalse(iterator.moveNext());
}

void main() {
  asyncTest(() => Future.forEach(TEST_DATA, testData));
}
