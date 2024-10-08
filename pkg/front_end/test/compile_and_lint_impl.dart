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
import 'package:front_end/src/base/command_line_reporting.dart'
    as command_line_reporting;
import 'package:front_end/src/builder/declaration_builders.dart'
    show TypeDeclarationBuilder;
import 'package:front_end/src/builder/type_builder.dart' show TypeBuilder;
import 'package:front_end/src/codes/cfe_codes.dart' as fasta
    show templateUnspecified;
import 'package:front_end/src/kernel/body_builder.dart' show BodyBuilder;
import 'package:front_end/src/kernel/constness.dart' show Constness;
import 'package:front_end/src/kernel/expression_generator_helper.dart'
    show UnresolvedKind;
import 'package:front_end/src/kernel/kernel_target.dart' show BuildResult;
import 'package:front_end/src/util/import_export_etc_helper.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/type_environment.dart';
import 'package:package_config/package_config.dart';

import 'compiler_test_helper.dart' show BodyBuilderTest, compile;

Set<Uri> _ignoredDirectoryUris = {};
Set<Uri> _explicitCreationIgnoredDirectoryUris = {};

Set<Uri> _includedDirectoryUris = {};

/// Run the compile and lint test (e.g. reporting missing 'new' tokens).
///
/// Explicitly compiles [includedFiles], reporting only errors for files in a
/// path in [includedDirectoryUris] and not in [ignoredDirectoryUris].
/// Note that this means that there can be reported errors in files not
/// explicitly included in [includedFiles], although that is not guaranteed.
///
/// Returns the number of errors found.
Future<int> runCompileAndLintTest(
    {required Set<Uri> includedFiles,
    required Set<Uri> includedDirectoryUris,
    required Uri repoDir}) async {
  _includedDirectoryUris.clear();
  _includedDirectoryUris.addAll(includedDirectoryUris);
  _ignoredDirectoryUris.clear();
  _ignoredDirectoryUris
      .add(repoDir.resolve("pkg/frontend_server/test/fixtures/"));

  // Ignore kernel for the explicit creation, but include in ast-walking
  // problem finder.
  _explicitCreationIgnoredDirectoryUris.clear();
  _explicitCreationIgnoredDirectoryUris.add(repoDir.resolve("pkg/kernel/"));

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
      omitPlatform: false,
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

  ProblemFinder problemFinder = new ProblemFinder(partsReplaced);
  Stopwatch visitStopwatch = new Stopwatch()..start();
  result.component?.accept(problemFinder);
  print("Visited result in ${visitStopwatch.elapsed} and "
      "found ${problemFinder.foundErrors} error(s).");

  return errorCount + problemFinder.foundErrors;
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
      if (!f.path.endsWith(".dart")) continue;
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
  late Set<Uri> _ignoredDirs = {
    ..._ignoredDirectoryUris,
    ..._explicitCreationIgnoredDirectoryUris
  };

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
        for (Uri libUri in _ignoredDirs) {
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

class ProblemFinder extends RecursiveVisitor {
  final Set<Uri> wantedUris;
  Reference? stackTraceCurrent;
  Reference? identicalReference;
  Reference? intReference;
  StatefulStaticTypeContext? staticTypeContext;
  Map<Uri, Source>? uriToSource;
  bool inField = false;
  int foundErrors = 0;

  ProblemFinder(this.wantedUris);

  void reportError(TreeNode node, int squigglyLength, String messageText) {
    foundErrors++;
    Location location = node.location!;
    print(command_line_reporting.formatErrorMessage(
        uriToSource?[location.file]?.getTextLine(location.line),
        location,
        squigglyLength,
        location.file.toFilePath(),
        messageText));
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    // For now allow it in asserts.
    return;
  }

  @override
  void visitComponent(Component node) {
    uriToSource = node.uriToSource;
    LibraryIndex platformIndex = new LibraryIndex.coreLibraries(node);
    stackTraceCurrent = platformIndex
        .getProcedure("dart:core", "StackTrace", "get:current")
        .reference;
    identicalReference =
        platformIndex.getTopLevelMember("dart:core", "identical").reference;
    intReference = platformIndex.getClass("dart:core", "int").reference;

    CoreTypes coreTypes = new CoreTypes(node);
    TypeEnvironment types =
        TypeEnvironment(coreTypes, new ClassHierarchy(node, coreTypes));
    staticTypeContext = StatefulStaticTypeContext.stacked(types);
    super.visitComponent(node);
  }

  @override
  void visitField(Field node) {
    staticTypeContext?.enterMember(node);
    inField = true;
    super.visitField(node);
    inField = false;
    staticTypeContext?.leaveMember(node);
  }

  @override
  void visitLibrary(Library node) {
    if (wantedUris.contains(node.importUri) ||
        wantedUris.contains(node.fileUri)) {
      staticTypeContext?.enterLibrary(node);
      super.visitLibrary(node);
      staticTypeContext?.leaveLibrary(node);
    }
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.name.text.startsWith("assert")) {
      // Assume this is only called via asserts.
      return;
    }

    staticTypeContext?.enterMember(node);
    super.visitProcedure(node);
    staticTypeContext?.leaveMember(node);
  }

  @override
  void visitStaticGet(StaticGet node) {
    super.visitStaticGet(node);

    // For now only disallow it in fields.
    if (!inField) return;

    if (node.targetReference == stackTraceCurrent) {
      reportError(node, "current".length, "Usage of StackTrace.current");
    }
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);

    if (node.targetReference == identicalReference &&
        staticTypeContext != null &&
        node.arguments.positional.any(_hasStaticTypeInt)) {
      reportError(node, "identical".length, "Usage of identical on int");
    }
  }

  bool _hasStaticTypeInt(Expression expression) {
    try {
      DartType type = expression.getStaticType(staticTypeContext!);
      if (type is InterfaceType && type.classReference == intReference) {
        return true;
      }
      return false;
    } catch (e) {
      // Let's assume this means no.
      // E.g. this might happen if finding the static type of `this` when not
      // having done all the enter/leave things adequately.
      return false;
    }
  }
}
