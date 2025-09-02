// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import "vm_service_heap_helper.dart" as helper;

late Completer completer;

Set<String> files = {};

// General idea: Do the once-a-week leak testing script
// => In this file:
//    * Start the frontend_server
//    * Do a compilation
//    * Pause the VM and do a "leak iteration"
//    * Once the VM has been unpaused, do an invalidation etc and repeat.
//
// This script also makes sure to clone flutter gallery,
// but assumes that flutter has been setup as by the script
// `tools/bots/flutter/compile_flutter.sh`.

Future<void> main(List<String> args) async {
  if (Platform.isWindows) {
    throw "This script cannot run on Windows as it uses non-Windows "
        "assumptions both for the placement of pub packages and the presence "
        "of 'ln' for symbolic links. It has only been tested on Linux but will "
        "probably also work on Mac.";
  }

  bool quicker = false;
  String? rootPath;

  for (String arg in args) {
    if (arg == "--quicker") {
      quicker = true;
    } else if (arg.startsWith("--path=")) {
      rootPath = arg.substring("--path=".length);
    } else {
      throw "Unknown argument '$arg'";
    }
  }

  if (rootPath == null) {
    throw "No path given. Pass with --path=<path>";
  }

  Directory patchedSdk = new Directory("$rootPath/flutter_patched_sdk/");
  if (!patchedSdk.existsSync()) {
    throw "Directory $patchedSdk doesn't exist.";
  }
  Uri frontendServerStarter = Platform.script.resolve(
    "../../frontend_server/bin/frontend_server_starter.dart",
  );
  if (!new File.fromUri(frontendServerStarter).existsSync()) {
    throw "File not found: $frontendServerStarter";
  }

  File packageConfig = new File(
    "$rootPath/flutter/.dart_tool/package_config.json",
  );

  if (!packageConfig.existsSync()) {
    // If the package_config doesn't exist we should run pub get.
    Process process = await Process.start("bin/flutter", [
      "pub",
      "get",
    ], workingDirectory: "$rootPath/flutter/");
    process.stdout.transform(utf8.decoder).transform(new LineSplitter()).listen(
      (line) {
        print("flutter stdout> $line");
      },
    );
    process.stderr.transform(utf8.decoder).transform(new LineSplitter()).listen(
      (line) {
        print("flutter stderr> $line");
      },
    );
    int processExitCode = await process.exitCode;
    print("Exit code from flutter: $processExitCode");
  }

  if (!packageConfig.existsSync()) {
    // If it still doesn't exist something is wrong.
    throw "Didn't find $packageConfig";
  }

  List<helper.Interest> interests = <helper.Interest>[];
  interests.add(
    new helper.Interest(Uri.parse("package:kernel/ast.dart"), "Library", [
      "fileUri",
    ], expectToAlwaysFind: true),
  );
  helper.VMServiceHeapHelperSpecificExactLeakFinder heapHelper =
      new helper.VMServiceHeapHelperSpecificExactLeakFinder(
        interests: interests,
        prettyPrints: [
          new helper.Interest(
            Uri.parse("package:kernel/ast.dart"),
            "Library",
            ["fileUri", "libraryIdForTesting"],
            expectToAlwaysFind: true,
          ),
        ],
        throwOnPossibleLeak: true,
      );

  print(
    "About to run with "
    "quicker = $quicker; "
    "path = $rootPath; "
    "...",
  );

  List<String> processArgs = [
    "--disable_dart_dev",
    "--disable-service-auth-codes",
    frontendServerStarter.toString(),
    "--sdk-root",
    "$rootPath/flutter_patched_sdk/",
    "--incremental",
    "--target=flutter",
    "--output-dill",
    "$rootPath/flutter_server_tmp.dill",
    "--packages",
    packageConfig.path,
    "-Ddart.vm.profile=false",
    "-Ddart.vm.product=false",
    "--enable-asserts",
    "--track-widget-creation",
    "--initialize-from-dill",
    "$rootPath/cache.dill",
  ];

  await heapHelper.start(
    processArgs,
    stdoutReceiver: (s) {
      if (s.startsWith("+")) {
        files.add(s.substring(1));
      } else if (s.startsWith("-")) {
        files.remove(s.substring(1));
      } else {
        List<String> split = s.split(" ");
        if (int.tryParse(split.last) != null &&
            split[split.length - 2].endsWith(".dill")) {
          // e.g. something like "filename.dill 0" for output file and 0
          // errors.
          completer.complete();
        } else {
          print("out> $s");
        }
      }
    },
    stderrReceiver: (s) => print("err> $s"),
  );

  Stopwatch stopwatch = new Stopwatch()..start();
  await sendAndWait(heapHelper.process, ['compile package:gallery/main.dart']);
  print("First compile took ${stopwatch.elapsedMilliseconds} ms");
  await accept(heapHelper);
  await pauseAndWait(heapHelper);

  await recompileAndWait(heapHelper.process, "package:gallery/main.dart", []);
  await accept(heapHelper);
  await sendAndWaitSetSelection(heapHelper.process);
  await sendAndWaitToObjectForSourceLocation(heapHelper.process);
  await sendAndWaitToObject(heapHelper.process);
  await pauseAndWait(heapHelper);

  print("Knows about ${files.length} files...");
  List<String> listFiles = new List<String>.from(files);
  int iteration = 0;
  for (String s in listFiles) {
    print("On iteration ${iteration++} / ${listFiles.length}");
    print(" => Invalidating $s");
    stopwatch.reset();
    await recompileAndWait(heapHelper.process, "package:gallery/main.dart", [
      s,
    ]);
    await accept(heapHelper);
    print("Recompile took ${stopwatch.elapsedMilliseconds} ms");
    await sendAndWaitSetSelection(heapHelper.process);
    await sendAndWaitToObjectForSourceLocation(heapHelper.process);
    await sendAndWaitToObject(heapHelper.process);
    if (quicker) {
      if (iteration % 10 == 0) {
        await pauseAndWait(heapHelper);
      }
    } else {
      await pauseAndWait(heapHelper);
    }
  }
  if (quicker) {
    await pauseAndWait(heapHelper);
  }

  // We should now be done.
  print("Done!");
  heapHelper.process.kill();
}

