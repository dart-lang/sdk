// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, FileSystemEntity;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind, MemberKind, Parser;

import 'package:_fe_analyzer_shared/src/parser/listener.dart' show Listener;

import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show ScannerConfiguration;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:front_end/src/fasta/command_line_reporting.dart'
    as command_line_reporting;
import 'package:front_end/src/fasta/source/diet_parser.dart'
    show useImplicitCreationExpressionInCfe;

import 'package:kernel/kernel.dart';

import 'package:package_config/package_config.dart';

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import 'testing_utils.dart' show checkEnvironment, getGitFiles;

void main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  const Set<String> knownEnvironmentKeys = {"onlyInGit"};
  checkEnvironment(environment, knownEnvironmentKeys);

  bool onlyInGit = environment["onlyInGit"] != "false";
  return new Context(onlyInGit: onlyInGit);
}

class LintTestDescription extends TestDescription {
  @override
  final String shortName;
  @override
  final Uri uri;
  final LintTestCache cache;
  final LintListener listener;

  LintTestDescription(this.shortName, this.uri, this.cache, this.listener) {
    this.listener.description = this;
    this.listener.uri = uri;
  }

  String getErrorMessage(int offset, int squigglyLength, String message) {
    cache.source ??= new Source(cache.lineStarts, cache.rawBytes!, uri, uri);
    Location location = cache.source!.getLocation(uri, offset);
    return command_line_reporting.formatErrorMessage(
        cache.source!.getTextLine(location.line),
        location,
        squigglyLength,
        uri.toString(),
        message);
  }
}

class LintTestCache {
  List<int>? rawBytes;
  late List<int> lineStarts;
  Source? source;
  Token? firstToken;
  PackageConfig? packages;
}

class Context extends ChainContext {
  final bool onlyInGit;
  Context({required this.onlyInGit});

  @override
  final List<Step> steps = const <Step>[
    const LintStep(),
  ];

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }

  @override
  Stream<LintTestDescription> list(Chain suite) async* {
    late Set<Uri> gitFiles;
    if (onlyInGit) {
      gitFiles = await getGitFiles(suite.uri);
    }

    Directory testRoot = new Directory.fromUri(suite.uri);
    if (await testRoot.exists()) {
      Stream<FileSystemEntity> files =
          testRoot.list(recursive: true, followLinks: false);
      await for (FileSystemEntity entity in files) {
        if (entity is! File) continue;
        String path = entity.uri.path;
        if (suite.exclude.any((RegExp r) => path.contains(r))) continue;
        if (suite.pattern.any((RegExp r) => path.contains(r))) {
          if (onlyInGit && !gitFiles.contains(entity.uri)) continue;
          Uri root = suite.uri;
          String baseName = "${entity.uri}".substring("$root".length);
          baseName = baseName.substring(0, baseName.length - ".dart".length);
          LintTestCache cache = new LintTestCache();

          yield new LintTestDescription(
            "$baseName/ExplicitType",
            entity.uri,
            cache,
            new ExplicitTypeLintListener(),
          );

          yield new LintTestDescription(
            "$baseName/ImportsTwice",
            entity.uri,
            cache,
            new ImportsTwiceLintListener(),
          );

          Uri apiUnstableUri =
              Uri.base.resolve("pkg/front_end/lib/src/api_unstable/");
          if (!entity.uri.toString().startsWith(apiUnstableUri.toString())) {
            yield new LintTestDescription(
              "$baseName/Exports",
              entity.uri,
              cache,
              new ExportsLintListener(),
            );
          }
        }
      }
    } else {
      throw "${suite.uri} isn't a directory";
    }
  }
}

class LintStep extends Step<LintTestDescription, LintTestDescription, Context> {
  const LintStep();

  @override
  String get name => "lint";

