// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart'
    show CompilerOptions, DiagnosticMessage, computePlatformBinariesLocation;
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
  final options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..target = new VmTarget(new TargetFlags())
    ..linkedDependencies = <Uri>[platformKernel]
    ..onDiagnostic = (DiagnosticMessage message) {
      fail("Compilation error: ${message.plainTextFormatted.join('\n')}");
    }
    ..environmentDefines = const {};

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
          equals('library;\n'
              'import self as self;\n'
              '\n'
              'static method main() → dynamic {}\n'));
    });

    test('compile exclude sources', () async {
      CompilerOptions optionsExcludeSources = new CompilerOptions()
        ..sdkRoot = options.sdkRoot
        ..target = options.target
        ..linkedDependencies = options.linkedDependencies
        ..onDiagnostic = options.onDiagnostic
        ..embedSourceText = false
        ..environmentDefines = options.environmentDefines;
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
          equals('library;\n'
              'import self as self;\n'
              '\n'
              'static method main() → dynamic {}\n'));
    });

    test('compile expressions errors are not re-reported', () async {
      var errorsReported = 0;
      CompilerOptions optionsAcceptErrors = new CompilerOptions()
        ..sdkRoot = options.sdkRoot
        ..target = options.target
        ..linkedDependencies = options.linkedDependencies
        ..onDiagnostic = (DiagnosticMessage message) {
          errorsReported++;
          message.plainTextFormatted.forEach(print);
        }
        ..environmentDefines = options.environmentDefines;
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
      {bool resume: true}) async {
    RemoteVm remoteVm = new RemoteVm(port);

    // Wait for the script to have finished.
    while (true) {
      Map isolate = await remoteVm.getIsolate();
      Map pauseEvent = isolate["pauseEvent"];
      if (pauseEvent["kind"] == "PauseExit") break;
    }

    // Collect coverage for the two user scripts.
    List<Map> sourceReports = new List<Map>();
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

    List<String> errorMessages = new List<String>();
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
      if (getAllSources) {
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
          for (int pos in range["possibleBreakpoints"]) positions.add(pos);
          Map script = scriptIndexToScript[range["scriptIndex"]];
          Set<int> knownPositions = new Set<int>();
          if (script["tokenPosTable"] != null) {
            for (List tokenPosTableLine in script["tokenPosTable"]) {
              for (int i = 1; i < tokenPosTableLine.length; i += 2) {
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
        list.path
      ]);

      const kObservatoryListening = 'Observatory listening on ';
      final RegExp observatoryPortRegExp =
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)/");
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
        list.path
      ]);

      const kObservatoryListening = 'Observatory listening on ';
      final RegExp observatoryPortRegExp =
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)/");
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
    test('picks up after rejected delta', () async {
      var systemTempDir = Directory.systemTemp;
      var file = new File('${systemTempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("import 'bar.dart';\n"
          "import 'baz.dart';\n"
          "main() {\n"
          "  new A();\n"
          "  openReceivePortSoWeWontDie();"
          "}\n");

      var fileBar = new File('${systemTempDir.path}/bar.dart')..createSync();
      fileBar.writeAsStringSync("class A<T> { int _a; }\n");

      var fileBaz = new File('${systemTempDir.path}/baz.dart')..createSync();
      fileBaz.writeAsStringSync("import 'dart:isolate';\n"
          "openReceivePortSoWeWontDie() { new RawReceivePort(); }\n");

      IncrementalCompiler compiler = new IncrementalCompiler(options, file.uri);
      Component component = await compiler.compile();

      File outputFile = new File('${systemTempDir.path}/foo.dart.dill');
      await _writeProgramToFile(component, outputFile);

      final List<String> vmArgs = [
        '--trace_reload',
        '--trace_reload_verbose',
        '--enable-vm-service=0', // Note: use 0 to avoid port collisions.
        '--pause_isolates_on_start',
        '--disable-service-auth-codes',
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
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)/");
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
      fileBar.writeAsStringSync("class A<T,U> { int _a; }\n");
      compiler.invalidate(fileBar.uri);
      component = await compiler.compile();
      await _writeProgramToFile(component, outputFile);
      reloadResult = await remoteVm.reload(new Uri.file(outputFile.path));
      expect(reloadResult['success'], isFalse);

      // Fix a change so VM is happy to accept the change.
      fileBar.writeAsStringSync("class A<T> { int _a; hi() => _a; }\n");
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
      options.packagesFileUri = packageUri;
      IncrementalCompiler compiler =
          new IncrementalCompiler(options, packageEntry);
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
  });
}

_writeProgramToFile(Component component, File outputFile) async {
  final IOSink sink = outputFile.openWrite();
  final BinaryPrinter printer = new BinaryPrinter(sink);
  printer.writeComponentFile(component);
  await sink.flush();
  await sink.close();
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
    var vm = await rpc.sendRequest('getVM');
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
