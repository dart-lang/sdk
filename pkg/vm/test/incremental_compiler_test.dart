// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:front_end/src/api_prototype/compilation_message.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/binary/limited_ast_to_binary.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/target/vm.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:test/test.dart';
import 'package:vm/incremental_compiler.dart';
import '../../front_end/test/tool/reload.dart' show RemoteVm;

main() {
  final platformKernel =
      computePlatformBinariesLocation().resolve('vm_platform_strong.dill');
  final sdkRoot = computePlatformBinariesLocation();
  final options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..strongMode = true
    ..target = new VmTarget(new TargetFlags(strongMode: true))
    ..linkedDependencies = <Uri>[platformKernel]
    ..reportMessages = true
    ..onError = (CompilationMessage error) {
      fail("Compilation error: ${error}");
    };

  group('basic', () {
    test('compile', () async {
      var systemTempDir = Directory.systemTemp;
      var file = new File('${systemTempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");

      IncrementalCompiler compiler = new IncrementalCompiler(options, file.uri);
      Program program = await compiler.compile();

      final StringBuffer buffer = new StringBuffer();
      new Printer(buffer, showExternal: false, showMetadata: true)
          .writeLibraryFile(program.mainMethod.enclosingLibrary);
      expect(
          buffer.toString(),
          equals('library;\n'
              'import self as self;\n'
              '\n'
              'static method main() → dynamic {}\n'));
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
          "  startTimerSoWeWontDie();"
          "}\n");

      var fileBar = new File('${systemTempDir.path}/bar.dart')..createSync();
      fileBar.writeAsStringSync("class A<T> { int _a; }\n");

      var fileBaz = new File('${systemTempDir.path}/baz.dart')..createSync();
      fileBaz.writeAsStringSync("import 'dart:async';\n"
          "startTimerSoWeWontDie() { new Timer.periodic(new Duration(milliseconds: 1000), (timer) {}); }\n");

      IncrementalCompiler compiler = new IncrementalCompiler(options, file.uri);
      Program program = await compiler.compile();

      File outputFile = new File('${systemTempDir.path}/foo.dart.dill');
      await _writeProgramToFile(program, outputFile);

      final List<String> vmArgs = [
        '--enable-vm-service=0', // Note: use 0 to avoid port collisions.
        '--pause_isolates_on_start',
        '--kernel-binaries=${sdkRoot.toFilePath()}',
        outputFile.path
      ];
      final vm = await Process.start(Platform.executable, vmArgs);
      final splitter = new LineSplitter();

      vm.exitCode.then((exitCode) {
        print("Compiler terminated with $exitCode exit code");
      });

      final String portLine =
          await vm.stdout.transform(UTF8.decoder).transform(splitter).first;

      vm.stderr
          .transform(UTF8.decoder)
          .transform(splitter)
          .toList()
          .then((err) {
        print(err.join('\n'));
        expect(err.isEmpty, isTrue,
            reason: "Should be no errors, but got ${err.join('\n')}");
      });

      final RegExp observatoryPortRegExp =
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)/");
      expect(observatoryPortRegExp.hasMatch(portLine), isTrue);
      final match = observatoryPortRegExp.firstMatch(portLine);
      final port = int.parse(match.group(1));

      var remoteVm = new RemoteVm(port);
      await remoteVm.resume();
      compiler.accept();

      print("Started program");

      // Confirm that without changes VM reloads nothing.
      program = await compiler.compile();
      _writeProgramToFile(program, outputFile);
      var reloadResult = await remoteVm.reload(Uri.parse(outputFile.path));
      expect(reloadResult['success'], isTrue);
      expect(reloadResult['details']['loadedLibraryCount'], equals(0));
      print("Completed no changes test");

      // Introduce a change that force VM to reject the change.
      fileBar.writeAsStringSync("class A<T,U> { int _a; }\n");
      compiler.invalidate(fileBar.uri);
      program = await compiler.compile();
      await _writeProgramToFile(program, outputFile);
      reloadResult = await remoteVm.reload(Uri.parse(outputFile.path));
      expect(reloadResult['success'], isFalse);
      print("Completed test that checks that invalid change failed to reload");

      // Fix a change so VM is happy to accept the change.
      fileBar.writeAsStringSync("class A<T> { int _a; hi() => _a; }\n");
      compiler.invalidate(fileBar.uri);
      program = await compiler.compile();
      _writeProgramToFile(program, outputFile);
      reloadResult = await remoteVm.reload(Uri.parse(outputFile.path));
      expect(reloadResult['success'], isTrue);
      expect(reloadResult['details']['loadedLibraryCount'], equals(2));
      compiler.accept();
      print("Completed test that checks that good change is reloaded");

      vm.kill();
    });
  });
}

_writeProgramToFile(Program program, File outputFile) async {
  final IOSink sink = outputFile.openWrite();
  final BinaryPrinter printer = new LimitedBinaryPrinter(
      sink, (_) => true /* predicate */, false /* excludeUriToSource */);
  printer.writeProgramFile(program);
  await sink.close();
}
