// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

// TODO(dacoharkes): Migrate script to be nullsafe and generate nullsafe
// Flutter app.

main(List<String> args) async {
  if (args.length != 1) {
    print('Usage ${Platform.executable} ${Platform.script} <output-dir>');
    exit(1);
  }

  final sdkRoot =
      path.canonicalize(path.join(Platform.script.path, '../../..'));
  final flutterTestsDir = args.single;

  print('Using SDK root: $sdkRoot');
  final testFiles = <String>[];
  final failedOrTimedOut = <String>[];
  final filteredTests = <String>[];
  await for (final testFile in listTestFiles(sdkRoot, filteredTests)) {
    final duration = await run(sdkRoot, testFile);
    if (duration != null && duration.inSeconds < 5) {
      testFiles.add(testFile);
    } else {
      failedOrTimedOut.add(testFile);
    }
  }
  testFiles.sort();
  failedOrTimedOut.sort();
  filteredTests.sort();

  dumpTestList(testFiles, 'The following tests will be included:');
  dumpTestList(failedOrTimedOut,
      'The following tests will be excluded due to timeout or test failure:');
  dumpTestList(
      filteredTests,
      'The following tests were filtered due to using '
      'dart_api.h/async/DynamicLibrary.{process,executable}/...');

  final allFiles = <String>{};
  allFiles.add(path.join(sdkRoot, 'pkg/expect/lib/expect.dart'));
  for (final testFile in testFiles) {
    allFiles.add(testFile);
    await addImportedFilesTo(allFiles, testFile);
  }

  await generateCleanDir(flutterTestsDir);

  final dartTestsDirRelative = 'example/lib';
  final dartTestsDir = path.join(flutterTestsDir, dartTestsDirRelative);
  await generateDartTests(dartTestsDir, allFiles, testFiles);

  final ccDirRelative = 'ios/Classes';
  final ccDir = path.join(flutterTestsDir, ccDirRelative);
  await generateCLibs(sdkRoot, ccDir, allFiles, testFiles);

  print('''

Files generated in:
  * $dartTestsDir
  * $ccDir

Generate flutter test application with:
  flutter create --platforms=android,ios --template=plugin <ffi_test_app_name>

Please copy generated files into FFI flutter test application:
  cd <ffi_test_app_dir> && cp -r $flutterTestsDir ./

After copying modify the test application:
  * Modify example/pubspec.yaml to depend on package:ffi.
  * Modify example/lib/main.dart to invoke all.dart while rendering.
  * Open example/ios/Runner.xcworkspace in Xcode.
    * Add the cpp files to Pods/Development Pods/<deep nesting>/ios/Classes
      to ensure they are statically linked to the app.
''');
  // TODO(dacoharkes): Automate these steps. How to automate the XCode step?
}

void dumpTestList(List<String> testFiles, String message) {
  if (testFiles.isEmpty) return;

  print(message);
  for (final testFile in testFiles) {
    print('  ${path.basename(testFile)}');
  }
}

final importRegExp = RegExp(r'''^import.*['"](.+)['"].*;''');

Future addImportedFilesTo(Set<String> allFiles, String testFile) async {
  final content = await File(testFile).readAsString();
  for (final line in content.split('\n')) {
    final match = importRegExp.matchAsPrefix(line);
    if (match != null) {
      final filename = match.group(1);
      if (!filename.contains('dart:') &&
          !filename.contains('package:expect') &&
          !filename.contains('package:ffi')) {
        final importedFile = Uri.file(testFile).resolve(filename).toFilePath();
        if (allFiles.add(importedFile)) {
          addImportedFilesTo(allFiles, importedFile);
        }
      }
    }
  }
}