Future accept(
  helper.VMServiceHeapHelperSpecificExactLeakFinder heapHelper,
) async {
  heapHelper.process.stdin.writeln('accept');
  int waits = 0;
  while (!await heapHelper.isIdle()) {
    if (waits > 100) {
      // Waited for at least 10 seconds --- assume there's something wrong.
      throw "Timed out waiting to become idle!";
    }
    await new Future.delayed(new Duration(milliseconds: 100));
    waits++;
  }
}

class Uuid {
  final Random _random = new Random();

  /// Generate a version 4 (random) uuid. This is a uuid scheme that only uses
  /// random numbers as the source of the generated uuid.
  String generateV4() {
    // Generate xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx / 8-4-4-4-12.
    int special = 8 + _random.nextInt(4);

    return '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
        '${_bitsDigits(16, 4)}-'
        '4${_bitsDigits(12, 3)}-'
        '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
        '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
  }

  String _bitsDigits(int bitCount, int digitCount) =>
      _printDigits(_generateBits(bitCount), digitCount);

  int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

  String _printDigits(int value, int count) =>
      value.toRadixString(16).padLeft(count, '0');
}

Future pauseAndWait(
  helper.VMServiceHeapHelperSpecificExactLeakFinder heapHelper,
) async {
  int prevIterationNumber = heapHelper.iterationNumber;
  await heapHelper.pause();

  int waits = 0;
  while (heapHelper.iterationNumber == prevIterationNumber) {
    if (waits > 10000) {
      // Waited for at least 1000 seconds --- assume there's something wrong.
      throw "Timed out waiting for the helper iteration number to increase!";
    }
    await new Future.delayed(new Duration(milliseconds: 100));
    waits++;
  }
}

