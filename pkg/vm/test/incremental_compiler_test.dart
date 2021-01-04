// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        DiagnosticMessage,
        ExperimentalFlag,
        computePlatformBinariesLocation;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

import 'package:vm/incremental_compiler.dart';
import 'package:vm/target/vm.dart';

import 'common_test_utils.dart';

main() {
  final platformKernel =
      computePlatformBinariesLocation().resolve('vm_platform_strong.dill');
  final sdkRoot = computePlatformBinariesLocation();

  CompilerOptions getFreshOptions() {
    return new CompilerOptions()
      ..sdkRoot = sdkRoot
      ..target = new VmTarget(new TargetFlags())
      ..additionalDills = <Uri>[platformKernel]
      ..onDiagnostic = (DiagnosticMessage message) {
        fail("Compilation error: ${message.plainTextFormatted.join('\n')}");
      }
      ..environmentDefines = const {};
  }

  final options = getFreshOptions();

  group('basic', () {
    Directory mytest;
    File main;

    setUpAll(() {
      mytest = Directory.systemTemp.createTempSync('incremental');
      main = new File('${mytest.path}/main.dart')..createSync();
      main.writeAsStringSync("main() {}\n");
    });

    tearDownAll(() {
      try {
        mytest.deleteSync(recursive: true);
      } catch (_) {
        // Ignore errors;
      }
    });

    test('compile', () async {
      IncrementalCompiler compiler = new IncrementalCompiler(options, main.uri);
      Component component = await compiler.compile();

      final StringBuffer buffer = new StringBuffer();
      new Printer(buffer, showMetadata: true)
          .writeLibraryFile(component.mainMethod.enclosingLibrary);
      expect(
          buffer.toString(),
          equals('library /*isNonNullableByDefault*/;\n'
              'import self as self;\n'
              '\n'
              'static method main() → dynamic {}\n'));
    });

    test('compile exclude sources', () async {
      CompilerOptions optionsExcludeSources = getFreshOptions()
        ..embedSourceText = false;
      IncrementalCompiler compiler =
          new IncrementalCompiler(optionsExcludeSources, main.uri);
      Component component = await compiler.compile();

      for (Source source in component.uriToSource.values) {
        expect(source.source.length, equals(0));
      }

      final StringBuffer buffer = new StringBuffer();
      new Printer(buffer, showMetadata: true)
          .writeLibraryFile(component.mainMethod.enclosingLibrary);
      expect(
          buffer.toString(),
          equals('library /*isNonNullableByDefault*/;\n'
              'import self as self;\n'
              '\n'
              'static method main() → dynamic {}\n'));
    });

    test('compile expressions errors are not re-reported', () async {
      var errorsReported = 0;
      CompilerOptions optionsAcceptErrors = getFreshOptions()
        ..onDiagnostic = (DiagnosticMessage message) {
          errorsReported++;
          message.plainTextFormatted.forEach(print);
        };
      IncrementalCompiler compiler =
          new IncrementalCompiler(optionsAcceptErrors, main.uri);
      await compiler.compile();
      compiler.accept();
      {
        Procedure procedure = await compiler.compileExpression(
            'main', <String>[], <String>[], main.uri.toString(), null, true);
        expect(procedure, isNotNull);
        expect(errorsReported, equals(0));
      }
      {
        Procedure procedure = await compiler.compileExpression(
            'main1', <String>[], <String>[], main.uri.toString(), null, true);
        expect(procedure, isNotNull);
        expect(errorsReported, equals(1));
        errorsReported = 0;
      }
      await compiler.compile();
      expect(errorsReported, equals(0));
    });
  });

  /// Collects coverage for "main.dart", "lib.dart", "lib1.dart" and "lib2.dart"
  /// checks that all tokens can be translated to line and column,
  /// return the hit positions for "lib1.dart".
  /// If [getAllSources] is false it will ask specifically for report
  /// (and thus hits) for "lib1.dart" only.
  Future<Set<int>> collectAndCheckCoverageData(int port, bool getAllSources,
      {bool resume: true,
      bool onGetAllVerifyCount: true,
      Set<int> coverageForLines}) async {
    RemoteVm remoteVm = new RemoteVm(port);

    // Wait for the script to have finished.
    while (true) {
      Map isolate = await remoteVm.getIsolate();
      Map pauseEvent = isolate["pauseEvent"];
      if (pauseEvent["kind"] == "PauseExit") break;
    }

    // Collect coverage for the two user scripts.
    List<Map> sourceReports = <Map>[];
    if (getAllSources) {
      Map sourceReport = await remoteVm.getSourceReport();
      sourceReports.add(sourceReport);
    } else {
      Map scriptsMap = await remoteVm.getScripts();
      List scripts = scriptsMap["scripts"];
      Set<String> scriptIds = new Set<String>();
      for (int i = 0; i < scripts.length; i++) {
        Map script = scripts[i];
        String scriptUri = script["uri"];
        if (scriptUri.contains("lib1.dart")) {
          scriptIds.add(script["id"]);
        }
      }

      for (String scriptId in scriptIds) {
        Map sourceReport = await remoteVm.getSourceReport(scriptId);
        sourceReports.add(sourceReport);
      }
    }

    List<String> errorMessages = <String>[];
    Set<int> hits = new Set<int>();

    // Ensure that we can get a line and column number for all reported
    // positions in the scripts we care about.
    for (Map sourceReport in sourceReports) {
      List scripts = sourceReport["scripts"];
      Map<String, int> scriptIdToIndex = new Map<String, int>();
      Set<int> lib1scriptIndices = new Set<int>();
      int i = 0;
      for (Map script in scripts) {
        if (script["uri"].toString().endsWith("main.dart") ||
            script["uri"].toString().endsWith("lib.dart") ||
            script["uri"].toString().endsWith("lib1.dart") ||
            script["uri"].toString().endsWith("lib2.dart")) {
          scriptIdToIndex[script["id"]] = i;
          if (script["uri"].toString().endsWith("lib1.dart")) {
            lib1scriptIndices.add(i);
          }
        }
        i++;
      }
      if (getAllSources && onGetAllVerifyCount) {
        expect(scriptIdToIndex.length >= 2, isTrue);
      }

      // Ensure the scripts all have a non-null 'tokenPosTable' entry.
      Map<int, Map> scriptIndexToScript = new Map<int, Map>();
      for (String scriptId in scriptIdToIndex.keys) {
        Map script = await remoteVm.getObject(scriptId);
        int scriptIdx = scriptIdToIndex[scriptId];
        scriptIndexToScript[scriptIdx] = script;
        List tokenPosTable = script["tokenPosTable"];
        if (tokenPosTable == null) {
          errorMessages.add("Script with uri ${script['uri']} "
              "and id ${script['id']} "
              "has null tokenPosTable.");
        } else if (tokenPosTable.isEmpty) {
          errorMessages.add("Script with uri ${script['uri']} "
              "and id ${script['id']} "
              "has empty tokenPosTable.");
        }
      }

      List ranges = sourceReport["ranges"];
      Set<int> scriptIndexesSet = new Set<int>.from(scriptIndexToScript.keys);
      for (Map range in ranges) {
        if (scriptIndexesSet.contains(range["scriptIndex"])) {
          Set<int> positions = new Set<int>();
          positions.add(range["startPos"]);
          positions.add(range["endPos"]);
          Map coverage = range["coverage"];
          for (int pos in coverage["hits"]) {
            positions.add(pos);
            if (lib1scriptIndices.contains(range["scriptIndex"])) {
              hits.add(pos);
            }
          }
          for (int pos in coverage["misses"]) positions.add(pos);
          if (range["possibleBreakpoints"] != null) {
            for (int pos in range["possibleBreakpoints"]) positions.add(pos);
          }
          Map script = scriptIndexToScript[range["scriptIndex"]];
          Set<int> knownPositions = new Set<int>();
          Map<int, int> tokenPosToLine = {};
          if (script["tokenPosTable"] != null) {
            for (List tokenPosTableLine in script["tokenPosTable"]) {
              for (int i = 1; i < tokenPosTableLine.length; i += 2) {
                tokenPosToLine[tokenPosTableLine[i]] = tokenPosTableLine[0];
                knownPositions.add(tokenPosTableLine[i]);
              }
            }
          }
          for (int pos in positions) {
            if (!knownPositions.contains(pos)) {
              errorMessages.add("Script with uri ${script['uri']} "
                  "and id ${script['id']} "
                  "references position $pos which cannot be translated to "
                  "line and column.");
            }
          }

          if (coverageForLines != null) {
            for (int pos in coverage["hits"]) {
              if (lib1scriptIndices.contains(range["scriptIndex"])) {
                coverageForLines.add(tokenPosToLine[pos]);
              }
            }
          }
        }
      }
    }
    expect(errorMessages, isEmpty);
    if (resume) {
      remoteVm.resume();
    }
    return hits;
  }

  group('multiple kernels', () {
    Directory mytest;
    File main;
    File lib;
    Process vm;
    setUpAll(() {
      mytest = Directory.systemTemp.createTempSync('incremental');
      main = new File('${mytest.path}/main.dart')..createSync();
      main.writeAsStringSync("""
      import 'lib.dart';
      main() => print(foo());
      class C1 extends Object with C2, C3 {
        c1method() {
          print("c1");
        }
      }
      class C3 {
        c3method() {
          print("c3");
        }
      }
      """);
      lib = new File('${mytest.path}/lib.dart')..createSync();
      lib.writeAsStringSync("""
      import 'main.dart';
      foo() => 'foo';
      main() => print('bar');
      class C2 extends Object with C3 {
        c2method() {
          print("c2");
        }
      }
      """);
    });

    tearDownAll(() {
      try {
        mytest.deleteSync(recursive: true);
      } catch (_) {
        // Ignore errors;
      }
      try {
        vm.kill();
      } catch (_) {
        // Ignore errors;
      }
    });

    compileAndSerialize(
        File mainDill, File libDill, IncrementalCompiler compiler) async {
      Component component = await compiler.compile();
      new BinaryPrinter(new DevNullSink<List<int>>())
          .writeComponentFile(component);
      IOSink sink = mainDill.openWrite();
      BinaryPrinter printer = new BinaryPrinter(sink,
          libraryFilter: (lib) => lib.fileUri.path.endsWith("main.dart"));
      printer.writeComponentFile(component);
      await sink.flush();
      await sink.close();
      sink = libDill.openWrite();
      printer = new BinaryPrinter(sink,
          libraryFilter: (lib) => lib.fileUri.path.endsWith("lib.dart"));
      printer.writeComponentFile(component);
      await sink.flush();
      await sink.close();
    }

    test('main first, lib second', () async {
      Directory dir = mytest.createTempSync();
      File mainDill = File(p.join(dir.path, p.basename(main.path + ".dill")));
      File libDill = File(p.join(dir.path, p.basename(lib.path + ".dill")));
      IncrementalCompiler compiler = new IncrementalCompiler(options, main.uri);
      await compileAndSerialize(mainDill, libDill, compiler);

      var list = new File(p.join(dir.path, 'myMain.dilllist'))..createSync();
      list.writeAsStringSync("#@dill\n${mainDill.path}\n${libDill.path}\n");
      vm =
          await Process.start(Platform.resolvedExecutable, <String>[list.path]);

      final splitter = new LineSplitter();
      Completer<String> portLineCompleter = new Completer<String>();
      vm.stdout.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stdout: $s");
        if (!portLineCompleter.isCompleted) {
          portLineCompleter.complete(s);
        }
      });
      vm.stderr.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stderr: $s");
      });
      expect(await portLineCompleter.future, equals('foo'));
      print("Compiler terminated with ${await vm.exitCode} exit code");
    });

    test('main second, lib first', () async {
      Directory dir = mytest.createTempSync();
      File mainDill = File(p.join(dir.path, p.basename(main.path + ".dill")));
      File libDill = File(p.join(dir.path, p.basename(lib.path + ".dill")));
      IncrementalCompiler compiler = new IncrementalCompiler(options, lib.uri);
      await compileAndSerialize(mainDill, libDill, compiler);

      var list = new File(p.join(dir.path, 'myMain.dilllist'))..createSync();
      list.writeAsStringSync("#@dill\n${libDill.path}\n${mainDill.path}\n");
      vm =
          await Process.start(Platform.resolvedExecutable, <String>[list.path]);

      final splitter = new LineSplitter();

      Completer<String> portLineCompleter = new Completer<String>();
      vm.stdout.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stdout: $s");
        if (!portLineCompleter.isCompleted) {
          portLineCompleter.complete(s);
        }
      });
      vm.stderr.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stderr: $s");
      });
      expect(await portLineCompleter.future, equals('bar'));
      print("Compiler terminated with ${await vm.exitCode} exit code");
    });

    test('empty list', () async {
      var list = new File(p.join(mytest.path, 'myMain.dilllist'))..createSync();
      list.writeAsStringSync("#@dill\n");
      vm =
          await Process.start(Platform.resolvedExecutable, <String>[list.path]);

      Completer<int> exitCodeCompleter = new Completer<int>();
      vm.exitCode.then((exitCode) {
        print("Compiler terminated with $exitCode exit code");
        exitCodeCompleter.complete(exitCode);
      });
      expect(await exitCodeCompleter.future, equals(254));
    });

    test('fallback to source compilation if fail to load', () async {
      var list = new File('${mytest.path}/myMain.dilllist')..createSync();
      list.writeAsStringSync("main() => print('baz');\n");
      vm =
          await Process.start(Platform.resolvedExecutable, <String>[list.path]);

      final splitter = new LineSplitter();

      Completer<String> portLineCompleter = new Completer<String>();
      vm.stdout.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stdout: $s");
        if (!portLineCompleter.isCompleted) {
          portLineCompleter.complete(s);
        }
      });
      vm.stderr.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stderr: $s");
      });
      expect(await portLineCompleter.future, equals('baz'));
      print("Compiler terminated with ${await vm.exitCode} exit code");
    });

    test('relative paths', () async {
      Directory dir = mytest.createTempSync();
      File mainDill = File(p.join(dir.path, p.basename(main.path + ".dill")));
      File libDill = File(p.join(dir.path, p.basename(lib.path + ".dill")));
      IncrementalCompiler compiler = new IncrementalCompiler(options, main.uri);
      await compileAndSerialize(mainDill, libDill, compiler);

      var list = new File(p.join(dir.path, 'myMain.dilllist'))..createSync();
      list.writeAsStringSync("#@dill\nmain.dart.dill\nlib.dart.dill\n");
      Directory runFrom = new Directory(dir.path + "/runFrom")..createSync();
      vm = await Process.start(Platform.resolvedExecutable, <String>[list.path],
          workingDirectory: runFrom.path);

      final splitter = new LineSplitter();
      Completer<String> portLineCompleter = new Completer<String>();
      vm.stdout.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stdout: $s");
        if (!portLineCompleter.isCompleted) {
          portLineCompleter.complete(s);
        }
      });
      vm.stderr.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stderr: $s");
      });
      expect(await portLineCompleter.future, equals('foo'));
      print("Compiler terminated with ${await vm.exitCode} exit code");
    });

    test('collect coverage', () async {
      Directory dir = mytest.createTempSync();
      File mainDill = File(p.join(dir.path, p.basename(main.path + ".dill")));
      File libDill = File(p.join(dir.path, p.basename(lib.path + ".dill")));
      IncrementalCompiler compiler = new IncrementalCompiler(options, main.uri);
      await compileAndSerialize(mainDill, libDill, compiler);

      var list = new File(p.join(dir.path, 'myMain.dilllist'))..createSync();
      list.writeAsStringSync("#@dill\n${mainDill.path}\n${libDill.path}\n");
      vm = await Process.start(Platform.resolvedExecutable, <String>[
        "--pause-isolates-on-exit",
        "--enable-vm-service:0",
        "--disable-service-auth-codes",
        "--disable-dart-dev",
        list.path
      ]);

      const kObservatoryListening = 'Observatory listening on ';
      final RegExp observatoryPortRegExp =
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)");
      int port;
      final splitter = new LineSplitter();
      Completer<String> portLineCompleter = new Completer<String>();
      vm.stdout
          .transform(utf8.decoder)
          .transform(splitter)
          .listen((String s) async {
        if (s.startsWith(kObservatoryListening)) {
          expect(observatoryPortRegExp.hasMatch(s), isTrue);
          final match = observatoryPortRegExp.firstMatch(s);
          port = int.parse(match.group(1));
          await collectAndCheckCoverageData(port, true);
          if (!portLineCompleter.isCompleted) {
            portLineCompleter.complete("done");
          }
        }
        print("vm stdout: $s");
      });
      vm.stderr.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stderr: $s");
      });
      await portLineCompleter.future;
      print("Compiler terminated with ${await vm.exitCode} exit code");
    });
  });

  group('multiple kernels constant coverage', () {
    Directory mytest;
    File main;
    File lib1;
    int lineForUnnamedConstructor;
    int lineForNamedConstructor;
    Process vm;
    setUpAll(() {
      mytest = Directory.systemTemp.createTempSync('incremental');
      main = new File('${mytest.path}/main.dart')..createSync();
      main.writeAsStringSync("""
        // This file - combined with the lib - should have coverage for both
        // constructors of Foo.
        import 'lib1.dart' as lib1;

        void testFunction() {
          const foo = lib1.Foo.named();
          const foo2 = lib1.Foo.named();
          if (!identical(foo, foo2)) throw "what?";
        }

        main() {
          lib1.testFunction();
          testFunction();
          print("main");
        }
      """);
      lib1 = new File('${mytest.path}/lib1.dart')..createSync();
      lib1.writeAsStringSync("""
        // Compiling this file should mark the default constructor - but not the
        // named constructor - as having coverage.
        class Foo {
          final int x;
          const Foo([int? x]) : this.x = x ?? 42;
          const Foo.named([int? x]) : this.x = x ?? 42;
        }

        void testFunction() {
          const foo = Foo();
          const foo2 = Foo();
          if (!identical(foo, foo2)) throw "what?";
        }

        main() {
          testFunction();
          print("lib1");
        }
      """);
      lineForUnnamedConstructor = 5;
      lineForNamedConstructor = 6;
    });

    tearDownAll(() {
      try {
        mytest.deleteSync(recursive: true);
      } catch (_) {
        // Ignore errors;
      }
      try {
        vm.kill();
      } catch (_) {
        // Ignore errors;
      }
    });

    Future<Set<int>> runAndGetLineCoverage(
        File list, String expectStdoutContains) async {
      vm = await Process.start(Platform.resolvedExecutable, <String>[
        "--pause-isolates-on-exit",
        "--enable-vm-service:0",
        "--disable-service-auth-codes",
        "--disable-dart-dev",
        list.path
      ]);

      const kObservatoryListening = 'Observatory listening on ';
      final RegExp observatoryPortRegExp =
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)");
      int port;
      final splitter = new LineSplitter();
      Completer<String> portLineCompleter = new Completer<String>();
      Set<int> coverageLines = {};
      bool foundExpectedString = false;
      vm.stdout
          .transform(utf8.decoder)
          .transform(splitter)
          .listen((String s) async {
        if (s == expectStdoutContains) {
          foundExpectedString = true;
        }
        if (s.startsWith(kObservatoryListening)) {
          expect(observatoryPortRegExp.hasMatch(s), isTrue);
          final match = observatoryPortRegExp.firstMatch(s);
          port = int.parse(match.group(1));
          await collectAndCheckCoverageData(port, true,
              onGetAllVerifyCount: false, coverageForLines: coverageLines);
          if (!portLineCompleter.isCompleted) {
            portLineCompleter.complete("done");
          }
        }
        print("vm stdout: $s");
      });
      vm.stderr.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stderr: $s");
      });
      await portLineCompleter.future;
      print("Compiler terminated with ${await vm.exitCode} exit code");
      expect(foundExpectedString, isTrue);
      return coverageLines;
    }

    test('compile seperatly, check coverage', () async {
      Directory dir = mytest.createTempSync();

      // First compile lib, run and verify coverage (un-named constructor
      // covered, but not the named constructor).
      // Note that it's called 'lib1' to match with expectations from coverage
      // collector helper in this file.
      File libDill = File(p.join(dir.path, p.basename(lib1.path + ".dill")));
      IncrementalCompiler compiler = new IncrementalCompiler(options, lib1.uri);
      Component component = await compiler.compile();
      expect(component.libraries.length, equals(1));
      expect(component.libraries.single.fileUri, equals(lib1.uri));
      IOSink sink = libDill.openWrite();
      BinaryPrinter printer = new BinaryPrinter(sink);
      printer.writeComponentFile(component);
      await sink.flush();
      await sink.close();
      File list = new File(p.join(dir.path, 'dill.list'))..createSync();
      list.writeAsStringSync("#@dill\n${libDill.path}\n");
      Set<int> lineCoverage = await runAndGetLineCoverage(list, "lib1");
      // Expect coverage for unnamed constructor but not for the named one.
      expect(
          lineCoverage.intersection(
              {lineForUnnamedConstructor, lineForNamedConstructor}),
          equals({lineForUnnamedConstructor}));

      try {
        vm.kill();
      } catch (_) {
        // Ignore errors;
      }
      // Accept the compile to not include the lib again.
      compiler.accept();

      // Then compile lib, run and verify coverage (un-named constructor
      // covered, and the named constructor coveraged too).
      File mainDill = File(p.join(dir.path, p.basename(main.path + ".dill")));
      component = await compiler.compile(entryPoint: main.uri);
      expect(component.libraries.length, equals(1));
      expect(component.libraries.single.fileUri, equals(main.uri));
      sink = mainDill.openWrite();
      printer = new BinaryPrinter(sink);
      printer.writeComponentFile(component);
      await sink.flush();
      await sink.close();
      list.writeAsStringSync("#@dill\n${mainDill.path}\n${libDill.path}\n");
      lineCoverage = await runAndGetLineCoverage(list, "main");

      // Expect coverage for both unnamed constructor and for the named one.
      expect(
          lineCoverage.intersection(
              {lineForUnnamedConstructor, lineForNamedConstructor}),
          equals({lineForUnnamedConstructor, lineForNamedConstructor}));

      try {
        vm.kill();
      } catch (_) {
        // Ignore errors;
      }
      // Accept the compile to not include the lib again.
      compiler.accept();

      // Finally, change lib to shift the constructors so the old line numbers
      // doesn't match. Compile lib by itself, compile lib, run with the old
      // main and verify coverage is still correct (both un-named constructor
      // and named constructor (at new line numbers) are covered, and the old
      // line numbers are not coverage.

      lib1.writeAsStringSync("""
        //
        // Shift lines down by five
        // lines so the original
        // lines can't be coverred
        //
        class Foo {
          final int x;
          const Foo([int? x]) : this.x = x ?? 42;
          const Foo.named([int? x]) : this.x = x ?? 42;
        }

        void testFunction() {
          const foo = Foo();
          const foo2 = Foo();
          if (!identical(foo, foo2)) throw "what?";
        }

        main() {
          testFunction();
          print("lib1");
        }
      """);
      int newLineForUnnamedConstructor = 8;
      int newLineForNamedConstructor = 9;
      compiler.invalidate(lib1.uri);
      component = await compiler.compile(entryPoint: lib1.uri);
      expect(component.libraries.length, equals(1));
      expect(component.libraries.single.fileUri, equals(lib1.uri));
      sink = libDill.openWrite();
      printer = new BinaryPrinter(sink);
      printer.writeComponentFile(component);
      await sink.flush();
      await sink.close();
      list.writeAsStringSync("#@dill\n${mainDill.path}\n${libDill.path}\n");
      lineCoverage = await runAndGetLineCoverage(list, "main");

      // Expect coverage for both unnamed constructor and for the named one on
      // the new positions, but no coverage on the old positions.
      expect(
          lineCoverage.intersection({
            lineForUnnamedConstructor,
            lineForNamedConstructor,
            newLineForUnnamedConstructor,
            newLineForNamedConstructor
          }),
          equals({newLineForUnnamedConstructor, newLineForNamedConstructor}));

      try {
        vm.kill();
      } catch (_) {
        // Ignore errors;
      }
      // Accept the compile to not include the lib again.
      compiler.accept();
    });
  });

  group('multiple kernels 2', () {
    Directory mytest;
    File main;
    File lib1;
    File lib2;
    Process vm;
    setUpAll(() {
      mytest = Directory.systemTemp.createTempSync('incremental');
      main = new File('${mytest.path}/main.dart')..createSync();
      main.writeAsStringSync("""
        import 'lib1.dart';
        import 'lib2.dart';

        void main() {
          TestA().foo();
          bar();
        }

        class TestA with A {}
      """);
      lib1 = new File('${mytest.path}/lib1.dart')..createSync();
      lib1.writeAsStringSync("""
        mixin A {
          void foo() {
            print('foo');
          }
          void bar() {
            print('bar');
          }
        }
      """);
      lib2 = new File('${mytest.path}/lib2.dart')..createSync();
      lib2.writeAsStringSync("""
        import 'lib1.dart';
        void bar() {
          TestB().bar();
        }
        class TestB with A {}
      """);
    });

    tearDownAll(() {
      try {
        mytest.deleteSync(recursive: true);
      } catch (_) {
        // Ignore errors;
      }
      try {
        vm.kill();
      } catch (_) {
        // Ignore errors;
      }
    });

    compileAndSerialize(File mainDill, File lib1Dill, File lib2Dill,
        IncrementalCompiler compiler) async {
      Component component = await compiler.compile();
      new BinaryPrinter(new DevNullSink<List<int>>())
          .writeComponentFile(component);
      IOSink sink = mainDill.openWrite();
      BinaryPrinter printer = new BinaryPrinter(sink,
          libraryFilter: (lib) => lib.fileUri.path.endsWith("main.dart"));
      printer.writeComponentFile(component);
      await sink.flush();
      await sink.close();
      sink = lib1Dill.openWrite();
      printer = new BinaryPrinter(sink,
          libraryFilter: (lib) => lib.fileUri.path.endsWith("lib1.dart"));
      printer.writeComponentFile(component);
      await sink.flush();
      await sink.close();
      sink = lib2Dill.openWrite();
      printer = new BinaryPrinter(sink,
          libraryFilter: (lib) => lib.fileUri.path.endsWith("lib2.dart"));
      printer.writeComponentFile(component);
      await sink.flush();
      await sink.close();
    }

    test('collect coverage hits', () async {
      Directory dir = mytest.createTempSync();
      File mainDill = File(p.join(dir.path, p.basename(main.path + ".dill")));
      File lib1Dill = File(p.join(dir.path, p.basename(lib1.path + ".dill")));
      File lib2Dill = File(p.join(dir.path, p.basename(lib2.path + ".dill")));
      IncrementalCompiler compiler = new IncrementalCompiler(options, main.uri);
      await compileAndSerialize(mainDill, lib1Dill, lib2Dill, compiler);

      var list = new File(p.join(dir.path, 'myMain.dilllist'))..createSync();
      list.writeAsStringSync(
          "#@dill\n${mainDill.path}\n${lib1Dill.path}\n${lib2Dill.path}\n");
      vm = await Process.start(Platform.resolvedExecutable, <String>[
        "--pause-isolates-on-exit",
        "--enable-vm-service:0",
        "--disable-service-auth-codes",
        "--disable-dart-dev",
        list.path
      ]);

      const kObservatoryListening = 'Observatory listening on ';
      final RegExp observatoryPortRegExp =
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)");
      int port;
      final splitter = new LineSplitter();
      Completer<String> portLineCompleter = new Completer<String>();
      vm.stdout
          .transform(utf8.decoder)
          .transform(splitter)
          .listen((String s) async {
        if (s.startsWith(kObservatoryListening)) {
          expect(observatoryPortRegExp.hasMatch(s), isTrue);
          final match = observatoryPortRegExp.firstMatch(s);
          port = int.parse(match.group(1));
          Set<int> hits1 =
              await collectAndCheckCoverageData(port, true, resume: false);
          Set<int> hits2 =
              await collectAndCheckCoverageData(port, false, resume: true);
          expect(hits1.toList()..sort(), equals(hits2.toList()..sort()));
          if (!portLineCompleter.isCompleted) {
            portLineCompleter.complete("done");
          }
        }
        print("vm stdout: $s");
      });
      vm.stderr.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stderr: $s");
      });
      await portLineCompleter.future;
      print("Compiler terminated with ${await vm.exitCode} exit code");
    });
  });

  group('reload', () {
    Directory mytest;

    setUpAll(() {
      mytest = Directory.systemTemp.createTempSync('incremental');
    });

    tearDownAll(() {
      try {
        mytest.deleteSync(recursive: true);
      } catch (_) {
        // Ignore errors;
      }
    });

    test('picks up after rejected delta', () async {
      var file = new File('${mytest.path}/foo.dart')..createSync();
      file.writeAsStringSync("import 'bar.dart';\n"
          "import 'baz.dart';\n"
          "main() {\n"
          "  new A();\n"
          "  openReceivePortSoWeWontDie();"
          "}\n");

      var fileBar = new File('${mytest.path}/bar.dart')..createSync();
      fileBar.writeAsStringSync("class A<T> { int _a = 0; }\n");

      var fileBaz = new File('${mytest.path}/baz.dart')..createSync();
      fileBaz.writeAsStringSync("import 'dart:isolate';\n"
          "openReceivePortSoWeWontDie() { new RawReceivePort(); }\n");

      IncrementalCompiler compiler = new IncrementalCompiler(options, file.uri);
      Component component = await compiler.compile();

      File outputFile = new File('${mytest.path}/foo.dart.dill');
      await _writeProgramToFile(component, outputFile);

      final List<String> vmArgs = [
        '--trace_reload',
        '--trace_reload_verbose',
        '--enable-vm-service=0', // Note: use 0 to avoid port collisions.
        '--pause_isolates_on_start',
        '--disable-service-auth-codes',
        '--disable-dart-dev',
        outputFile.path
      ];
      final vm = await Process.start(Platform.resolvedExecutable, vmArgs);

      final splitter = new LineSplitter();

      vm.exitCode.then((exitCode) {
        print("Compiler terminated with $exitCode exit code");
      });

      Completer<String> portLineCompleter = new Completer<String>();
      vm.stdout.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stdout: $s");
        if (!portLineCompleter.isCompleted) {
          portLineCompleter.complete(s);
        }
      });

      vm.stderr.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stderr: $s");
      });

      String portLine = await portLineCompleter.future;

      final RegExp observatoryPortRegExp =
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)");
      expect(observatoryPortRegExp.hasMatch(portLine), isTrue);
      final match = observatoryPortRegExp.firstMatch(portLine);
      final port = int.parse(match.group(1));

      var remoteVm = new RemoteVm(port);
      await remoteVm.resume();
      compiler.accept();

      // Confirm that without changes VM reloads nothing.
      component = await compiler.compile();
      await _writeProgramToFile(component, outputFile);
      var reloadResult = await remoteVm.reload(new Uri.file(outputFile.path));
      expect(reloadResult['success'], isTrue);
      expect(reloadResult['details']['loadedLibraryCount'], equals(0));

      // Introduce a change that force VM to reject the change.
      fileBar.writeAsStringSync("class A<T,U> { int _a = 0; }\n");
      compiler.invalidate(fileBar.uri);
      component = await compiler.compile();
      await _writeProgramToFile(component, outputFile);
      reloadResult = await remoteVm.reload(new Uri.file(outputFile.path));
      expect(reloadResult['success'], isFalse);

      // Fix a change so VM is happy to accept the change.
      fileBar.writeAsStringSync("class A<T> { int _a = 0; hi() => _a; }\n");
      compiler.invalidate(fileBar.uri);
      component = await compiler.compile();
      await _writeProgramToFile(component, outputFile);
      reloadResult = await remoteVm.reload(new Uri.file(outputFile.path));
      expect(reloadResult['success'], isTrue);
      expect(reloadResult['details']['loadedLibraryCount'], equals(2));
      compiler.accept();

      vm.kill();
    });
  });

  group('reject', () {
    Directory mytest;
    setUpAll(() {
      mytest = Directory.systemTemp.createTempSync('incremental_reject');
    });

    tearDownAll(() {
      try {
        mytest.deleteSync(recursive: true);
      } catch (_) {
        // Ignore errors;
      }
    });

    test('compile, reject, compile again', () async {
      var packageUri = Uri.file('${mytest.path}/.packages');
      new File(packageUri.toFilePath()).writeAsStringSync('foo:lib/\n');
      new Directory(mytest.path + "/lib").createSync();
      var fooUri = Uri.file('${mytest.path}/lib/foo.dart');
      new File(fooUri.toFilePath())
          .writeAsStringSync("import 'package:foo/bar.dart';\n"
              "import 'package:foo/baz.dart';\n"
              "main() {\n"
              "  new A();\n"
              "  openReceivePortSoWeWontDie();"
              "}\n");

      var barUri = Uri.file('${mytest.path}/lib/bar.dart');
      new File(barUri.toFilePath())
          .writeAsStringSync("class A { static int a; }\n");

      var bazUri = Uri.file('${mytest.path}/lib/baz.dart');
      new File(bazUri.toFilePath()).writeAsStringSync("import 'dart:isolate';\n"
          "openReceivePortSoWeWontDie() { new RawReceivePort(); }\n");

      Uri packageEntry = Uri.parse('package:foo/foo.dart');

      CompilerOptions optionsModified = getFreshOptions()
        ..packagesFileUri = packageUri;
      IncrementalCompiler compiler =
          new IncrementalCompiler(optionsModified, packageEntry);
      {
        Component component = await compiler.compile(entryPoint: packageEntry);
        File outputFile = new File('${mytest.path}/foo.dart.dill');
        await _writeProgramToFile(component, outputFile);
      }
      compiler.accept();
      {
        Procedure procedure = await compiler.compileExpression(
            'a', <String>[], <String>[], 'package:foo/bar.dart', 'A', true);
        expect(procedure, isNotNull);
      }

      new File(barUri.toFilePath())
          .writeAsStringSync("class A { static int b; }\n");
      compiler.invalidate(barUri);
      {
        Component component = await compiler.compile(entryPoint: packageEntry);
        File outputFile = new File('${mytest.path}/foo1.dart.dill');
        await _writeProgramToFile(component, outputFile);
      }
      await compiler.reject();
      {
        Procedure procedure = await compiler.compileExpression(
            'a', <String>[], <String>[], 'package:foo/bar.dart', 'A', true);
        expect(procedure, isNotNull);
      }
    });

    /// This test basicaly verifies that components `relink` method is correctly
    /// called when rejecting (i.e. logically going back in time to before a
    /// rejected compilation).
    test('check links after reject', () async {
      final Uri fooUri = Uri.file('${mytest.path}/foo.dart');
      new File.fromUri(fooUri).writeAsStringSync("""
        import 'bar.dart';
        main() {
          A a = new A();
          print(a.b());
          print(A.a);
        }
        """);

      final Uri barUri = Uri.file('${mytest.path}/bar.dart');
      new File.fromUri(barUri).writeAsStringSync("""
        class A {
          static int a;
          int b() { return 42; }
        }
        """);

      final CompilerOptions optionsModified = getFreshOptions();
      optionsModified.explicitExperimentalFlags[
          ExperimentalFlag.alternativeInvalidationStrategy] = true;

      final IncrementalCompiler compiler =
          new IncrementalCompiler(optionsModified, fooUri);
      Library fooLib;
      Library barLib;
      {
        final Component component = await compiler.compile(entryPoint: fooUri);
        expect(component.libraries.length, equals(2));
        fooLib = component.libraries.firstWhere((lib) => lib.fileUri == fooUri);
        barLib = component.libraries.firstWhere((lib) => lib.fileUri == barUri);
        // Verify that foo only has links to this bar.
        final LibraryReferenceCollector lrc = new LibraryReferenceCollector();
        fooLib.accept(lrc);
        expect(lrc.librariesReferenced, equals(<Library>{barLib}));
      }
      compiler.accept();
      {
        final Procedure procedure = await compiler.compileExpression(
            'a', <String>[], <String>[], barUri.toString(), 'A', true);
        expect(procedure, isNotNull);
        // Verify that the expression only has links to the only bar we know
        // about.
        final LibraryReferenceCollector lrc = new LibraryReferenceCollector();
        procedure.accept(lrc);
        expect(lrc.librariesReferenced, equals(<Library>{barLib}));
      }

      new File.fromUri(barUri).writeAsStringSync("""
        class A {
          static int a;
          int b() { return 84; }
        }
        """);
      compiler.invalidate(barUri);
      {
        final Component component = await compiler.compile(entryPoint: fooUri);
        final Library fooLib2 = component.libraries
            .firstWhere((lib) => lib.fileUri == fooUri, orElse: () => null);
        expect(fooLib2, isNull);
        final Library barLib2 =
            component.libraries.firstWhere((lib) => lib.fileUri == barUri);
        // Verify that the fooLib (we only have the original one) only has
        // links to the newly compiled bar.
        final LibraryReferenceCollector lrc = new LibraryReferenceCollector();
        fooLib.accept(lrc);
        expect(lrc.librariesReferenced, equals(<Library>{barLib2}));
      }
      await compiler.reject();
      {
        // Verify that the original foo library only has links to the original
        // compiled bar.
        final LibraryReferenceCollector lrc = new LibraryReferenceCollector();
        fooLib.accept(lrc);
        expect(lrc.librariesReferenced, equals(<Library>{barLib}));
      }
      {
        // Verify that the saved "last known good" compnent only contains links
        // to the original 'foo' and 'bar' libraries.
        final LibraryReferenceCollector lrc = new LibraryReferenceCollector();
        compiler.lastKnownGoodComponent.accept(lrc);
        expect(lrc.librariesReferenced, equals(<Library>{fooLib, barLib}));
      }
      {
        final Procedure procedure = await compiler.compileExpression(
            'a', <String>[], <String>[], barUri.toString(), 'A', true);
        expect(procedure, isNotNull);
        // Verify that the expression only has links to the original bar.
        final LibraryReferenceCollector lrc = new LibraryReferenceCollector();
        procedure.accept(lrc);
        expect(lrc.librariesReferenced, equals(<Library>{barLib}));
      }
    });
  });

  group('expression evaluation', () {
    Directory mytest;
    Process vm;

    setUpAll(() {
      mytest = Directory.systemTemp.createTempSync('expression_evaluation');
    });

    tearDownAll(() {
      try {
        mytest.deleteSync(recursive: true);
      } catch (_) {
        // Ignore errors;
      }
      try {
        vm.kill();
      } catch (_) {
        // Ignore errors;
      }
    });

    launchBreakAndEvaluate(File scriptOrDill, String scriptUriToBreakIn,
        int lineToBreakAt, List<String> expressionsAndExpectedResults,
        {Future Function(RemoteVm remoteVm) callback}) async {
      vm = await Process.start(Platform.resolvedExecutable, <String>[
        "--pause-isolates-on-start",
        "--enable-vm-service:0",
        "--disable-service-auth-codes",
        "--disable-dart-dev",
        scriptOrDill.path
      ]);

      const kObservatoryListening = 'Observatory listening on ';
      final RegExp observatoryPortRegExp =
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)");
      int port;
      final splitter = new LineSplitter();
      Completer<String> portLineCompleter = new Completer<String>();
      vm.stdout
          .transform(utf8.decoder)
          .transform(splitter)
          .listen((String s) async {
        print("vm stdout: $s");
        if (s.startsWith(kObservatoryListening)) {
          expect(observatoryPortRegExp.hasMatch(s), isTrue);
          final match = observatoryPortRegExp.firstMatch(s);
          port = int.parse(match.group(1));
          RemoteVm remoteVm = new RemoteVm(port);

          // Wait for the script to have loaded.
          while (true) {
            Map isolate = await remoteVm.getIsolate();
            Map pauseEvent = isolate["pauseEvent"];
            if (pauseEvent["kind"] == "PauseStart") break;
          }

          var breakpoint = await findScriptAndBreak(
              remoteVm, scriptUriToBreakIn, lineToBreakAt);
          await remoteVm.resume();
          await waitForScriptToHavePaused(remoteVm);
          await evaluateExpressions(expressionsAndExpectedResults, remoteVm);
          await deletePossibleBreakpoint(remoteVm, breakpoint);

          if (callback != null) {
            await callback(remoteVm);
          }

          await remoteVm.resume();

          if (!portLineCompleter.isCompleted) {
            portLineCompleter.complete("done");
          }
        }
      });
      bool gotStdErrOutput = false;
      vm.stderr.transform(utf8.decoder).transform(splitter).listen((String s) {
        print("vm stderr: $s");
        gotStdErrOutput = true;
      });
      await portLineCompleter.future;
      int exitCode = await vm.exitCode;
      print("Compiler terminated with ${exitCode} exit code");
      expect(exitCode, equals(0));
      expect(gotStdErrOutput, isFalse);
    }

    test('from source', () async {
      Directory dir = mytest.createTempSync();
      File mainFile = new File.fromUri(dir.uri.resolve("main.dart"));
      mainFile.writeAsStringSync(r"""
        var hello = "Hello";
        main() {
          var s = "$hello world!";
          print(s);
        }
        int extra() { return 22; }
      """);

      await launchBreakAndEvaluate(mainFile, mainFile.uri.toString(), 4, [
        // 1st expression
        "s.length",
        "12",

        // 2nd expression
        "s",
        "Hello world!",

        // 3rd expression
        "hello",
        "Hello",

        // 4th expression
        "extra()",
        "22",
      ]);
    });

    test('from dill', () async {
      Directory dir = mytest.createTempSync();
      File mainFile = new File.fromUri(dir.uri.resolve("main.dart"));
      mainFile.writeAsStringSync(r"""
        var hello = "Hello";
        main() {
          var s = "$hello world!";
          print(s);
        }
        int extra() { return 22; }
      """);
      IncrementalCompiler compiler =
          new IncrementalCompiler(options, mainFile.uri);
      Component component = await compiler.compile();
      File mainDill = new File.fromUri(mainFile.uri.resolve("main.dill"));
      IOSink sink = mainDill.openWrite();
      new BinaryPrinter(sink).writeComponentFile(component);
      await sink.flush();
      await sink.close();

      mainFile.deleteSync();

      await launchBreakAndEvaluate(mainDill, mainFile.uri.toString(), 4, [
        // 1st expression
        "s.length",
        "12",

        // 2nd expression
        "s",
        "Hello world!",

        // 3rd expression
        "hello",
        "Hello",

        // 4th expression
        "extra()",
        "22",
      ]);
    });

    test('from dill with reload', () async {
      Directory dir = mytest.createTempSync();
      File mainFile = new File.fromUri(dir.uri.resolve("main.dart"));
      mainFile.writeAsStringSync(r"""
        import 'dart:async';
        import 'helper.dart';
        main() {
          int latestReloadTime = -1;
          int noChangeCount = 0;
          int numChanges = 0;
          new Timer.periodic(new Duration(milliseconds: 5), (timer) async {
            var result = reloadTime();
            if (latestReloadTime != result) {
              latestReloadTime = result;
              numChanges++;
              helperMethod();
            } else {
              noChangeCount++;
            }
            if (latestReloadTime == 42) {
              timer.cancel();
            }
            if (numChanges > 20) {
              timer.cancel();
            }
            if (noChangeCount >= 400) {
              // ~2 seconds with no change.
              throw "Expected to be done but wasn't";
            }
          });
        }
      """);
      File helperFile = new File.fromUri(dir.uri.resolve("helper.dart"));
      helperFile.writeAsStringSync(r"""
        int reloadTime() {
          return 0;
        }
        void helperMethod() {
          var hello = "Hello";
          var s = "$hello world!";
          print(s);
        }
      """);
      IncrementalCompiler compiler =
          new IncrementalCompiler(options, mainFile.uri);
      Component component = await compiler.compile();
      File mainDill = new File.fromUri(mainFile.uri.resolve("main.dill"));
      IOSink sink = mainDill.openWrite();
      new BinaryPrinter(sink).writeComponentFile(component);
      await sink.flush();
      await sink.close();
      print("=> Notice main file has size ${mainDill.lengthSync()}");

      helperFile.writeAsStringSync(r"""
        int reloadTime() {
          return 1;
        }
        void helperMethod() {
          var hello = "Hello";
          var s = "$hello world!!!";
          print(s);
        }
        int helperMethod2() {
          return 42;
        }
      """);
      compiler.invalidate(helperFile.uri);
      component = await compiler.compile();
      File partial1Dill =
          new File.fromUri(mainFile.uri.resolve("partial1.dill"));
      sink = partial1Dill.openWrite();
      new BinaryPrinter(sink).writeComponentFile(component);
      await sink.flush();
      await sink.close();
      print("=> Notice partial file #1 has size ${partial1Dill.lengthSync()}");

      helperFile.writeAsStringSync(r"""
        int reloadTime() {
          return 2;
        }
        void helperMethod() {
          var hello = "Hello";
          var s = "$hello world!!!!";
          print(s);
        }
        int helperMethod2() {
          return 21;
        }
        int helperMethod3() {
          return 84;
        }
      """);
      compiler.invalidate(helperFile.uri);
      component = await compiler.compile();
      File partial2Dill =
          new File.fromUri(mainFile.uri.resolve("partial2.dill"));
      sink = partial2Dill.openWrite();
      new BinaryPrinter(sink).writeComponentFile(component);
      await sink.flush();
      await sink.close();
      print("=> Notice partial file #2 has size ${partial2Dill.lengthSync()}");

      mainFile.deleteSync();
      helperFile.deleteSync();

      await launchBreakAndEvaluate(mainDill, helperFile.uri.toString(), 7, [
        // 1st expression
        "s.length",
        "12",

        // 2nd expression
        "s",
        "Hello world!",

        // 3rd expression
        "hello",
        "Hello",

        // 4th expression
        "reloadTime()",
        "0",
      ], callback: (RemoteVm remoteVm) async {
        for (int q = 0; q < 10; q++) {
          var reloadResult = await remoteVm.reload(partial1Dill.uri);
          expect(reloadResult is Map, isTrue);
          expect(reloadResult["success"], equals(true));

          await remoteVm.forceGc();

          var breakpoint =
              await findScriptAndBreak(remoteVm, helperFile.uri.toString(), 7);
          await remoteVm.resume();
          await waitForScriptToHavePaused(remoteVm);
          await evaluateExpressions([
            // 1st expression
            "s.length",
            "14",

            // 2nd expression
            "s",
            "Hello world!!!",

            // 3rd expression
            "hello",
            "Hello",

            // 4th expression
            "reloadTime()",
            "1",

            // 5th expression
            "helperMethod2()",
            "42",
          ], remoteVm);
          await deletePossibleBreakpoint(remoteVm, breakpoint);

          reloadResult = await remoteVm.reload(partial2Dill.uri);
          expect(reloadResult is Map, isTrue);
          expect(reloadResult["success"], equals(true));

          await remoteVm.forceGc();

          breakpoint =
              await findScriptAndBreak(remoteVm, helperFile.uri.toString(), 7);
          await remoteVm.resume();
          await waitForScriptToHavePaused(remoteVm);
          await evaluateExpressions([
            // 1st expression
            "s.length",
            "15",

            // 2nd expression
            "s",
            "Hello world!!!!",

            // 3rd expression
            "hello",
            "Hello",

            // 4th expression
            "reloadTime()",
            "2",

            // 5th expression
            "helperMethod2()",
            "21",

            // 6th expression
            "helperMethod3()",
            "84",
          ], remoteVm);
          await deletePossibleBreakpoint(remoteVm, breakpoint);
        }
      });
    });

    test('from dill with package uri', () async {
      // 2 iterations: One where the .packages file is deleted, and one where
      // it is not.
      for (int i = 0; i < 2; i++) {
        Directory dir = mytest.createTempSync();
        File mainFile = new File.fromUri(dir.uri.resolve("main.dart"));
        mainFile.writeAsStringSync(r"""
          var hello = "Hello";
          main() {
            var s = "$hello world!";
            print(s);
          }
          int extra() { return 22; }
        """);

        File packagesFile = new File.fromUri(dir.uri.resolve(".packages"));
        packagesFile.writeAsStringSync("foo:.");

        Uri mainUri = Uri.parse("package:foo/main.dart");

        CompilerOptions optionsModified = getFreshOptions()
          ..packagesFileUri = packagesFile.uri;
        IncrementalCompiler compiler =
            new IncrementalCompiler(optionsModified, mainUri);

        Component component = await compiler.compile();
        File mainDill = new File.fromUri(mainFile.uri.resolve("main.dill"));
        IOSink sink = mainDill.openWrite();
        new BinaryPrinter(sink).writeComponentFile(component);
        await sink.flush();
        await sink.close();

        mainFile.deleteSync();
        if (i == 0) {
          packagesFile.deleteSync();
        }

        await launchBreakAndEvaluate(mainDill, mainUri.toString(), 4, [
          // 1st expression
          "s.length",
          "12",

          // 2nd expression
          "s",
          "Hello world!",

          // 3rd expression
          "hello",
          "Hello",

          // 4th expression
          "extra()",
          "22",
        ]);

        try {
          dir.deleteSync(recursive: true);
        } catch (e) {
          // ignore.
        }
      }
    });
  });
}

