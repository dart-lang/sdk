// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show File, Directory;

import 'package:compiler/compiler_api.dart' as api show OutputType;
import 'package:compiler/compiler_api.dart';
import 'package:compiler/src/commandline_options.dart' show Flags;
import 'package:compiler/src/util/memory_compiler.dart';
import 'package:expect/expect.dart' show Expect;
import 'package:path/path.dart' as path;
import 'package:record_use/record_use_internal.dart';
import 'package:test/test.dart';

/// Options to pass to the compiler such as
/// `Flags.disableTypeInference` or `Flags.disableInlining`
const List<String> compilerOptions = [Flags.writeRecordedUses, Flags.testMode];

/// Run `dart --define=updateExpectations=true pkg/compiler/test/record_use/record_use_test.dart`
/// to update.
Future<void> main() async {
  final vmTestCases = Directory('pkg/vm/testcases/transformations/record_use');
  final testFiles = vmTestCases
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map(
        (file) => TestFile(
          file: file,
          basename: path.basename(file.path),
          contents: file.readAsStringSync(),
          uri: _createUri(path.basename(file.path)),
        ),
      );

  final allFiles = {for (final file in testFiles) file.uri.path: file.contents};
  for (final testFile in testFiles.where((element) => element.hasMain)) {
    test(
      '${testFile.file.path}',
      skip: dart2jsNotSupported.contains(testFile.basename),
      () async {
        final recordedUsages = await compileWithUsages(
          entryPoint: testFile.uri,
          memorySourceFiles: allFiles,
        );
        final goldenFile = File(testFile.file.path + '.json.expect');
        const update = bool.fromEnvironment('updateExpectations');
        if (!goldenFile.existsSync() || update) {
          await goldenFile.create();
          await goldenFile.writeAsString(recordedUsages);
        } else {
          final actual = Recordings.fromJson(jsonDecode(recordedUsages));
          final goldenContents = await goldenFile.readAsString();
          final golden = Recordings.fromJson(jsonDecode(goldenContents));
          final semanticEquals = actual.semanticEquals(
            golden,
            allowMetadataMismatch: true,
            allowMoreConstArguments: true,
            // Ensure test coverage of tear offs, add pragmas to prevent
            // optimiations if necessary.
            allowTearOffToStaticPromotion: false,
            uriMapping: (String uri) =>
                uri.replaceFirst('memory:sdk/tests/web/native/', ''),
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
}

class TestFile {
  final File file;
  final String basename;
  final String contents;
  final Uri uri;

  const TestFile({
    required this.file,
    required this.basename,
    required this.contents,
    required this.uri,
  });

  bool get hasMain => contents.contains('main()');
}

typedef CompiledOutput = Map<api.OutputType, Map<String, String>>;

Future<String> compileWithUsages({
  Uri? entryPoint,
  required Map<String, dynamic> memorySourceFiles,
}) async {
  final outputProvider = OutputCollector();

  CompilationResult result = await runCompiler(
    entryPoint: entryPoint,
    memorySourceFiles: memorySourceFiles,
    outputProvider: outputProvider,
    options: [Flags.writeRecordedUses],
  );
  Expect.isTrue(result.isSuccess);

  return outputProvider.outputMap[OutputType.recordedUses]!.values.first
      .toString();
}

// Pretend this is a dart2js_native test to allow use of 'native' keyword
// and import of private libraries.
Uri _createUri(String fileName) {
  return Uri.parse('memory:sdk/tests/web/native/$fileName');
}

const dart2jsNotSupported = {
  // No support for instance constants.
  // https://github.com/dart-lang/native/issues/2893
  'instance_class.dart',
  'instance_complex.dart',
  'instance_duplicates.dart',
  'instance_method.dart',
  'instance_not_annotation.dart',
  'nested.dart',
  'record_enum.dart',
  'record_instance_constant_empty.dart',
  // Named arguments are converted to positional arguments.
  // https://github.com/dart-lang/native/issues/2883
  'named_and_positional.dart',
  'named_both.dart',
  'named_optional.dart',
  'named_required.dart',
};