Future recompileAndWait(
  Process _server,
  String what,
  List<String> invalidates,
) async {
  String inputKey = Uuid().generateV4();
  List<String> data = ['recompile $what $inputKey'];
  invalidates.forEach(data.add);
  data.add('$inputKey');
  await sendAndWait(_server, data);
}

Future sendAndWait(Process _server, List<String> data) async {
  completer = new Completer();
  data.forEach(_server.stdin.writeln);
  Timer timer = Timer(const Duration(minutes: 5), () {
    throw "Timeout in sendAndWait with $data";
  });
  await completer.future;
  timer.cancel();
}

Future sendAndWaitDebugDidSendFirstFrameEvent(Process _server) async {
  String inputKey = Uuid().generateV4();
  await sendAndWait(_server, [
    /* 'compile-expression' <boundarykey> */ 'compile-expression $inputKey',
    /* expression */ 'WidgetsBinding.instance.debugDidSendFirstFrameEvent',
    /* no definitions */
    /* <boundarykey> */ inputKey,
    /* no definition types */
    /* <boundarykey> */ inputKey,
    /* no type-definitions */
    /* <boundarykey> */ inputKey,
    /* no type bounds */
    /* <boundarykey> */ inputKey,
    /* no type defaults */
    /* <boundarykey> */ inputKey,
    /* libraryUri */ 'package:flutter/src/widgets/binding.dart',
    /* class */ '',
    /* method */ '',
    /* isStatic */ 'true',
  ]);
}

Future sendAndWaitSetSelection(Process _server) async {
  String inputKey = Uuid().generateV4();
  await sendAndWait(_server, [
    /* 'compile-expression' <boundarykey> */ 'compile-expression $inputKey',
    /* expression */ 'WidgetInspectorService.instance.setSelection('
        'arg1, "dummy_68")',
    /* definition #1 */ 'arg1',
    /* <boundarykey> */ inputKey,
    /* definition type #1 */ 'null' /* aka dynamic */,
    /* <boundarykey> */ inputKey,
    /* no type-definitions */
    /* <boundarykey> */ inputKey,
    /* no type-bounds */
    /* <boundarykey> */ inputKey,
    /* no type-defaults */
    /* <boundarykey> */ inputKey,
    /* libraryUri */ 'package:flutter/src/widgets/widget_inspector.dart',
    /* class */ '',
    /* method */ '',
    /* isStatic */ 'true',
  ]);
}

Future sendAndWaitToObject(Process _server) async {
  String inputKey = Uuid().generateV4();
  await sendAndWait(_server, [
    /* 'compile-expression' <boundarykey> */ 'compile-expression $inputKey',
    /* expression */ 'WidgetInspectorService.instance.toObject('
        '"inspector-836", "tree_112")',
    /* no definitions */
    /* <boundarykey> */ inputKey,
    /* no definition types */
    /* <boundarykey> */ inputKey,
    /* no type-definitions */
    /* <boundarykey> */ inputKey,
    /* no type bounds */
    /* <boundarykey> */ inputKey,
    /* no type defaults */
    /* <boundarykey> */ inputKey,
    /* libraryUri */ 'package:flutter/src/widgets/widget_inspector.dart',
    /* class */ '',
    /* method */ '',
    /* isStatic */ 'true',
  ]);
}

Future sendAndWaitToObjectForSourceLocation(Process _server) async {
  String inputKey = Uuid().generateV4();
  await sendAndWait(_server, [
    /* 'compile-expression' <boundarykey> */ 'compile-expression $inputKey',
    /* expression */ 'WidgetInspectorService.instance.'
        'toObjectForSourceLocation("inspector-607", "tree_112")',
    /* no definitions */
    /* <boundarykey> */ inputKey,
    /* no definition types */
    /* <boundarykey> */ inputKey,
    /* no type-definitions */
    /* <boundarykey> */ inputKey,
    /* no type bounds */
    /* <boundarykey> */ inputKey,
    /* no type defaults */
    /* <boundarykey> */ inputKey,
    /* libraryUri */ 'package:flutter/src/widgets/widget_inspector.dart',
    /* class */ '',
    /* method */ '',
    /* isStatic */ 'true',
  ]);
}
