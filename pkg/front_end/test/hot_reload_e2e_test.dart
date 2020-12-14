// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Integration test that runs the incremental compiler, runs the compiled
/// program, incrementally rebuild portions of the app, and triggers a hot
/// reload on the running program.
library front_end.incremental.hot_reload_e2e_test;

import 'dart:async' show Completer;

import 'dart:convert' show LineSplitter, utf8;

import 'dart:io' show Directory, File, Platform, Process;

import 'package:async_helper/async_helper.dart' show asyncTest;

import 'package:expect/expect.dart' show Expect;

import 'package:kernel/ast.dart' show Component;

import 'package:kernel/binary/ast_to_binary.dart';

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import 'package:front_end/src/api_prototype/file_system.dart' show FileSystem;

import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator;

import 'package:front_end/src/api_prototype/memory_file_system.dart'
    show MemoryFileSystem;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/hybrid_file_system.dart'
    show HybridFileSystem;
import 'package:kernel/target/targets.dart';
import 'package:vm/target/vm.dart';

import 'tool/reload.dart' show RemoteVm;

abstract class TestCase {
  IncrementalKernelGenerator compiler;
  MemoryFileSystem fs;
  Directory outDir;
  Uri outputUri;
  List<Future<String>> lines;
  Future programIsDone;

  String get name;

  Future run();

  Future test() async {
    await setUp();
    try {
      await run();
      print("$name done");
    } finally {
      await tearDown();
    }
  }

  setUp() async {
    outDir = Directory.systemTemp.createTempSync('hotreload_test');
    outputUri = outDir.uri.resolve('test.dill');
    var root = Uri.parse('org-dartlang-test:///');
    fs = new MemoryFileSystem(root);
    fs.entityForUri(root).createDirectory();
    writeFile(fs, 'a.dart', sourceA);
    writeFile(fs, 'b.dart', sourceB);
    writeFile(fs, 'c.dart', sourceC);
    writeFile(fs, '.packages', '');
    compiler = createIncrementalCompiler(
        'org-dartlang-test:///a.dart', new HybridFileSystem(fs));
    await rebuild(compiler, outputUri); // this is a full compile.
  }

  tearDown() async {
    outDir.deleteSync(recursive: true);
    lines = null;
  }

  Future<int> computeVmPort() async {
    var portLine = await lines[0];
    Expect.isTrue(observatoryPortRegExp.hasMatch(portLine));
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
      '--disable-service-auth-codes',
      // TODO(bkonyi): The service isolate starts before DartDev has a chance
      // to spawn DDS. We should suppress the Observatory message until DDS
      // starts (#42727).
      '--disable-dart-dev',
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
    vm.stdout.transform(utf8.decoder).transform(splitter).listen((line) {
      Expect.isTrue(i < expectedLines);
      completers[i++].complete(line);
    }, onDone: () {
      Expect.equals(expectedLines, i);
    });

    // ignore: unawaited_futures
    vm.stderr.transform(utf8.decoder).transform(splitter).toList().then((err) {
      Expect.isTrue(err.isEmpty, err.join('\n'));
    });

    programIsDone = vm.exitCode;
    await resume();
  }

  /// Request a hot reload on the running program.
  Future hotReload() async {
    var port = await computeVmPort();
    var remoteVm = new RemoteVm(port);
    var reloadResult = await remoteVm.reload(outputUri);
    Expect.isTrue(reloadResult['success']);
    await remoteVm.disconnect();
  }
}

class InitialProgramIsValid extends TestCase {
  @override
  String get name => 'initial program is valid';

  @override
  Future run() async {
    await startProgram(0);
    await programIsDone;
    Expect.stringEquals("part1 part2", await lines[1]);
  }
}

class ReloadAfterLeafLibraryModification extends TestCase {
  @override
  String get name => 'reload after leaf library modification';

  @override
  Future run() async {
    await startProgram(1);
    Expect.stringEquals("part1 part2", await lines[1]);

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part3"));
    await rebuild(compiler, outputUri);
    await hotReload();
    await programIsDone;
    Expect.stringEquals("part3 part2", await lines[2]);
  }
}

class ReloadAfterNonLeafLibraryModification extends TestCase {
  @override
  String get name => "reload after non-leaf library modification";