Future evaluateExpressions(
    List<String> expressionsAndExpectedResults, RemoteVm remoteVm) async {
  for (int i = 0; i < expressionsAndExpectedResults.length; i += 2) {
    String expression = expressionsAndExpectedResults[i];
    String expectedResult = expressionsAndExpectedResults[i + 1];

    print("Evaluating $expression (expecting $expectedResult)");
    var result = await remoteVm.evaluateInFrame(expression);
    expect(result is Map, isTrue);
    expect(result["type"], equals("@Instance"));
    expect(result["valueAsString"], equals(expectedResult));
  }
}

Future waitForScriptToHavePaused(RemoteVm remoteVm) async {
  // Wait for the script to have paused.
  while (true) {
    Map isolate = await remoteVm.getIsolate();
    Map pauseEvent = isolate["pauseEvent"];
    if (pauseEvent["kind"] == "PauseBreakpoint") break;
  }
}

Future findScriptAndBreak(
    RemoteVm remoteVm, String scriptUriToBreakIn, int lineToBreakAt) async {
  Map scriptsMap = await remoteVm.getScripts();
  List scripts = scriptsMap["scripts"];
  String scriptId;
  for (int i = 0; i < scripts.length; i++) {
    Map script = scripts[i];
    String scriptUri = script["uri"];
    if (scriptUri == scriptUriToBreakIn) {
      scriptId = script["id"];
      break;
    }
  }
  expect(scriptId, isNotNull);

  return await remoteVm.addBreakpoint(scriptId, lineToBreakAt);
}

