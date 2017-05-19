// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.analyze;

import 'dart:async' show Stream, Future;

import 'dart:convert' show LineSplitter, UTF8;

import 'dart:io' show File, Process;

import '../testing.dart' show startDart;

import 'log.dart' show isVerbose;

import 'suite.dart' show Suite;

class Analyze extends Suite {
  final Uri analysisOptions;

  final List<Uri> uris;

  final List<RegExp> exclude;

  Analyze(this.analysisOptions, this.uris, this.exclude)
      : super("analyze", "analyze", null);

  Future<Null> run(Uri packages, List<Uri> extraUris) {
    List<Uri> allUris = new List<Uri>.from(uris);
    if (extraUris != null) {
      allUris.addAll(extraUris);
    }
    return analyzeUris(analysisOptions, packages, allUris, exclude);
  }

  static Future<Analyze> fromJsonMap(
      Uri base, Map json, List<Suite> suites) async {
    String optionsPath = json["options"];
    Uri optionsUri = optionsPath == null ? null : base.resolve(optionsPath);

    List<Uri> uris = new List<Uri>.from(
        json["uris"].map((String relative) => base.resolve(relative)));

    List<RegExp> exclude =
        new List<RegExp>.from(json["exclude"].map((String p) => new RegExp(p)));

    return new Analyze(optionsUri, uris, exclude);
  }

  String toString() => "Analyze($uris, $exclude)";
}

class AnalyzerDiagnostic {
  final String kind;

  final String detailedKind;

  final String code;

  final Uri uri;

  final int line;

  final int startColumn;

  final int endColumn;

  final String message;

  static final Pattern potentialSplitPattern = new RegExp(r"\\|\|");

  static final Pattern unescapePattern = new RegExp(r"\\(.)");

  AnalyzerDiagnostic(this.kind, this.detailedKind, this.code, this.uri,
      this.line, this.startColumn, this.endColumn, this.message);

  AnalyzerDiagnostic.malformed(String line)
      : this(null, null, null, null, -1, -1, -1, line);

  factory AnalyzerDiagnostic.fromLine(String line) {
    List<String> parts = <String>[];
    int start = 0;
    int index = line.indexOf(potentialSplitPattern);
    addPart() {
      parts.add(line
          .substring(start, index == -1 ? null : index)
          .replaceAllMapped(unescapePattern, (Match m) => m[1]));
    }

    while (index != -1) {
      if (line[index] == "\\") {
        index = line.indexOf(potentialSplitPattern, index + 2);
      } else {
        addPart();
        start = index + 1;
        index = line.indexOf(potentialSplitPattern, start);
      }
    }
    addPart();
    if (parts.length != 8) {
      return new AnalyzerDiagnostic.malformed(line);
    }
    return new AnalyzerDiagnostic(
        parts[0],
        parts[1],
        parts[2],
        Uri.base.resolveUri(new Uri.file(parts[3])),
        int.parse(parts[4]),
        int.parse(parts[5]),
        int.parse(parts[6]),
        parts[7]);
  }

  String toString() {
    return kind == null
        ? "Malformed output from dartanalyzer:\n$message"
        : "${uri.toFilePath()}:$line:$startColumn: "
        "${kind == 'INFO' ? 'warning: hint' : kind.toLowerCase()}:\n"
        "[$code] $message";
  }
}

Stream<AnalyzerDiagnostic> parseAnalyzerOutput(
    Stream<List<int>> stream) async* {
  Stream<String> lines =
      stream.transform(UTF8.decoder).transform(new LineSplitter());
  await for (String line in lines) {
    yield new AnalyzerDiagnostic.fromLine(line);
  }
}

/// Run dartanalyzer on all tests in [uris].
Future<Null> analyzeUris(Uri analysisOptions, Uri packages, List<Uri> uris,
    List<RegExp> exclude) async {
  if (uris.isEmpty) return;
  const String analyzerPath = "pkg/analyzer_cli/bin/analyzer.dart";
  Uri analyzer = Uri.base.resolve(analyzerPath);
  if (!await new File.fromUri(analyzer).exists()) {
    throw "Couldn't find '$analyzerPath' in '${Uri.base.toFilePath()}'";
  }
  List<String> arguments = <String>[
    "--packages=${packages.toFilePath()}",
    "--package-warnings",
    "--format=machine",
    "--dart-sdk=${Uri.base.resolve('sdk/').toFilePath()}",
  ];
  if (analysisOptions != null) {
    arguments.add("--options=${analysisOptions.toFilePath()}");
  }
  arguments.addAll(uris.map((Uri uri) => uri.toFilePath()));
  if (isVerbose) {
    print("Running:\n  ${analyzer.toFilePath()} ${arguments.join(' ')}");
  } else {
    print("Running dartanalyzer.");
  }
  Stopwatch sw = new Stopwatch()..start();
  Process process = await startDart(analyzer, arguments);
  process.stdin.close();
  Future stdoutFuture = parseAnalyzerOutput(process.stdout).toList();
  Future stderrFuture = parseAnalyzerOutput(process.stderr).toList();
  await process.exitCode;
  List<AnalyzerDiagnostic> diagnostics = <AnalyzerDiagnostic>[];
  diagnostics.addAll(await stdoutFuture);
  diagnostics.addAll(await stderrFuture);
  bool hasOutput = false;
  Set<String> seen = new Set<String>();
  for (AnalyzerDiagnostic diagnostic in diagnostics) {
    String path = diagnostic.uri?.path;
    if (path != null && exclude.any((RegExp r) => path.contains(r))) {
      continue;
    }
    String message = "$diagnostic";
    if (seen.add(message)) {
      hasOutput = true;
      print(message);
    }
  }
  if (hasOutput) {
    throw "Non-empty output from analyzer.";
  }
  sw.stop();
  print("Running analyzer took: ${sw.elapsed}.");
}