  @override
  Future run() async {
    await startProgram(1);
    Expect.stringEquals("part1 part2", await lines[1]);

    writeFile(fs, 'a.dart', sourceA.replaceAll("part2", "part4"));
    await rebuild(compiler, outputUri);
    await hotReload();
    await programIsDone;
    Expect.stringEquals("part1 part4", await lines[2]);
  }
}

class ReloadAfterWholeProgramModification extends TestCase {
  @override
  String get name => "reload after whole program modification";

  @override
  Future run() async {
    await startProgram(1);
    Expect.stringEquals("part1 part2", await lines[1]);

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part5"));
    writeFile(fs, 'a.dart', sourceA.replaceAll("part2", "part6"));
    await rebuild(compiler, outputUri);
    await hotReload();
    await programIsDone;
    Expect.stringEquals("part5 part6", await lines[2]);
  }
}

class ReloadTwice extends TestCase {
  @override
  String get name => "reload twice";

  @override
  Future run() async {
    await startProgram(2);
    Expect.stringEquals("part1 part2", await lines[1]);

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part5"));
    writeFile(fs, 'a.dart', sourceA.replaceAll("part2", "part6"));
    await rebuild(compiler, outputUri);
    await hotReload();
    Expect.stringEquals("part5 part6", await lines[2]);

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part7"));
    writeFile(fs, 'a.dart', sourceA.replaceAll("part2", "part8"));
    await rebuild(compiler, outputUri);
    await hotReload();
    await programIsDone;
    Expect.stringEquals("part7 part8", await lines[3]);
  }
}

class ReloadToplevelField extends TestCase {
  @override
  String get name => "reload top level field";

  @override
  Future run() async {
    await startProgram(2);
    Expect.stringEquals("part1 part2", await lines[1]);

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part3"));
    writeFile(fs, 'c.dart', r"""
      void g() {
        bField.a("a");
      }

      class B {
        dynamic a;
        B({this.a});
      }

      var bField = new B(a: (String s) => "$s");
    """);

    await rebuild(compiler, outputUri);
    await hotReload();
    Expect.stringEquals("part3 part2", await lines[2]);

    writeFile(fs, 'b.dart', sourceB.replaceAll("part1", "part4"));
    writeFile(fs, 'c.dart', r"""
      void g() {
        bField.a("a");
      }

      class B {
        dynamic a;
        dynamic b;
        B({this.a});
      }

      var bField = new B(a: (String s) => "$s");
    """);

    await rebuild(compiler, outputUri);
    await hotReload();
    Expect.stringEquals("part4 part2", await lines[3]);
    await programIsDone;
  }
}

main() {
  asyncTest(() async {
    await new InitialProgramIsValid().test();
    await new ReloadAfterLeafLibraryModification().test();
    await new ReloadAfterNonLeafLibraryModification().test();
    await new ReloadAfterWholeProgramModification().test();
    await new ReloadTwice().test();
    await new ReloadToplevelField().test();
  });
}

final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);

IncrementalKernelGenerator createIncrementalCompiler(
    String entry, FileSystem fs) {
  var entryUri = Uri.base.resolve(entry);
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..librariesSpecificationUri = Uri.base.resolve("sdk/lib/libraries.json")
    ..fileSystem = fs
    ..target = new VmTarget(new TargetFlags())
    ..environmentDefines = {};
  return new IncrementalKernelGenerator(options, entryUri);
}

Future<bool> rebuild(IncrementalKernelGenerator compiler, Uri outputUri) async {
  compiler.invalidate(Uri.parse("org-dartlang-test:///a.dart"));
  compiler.invalidate(Uri.parse("org-dartlang-test:///b.dart"));
  compiler.invalidate(Uri.parse("org-dartlang-test:///c.dart"));
  var component = await compiler.computeDelta();
  if (component != null && !component.libraries.isEmpty) {
    await writeProgram(component, outputUri);
    return true;
  }
  return false;
}

Future<Null> writeProgram(Component component, Uri outputUri) async {
  var sink = new File.fromUri(outputUri).openWrite();
  // TODO(sigmund): the incremental generator should always filter these
  // libraries instead.
  new BinaryPrinter(sink,
          libraryFilter: (library) => library.importUri.scheme != 'dart')
      .writeComponentFile(component);
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
import 'c.dart';

void main(List<String> args) {
  var last = f();
  print(last);
  g();

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
      g();
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

const sourceC = r'''
void g() {}
''';

RegExp observatoryPortRegExp =
    new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)/");