Future deletePossibleBreakpoint(
    RemoteVm remoteVm, dynamic possibleBreakpoint) async {
  if (possibleBreakpoint is Map && possibleBreakpoint["id"] is String) {
    return await remoteVm.removeBreakpoint(possibleBreakpoint["id"]);
  }
}

_writeProgramToFile(Component component, File outputFile) async {
  final IOSink sink = outputFile.openWrite();
  final BinaryPrinter printer = new BinaryPrinter(sink);
  printer.writeComponentFile(component);
  await sink.flush();
  await sink.close();
}

class LibraryReferenceCollector extends RecursiveVisitor<void> {
  Set<Library> librariesReferenced = {};

  void defaultMemberReference(Member node) {
    Library lib = node.enclosingLibrary;
    if (lib.importUri.scheme != "dart") {
      librariesReferenced.add(lib);
    }
    return super.defaultMemberReference(node);
  }
}

/// APIs to communicate with a remote VM via the VM's service protocol.
///
/// Only supports APIs to resume the program execution (when isolates are paused
/// at startup) and to trigger hot reloads.
class RemoteVm {
  /// Port used to connect to the vm service protocol, typically 8181.
  final int port;

  /// An peer point used to send service protocol messages. The service
  /// protocol uses JSON rpc on top of web-sockets.
  json_rpc.Peer get rpc => _rpc ??= _createPeer();
  json_rpc.Peer _rpc;

