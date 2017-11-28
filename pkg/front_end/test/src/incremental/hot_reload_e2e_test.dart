// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Integration test that runs the incremental compiler, runs the compiled
/// program, incrementally rebuild portions of the app, and triggers a hot
/// reload on the running program.
library front_end.incremental.hot_reload_e2e_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:front_end/byte_store.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/testing/hybrid_file_system.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/binary/limited_ast_to_binary.dart';
import 'package:test/test.dart';

import '../../tool/reload.dart';

main() {
  IncrementalKernelGenerator compiler;
  MemoryFileSystem fs;
  Directory outDir;
  Uri outputUri;
  List<Future<String>> lines;
  Future programIsDone;

  setUp(() async {
    outDir = Directory.systemTemp.createTempSync('hotreload_test');
    outputUri = outDir.uri.resolve('test.dill');
    var root = Uri.parse('org-dartlang-test:///');
    fs = new MemoryFileSystem(root);
    fs.entityForUri(root).createDirectory();
    writeFile(fs, 'a.dart', sourceA);
    writeFile(fs, 'b.dart', sourceB);
    writeFile(fs, '.packages', '');
    compiler = await createIncrementalCompiler(
        'org-dartlang-test:///a.dart', new HybridFileSystem(fs));
    await rebuild(compiler, outputUri); // this is a full compile.
    compiler.acceptLastDelta();
  });

  tearDown(() async {
    outDir.deleteSync(recursive: true);
    lines = null;
  });

  Future<int> computeVmPort() async {
    var portLine = await lines[0];
    expect(observatoryPortRegExp.hasMatch(portLine), isTrue);
    var match = observatoryPortRegExp.firstMatch(portLine);
    return int.parse(match.group(1));
  }

  /// Request vm to resume execution
  Future resume() async {
    var port = await computeVmPort();
    var remoteVm = new RemoteVm(port);
    await remoteVm.resume();
  }

  /// Start the VM with the first version of the program compiled by the
  /// incremental compiler.
  startProgram(int reloadCount) async {
    var vmArgs = [
      '--enable-vm-service=0', // Note: use 0 to avoid port collisions.
      '--pause_isolates_on_start',
      '--kernel-binaries=${dartVm.resolve(".").toFilePath()}',
      outputUri.toFilePath()
    ];
    vmArgs.add('$reloadCount');
    var vm = await Process.start(Platform.executable, vmArgs);
    var splitter = new LineSplitter();

    /// The program prints at most 2 + reloadCount lines:
    ///  - a line displaying the observatory port
    ///  - a line before waiting for a reload
    ///  - a line after each hot-reload
    int i = 0;
    int expectedLines = 2 + reloadCount;
    var completers =
        new List.generate(expectedLines, (_) => new Completer<String>());
    lines = completers.map((c) => c.future).toList();
    vm.stdout.transform(UTF8.decoder).transform(splitter).listen((line) {
      expect(i, lessThan(expectedLines));
      completers[i++].complete(line);
    }, onDone: () {
      expect(i, expectedLines);
    });

    vm.stderr.transform(UTF8.decoder).transform(splitter).toList().then((err) {
      expect(err, isEmpty, reason: err.join('\n'));
    });

    programIsDone = vm.exitCode;
    await resume();
  }

  /// Request a hot reload on the running program.
  Future hotReload() async {
    var port = await computeVmPort();
    var remoteVm = new RemoteVm(port);
    var reloadResult = await remoteVm.reload(outputUri);
    expect(reloadResult['success'], isTrue);
    compiler.acceptLastDelta();
    await remoteVm.disconnect();
  }

  test('initial program is valid', () async {
    await startProgram(0);
    await programIsDone;
    expect(await lines[1], "part1 part2");
  });

  test('reload after leaf library modification', () async {
    await startProgram(1);
    expect(await lines[1], "part1 part2");

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part3"));
    await rebuild(compiler, outputUri);
    await hotReload();
    await programIsDone;
    expect(await lines[2], "part3 part2");
  });

  test('reload after non-leaf library modification', () async {
    await startProgram(1);
    expect(await lines[1], "part1 part2");

    writeFile(fs, 'a.dart', sourceA.replaceAll("part2", "part4"));
    await rebuild(compiler, outputUri);
    await hotReload();
    await programIsDone;
    expect(await lines[2], "part1 part4");
  });

  test('reload after whole program modification', () async {
    await startProgram(1);
    expect(await lines[1], "part1 part2");

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part5"));
    writeFile(fs, 'a.dart', sourceA.replaceAll("part2", "part6"));
    await rebuild(compiler, outputUri);
    await hotReload();
    await programIsDone;
    expect(await lines[2], "part5 part6");
  });

  test('reload twice', () async {
    await startProgram(2);
    expect(await lines[1], "part1 part2");

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part5"));
    writeFile(fs, 'a.dart', sourceA.replaceAll("part2", "part6"));
    await rebuild(compiler, outputUri);
    await hotReload();
    expect(await lines[2], "part5 part6");

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part7"));
    writeFile(fs, 'a.dart', sourceA.replaceAll("part2", "part8"));
    await rebuild(compiler, outputUri);
    await hotReload();
    await programIsDone;
    expect(await lines[3], "part7 part8");
  });
}

var dartVm = Uri.base.resolve(Platform.resolvedExecutable);
var sdkRoot = dartVm.resolve("patched_sdk/");

Future<IncrementalKernelGenerator> createIncrementalCompiler(
    String entry, FileSystem fs) {
  var entryUri = Uri.base.resolve(entry);
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..strongMode = false
    ..compileSdk = true // the incremental generator requires the sdk sources
    ..fileSystem = fs
    ..byteStore = new MemoryByteStore();
  return IncrementalKernelGenerator.newInstance(options, entryUri);
}

Future<bool> rebuild(IncrementalKernelGenerator compiler, Uri outputUri) async {
  compiler.invalidate(Uri.parse("org-dartlang-test:///a.dart"));
  compiler.invalidate(Uri.parse("org-dartlang-test:///b.dart"));
  var program = (await compiler.computeDelta()).newProgram;
  if (program != null && !program.libraries.isEmpty) {
    await writeProgram(program, outputUri);
    return true;
  }
  return false;
}

Future<Null> writeProgram(Program program, Uri outputUri) async {
  var sink = new File.fromUri(outputUri).openWrite();
  // TODO(sigmund): the incremental generator should always filter these
  // libraries instead.
  new LimitedBinaryPrinter(
          sink, (library) => library.importUri.scheme != 'dart', false)
      .writeProgramFile(program);
  await sink.close();
}

void writeFile(MemoryFileSystem fs, String fileName, String contents) {
  fs
      .entityForUri(Uri.parse('org-dartlang-test:///$fileName'))
      .writeAsStringSync(contents);
}

/// This program calls a function periodically and tracks when the function
/// returns a different value than before (which only happens after a
/// hot-reload). The program exits after certain number of reloads, specified as
/// an argument to main.
const sourceA = r'''
import 'dart:async';
import 'b.dart';

void main(List<String> args) {
  var last = f();
  print(last);

  // The argument indicates how many "visible" hot-reloads to run
  int reloadCount = 0;
  if (args.length > 0) {
    reloadCount = int.parse(args[0]);
  }
  if (reloadCount == 0) return;

  new Timer.periodic(new Duration(milliseconds: 100), (timer) {
    var result = f();
    if (last != result) {
      print(result);
      last = result;
      if (--reloadCount == 0) timer.cancel();
    }
  });
}

f() => "$line part2";
''';

const sourceB = r'''
get line => "part1";
''';

RegExp observatoryPortRegExp =
    new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)/");
