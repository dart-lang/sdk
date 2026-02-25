// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:compiler/compiler_api.dart' as api;
import 'package:compiler/src/commandline_options.dart' show Flags;
import 'package:compiler/src/util/memory_compiler.dart';
import 'package:expect/expect.dart' show Expect;
import 'package:path/path.dart' as path;
import 'package:record_use/record_use_internal.dart';
import 'package:test/test.dart';

/// Options to pass to the compiler such as
/// `Flags.disableTypeInference` or `Flags.disableInlining`
const List<String> compilerOptions = [
  Flags.writeRecordedUses,
  Flags.testMode,
  Flags.disableInlining,
  Flags.disableTypeInference,
];

/// Run `dart --define=updateExpectations=true pkg/compiler/test/record_use/record_use_test.dart`
/// to update.
/// Run `dart -DupdateExpectations=true pkg/vm/test/transformations/record_use_test.dart`
/// to update the shared expectations to the VM output.
Future<void> main() async {
  final vmFiles = _getTestFiles(
    'pkg/vm/testcases/transformations/record_use/lib',
    'record_use_test',
  );
  final jsFiles = _getTestFiles(
    'pkg/compiler/test/record_use/data/lib',
    'record_use_js_test',
  );

  final testFiles = [...vmFiles, ...jsFiles];

  final allFiles = {
    for (final file in vmFiles)
      '/record_use_test/lib/${file.basename}': file.contents,
    for (final file in jsFiles)
      '/record_use_js_test/lib/${file.basename}': file.contents,
    '/.dart_tool/package_config.json': jsonEncode({
      "configVersion": 2,
      "packages": [
        {
          "name": "record_use_test",
          "rootUri": "/record_use_test/",
          "packageUri": "lib/",
          "languageVersion": "3.9",
        },
        {
          "name": "record_use_js_test",
          "rootUri": "/record_use_js_test/",
          "packageUri": "lib/",
          "languageVersion": "3.9",
        },
        {
          "name": "meta",
          "rootUri": Directory.current.uri.resolve('pkg/meta/').toString(),
          "packageUri": "lib/",
          "languageVersion": "3.9",
        },
      ],
    }),
  };
  for (final testFile in testFiles.where((element) => element.hasMain)) {
    final bool isThrowsTest = testFile.basename.contains('throws');
    test(
      '${testFile.file.path}',
      skip: dart2jsNotSupported.contains(testFile.basename),
      () async {
        final diagnosticCollector = DiagnosticCollector();
        final recordedUsages = await compileWithUsages(
          entryPoint: testFile.uri,
          memorySourceFiles: allFiles,
          diagnosticHandler: diagnosticCollector,
          expectSuccess: !isThrowsTest,
        );

        if (isThrowsTest) {
          Expect.isTrue(recordedUsages == null);
          final errors = diagnosticCollector.errors
              .map((e) => e.text)
              .join('\n');
          if (testFile.basename.contains('invalid_location')) {
            Expect.contains('RecordUse', errors);
            Expect.contains(
              'annotation cannot be placed on this element',
              errors,
            );
          }
          if (testFile.basename.contains('record_use_final')) {
            Expect.contains('RecordUse', errors);
            Expect.contains('must be final', errors);
          }
          if (testFile.basename.contains('subtyping')) {
            Expect.contains('RecordUse', errors);
            Expect.contains('cannot be used as a supertype', errors);
          }
          return;
        }

        final goldenFile = File(testFile.file.path + '.json.expect');
        const update = bool.fromEnvironment('updateExpectations');
        if (!goldenFile.existsSync() || update) {
          await goldenFile.create();
          await goldenFile.writeAsString(recordedUsages!);
        } else {
          final actual = Recordings.fromJson(jsonDecode(recordedUsages!));
          final goldenContents = await goldenFile.readAsString();
          final golden = Recordings.fromJson(jsonDecode(goldenContents));
          final semanticEquals = actual.semanticEquals(
            golden,
            allowMetadataMismatch: true,
            allowMoreConstArguments: true,
            // Ensure test coverage of tear offs, add pragmas to prevent
            // optimiations if necessary.
            allowTearoffToStaticPromotion: false,
            loadingUnitMapping: (String unit) =>
                const <String, String>{'out': '1', 'out_1': '2'}[unit] ?? unit,
          );
          if (!semanticEquals) {
            // Print the error message based on string representation.
            Expect.stringEquals(
              recordedUsages.trim(),
              goldenContents.trim(),
              'Recorded usages for ${testFile.uri} do not match golden file.',
            );
          }
        }
      },
    );
  }

  test('outside_package_throws', () async {
    final entryPoint = Uri.parse('memory:/outside.dart');
    final memorySourceFiles = {
      ...allFiles,
      '/outside.dart': '''
import 'package:meta/meta.dart' show RecordUse;
class SomeClass {
  @RecordUse()
  static String someStaticMethod(int a) => a.toString();
}
void main() {
  print(SomeClass.someStaticMethod(42));
}
''',
    };
    final diagnosticCollector = DiagnosticCollector();
    await compileWithUsages(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      diagnosticHandler: diagnosticCollector,
      expectSuccess: false,
    );
    final errors = diagnosticCollector.errors.map((e) => e.text).join('\n');
    Expect.contains('RecordUse', errors);
    Expect.contains('package:', errors);
  });
}

Iterable<TestFile> _getTestFiles(String dirPath, String packageName) {
  final baseDir = Directory(dirPath);
  return baseDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) {
        final relativePath = path.relative(file.path, from: baseDir.path);
        return TestFile(
          file: file,
          basename: relativePath,
          contents: file.readAsStringSync(),
          uri: Uri.parse('package:$packageName/$relativePath'),
          packageName: packageName,
        );
      });
}

class TestFile {
  final File file;
  final String basename;
  final String contents;
  final Uri uri;
  final String packageName;

  const TestFile({
    required this.file,
    required this.basename,
    required this.contents,
    required this.uri,
    required this.packageName,
  });

  bool get hasMain => contents.contains('main()');
}

typedef CompiledOutput = Map<api.OutputType, Map<String, String>>;

Future<String?> compileWithUsages({
  Uri? entryPoint,
  required Map<String, dynamic> memorySourceFiles,
  api.CompilerDiagnostics? diagnosticHandler,
  bool expectSuccess = true,
}) async {
  final outputProvider = OutputCollector();

  api.CompilationResult result = await runCompiler(
    entryPoint: entryPoint,
    memorySourceFiles: memorySourceFiles,
    outputProvider: outputProvider,
    diagnosticHandler: diagnosticHandler,
    options: compilerOptions,
    packageConfig: Uri.parse('memory:/.dart_tool/package_config.json'),
  );
  if (expectSuccess) {
    Expect.isTrue(result.isSuccess);
  } else {
    if (result.isSuccess) {
      throw 'Compilation succeeded but was expected to fail.';
    }
    return null;
  }

  return outputProvider.outputMap[api.OutputType.recordedUses]!.values.first
      .toString();
}

const Set<String> dart2jsNotSupported = {};