  /// The main isolate ID of the running VM. Needed to indicate to the VM which
  /// isolate to reload.
  FutureOr<String> get mainId async => _mainId ??= await _computeMainId();
  String _mainId;

  RemoteVm([this.port = 8181]);

  /// Establishes the JSON rpc connection.
  json_rpc.Peer _createPeer() {
    var socket = new IOWebSocketChannel.connect('ws://127.0.0.1:$port/ws');
    var peer = new json_rpc.Peer(socket.cast<String>());
    peer.listen().then((_) {
      print('connection to vm-service closed');
      return disconnect();
    }).catchError((e) {
      print('error connecting to the vm-service');
      return disconnect();
    });
    return peer;
  }

  /// Retrieves the ID of the main isolate using the service protocol.
  Future<String> _computeMainId() async {
    var vm = await rpc.sendRequest('getVM', {});
    var isolates = vm['isolates'];
    for (var isolate in isolates) {
      if (isolate['name'].contains(r'$main')) {
        return isolate['id'];
      }
    }
    return isolates.first['id'];
  }

  /// Send a request to the VM to reload sources from [entryUri].
  ///
  /// This will establish a connection with the VM assuming it is running on the
  /// local machine and listening on [port] for service protocol requests.
  ///
  /// The result is the JSON map received from the reload request.
  Future<Map> reload(Uri entryUri) async {
    print("reload($entryUri)");
    var id = await mainId;
    print("got $id, sending reloadSources rpc request");
    var result = await rpc.sendRequest('reloadSources', {
      'isolateId': id,
      'rootLibUri': entryUri.toString(),
    });
    print("got rpc result $result");
    return result;
  }