  @override
  Future<Result<LintTestDescription>> run(
      LintTestDescription description, Context context) async {
    if (description.cache.rawBytes == null) {
      File f = new File.fromUri(description.uri);
      description.cache.rawBytes = f.readAsBytesSync();

      Uint8List bytes = new Uint8List(description.cache.rawBytes!.length + 1);
      bytes.setRange(
          0, description.cache.rawBytes!.length, description.cache.rawBytes!);

      Utf8BytesScanner scanner = new Utf8BytesScanner(bytes,
          configuration: ScannerConfiguration.nonNullable,
          includeComments: true);
      description.cache.firstToken = scanner.tokenize();
      description.cache.lineStarts = scanner.lineStarts;

      Uri packageConfig =
          description.uri.resolve(".dart_tool/package_config.json");
      while (true) {
        if (new File.fromUri(packageConfig).existsSync()) {
          break;
        }
        // Stupid bailout.
        if (packageConfig.pathSegments.length < Uri.base.pathSegments.length) {
          break;
        }
        packageConfig =
            packageConfig.resolve("../../.dart_tool/package_config.json");
      }

      File packageConfigUri = new File.fromUri(packageConfig);
      if (packageConfigUri.existsSync()) {
        description.cache.packages = await loadPackageConfigUri(packageConfig);
      }
    }

    if (description.cache.firstToken == null) {
      return crash(description, StackTrace.current);
    }

    Parser parser = new Parser(description.listener,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
    parser.parseUnit(description.cache.firstToken!);

    if (description.listener.problems.isEmpty) {
      return pass(description);
    }
    return fail(description, description.listener.problems.join("\n\n"));
  }
}

class LintListener extends Listener {
  List<String> problems = <String>[];
  late final LintTestDescription description;
  @override
  late final Uri uri;

  void onProblem(int offset, int squigglyLength, String message) {
    problems.add(description.getErrorMessage(offset, squigglyLength, message));
  }
}

class ExplicitTypeLintListener extends LintListener {
  List<LatestType> _latestTypes = <LatestType>[];

  @override
  void beginVariablesDeclaration(
      Token token, Token? lateToken, Token? varFinalOrConst) {
    if (!_latestTypes.last.type) {
      onProblem(
          varFinalOrConst!.offset, varFinalOrConst.length, "No explicit type.");
    }
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    _latestTypes.add(new LatestType(beginToken, true));
  }

  @override
  void handleNoType(Token lastConsumed) {
    _latestTypes.add(new LatestType(lastConsumed, false));
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    _latestTypes.add(new LatestType(functionToken, true));
  }

  @override
  void endTopLevelFields(
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    if (!_latestTypes.last.type) {
      onProblem(beginToken.offset, beginToken.length, "No explicit type.");
    }
    _latestTypes.removeLast();
  }

  @override
  void endClassFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    if (!_latestTypes.last.type) {
      onProblem(
          varFinalOrConst!.offset, varFinalOrConst.length, "No explicit type.");
    }
    _latestTypes.removeLast();
  }

  @override
  void endFormalParameter(
      Token? thisKeyword,
      Token? superKeyword,
      Token? periodAfterThisOrSuper,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    _latestTypes.removeLast();
  }
}

class LatestType {
  final Token token;
  bool type;

  LatestType(this.token, this.type);
}

class ImportsTwiceLintListener extends LintListener {
  Map<Uri, Set<String?>> seenImports = {};

  Token? seenAsKeyword;

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    seenAsKeyword = asKeyword;
  }

  @override
  void endImport(Token importKeyword, Token? augmentToken, Token? semicolon) {
    Token importUriToken = importKeyword.next!;
    String importUri = importUriToken.lexeme;
    if (importUri.startsWith("r")) {
      importUri = importUri.substring(2, importUri.length - 1);
    } else {
      importUri = importUri.substring(1, importUri.length - 1);
    }
    Uri resolved = uri.resolve(importUri);
    if (resolved.isScheme("package")) {
      if (description.cache.packages != null) {
        resolved = description.cache.packages!.resolve(resolved)!;
      }
    }
    String? asName = seenAsKeyword?.lexeme;
    Set<String?> asNames = seenImports[resolved] ??= {};
    if (!asNames.add(asName)) {
      if (asName != null) {
        onProblem(importUriToken.offset, importUriToken.lexeme.length,
            "Uri '$resolved' already imported once as '${asName}'.");
      } else {
        onProblem(importUriToken.offset, importUriToken.lexeme.length,
            "Uri '$resolved' already imported once.");
      }
    }
  }
}

class ExportsLintListener extends LintListener {
  @override
  void endExport(Token exportKeyword, Token semicolon) {
    Token exportUriToken = exportKeyword.next!;
    String exportUri = exportUriToken.lexeme;
    if (exportUri.startsWith("r")) {
      exportUri = exportUri.substring(2, exportUri.length - 1);
    } else {
      exportUri = exportUri.substring(1, exportUri.length - 1);
    }
    Uri resolved = uri.resolve(exportUri);
    if (resolved.isScheme("package")) {
      if (description.cache.packages != null) {
        resolved = description.cache.packages!.resolve(resolved)!;
      }
    }
    onProblem(exportUriToken.offset, exportUriToken.lexeme.length,
        "Exports disallowed internally.");
  }
}
