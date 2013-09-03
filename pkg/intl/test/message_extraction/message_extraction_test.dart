// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library message_extraction_test;

import 'package:unittest/unittest.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../data_directory.dart';
import 'verify_messages.dart';
import 'sample_with_messages.dart' as sample;

final dart = Platform.executable;

/** The VM arguments we were given, most important package-root. */
final vmArgs = Platform.executableArguments;

/**
 * Translate a file path into this test directory, regardless of the
 * working directory.
 */
String dir([String s]) {
  if (s != null && s.startsWith("--")) { // Don't touch command-line options.
    return s;
  } else {
   return path.join(intlDirectory, 'test', 'message_extraction', s);
  }
}

main() {
  test("Test round trip message extraction, translation, code generation, "
      "and printing", () {
    deleteGeneratedFiles();
    return extractMessages(null).then((result) {
      return generateTranslationFiles(result);
    }).then((result) {
      return generateCodeFromTranslation(result);
    }).then((_) => sample.main())
    .then(verifyResult)
    .whenComplete(deleteGeneratedFiles);
  });
}

void deleteGeneratedFiles() {
  var files = [dir('intl_messages.json'), dir('translation_fr.json'),
      dir('translation_de_DE.json')];
  files.map((name) => new File(name)).forEach((x) {
    if (x.existsSync()) x.deleteSync();});
}

/**
 * Run the process with the given list of filenames, which we assume
 * are in dir() and need to be qualified in case that's not our working
 * directory.
 */
Future<ProcessResult> run(ProcessResult previousResult, List<String> filenames)
{
  // If there's a failure in one of the sub-programs, print its output.
  if (previousResult != null) {
    if (previousResult.exitCode != 0) {
      print("Error running sub-program:");
    }
    print(previousResult.stdout);
    print(previousResult.stderr);
    print("exitCode=${previousResult.exitCode}");
  }
  var filesInTheRightDirectory = filenames.map((x) => dir(x)).toList();
  // Inject the script argument --output-dir in between the script and its
  // arguments.
  var args = []
      ..addAll(vmArgs)
      ..add(filesInTheRightDirectory.first)
      ..addAll(["--output-dir=${dir()}"])
      ..addAll(filesInTheRightDirectory.skip(1));
  var result = Process.run(dart, args, stdoutEncoding: UTF8,
      stderrEncoding: UTF8);
  return result;
}

Future<ProcessResult> extractMessages(ProcessResult previousResult) => run(
    previousResult,
    ['extract_to_json.dart', '--suppress-warnings', 'sample_with_messages.dart',
        'part_of_sample_with_messages.dart']);

Future<ProcessResult> generateTranslationFiles(ProcessResult previousResult) =>
    run(
        previousResult,
        ['make_hardcoded_translation.dart', 'intl_messages.json']);

Future<ProcessResult> generateCodeFromTranslation(ProcessResult previousResult)
    => run(
        previousResult,
        ['generate_from_json.dart', '--generated-file-prefix=foo_',
         'sample_with_messages.dart',
             'part_of_sample_with_messages.dart', 'translation_fr.json',
             'translation_de_DE.json' ]);

