// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection2.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisContextCollection2Test);
  });
}

@reflectiveTest
class AnalysisContextCollection2Test with ResourceProviderMixin {
  Folder get sdkRoot => newFolder('/sdk');

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    registerLintRules();
  }

  test_contextFor_noContext() {
    var collection = _newCollection(includedPaths: [convertPath('/root')]);
    expect(
      () => collection.contextFor(convertPath('/other/test.dart')),
      throwsStateError,
    );
  }

  test_contextFor_notAbsolute() {
    var collection = _newCollection(includedPaths: [convertPath('/root')]);
    expect(
      () => collection.contextFor(convertPath('test.dart')),
      throwsArgumentError,
    );
  }

  test_contextFor_notNormalized() {
    var collection = _newCollection(includedPaths: [convertPath('/root')]);
    expect(
      () => collection.contextFor(convertPath('/test/lib/../lib/test.dart')),
      throwsArgumentError,
    );
  }

  test_new_analysisOptions_includes() {
    var rootFolder = newFolder('/home/test');
    var fooFolder = newFolder('/home/packages/foo');
    newFile('${fooFolder.path}/lib/included.yaml', r'''
linter:
  rules:
    - empty_statements
''');

    var packageConfigFileBuilder = PackageConfigFileBuilder()
      ..add(name: 'foo', rootPath: fooFolder.path);
    newPackageConfigJsonFile(
      rootFolder.path,
      packageConfigFileBuilder.toContent(toUriStr: toUriStr),
    );

    newAnalysisOptionsYamlFile(rootFolder.path, r'''
include: package:foo/included.yaml

linter:
  rules:
    - unnecessary_parenthesis
''');

    var collection = _newCollection(includedPaths: [rootFolder.path]);
    var analysisContext = collection.contextFor(rootFolder.path);
    var analysisOptions = analysisContext.analysisOptions;

    expect(
      analysisOptions.lintRules.map((e) => e.name),
      unorderedEquals(['empty_statements', 'unnecessary_parenthesis']),
    );
  }

  test_new_analysisOptions_lintRules() {
    var rootFolder = newFolder('/home/test');
    newAnalysisOptionsYamlFile(rootFolder.path, r'''
linter:
  rules:
    - non_existent_lint_rule
    - unnecessary_parenthesis
''');

    var collection = _newCollection(includedPaths: [rootFolder.path]);
    var analysisContext = collection.contextFor(rootFolder.path);
    var analysisOptions = analysisContext.analysisOptions;

    expect(
      analysisOptions.lintRules.map((e) => e.name),
      unorderedEquals(['unnecessary_parenthesis']),
    );
  }

  test_new_includedPaths_notAbsolute() {
    expect(
      () => AnalysisContextCollectionImpl(includedPaths: ['root']),
      throwsArgumentError,
    );
  }

  test_new_includedPaths_notNormalized() {
    expect(
      () => AnalysisContextCollectionImpl(
          includedPaths: [convertPath('/root/lib/../lib')]),
      throwsArgumentError,
    );
  }

  test_new_outer_inner() {
    // OUTER
    var outerFolder = newFolder('/test/outer');
    newAnalysisOptionsYamlFile('/test/outer', r'''
linter:
  rules:
    - always_specify_types
''');
    var outerFile = newFile('/test/outer/lib/outer.dart', '');

    // INNER
    newFolder('/test/outer/inner');
    newAnalysisOptionsYamlFile('/test/outer/inner', r'''
linter:
  rules:
    - camel_case_types
''');
    var innerFile = newFile('/test/outer/inner/inner.dart', '');

    var collection = _newCollection(includedPaths: [outerFolder.path]);
    expect(collection.contexts, hasLength(1));
    var context = collection.contexts.first;

    // Files with different analysis options, share a single context.
    expect(collection.contextFor(convertPath('/test/outer/lib/outer.dart')),
        same(context));
    expect(collection.contextFor(convertPath('/test/outer/inner/inner.dart')),
        same(context));

    // But have their own analysis options.
    var outerOptions = context.getAnalysisOptionsForFile(outerFile);
    expectContainsExactly(
      outerOptions,
      lints: ['always_specify_types'],
    );

    var innerOptions = context.getAnalysisOptionsForFile(innerFile);
    expectContainsExactly(
      innerOptions,
      lints: ['camel_case_types'],
    );

    // Files do not have to exist, during creation, or at all.
    expect(collection.contextFor(convertPath('/test/outer/lib/outer2.dart')),
        same(context));
    expect(collection.contextFor(convertPath('/test/outer/inner/inner2.dart')),
        same(context));
  }

  test_new_sdkPath_notAbsolute() {
    expect(
      () => AnalysisContextCollectionImpl(
          includedPaths: ['/root'], sdkPath: 'sdk'),
      throwsArgumentError,
    );
  }

  test_new_sdkPath_notNormalized() {
    expect(
      () => AnalysisContextCollectionImpl(
          includedPaths: [convertPath('/root')], sdkPath: '/home/sdk/../sdk'),
      throwsArgumentError,
    );
  }

  AnalysisContextCollectionImpl2 _newCollection(
      {required List<String> includedPaths}) {
    return AnalysisContextCollectionImpl2(
      resourceProvider: resourceProvider,
      includedPaths: includedPaths,
      sdkPath: sdkRoot.path,
    );
  }

  static void expectContainsExactly(AnalysisOptions? options,
      {List<String>? lints}) {
    expect(options, isNotNull);
    if (lints != null) {
      var rules = options!.lintRules.map((e) => e.name);
      expect(rules, unorderedEquals(lints));
    }
  }
}
