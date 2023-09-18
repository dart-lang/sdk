// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io" show File, exitCode;

import "../tool/_fasta/generate_messages.dart" as generateMessages;
import "../tool/_fasta/generate_experimental_flags.dart"
    as generateExperimentalFlags;
import "../tool/_fasta/parser_ast_helper_creator.dart"
    as generateParserAstHelper;
import "parser_test_listener_creator.dart" as generateParserTestListener;
import "parser_test_parser_creator.dart" as generateParserTestParser;
import '../tool/ast_model.dart';
import '../tool/generate_ast_equivalence.dart' as generateAstEquivalence;
import '../tool/generate_ast_coverage.dart' as generateAstCoverage;
import 'utils/io_utils.dart' show computeRepoDirUri;

final Uri repoDir = computeRepoDirUri();

Future<void> main() async {
  messages();
  experimentalFlags();
  directParserAstHelper();
  parserTestListener();
  parserTestParser();
  AstModel astModel = await deriveAstModel(repoDir);
  await astEquivalence(astModel);
  await astCoverage(astModel);
}

void parserTestParser() {
  Uri generatedFile = generateParserTestParser.computeTestParserUri(repoDir);
  String generated = generateParserTestParser.generateTestParser(repoDir);
  check(generated, generatedFile,
      "dart pkg/front_end/test/parser_test_parser_creator.dart");
}

void parserTestListener() {
  Uri generatedFile =
      generateParserTestListener.computeTestListenerUri(repoDir);
  String generated = generateParserTestListener.generateTestListener(repoDir);
  check(generated, generatedFile,
      "dart pkg/front_end/test/parser_test_listener_creator.dart");
}

void directParserAstHelper() {
  Uri generatedFile = generateParserAstHelper.computeAstHelperUri(repoDir);
  String generated = generateParserAstHelper.generateAstHelper(repoDir);
  check(generated, generatedFile,
      "dart pkg/front_end/tool/_fasta/parser_ast_helper_creator.dart");
}

Future<void> astEquivalence(AstModel astModel) async {
  Uri generatedFile = generateAstEquivalence.computeEquivalenceUri(repoDir);
  String generated =
      await generateAstEquivalence.generateAstEquivalence(repoDir, astModel);
  check(generated, generatedFile,
      "dart pkg/front_end/tool/generate_ast_equivalence.dart");
}

Future<void> astCoverage(AstModel astModel) async {
  Uri generatedFile = generateAstCoverage.computeCoverageUri(repoDir);
  String generated =
      await generateAstCoverage.generateAstCoverage(repoDir, astModel);
  check(generated, generatedFile,
      "dart pkg/front_end/tool/generate_ast_coverage.dart");
}

void experimentalFlags() {
  {
    Uri generatedFile =
        generateExperimentalFlags.computeFeAnalyzerSharedGeneratedFile(repoDir);
    String generated =
        generateExperimentalFlags.generateFeAnalyzerSharedFile(repoDir);
    check(generated, generatedFile,
        "dart pkg/front_end/tool/fasta.dart generate-experimental-flags");
  }
  {
    Uri generatedFile =
        generateExperimentalFlags.computeCfeGeneratedFile(repoDir);
    String generated = generateExperimentalFlags.generateCfeFile(repoDir);
    check(generated, generatedFile,
        "dart pkg/front_end/tool/fasta.dart generate-experimental-flags");
  }
  {
    Uri generatedFile =
        generateExperimentalFlags.computeKernelGeneratedFile(repoDir);
    String generated = generateExperimentalFlags.generateKernelFile(repoDir);
    check(generated, generatedFile,
        "dart pkg/front_end/tool/fasta.dart generate-experimental-flags");
  }
}

void messages() {
  generateMessages.Messages messages =
      generateMessages.generateMessagesFiles(repoDir);

  Uri generatedFile = generateMessages.computeSharedGeneratedFile(repoDir);
  check(messages.sharedMessages, generatedFile,
      "dart pkg/front_end/tool/fasta.dart generate-messages");

  Uri cfeGeneratedFile = generateMessages.computeCfeGeneratedFile(repoDir);
  check(messages.cfeMessages, cfeGeneratedFile,
      "dart pkg/front_end/tool/fasta.dart generate-messages");
}

void check(String generated, Uri generatedFile, String run) {
  String actual = new File.fromUri(generatedFile)
      .readAsStringSync()
      .replaceAll('\r\n', '\n');
  if (generated != actual) {
    print("""
------------------------

The generated file
  ${generatedFile.path}

is out of date. To regenerate the file, run
  $run

------------------------
""");
    exitCode = 1;
  }
}
