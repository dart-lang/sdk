// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.analyze;

import 'dart:async' show Stream, Future;

import 'dart:convert' show LineSplitter, UTF8;

import 'dart:io'
    show Directory, File, FileSystemEntity, Platform, Process, ProcessResult;

import '../testing.dart' show dartArguments, startDart;

import 'log.dart' show isVerbose, splitLines;

import 'suite.dart' show Suite;

class Analyze extends Suite {
  final Uri analysisOptions;

  final List<Uri> uris;

  final List<RegExp> exclude;

  final List<String> gitGrepPathspecs;

  final List<String> gitGrepPatterns;

  Analyze(this.analysisOptions, this.uris, this.exclude, this.gitGrepPathspecs,
      this.gitGrepPatterns)
      : super("analyze", "analyze", null);

  Future<Null> run(Uri packages, List<Uri> extraUris) {
    List<Uri> allUris = new List<Uri>.from(uris);
    if (extraUris != null) {
      allUris.addAll(extraUris);
    }
    return analyzeUris(analysisOptions, packages, allUris, exclude,
        gitGrepPathspecs, gitGrepPatterns);
  }

  static Future<Analyze> fromJsonMap(
      Uri base, Map json, List<Suite> suites) async {
    String optionsPath = json["options"];
    Uri optionsUri = optionsPath == null ? null : base.resolve(optionsPath);

    List<Uri> uris = new List<Uri>.from(
        json["uris"].map((String relative) => base.resolve(relative)));

    List<RegExp> exclude =
        new List<RegExp>.from(json["exclude"].map((String p) => new RegExp(p)));

    Map gitGrep = json["git grep"];
    List<String> gitGrepPathspecs;
    List<String> gitGrepPatterns;
    if (gitGrep != null) {
      gitGrepPathspecs = gitGrep["pathspecs"] ?? const <String>["."];
      gitGrepPatterns = gitGrep["patterns"];
    }

    return new Analyze(
        optionsUri, uris, exclude, gitGrepPathspecs, gitGrepPatterns);
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
    if (line.startsWith(">>> ")) continue;
    yield new AnalyzerDiagnostic.fromLine(line);
  }
}

/// Run dartanalyzer on all tests in [uris].
Future<Null> analyzeUris(
    Uri analysisOptions,
    Uri packages,
    List<Uri> uris,
    List<RegExp> exclude,
    List<String> gitGrepPathspecs,
    List<String> gitGrepPatterns) async {
  if (uris.isEmpty) return;
  String topLevel;
  try {
    topLevel = new Uri.directory(
            (await git("rev-parse", <String>["--show-toplevel"])).trimRight())
        .toFilePath(windows: false);
  } catch (e) {
    topLevel = Uri.base.toFilePath(windows: false);
  }

  String toFilePath(Uri uri) {
    String path = uri.toFilePath(windows: false);
    return path.startsWith(topLevel) ? path.substring(topLevel.length) : path;
  }

  Set<String> filesToAnalyze = new Set<String>();

  for (Uri uri in uris) {
    if (await new Directory.fromUri(uri).exists()) {
      await for (FileSystemEntity entity in new Directory.fromUri(uri)
          .list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith(".dart")) {
          filesToAnalyze.add(toFilePath(entity.uri));
        }
      }
    } else if (await new File.fromUri(uri).exists()) {
      filesToAnalyze.add(toFilePath(uri));
    } else {
      throw "File not found: ${uri}";
    }
  }

  if (gitGrepPatterns != null) {
    List<String> arguments = <String>["-l"];
    arguments.addAll(
        gitGrepPatterns.expand((String pattern) => <String>["-e", pattern]));
    arguments.add("--");
    arguments.addAll(gitGrepPathspecs);
    filesToAnalyze.addAll(splitLines(await git("grep", arguments))
        .map((String line) => line.trimRight()));
  }

  const String analyzerPath = "pkg/analyzer_cli/bin/analyzer.dart";
  Uri analyzer = Uri.base.resolve(analyzerPath);
  if (!await new File.fromUri(analyzer).exists()) {
    throw "Couldn't find '$analyzerPath' in '${toFilePath(Uri.base)}'";
  }
  List<String> arguments = <String>[
    "--packages=${toFilePath(packages)}",
    "--format=machine",
    "--dart-sdk=${Uri.base.resolve('sdk/').toFilePath()}",
  ];
  if (analysisOptions != null) {
    arguments.add("--options=${toFilePath(analysisOptions)}");
  }

  filesToAnalyze = filesToAnalyze
      .where((String path) => !exclude.any((RegExp r) => path.contains(r)))
      .toSet();
  arguments.addAll(filesToAnalyze);
  if (isVerbose) {
    print("Running:\n  ${toFilePath(analyzer)} ${arguments.join(' ')}");
  } else {
    print("Running dartanalyzer.");
  }
  Stopwatch sw = new Stopwatch()..start();
  Process process = await startDart(
      analyzer,
      const <String>["--batch"],
      dartArguments
        ..remove("-c")
        ..add("-DuseFastaScanner=true"));
  process.stdin.writeln(arguments.join(" "));
  process.stdin.close();

  bool hasOutput = false;
  Set<String> seen = new Set<String>();

  processAnalyzerOutput(Stream<AnalyzerDiagnostic> diagnostics) async {
    await for (AnalyzerDiagnostic diagnostic in diagnostics) {
      if (diagnostic.uri != null) {
        String path = toFilePath(diagnostic.uri);
        if (!(analysisOptions?.path.contains("/pkg/compiler/") ?? false) &&
            diagnostic.code.startsWith("STRONG_MODE") &&
            (path.startsWith("pkg/compiler/") ||
                path.startsWith("tests/compiler/dart2js/"))) {
          // TODO(ahe): Remove this hack to work around dart2js not being
          // strong-mode clean.
          continue;
        }
        if (!filesToAnalyze.contains(path)) continue;
      }
      String message = "$diagnostic";
      if (seen.add(message)) {
        hasOutput = true;
        print(message);
      }
    }
  }

  Future stderrFuture =
      processAnalyzerOutput(parseAnalyzerOutput(process.stderr));
  Future stdoutFuture =
      processAnalyzerOutput(parseAnalyzerOutput(process.stdout));
  await process.exitCode;
  await stdoutFuture;
  await stderrFuture;
  sw.stop();
  print("Running analyzer took: ${sw.elapsed}.");
  if (hasOutput) {
    throw "Non-empty output from analyzer.";
  }
}

Future<String> git(String command, Iterable<String> arguments,
    {String workingDirectory}) async {
  ProcessResult result = await Process.run(
      Platform.isWindows ? "git.bat" : "git",
      <String>[command]..addAll(arguments),
      workingDirectory: workingDirectory);
  if (result.exitCode != 0) {
    throw "Non-zero exit code from git $command (${result.exitCode})\n"
        "${result.stdout}\n${result.stderr}";
  }
  return result.stdout;
}