  Future resume() async {
    var id = await mainId;
    await rpc.sendRequest('resume', {'isolateId': id});
  }

  Future getIsolate() async {
    var id = await mainId;
    return await rpc.sendRequest('getIsolate', {'isolateId': id});
  }

  Future getScripts() async {
    var id = await mainId;
    return await rpc.sendRequest('getScripts', {
      'isolateId': id,
    });
  }

  Future getSourceReport([String scriptId]) async {
    var id = await mainId;
    if (scriptId != null) {
      return await rpc.sendRequest('getSourceReport', {
        'isolateId': id,
        'scriptId': scriptId,
        'reports': ['Coverage', 'PossibleBreakpoints'],
        'forceCompile': true
      });
    }
    return await rpc.sendRequest('getSourceReport', {
      'isolateId': id,
      'reports': ['Coverage', 'PossibleBreakpoints'],
      'forceCompile': true
    });
  }

  Future getObject(String objectId) async {
    var id = await mainId;
    return await rpc.sendRequest('getObject', {
      'isolateId': id,
      'objectId': objectId,
    });
  }

  Future addBreakpoint(String scriptId, int line) async {
    var id = await mainId;
    return await rpc.sendRequest('addBreakpoint', {
      'isolateId': id,
      'scriptId': scriptId,
      'line': line,
    });
  }

  Future removeBreakpoint(String breakpointId) async {
    var id = await mainId;
    return await rpc.sendRequest('removeBreakpoint', {
      'isolateId': id,
      'breakpointId': breakpointId,
    });
  }

  Future evaluateInFrame(String expression) async {
    var id = await mainId;
    var frameIndex = 0;
    return await rpc.sendRequest('evaluateInFrame', {
      'isolateId': id,
      "frameIndex": frameIndex,
      'expression': expression,
    });
  }

  Future forceGc() async {
    int expectGcAfter = new DateTime.now().millisecondsSinceEpoch;
    while (true) {
      var id = await mainId;
      Map result = await rpc.sendRequest('getAllocationProfile', {
        'isolateId': id,
        "gc": true,
      });
      String lastGc = result["dateLastServiceGC"];
      if (lastGc != null && int.parse(lastGc) >= expectGcAfter) return;
    }
  }

  /// Close any connections used to communicate with the VM.
  Future disconnect() async {
    if (_rpc == null) return null;
    this._mainId = null;
    if (!_rpc.isClosed) {
      var future = _rpc.close();
      _rpc = null;
      return future;
    }
    return null;
  }
}
