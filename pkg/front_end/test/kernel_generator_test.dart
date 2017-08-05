// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/front_end.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_InputError;
import 'package:front_end/src/testing/compiler_common.dart';
import 'package:kernel/ast.dart';

import 'package:test/test.dart';

main() {
  group('kernelForProgram', () {
    test('compiler fails if it cannot find sdk sources', () async {
      var errors = [];
      var options = new CompilerOptions()
        ..dartLibraries = invalidCoreLibs
        ..sdkSummary = null
        ..compileSdk = true // To prevent FE from loading an sdk-summary.
        ..onError = (e) => errors.add(e);

      var program =
          await compileScript('main() => print("hi");', options: options);
      expect(program, isNull);
      expect(errors, isNotEmpty);
    });

    test('compiler fails if it cannot find sdk summary', () async {
      var errors = [];
      var options = new CompilerOptions()
        ..sdkSummary = Uri.parse('file:///not_existing_summary_file')
        ..onError = (e) => errors.add(e);

      var program =
          await compileScript('main() => print("hi");', options: options);
      expect(program, isNull);
      expect(errors, isNotEmpty);
    });

    test('by default program is compiled using summaries', () async {
      var options = new CompilerOptions()
        // Note: we define [dartLibraries] with broken URIs to ensure we do not
        // attempt to lookup for sources of the sdk directly.
        ..dartLibraries = invalidCoreLibs;
      var program =
          await compileScript('main() => print("hi");', options: options);
      var core = program.libraries.firstWhere(isDartCoreLibrary);
      var printMember = core.members.firstWhere((m) => m.name.name == 'print');

      // Note: summaries created by the SDK today contain empty statements as
      // method bodies.
      expect(printMember.function.body is EmptyStatement, isTrue);
    });

    test('compiler requires a main method', () async {
      var errors = [];
      var options = new CompilerOptions()..onError = (e) => errors.add(e);
      await compileScript('a() => print("hi");', options: options);
      expect(errors.first.message, messageMissingMain.message);
    });

    test('default error handler throws on errors', () async {
      var options = new CompilerOptions();
      var exceptionThrown = false;
      try {
        await compileScript('a() => print("hi");', options: options);
      } on deprecated_InputError catch (e) {
        exceptionThrown = true;
        expect('${e.error}', contains("Compilation aborted"));
      }
      expect(exceptionThrown, isTrue);
    });

    test('generated program contains source-info', () async {
      var program = await compileScript('a() => print("hi"); main() {}',
          fileName: 'a.dart');
      // Kernel always store an empty '' key in the map, so there is always at
      // least one. Having more means that source-info is added.
      expect(program.uriToSource.keys.length, greaterThan(1));
      expect(program.uriToSource['file:///a/b/c/a.dart'], isNotNull);
    });

    test('code from summary dependencies are marked external', () async {
      var program = await compileScript('a() => print("hi"); main() {}',
          fileName: 'a.dart');
      for (var lib in program.libraries) {
        if (lib.importUri.scheme == 'dart') {
          expect(lib.isExternal, isTrue);
        }
      }

      // Pretend that the compiled code is a summary
      var bytes = serializeProgram(program);
      program = await compileScript(
          {
            'b.dart': 'import "a.dart" as m; b() => m.a(); main() {}',
            'summary.dill': bytes
          },
          fileName: 'b.dart',
          inputSummaries: ['summary.dill']);

      var aLib = program.libraries
          .firstWhere((lib) => lib.importUri.path == '/a/b/c/a.dart');
      expect(aLib.isExternal, isTrue);
    });

    test('code from linked dependencies are not marked external', () async {
      var program = await compileScript('a() => print("hi"); main() {}',
          fileName: 'a.dart');
      for (var lib in program.libraries) {
        if (lib.importUri.scheme == 'dart') {
          expect(lib.isExternal, isTrue);
        }
      }

      var bytes = serializeProgram(program);
      program = await compileScript(
          {
            'b.dart': 'import "a.dart" as m; b() => m.a(); main() {}',
            'link.dill': bytes
          },
          fileName: 'b.dart',
          linkedDependencies: ['link.dill']);

      var aLib = program.libraries
          .firstWhere((lib) => lib.importUri.path == '/a/b/c/a.dart');
      expect(aLib.isExternal, isFalse);
    });

    // TODO(sigmund): add tests discovering libraries.json
  });

  group('kernelForBuildUnit', () {
    test('compiler does not require a main method', () async {
      var errors = [];
      var options = new CompilerOptions()..onError = (e) => errors.add(e);
      await compileUnit(['a.dart'], {'a.dart': 'a() => print("hi");'},
          options: options);
      expect(errors, isEmpty);
    });

    test('compiler by default is hermetic', () async {
      var errors = [];
      var options = new CompilerOptions()..onError = (e) => errors.add(e);
      var sources = {
        'a.dart': 'import "b.dart"; a() => print("hi");',
        'b.dart': ''
      };
      await compileUnit(['a.dart'], sources, options: options);
      expect(errors.first.message, contains('Invalid access'));
      errors.clear();

      await compileUnit(['a.dart', 'b.dart'], sources, options: options);
      expect(errors, isEmpty);
    });

    test('chaseDependencies=true removes hermetic restriction', () async {
      var errors = [];
      var options = new CompilerOptions()
        ..chaseDependencies = true
        ..onError = (e) => errors.add(e);
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
      sources['a.dill'] = serializeProgram(unitA);

      var unitBC = await compileUnit(['b.dart', 'c.dart'], sources,
          inputSummaries: ['a.dill']);

      // Pretend that the compiled code is a summary
      sources['bc.dill'] = serializeProgram(unitBC);

      void checkDCallsC(Program program) {
        var dLib = findLibrary(program, 'd.dart');
        var cLib = findLibrary(program, 'c.dart');
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
