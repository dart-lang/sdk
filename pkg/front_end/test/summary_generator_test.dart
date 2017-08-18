// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/front_end.dart';
import 'package:front_end/src/testing/compiler_common.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';

import 'package:test/test.dart';

main() {
  test('summary has no source-info by default', () async {
    var summary = await summarize(['a.dart'], allSources);
    var program = loadProgramFromBytes(summary);

    // Note: the kernel representation always has an empty '' key in the map,
    // but otherwise no other data is included here.
    expect(program.uriToSource.keys.single, '');
  });

  test('summary includes declarations, but no method bodies', () async {
    var summary = await summarize(['a.dart'], allSources);
    var program = loadProgramFromBytes(summary);
    var aLib = findLibrary(program, 'a.dart');
    expect(aLib.importUri.path, '/a/b/c/a.dart');
    var classA = aLib.classes.first;
    expect(classA.name, 'A');
    var fooMethod = classA.procedures.first;
    expect(fooMethod.name.name, 'foo');
    expect(fooMethod.function.body is EmptyStatement, isTrue);
  });

  test('summarized libraries are not marked external', () async {
    var summary = await summarize(['a.dart'], allSources);
    var program = loadProgramFromBytes(summary);
    var aLib = findLibrary(program, 'a.dart');
    expect(aLib.importUri.path, '/a/b/c/a.dart');
    expect(aLib.isExternal, isFalse);
  });

  test('sdk dependencies are marked external', () async {
    // Note: by default this test is loading the SDK from summaries.
    var summary = await summarize(['a.dart'], allSources);
    var program = loadProgramFromBytes(summary);
    var coreLib = findLibrary(program, 'core');
    expect(coreLib.isExternal, isTrue);
  });

  test('non-sdk dependencies are marked external', () async {
    var summaryA = await summarize(['a.dart'], allSources);
    var sourcesWithA = new Map.from(allSources);
    sourcesWithA['a.dill'] = summaryA;
    var summaryB =
        await summarize(['b.dart'], sourcesWithA, inputSummaries: ['a.dill']);

    var program = loadProgramFromBytes(summaryB);
    var aLib = findLibrary(program, 'a.dart');
    var bLib = findLibrary(program, 'b.dart');
    expect(aLib.isExternal, isTrue);
    expect(bLib.isExternal, isFalse);
  });

  test('dependencies can be combined without conflict', () async {
    var summaryA = await summarize(['a.dart'], allSources);
    var sourcesWithA = new Map.from(allSources);
    sourcesWithA['a.dill'] = summaryA;

    var summaryBC = await summarize(['b.dart', 'c.dart'], sourcesWithA,
        inputSummaries: ['a.dill']);

    var sourcesWithABC = new Map.from(sourcesWithA);
    sourcesWithABC['bc.dill'] = summaryBC;

    // Note: a is loaded first, bc.dill have a.dart as an external reference so
    // we want to ensure loading them here will not create a problem.
    var summaryD = await summarize(['d.dart'], sourcesWithABC,
        inputSummaries: ['a.dill', 'bc.dill']);

    checkDSummary(summaryD);
  });

  test('dependencies can be combined in any order', () async {
    var summaryA = await summarize(['a.dart'], allSources);
    var sourcesWithA = new Map.from(allSources);
    sourcesWithA['a.dill'] = summaryA;

    var summaryBC = await summarize(['b.dart', 'c.dart'], sourcesWithA,
        inputSummaries: ['a.dill']);

    var sourcesWithABC = new Map.from(sourcesWithA);
    sourcesWithABC['bc.dill'] = summaryBC;

    // Note: unlinke the previous test now bc.dill is loaded first and contains
    // an external definition of library a.dart. Using this order also works
    // because we share a CanonicalName root to resolve names across multiple
    // dill files and because of how the kernel loader merges definitions.
    var summaryD = await summarize(['d.dart'], sourcesWithABC,
        inputSummaries: ['bc.dill', 'a.dill']);
    checkDSummary(summaryD);
  });

  test('summarization by default is hermetic', () async {
    var errors = [];
    var options = new CompilerOptions()..onError = (e) => errors.add(e);
    await summarize(['b.dart'], allSources, options: options);
    expect(errors.first.toString(), contains('Invalid access'));
    errors.clear();

    await summarize(['a.dart', 'b.dart'], allSources, options: options);
    expect(errors, isEmpty);
  });

  test('summarization with multi-roots can work hermetically', () async {
    var errors = [];
    var options = new CompilerOptions()
      ..onError = ((e) => errors.add(e))
      ..multiRoots = [toTestUri('rootA/'), toTestUri('rootB/')];

    var multiRootSources = <String, String>{
      'rootA/a.dart': allSources['a.dart'],
      'rootB/b.dart': allSources['b.dart'],
    };

    await summarize(['multi-root:/b.dart'], multiRootSources, options: options);
    expect(errors.first.toString(), contains('Invalid access'));
    errors.clear();

    await summarize(
        ['multi-root:/a.dart', 'multi-root:/b.dart'], multiRootSources,
        options: options);
    expect(errors, isEmpty);
  });

  // TODO(sigmund): test trimDependencies when it is part of the public API.
}

var allSources = {
  'a.dart': 'class A { foo() { print("hi"); } }',
  'b.dart': 'import "a.dart"; class B extends A {}',
  'c.dart': 'class C { bar() => 1; }',
  'd.dart': '''
      import "a.dart";
      import "b.dart";
      import "c.dart";
      class D extends B with C implements A { }''',
};

/// Helper function to check that some expectations from the summary of D.
checkDSummary(List<int> summary) {
  var program = loadProgramFromBytes(summary);
  var aLib = findLibrary(program, 'a.dart');
  var bLib = findLibrary(program, 'b.dart');
  var cLib = findLibrary(program, 'c.dart');
  var dLib = findLibrary(program, 'd.dart');

  // All libraries but `d.dart` are marked external.
  expect(aLib.isExternal, isTrue);
  expect(bLib.isExternal, isTrue);
  expect(cLib.isExternal, isTrue);
  expect(dLib.isExternal, isFalse);

  // The type-hierarchy for A, B, D is visible and correct
  var aClass = aLib.classes.firstWhere((c) => c.name == 'A');
  var bClass = bLib.classes.firstWhere((c) => c.name == 'B');
  expect(bClass.superclass, same(aClass));

  var dClass = dLib.classes.firstWhere((c) => c.name == 'D');
  expect(dClass.superclass.superclass, same(bClass));

  var dInterface = dClass.implementedTypes.first.classNode;
  expect(dInterface, same(aClass));
}
