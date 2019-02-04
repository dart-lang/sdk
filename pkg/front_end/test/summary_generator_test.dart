// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/testing/compiler_common.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';

import 'package:test/test.dart';

main() {
  test('summary has no source-info by default', () async {
    var summary = await summarize(['a.dart'], allSources);
    var component = loadComponentFromBytes(summary);

    // Note: the kernel representation always includes the Uri entries, but
    // doesn't include the actual source here.
    for (Source source in component.uriToSource.values) {
      expect(source.source.length, 0);
      expect(source.lineStarts.length, 0);
    }
  });

  test('summary includes declarations, but no method bodies', () async {
    var summary = await summarize(['a.dart'], allSources);
    var component = loadComponentFromBytes(summary);
    var aLib = findLibrary(component, 'a.dart');
    expect(aLib.importUri.path, '/a/b/c/a.dart');
    var classA = aLib.classes.first;
    expect(classA.name, 'A');
    var fooMethod = classA.procedures.first;
    expect(fooMethod.name.name, 'foo');
    expect(fooMethod.function.body is EmptyStatement, isTrue);
  });

  test('summarized libraries are not marked external', () async {
    var summary = await summarize(['a.dart'], allSources);
    var component = loadComponentFromBytes(summary);
    var aLib = findLibrary(component, 'a.dart');
    expect(aLib.importUri.path, '/a/b/c/a.dart');
    expect(aLib.isExternal, isFalse);
  });

  test('sdk dependencies are marked external', () async {
    // Note: by default this test is loading the SDK from summaries.
    var summary = await summarize(['a.dart'], allSources);
    var component = loadComponentFromBytes(summary);
    var coreLib = findLibrary(component, 'core');
    expect(coreLib.isExternal, isTrue);
  });

  test('non-sdk dependencies are marked external', () async {
    var summaryA = await summarize(['a.dart'], allSources);
    var sourcesWithA = new Map<String, dynamic>.from(allSources);
    sourcesWithA['a.dill'] = summaryA;
    var summaryB =
        await summarize(['b.dart'], sourcesWithA, inputSummaries: ['a.dill']);

    var component = loadComponentFromBytes(summaryB);
    var aLib = findLibrary(component, 'a.dart');
    var bLib = findLibrary(component, 'b.dart');
    expect(aLib.isExternal, isTrue);
    expect(bLib.isExternal, isFalse);
  });

  test('dependencies can be combined without conflict', () async {
    var summaryA = await summarize(['a.dart'], allSources);
    var sourcesWithA = new Map<String, dynamic>.from(allSources);
    sourcesWithA['a.dill'] = summaryA;

    var summaryBC = await summarize(['b.dart', 'c.dart'], sourcesWithA,
        inputSummaries: ['a.dill']);

    var sourcesWithABC = new Map<String, dynamic>.from(sourcesWithA);
    sourcesWithABC['bc.dill'] = summaryBC;

    // Note: a is loaded first, bc.dill have a.dart as an external reference so
    // we want to ensure loading them here will not create a problem.
    var summaryD = await summarize(['d.dart'], sourcesWithABC,
        inputSummaries: ['a.dill', 'bc.dill']);

    checkDSummary(summaryD);
  });

  test('dependencies can be combined in any order', () async {
    var summaryA = await summarize(['a.dart'], allSources);
    var sourcesWithA = new Map<String, dynamic>.from(allSources);
    sourcesWithA['a.dill'] = summaryA;

    var summaryBC = await summarize(['b.dart', 'c.dart'], sourcesWithA,
        inputSummaries: ['a.dill']);

    var sourcesWithABC = new Map<String, dynamic>.from(sourcesWithA);
    sourcesWithABC['bc.dill'] = summaryBC;

    // Note: unlinke the previous test now bc.dill is loaded first and contains
    // an external definition of library a.dart. Using this order also works
    // because we share a CanonicalName root to resolve names across multiple
    // dill files and because of how the kernel loader merges definitions.
    var summaryD = await summarize(['d.dart'], sourcesWithABC,
        inputSummaries: ['bc.dill', 'a.dill']);
    checkDSummary(summaryD);
  });

  test('dependencies not included in truncated summaries', () async {
    // Note: by default this test is loading the SDK from summaries.
    var summaryA = await summarize(['a.dart'], allSources, truncate: true);
    var component = loadComponentFromBytes(summaryA);
    expect(component.libraries.length, 1);
    expect(
        component.libraries.single.importUri.path.endsWith('a.dart'), isTrue);

    var sourcesWithA = new Map<String, dynamic>.from(allSources);
    sourcesWithA['a.dill'] = summaryA;
    var summaryB = await summarize(['b.dart'], sourcesWithA,
        inputSummaries: ['a.dill'], truncate: true);
    component = loadComponentFromBytes(summaryB);
    expect(component.libraries.length, 1);
    expect(
        component.libraries.single.importUri.path.endsWith('b.dart'), isTrue);
  });

  test('summarization by default is not hermetic', () async {
    var errors = [];
    var options = new CompilerOptions()..onDiagnostic = errors.add;
    await summarize(['b.dart'], allSources, options: options);
    expect(errors, isEmpty);
  });

  // TODO(sigmund): test trimDependencies when it is part of the public API.
}

var allSources = <String, String>{
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
  var component = loadComponentFromBytes(summary);
  var aLib = findLibrary(component, 'a.dart');
  var bLib = findLibrary(component, 'b.dart');
  var cLib = findLibrary(component, 'c.dart');
  var dLib = findLibrary(component, 'd.dart');

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
