// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, FileSystemEntity;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_fe_analyzer_shared/src/scanner/io.dart'
    show readBytesFromFileSync;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show KeywordToken, SimpleToken, Token;
import 'package:front_end/src/api_prototype/compiler_options.dart' as api
    show DiagnosticMessage;
import 'package:front_end/src/fasta/builder/declaration_builders.dart'
    show TypeDeclarationBuilder;
import 'package:front_end/src/fasta/builder/type_builder.dart' show TypeBuilder;
import 'package:front_end/src/codes/cfe_codes.dart' as fasta
    show templateUnspecified;
import 'package:front_end/src/fasta/kernel/body_builder.dart' show BodyBuilder;
import 'package:front_end/src/fasta/kernel/constness.dart' show Constness;
import 'package:front_end/src/fasta/kernel/expression_generator_helper.dart'
    show UnresolvedKind;
import 'package:front_end/src/fasta/kernel/kernel_target.dart' show BuildResult;
import 'package:front_end/src/fasta/util/import_export_etc_helper.dart';
import 'package:kernel/kernel.dart' show Arguments, Expression;
import 'package:package_config/package_config.dart';

import 'compiler_test_helper.dart' show BodyBuilderTest, compile;

Set<Uri> _ignoredDirectoryUris = {};

Set<Uri> _includedDirectoryUris = {};

/// Run the explicit creation test (i.e. reporting missing 'new' tokens).
///
/// Explicitly compiles [includedFiles], reporting only errors for files in a
/// path in [includedDirectoryUris] and not in [ignoredDirectoryUris].
/// Note that this means that there can be reported errors in files not
/// explicitly included in [includedFiles], although that is not guaranteed.
///
/// Returns the number of errors found.
Future<int> runExplicitCreationTest(
    {required Set<Uri> includedFiles,
    required Set<Uri> includedDirectoryUris,
    required Uri repoDir}) async {
  _includedDirectoryUris.clear();
  _includedDirectoryUris.addAll(includedDirectoryUris);
  _ignoredDirectoryUris.clear();
  _ignoredDirectoryUris
      .add(repoDir.resolve("pkg/frontend_server/test/fixtures/"));
  int errorCount = 0;

  Uri packageConfigUri = repoDir.resolve(".dart_tool/package_config.json");
  if (!new File.fromUri(packageConfigUri).existsSync()) {
    throw "Couldn't find .dart_tool/package_config.json";
  }

  Set<Uri> includedFilesFiltered = {};
  for (Uri uri in includedFiles) {
    bool include = true;
    for (Uri ignoredDir in _ignoredDirectoryUris) {
      if (uri.toString().startsWith(ignoredDir.toString())) {
        include = false;
        break;
      }
    }
    if (include) {
      includedFilesFiltered.add(uri);
    }
  }

  Stopwatch stopwatch = new Stopwatch()..start();

  // TODO(jensj): The target has to be VM or we can't compile the sdk,
  // but probably we don't actually need to run any vm-specific transformations
  // for instance.

  Set<Uri> partsReplaced =
      _replaceParts(packageConfigUri, includedFilesFiltered);
  if (!identical(partsReplaced, includedFilesFiltered)) {
    print("Replaced part of uris in ${stopwatch.elapsedMilliseconds} ms");
  }

  BuildResult result = await compile(
      inputs: partsReplaced.toList(),
      // Compile sdk because when this is run from a lint it uses the checked-in
      // sdk and we might not have a suitable compiled platform.dill file.
      compileSdk: true,
      packagesFileUri: packageConfigUri,
      onDiagnostic: (api.DiagnosticMessage message) {
        if (message.severity == Severity.error) {
          print(message.plainTextFormatted.join('\n'));
          errorCount++;
        }
      },
      repoDir: repoDir,
      bodyBuilderCreator: (
        create: BodyBuilderTester.new,
        createForField: BodyBuilderTester.forField,
        createForOutlineExpression: BodyBuilderTester.forOutlineExpression
      ),
      splitCompileAndCompileLess: true);

  print("Done in ${stopwatch.elapsedMilliseconds} ms. "
      "Found $errorCount errors.");

  print("Compiled ${result.component?.libraries.length} libraries.");

  return errorCount;
}

