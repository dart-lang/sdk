// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/severity.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart' as api;
import 'package:front_end/src/fasta/builder/declaration_builders.dart';
import 'package:front_end/src/fasta/builder/type_builder.dart';
import 'package:front_end/src/fasta/fasta_codes.dart' as fasta;
import 'package:front_end/src/fasta/kernel/body_builder.dart';
import 'package:front_end/src/fasta/kernel/constness.dart';
import 'package:front_end/src/fasta/kernel/expression_generator_helper.dart';
import 'package:kernel/kernel.dart';

import 'compiler_test_helper.dart';
import 'testing_utils.dart' show getGitFiles;
import "utils/io_utils.dart";

final Uri repoDir = computeRepoDirUri();

Set<Uri> libUris = {};

int errorCount = 0;

Future<void> main(List<String> args) async {
  List<Uri> inputs = [];
  if (args.isEmpty) {
    libUris.add(repoDir.resolve("pkg/front_end/lib/"));
    libUris.add(repoDir.resolve("pkg/_fe_analyzer_shared/lib/"));
  } else {
    if (args[0] == "--front-end-only") {
      libUris.add(repoDir.resolve("pkg/front_end/lib/"));
    } else if (args[0] == "--shared-only") {
      libUris.add(repoDir.resolve("pkg/_fe_analyzer_shared/lib/"));
    } else {
      throw "Unsupported arguments: $args";
    }
  }
  for (Uri uri in libUris) {
    Set<Uri> gitFiles = await getGitFiles(uri);
    List<FileSystemEntity> entities =
        new Directory.fromUri(uri).listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      if (entity is File &&
          entity.path.endsWith(".dart") &&
          gitFiles.contains(entity.uri)) {
        inputs.add(entity.uri);
      }
    }
  }

  Uri packageConfigUri = repoDir.resolve(".dart_tool/package_config.json");
  if (!new File.fromUri(packageConfigUri).existsSync()) {
    throw "Couldn't find .dart_tool/package_config.json";
  }

  Stopwatch stopwatch = new Stopwatch()..start();

  await compile(
      inputs: inputs,
      // Compile sdk because when this is run from a lint it uses the checked-in
      // sdk and we might not have a suitable compiled platform.dill file.
      compileSdk: true,
      packagesFileUri: packageConfigUri,
      onDiagnostic: (api.DiagnosticMessage message) {
        if (message.severity == Severity.error) {
          print(message.plainTextFormatted.join('\n'));
          errorCount++;
          exitCode = 1;
        }
      },
      repoDir: repoDir,
      bodyBuilderCreator: (
        create: BodyBuilderTester.new,
        createForField: BodyBuilderTester.forField,
        createForOutlineExpression: BodyBuilderTester.forOutlineExpression
      ));

  print("Done in ${stopwatch.elapsedMilliseconds} ms. "
      "Found $errorCount errors.");
}

class BodyBuilderTester = BodyBuilderTest with BodyBuilderTestMixin;

mixin BodyBuilderTestMixin on BodyBuilder {
  @override
  Expression buildConstructorInvocation(
      TypeDeclarationBuilder? type,
      Token nameToken,
      Token nameLastToken,
      Arguments? arguments,
      String name,
      List<TypeBuilder>? typeArguments,
      int charOffset,
      Constness constness,
      {bool isTypeArgumentsInForest = false,
      TypeDeclarationBuilder? typeAliasBuilder,
      required UnresolvedKind unresolvedKind}) {
    Token maybeNewOrConst = nameToken.previous!;
    bool doReport = true;
    if (maybeNewOrConst is KeywordToken) {
      if (maybeNewOrConst.lexeme == "new" ||
          maybeNewOrConst.lexeme == "const") {
        doReport = false;
      }
    } else if (maybeNewOrConst is SimpleToken) {
      if (maybeNewOrConst.lexeme == "@") {
        doReport = false;
      }
    }
    if (doReport) {
      bool match = false;
      for (Uri libUri in libUris) {
        if (uri.toString().startsWith(libUri.toString())) {
          match = true;
          break;
        }
      }
      if (!match) {
        doReport = false;
      }
    }
    if (doReport) {
      addProblem(
          fasta.templateUnspecified.withArguments("Should use new or const"),
          nameToken.charOffset,
          nameToken.length);
    }
    return super.buildConstructorInvocation(type, nameToken, nameLastToken,
        arguments, name, typeArguments, charOffset, constness,
        isTypeArgumentsInForest: isTypeArgumentsInForest,
        unresolvedKind: unresolvedKind);
  }
}
