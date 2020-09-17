// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show EmptyStatement, Component, ReturnStatement, StaticInvocation;

import 'package:test/test.dart'
    show
        expect,
        greaterThan,
        group,
        isEmpty,
        isNotEmpty,
        isNotNull,
        isTrue,
        same,
        test;

import 'package:front_end/src/api_prototype/front_end.dart'
    show CompilerOptions;

import 'package:front_end/src/fasta/fasta_codes.dart' show messageMissingMain;

import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;

import 'package:front_end/src/testing/compiler_common.dart'
    show
        compileScript,
        compileUnit,
        findLibrary,
        invalidCoreLibsSpecUri,
        isDartCoreLibrary;

main() {
  group('kernelForProgram', () {
    test('compiler fails if it cannot find sdk sources', () async {
      var errors = [];
      var options = new CompilerOptions()
        ..librariesSpecificationUri = invalidCoreLibsSpecUri
        ..sdkSummary = null
        ..compileSdk = true // To prevent FE from loading an sdk-summary.
        ..onDiagnostic = errors.add;

      Component component =
          (await compileScript('main() => print("hi");', options: options))
              ?.component;
      expect(component, isNotNull);
      expect(errors, isNotEmpty);
    });

    test('compiler fails if it cannot find sdk summary', () async {
      var errors = [];
      var options = new CompilerOptions()
        ..sdkSummary =
            Uri.parse('org-dartlang-test:///not_existing_summary_file')
        ..onDiagnostic = errors.add;

      Component component =
          (await compileScript('main() => print("hi");', options: options))
              ?.component;
      expect(component, isNotNull);
      expect(errors, isNotEmpty);
    });

    test('by default component is compiled using the full platform file',
        () async {
      var options = new CompilerOptions()
        // Note: we define [librariesSpecificationUri] with a specification that
        // contains broken URIs to ensure we do not attempt to lookup for
        // sources of the sdk directly.
        ..librariesSpecificationUri = invalidCoreLibsSpecUri;
      Component component =
          (await compileScript('main() => print("hi");', options: options))
              ?.component;
      var core = component.libraries.firstWhere(isDartCoreLibrary);
      var printMember = core.members.firstWhere((m) => m.name.text == 'print');

      // Note: summaries created by the SDK today contain empty statements as
      // method bodies.
      expect(printMember.function.body is! EmptyStatement, isTrue);
    });

    test('compiler requires a main method', () async {
      var errors = [];
      var options = new CompilerOptions()..onDiagnostic = errors.add;
      await compileScript('a() => print("hi");', options: options);
      expect(errors.first.message, messageMissingMain.message);
    });

    test('generated program contains source-info', () async {
      Component component = (await compileScript(
              'a() => print("hi"); main() {}',
              fileName: 'a.dart'))
          ?.component;
      // Kernel always store an empty '' key in the map, so there is always at
      // least one. Having more means that source-info is added.
      expect(component.uriToSource.keys.length, greaterThan(1));
      expect(
          component.uriToSource[Uri.parse('org-dartlang-test:///a/b/c/a.dart')],
          isNotNull);
    });

    // TODO(sigmund): add tests discovering libraries.json
  });

  group('kernelForComponent', () {
    test('compiler does not require a main method', () async {
      var errors = [];
      var options = new CompilerOptions()..onDiagnostic = errors.add;
      await compileUnit(['a.dart'], {'a.dart': 'a() => print("hi");'},
          options: options);
      expect(errors, isEmpty);
    });

    test('compiler is not hermetic by default', () async {
      var errors = [];
      var options = new CompilerOptions()..onDiagnostic = errors.add;
      await compileUnit([
        'a.dart'
      ], {
        'a.dart': 'import "b.dart"; a() => print("hi");',
        'b.dart': ''
      }, options: options);
      expect(errors, isEmpty);
    });

    test('dependencies can be loaded in any order', () async {
      var sources = <String, dynamic>{
        'a.dart': 'a() => print("hi");',
        'b.dart': 'import "a.dart"; b() => a();',
        'c.dart': 'import "b.dart"; c() => b();',
        'd.dart': 'import "c.dart"; d() => c();',
      };

      var unitA = await compileUnit(['a.dart'], sources);
      // Pretend that the compiled code is a summary
      sources['a.dill'] = serializeComponent(unitA);

      var unitBC = await compileUnit(['b.dart', 'c.dart'], sources,
          additionalDills: ['a.dill']);

      // Pretend that the compiled code is a summary
      sources['bc.dill'] = serializeComponent(unitBC);

      void checkDCallsC(Component component) {
        var dLib = findLibrary(component, 'd.dart');
        var cLib = findLibrary(component, 'c.dart');
        var dMethod = dLib.procedures.first;
        var dBody = dMethod.function.body;
        var dCall = (dBody as ReturnStatement).expression;
        var callTarget =
            (dCall as StaticInvocation).targetReference.asProcedure;
        expect(callTarget, same(cLib.procedures.first));
      }

      var unitD1 = await compileUnit(['d.dart'], sources,
          additionalDills: ['a.dill', 'bc.dill']);
      checkDCallsC(unitD1);

      var unitD2 = await compileUnit(['d.dart'], sources,
          additionalDills: ['bc.dill', 'a.dill']);
      checkDCallsC(unitD2);
    });

    // TODO(sigmund): add tests with trimming dependencies
  });
}