/// Try to replace any uri that's a "part of identifier;" with the uri of the
/// file with that library name. If one cannot be found it's removed.
/// Does nothing to "part of <uri>;" as the compiler should find out by itself.
Set<Uri> _replaceParts(Uri packageConfigUri, Set<Uri> files) {
  Map<Uri, FileInfoHelper> helpers = {};
  Map<String, Uri> knownLibraryNames = {};
  FileInfoHelper indexUriHelper(Uri uri) {
    FileInfoHelper fileInfo =
        helpers[uri] = getFileInfoHelper(readBytesFromFileSync(uri));
    if (fileInfo.libraryNames.isNotEmpty) {
      for (String name in fileInfo.libraryNames) {
        knownLibraryNames[name] = uri;
      }
    }
    return fileInfo;
  }

  Set<Uri> partOfLibraryNameUris = {};
  for (Uri uri in files) {
    FileInfoHelper fileInfo = indexUriHelper(uri);
    if (fileInfo.partOfIdentifiers.isNotEmpty) {
      partOfLibraryNameUris.add(uri);
    }
  }

  // If none of the input files are parts using identifiers do nothing.
  if (partOfLibraryNameUris.isEmpty) return files;

  // At least one of the inputs is a part of another library identified by
  // name.
  PackageConfig packageConfig = PackageConfig.parseBytes(
      new File.fromUri(packageConfigUri).readAsBytesSync(), packageConfigUri);

  Map<Package, Set<String>> packageToNeededLibraryNames = {};
  for (Uri uri in partOfLibraryNameUris) {
    Package? package = packageConfig.packageOf(uri);
    if (package != null) {
      Set<String> neededLibraryNames =
          packageToNeededLibraryNames[package] ??= {};
      for (String neededName in helpers[uri]!.partOfIdentifiers) {
        if (!knownLibraryNames.containsKey(neededName)) {
          neededLibraryNames.add(neededName);
        }
      }
    }
  }

  for (MapEntry<Package, Set<String>> packageEntry
      in packageToNeededLibraryNames.entries) {
    if (packageEntry.value.isEmpty) continue;
    Set<String> neededNames = packageEntry.value;
    for (FileSystemEntity f
        in Directory.fromUri(packageEntry.key.packageUriRoot)
            .listSync(recursive: true)) {
      if (f is! File) continue;
      if (helpers[f.uri] == null) {
        FileInfoHelper fileInfo = indexUriHelper(f.uri);
        for (String name in fileInfo.libraryNames) {
          neededNames.remove(name);
        }
        if (neededNames.isEmpty) break;
      }
    }
  }

  Set<Uri> result = {};
  for (Uri uri in files) {
    FileInfoHelper fileInfo = helpers[uri]!;
    if (fileInfo.partOfIdentifiers.isNotEmpty) {
      bool replaced = false;
      for (String identifier in fileInfo.partOfIdentifiers) {
        Uri? uriOf = knownLibraryNames[identifier];
        if (uriOf != null) {
          result.add(uriOf);
          replaced = true;
        }
      }
      if (!replaced) print("Warning: Couldn't find part-of for $uri");
    } else {
      result.add(uri);
    }
  }
  return result;
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
      for (Uri libUri in _includedDirectoryUris) {
        if (uri.toString().startsWith(libUri.toString())) {
          match = true;
          break;
        }
      }
      if (match) {
        for (Uri libUri in _ignoredDirectoryUris) {
          if (uri.toString().startsWith(libUri.toString())) {
            match = false;
            break;
          }
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