Future generateCLibs(String sdkRoot, String destDir, Set<String> allFiles,
    List<String> testFiles) async {
  final dir = await generateCleanDir(destDir);

  String destinationFile;

  final lib1 =
      path.join(sdkRoot, 'runtime/bin/ffi_test/ffi_test_dynamic_library.cc');
  destinationFile =
      path.join(dir.path, path.basename(lib1)).replaceAll('.cc', '.cpp');
  File(destinationFile).writeAsStringSync(File(lib1).readAsStringSync());

  final lib2 = path.join(sdkRoot, 'runtime/bin/ffi_test/ffi_test_functions.cc');
  destinationFile =
      path.join(dir.path, path.basename(lib2)).replaceAll('.cc', '.cpp');
  File(destinationFile).writeAsStringSync(File(lib2).readAsStringSync());

  final lib3 = path.join(
      sdkRoot, 'runtime/bin/ffi_test/ffi_test_functions_generated.cc');
  destinationFile =
      path.join(dir.path, path.basename(lib3)).replaceAll('.cc', '.cpp');
  File(destinationFile).writeAsStringSync(File(lib3).readAsStringSync());
}

String cleanDart(String content) {
  return content.replaceAll('package:expect/expect.dart', 'expect.dart');
}

Future generateDartTests(
    String destDir, Set<String> allFiles, List<String> testFiles) async {
  final dir = await generateCleanDir(destDir);

  final sink = File(path.join(dir.path, 'all.dart')).openWrite();
  sink.writeln('import "dart:async";');
  sink.writeln('');
  for (int i = 0; i < testFiles.length; ++i) {
    sink.writeln('import "${path.basename(testFiles[i])}" as main$i;');
  }
  sink.writeln('');
  sink.writeln('Future invoke(dynamic fun) async {');
  sink.writeln('  if (fun is void Function() || fun is Future Function()) {');
  sink.writeln('    return await fun();');
  sink.writeln('  } else {');
  sink.writeln('    return await fun(<String>[]);');
  sink.writeln('  }');
  sink.writeln('}');
  sink.writeln('');
  sink.writeln('dynamic main() async {');
  for (int i = 0; i < testFiles.length; ++i) {
    sink.writeln('  await invoke(main$i.main);');
  }
  sink.writeln('}');
  await sink.close();

  for (final file in allFiles) {
    File(path.join(dir.path, path.basename(file)))
        .writeAsStringSync(cleanDart(File(file).readAsStringSync()));
  }

  File(path.join(dir.path, 'dylib_utils.dart')).writeAsStringSync('''
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

ffi.DynamicLibrary dlopenPlatformSpecific(String name, {String path}) {
  return Platform.isAndroid
      ? ffi.DynamicLibrary.open('libffi_tests.so')
      : ffi.DynamicLibrary.process();
}
''');
}

Stream<String> listTestFiles(
    String sdkRoot, List<String> filteredTests) async* {
  await for (final file
      in Directory(path.join(sdkRoot, 'tests/ffi_2')).list()) {
    if (file is File && file.path.endsWith('_test.dart')) {
      // These tests are VM specific and cannot necessarily be run on Flutter.
      if (path.basename(file.path).startsWith('vmspecific_')) {
        filteredTests.add(file.path);
        continue;
      }
      // These tests use special features which are hard to test on Flutter.
      final contents = file.readAsStringSync();
      if (contents.contains(RegExp('//# .* compile-time error')) ||
          contents.contains('DynamicLibrary.process') ||
          contents.contains('DynamicLibrary.executable')) {
        filteredTests.add(file.path);
        continue;
      }
      yield file.path;
    }
  }
}

Future<Duration> run(String sdkRoot, String testFile) async {
  final env = Map<String, String>.from(Platform.environment);
  env['LD_LIBRARY_PATH'] = path.join(sdkRoot, 'out/ReleaseX64');
  final sw = Stopwatch()..start();
  final Process process = await Process.start(
      Platform.executable, <String>[testFile],
      environment: env);
  final timer = Timer(const Duration(seconds: 3), () => process.kill());
  process.stdout.listen((_) {});
  process.stderr.listen((_) {});
  if (await process.exitCode != 0) return null;
  timer.cancel();
  return sw.elapsed;
}

Future<Directory> generateCleanDir(String dirname) async {
  final directory = Directory(dirname);
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
  await directory.create(recursive: true);
  return directory;
}
