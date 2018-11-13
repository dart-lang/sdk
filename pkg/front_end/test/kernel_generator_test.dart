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
        isFalse,
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

      var component =
          await compileScript('main() => print("hi");', options: options);
      expect(component, isNotNull);
      expect(errors, isNotEmpty);
    });

    test('compiler fails if it cannot find sdk summary', () async {
      var errors = [];
      var options = new CompilerOptions()
        ..sdkSummary =
            Uri.parse('org-dartlang-test:///not_existing_summary_file')
        ..onDiagnostic = errors.add;

      var component =
          await compileScript('main() => print("hi");', options: options);
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
      var component =
          await compileScript('main() => print("hi");', options: options);
      var core = component.libraries.firstWhere(isDartCoreLibrary);
      var printMember = core.members.firstWhere((m) => m.name.name == 'print');

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
      var component = await compileScript('a() => print("hi"); main() {}',
          fileName: 'a.dart');
      // Kernel always store an empty '' key in the map, so there is always at
      // least one. Having more means that source-info is added.
      expect(component.uriToSource.keys.length, greaterThan(1));
      expect(
          component.uriToSource[Uri.parse('org-dartlang-test:///a/b/c/a.dart')],
          isNotNull);
    });

    test('code from summary dependencies are marked external', () async {
      var component = await compileScript('a() => print("hi"); main() {}',
          fileName: 'a.dart');
      for (var lib in component.libraries) {
        if (lib.importUri.scheme == 'dart') {
          expect(lib.isExternal, isTrue);
        }
      }

      // Pretend that the compiled code is a summary
      var bytes = serializeComponent(component);
      component = await compileScript(
          {
            'b.dart': 'import "a.dart" as m; b() => m.a(); main() {}',
            'summary.dill': bytes
          },
          fileName: 'b.dart',
          inputSummaries: ['summary.dill']);

      var aLib = component.libraries
          .firstWhere((lib) => lib.importUri.path == '/a/b/c/a.dart');
      expect(aLib.isExternal, isTrue);
    });

    test('code from linked dependencies are not marked external', () async {
      var component = await compileScript('a() => print("hi"); main() {}',
          fileName: 'a.dart');
      for (var lib in component.libraries) {
        if (lib.importUri.scheme == 'dart') {
          expect(lib.isExternal, isTrue);
        }
      }

      var bytes = serializeComponent(component);
      component = await compileScript(
          {
            'b.dart': 'import "a.dart" as m; b() => m.a(); main() {}',
            'link.dill': bytes
          },
          fileName: 'b.dart',
          linkedDependencies: ['link.dill']);

      var aLib = component.libraries
          .firstWhere((lib) => lib.importUri.path == '/a/b/c/a.dart');
      expect(aLib.isExternal, isFalse);
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
          inputSummaries: ['a.dill']);

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
          inputSummaries: ['a.dill', 'bc.dill']);
      checkDCallsC(unitD1);

      var unitD2 = await compileUnit(['d.dart'], sources,
          inputSummaries: ['bc.dill', 'a.dill']);
      checkDCallsC(unitD2);
    });

    // TODO(sigmund): add tests with trimming dependencies
  });
}
