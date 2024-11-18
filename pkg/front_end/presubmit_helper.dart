// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Warning: This file has to start up fast so we can't import lots of stuff.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'test/utils/io_utils.dart';

Future<void> main(List<String> args) async {
  Directory.current = Directory.fromUri(_repoDir);
  Stopwatch stopwatch = new Stopwatch()..start();
  // Expect something like /full/path/to/sdk/pkg/some_dir/whatever/else
  if (args.length != 1) throw "Need exactly one argument.";

  final List<String> changedFiles = getChangedFiles(collectUncommitted: false);
  String callerPath = args[0].replaceAll("\\", "/");
  if (!_shouldRun(changedFiles, callerPath)) {
    return;
  }

  List<Work> workItems = [];

  // This run is now the only run that will actually run any smoke tests.
  // First collect all relevant smoke tests.
  // Note that this is *not* perfect, e.g. it might think there's no reason for
  // a test because the tested hasn't changed even though the actual test has.
  // E.g. if you only update the spelling dictionary no spell test will be run
  // because the files being spell-tested hasn't changed.
  workItems.addIfNotNull(_createCompileAndLintTestWork(changedFiles));
  workItems.addIfNotNull(_createMessagesTestWork(changedFiles));
  workItems.addIfNotNull(_createSpellingTestNotSourceWork(changedFiles));
  workItems.addIfNotNull(_createSpellingTestSourceWork(changedFiles));
  workItems.addIfNotNull(_createLintWork(changedFiles));
  workItems.addIfNotNull(_createDepsTestWork(changedFiles));
  bool shouldRunGenerateFilesTest = _shouldRunGenerateFilesTest(changedFiles);

  // Then run them if we have any.
  if (workItems.isEmpty && !shouldRunGenerateFilesTest) {
    print("Nothing to do.");
    return;
  }

  List<Future> futures = [];
  if (shouldRunGenerateFilesTest) {
    print("Running generated_files_up_to_date_git_test in different process.");
    futures.add(_run(
        "pkg/front_end/test/generated_files_up_to_date_git_test.dart",
        const []));
  }

  if (workItems.isNotEmpty) {
    print("Will now run ${workItems.length} tests.");
    futures.add(_executePendingWorkItems(workItems));
  }

  await Future.wait(futures);
  print("All done in ${stopwatch.elapsed}");
}

/// Map from a dir name in "pkg" to the inner-dir we want to include in the
/// compile and lint test.
const Map<String, String> _compileAndLintDirs = {
  "frontend_server": "",
  "front_end": "lib/",
  "kernel": "lib/",
  "_fe_analyzer_shared": "lib/",
};

/// This is currently a representative list of the dependencies, but do update
/// if it turns out to be needed.
const Set<String> _generatedFilesUpToDateFiles = {
  "pkg/_fe_analyzer_shared/lib/src/experiments/flags.dart",
  "pkg/_fe_analyzer_shared/lib/src/messages/codes_generated.dart",
  "pkg/_fe_analyzer_shared/lib/src/parser/listener.dart",
  "pkg/_fe_analyzer_shared/lib/src/parser/parser_impl.dart",
  "pkg/front_end/lib/src/api_prototype/experimental_flags_generated.dart",
  "pkg/front_end/lib/src/codes/cfe_codes_generated.dart",
  "pkg/front_end/lib/src/util/parser_ast_helper.dart",
  "pkg/front_end/messages.yaml",
  "pkg/front_end/test/generated_files_up_to_date_git_test.dart",
  "pkg/front_end/test/parser_test_listener_creator.dart",
  "pkg/front_end/test/parser_test_listener.dart",
  "pkg/front_end/test/parser_test_parser_creator.dart",
  "pkg/front_end/test/parser_test_parser.dart",
  "pkg/front_end/tool/generate_messages.dart",
  "pkg/front_end/tool/parser_ast_helper_creator.dart",
  "pkg/front_end/tool/generate_ast_coverage.dart",
  "pkg/front_end/tool/generate_ast_equivalence.dart",
  "pkg/front_end/tool/visitor_generator.dart",
  "pkg/kernel/lib/ast.dart",
  "pkg/kernel/lib/default_language_version.dart",
  "pkg/kernel/lib/src/ast/patterns.dart",
  "pkg/kernel/lib/src/coverage.dart",
  "pkg/kernel/lib/src/equivalence.dart",
  "sdk/lib/libraries.json",
  "tools/experimental_features.yaml",
};

/// Map from a dir name in "pkg" to the inner-dir we want to include in the
/// lint test.
const Map<String, String> _lintDirs = {
  "frontend_server": "",
  "front_end": "lib/",
  "kernel": "lib/",
  "_fe_analyzer_shared": "lib/",
};

/// Map from a dir name in "pkg" to the inner-dirs we want to include in the
/// spelling (source) test.
const Map<String, List<String>> _spellDirs = {
  "frontend_server": ["lib/", "bin/"],
  "kernel": ["lib/", "bin/"],
  "front_end": ["lib/"],
  "_fe_analyzer_shared": ["lib/"],
};

/// Set of dirs in "pkg" we care about.
const Set<String> _usDirs = {
  "kernel",
  "frontend_server",
  "front_end",
  "_fe_analyzer_shared",
};

final Uri _repoDir = computeRepoDirUri();

String get _dartVm => Platform.executable;

DepsTestWork? _createDepsTestWork(List<String> changedFiles) {
  bool foundFiles = false;
  for (String path in changedFiles) {
    if (!path.endsWith(".dart")) continue;
    if (path.startsWith("pkg/front_end/lib/")) {
      foundFiles = true;
      break;
    }
  }

  if (!foundFiles) return null;

  return new DepsTestWork();
}

CompileAndLintWork? _createCompileAndLintTestWork(List<String> changedFiles) {
  Set<Uri> includedDirs = {};
  for (MapEntry<String, String> entry in _compileAndLintDirs.entries) {
    includedDirs.add(_repoDir.resolve("pkg/${entry.key}/${entry.value}"));
  }

  Set<Uri> files = {};
  for (String path in changedFiles) {
    if (!path.endsWith(".dart")) continue;
    bool found = false;
    for (MapEntry<String, String> usDirEntry in _compileAndLintDirs.entries) {
      if (path.startsWith("pkg/${usDirEntry.key}/${usDirEntry.value}")) {
        found = true;
        break;
      }
    }
    if (!found) continue;
    files.add(_repoDir.resolve(path));
  }

  if (files.isEmpty) return null;

  return new CompileAndLintWork(
      includedFiles: files,
      includedDirectoryUris: includedDirs,
      repoDir: _repoDir);
}

LintWork? _createLintWork(List<String> changedFiles) {
  List<String> filters = [];
  pathLoop:
  for (String path in changedFiles) {
    if (!path.endsWith(".dart")) continue;
    for (MapEntry<String, String> entry in _lintDirs.entries) {
      if (path.startsWith("pkg/${entry.key}/${entry.value}")) {
        String filter = path.substring("pkg/".length, path.length - 5);
        filters.add("lint/$filter/...");
        continue pathLoop;
      }
    }
  }

  if (filters.isEmpty) return null;

  return new LintWork(filters: filters, repoDir: _repoDir);
}

MessagesWork? _createMessagesTestWork(List<String> changedFiles) {
  // TODO(jensj): Could we detect what ones are changed/added and only test
  // those?
  for (String file in changedFiles) {
    if (file == "pkg/front_end/messages.yaml") {
      return new MessagesWork(repoDir: _repoDir);
    }
  }

  // messages.yaml not changed.
  return null;
}

SpellNotSourceWork? _createSpellingTestNotSourceWork(
    List<String> changedFiles) {
  // TODO(jensj): Not here, but I'll add the note here.
  // package:testing takes *a long time* listing files because it does
  // ```
  // if (suite.exclude.any((RegExp r) => path.contains(r))) continue;
  // if (suite.pattern.any((RegExp r) => path.contains(r))) {}
  // ```
  // for each file it finds. Maybe it should do something more efficient,
  // and maybe it should even take given filters into account at this point?
  //
  // Also it lists all files in the specified "path", so for instance for the
  // src spell one we have to list all files in "pkg/", then filter it down to
  // stuff in one of the dirs we care about.
  List<String> filters = [];
  for (String path in changedFiles) {
    if (!path.endsWith(".dart")) continue;
    if (path.startsWith("pkg/front_end/") &&
        !path.startsWith("pkg/front_end/lib/")) {
      // Remove front of path and ".dart".
      String filter = path.substring("pkg/front_end/".length, path.length - 5);
      filters.add("spelling_test_not_src/$filter");
    }
  }

  if (filters.isEmpty) return null;

  return new SpellNotSourceWork(filters: filters, repoDir: _repoDir);
}

SpellSourceWork? _createSpellingTestSourceWork(List<String> changedFiles) {
  List<String> filters = [];
  pathLoop:
  for (String path in changedFiles) {
    if (!path.endsWith(".dart")) continue;
    for (MapEntry<String, List<String>> entry in _spellDirs.entries) {
      for (String subPath in entry.value) {
        if (path.startsWith("pkg/${entry.key}/$subPath")) {
          String filter = path.substring("pkg/".length, path.length - 5);
          filters.add("spelling_test_src/$filter");
          continue pathLoop;
        }
      }
    }
  }

  if (filters.isEmpty) return null;

  return new SpellSourceWork(filters: filters, repoDir: _repoDir);
}

Future<void> _executePendingWorkItems(List<Work> workItems) async {
  int currentlyRunning = 0;
  SpawnHelper spawnHelper = new SpawnHelper();
  print("Waiting for spawn to start up.");
  Stopwatch stopwatch = new Stopwatch()..start();
  await spawnHelper
      .spawn(_repoDir.resolve("pkg/front_end/presubmit_helper_spawn.dart"),
          (dynamic ok) {
    if (ok is! bool) {
      exitCode = 1;
      print("Error got message of type ${ok.runtimeType}");
      return;
    }
    currentlyRunning--;
    if (!ok) {
      exitCode = 1;
    }
  });
  print("Isolate started in ${stopwatch.elapsed}");

  for (Work workItem in workItems) {
    print("Executing ${workItem.name}.");
    currentlyRunning++;
    spawnHelper.send(json.encode(workItem.toJson()));
  }

  while (currentlyRunning > 0) {
    await Future.delayed(const Duration(milliseconds: 42));
  }
  spawnHelper.close();
}

/// Queries git about changes against upstream, or origin/main if no upstream is
/// set. This is similar (but different), I believe, to what
/// `git cl presubmit` does.
List<String> getChangedFiles({required bool collectUncommitted}) {
  Set<String> paths = {};
  void collectChanges(ProcessResult processResult) {
    for (String line in processResult.stdout.toString().split("\n")) {
      List<String> split = line.split("\t");
      if (split.length != 2) continue;
      if (split[0] == 'D') continue; // Don't check deleted files.
      String path = split[1].trim().replaceAll("\\", "/");
      paths.add(path);
    }
  }

  ProcessResult result = Process.runSync(
      "git",
      [
        "-c",
        "core.quotePath=false",
        "diff",
        "--name-status",
        "--no-renames",
        "@{u}...HEAD",
      ],
      runInShell: true);
  if (result.exitCode != 0) {
    result = Process.runSync(
        "git",
        [
          "-c",
          "core.quotePath=false",
          "diff",
          "--name-status",
          "--no-renames",
          "origin/main...HEAD",
        ],
        runInShell: true);
  }
  if (result.exitCode != 0) {
    throw "Failure";
  }
  collectChanges(result);

  if (collectUncommitted) {
    result = Process.runSync(
        "git",
        [
          "-c",
          "core.quotePath=false",
          "diff",
          "--name-status",
          "--no-renames",
          "HEAD",
        ],
        runInShell: true);
    collectChanges(result);
  }

  return paths.toList();
}

/// If [inner] is a dir or file inside [outer] this returns the index into
/// `inner.pathSegments` corresponding to the folder- or filename directly
/// inside [outer].
/// If [inner] is not inside [outer] it returns null.
int? _getPathSegmentIndexIfSubEntry(Uri outer, Uri inner) {
  List<String> outerPathSegments = outer.pathSegments;
  List<String> innerPathSegments = inner.pathSegments;
  if (innerPathSegments.length < outerPathSegments.length) return null;
  int end = outerPathSegments.length;
  if (outerPathSegments.last == "") end--;
  for (int i = 0; i < end; i++) {
    if (Platform.isWindows) {
      if (outerPathSegments[i].toLowerCase() !=
          innerPathSegments[i].toLowerCase()) {
        return null;
      }
    } else {
      if (outerPathSegments[i] != innerPathSegments[i]) {
        return null;
      }
    }
  }
  return end;
}

Future<void> _run(
  String script,
  List<String> scriptArguments,
) async {
  List<String> arguments = [];
  arguments.add("$script");
  arguments.addAll(scriptArguments);

  Stopwatch stopwatch = new Stopwatch()..start();
  ProcessResult result = await Process.run(_dartVm, arguments,
      workingDirectory: _repoDir.toFilePath());
  String runWhat = "${_dartVm} ${arguments.join(' ')}";
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    print("-----");
    print("Running: $runWhat: "
        "Failed with exit code ${result.exitCode} "
        "in ${stopwatch.elapsedMilliseconds} ms.");
    String stdout = result.stdout.toString();
    stdout = stdout.trim();
    if (stdout.isNotEmpty) {
      print("--- stdout start ---");
      print(stdout);
      print("--- stdout end ---");
    }

    String stderr = result.stderr.toString().trim();
    if (stderr.isNotEmpty) {
      print("--- stderr start ---");
      print(stderr);
      print("--- stderr end ---");
    }
  } else {
    print("Running: $runWhat: Done in ${stopwatch.elapsedMilliseconds} ms.");
  }
}

// This script is potentially called from several places (once from each),
// but we only want to actually run it once. To that end we - from the changed
// files figure out which would call this script, and only if the caller is
// the top one (just alphabetically sorted) we actually run.
bool _shouldRun(final List<String> changedFiles, final String callerPath) {
  Uri pkgDir = _repoDir.resolve("pkg/");
  Uri callerUri = Uri.base.resolveUri(Uri.file(callerPath));
  int? endPathIndex = _getPathSegmentIndexIfSubEntry(pkgDir, callerUri);
  if (endPathIndex == null) {
    throw "Unsupported path";
  }
  final String callerPkgDir = callerUri.pathSegments[endPathIndex];
  if (!_usDirs.contains(callerPkgDir)) {
    throw "Unsupported dir: $callerPkgDir -- expected one of $_usDirs.";
  }

  final Set<String> changedUsDirsSet = {};
  for (String path in changedFiles) {
    if (!path.startsWith("pkg/")) continue;
    List<String> paths = path.split("/");
    if (paths.length < 2) continue;
    if (_usDirs.contains(paths[1])) {
      changedUsDirsSet.add(paths[1]);
    }
  }

  if (changedUsDirsSet.isEmpty) {
    print("We have no changes.");
    return false;
  }

  final List<String> changedUsDirs = changedUsDirsSet.toList()..sort();
  if (changedUsDirs.first != callerPkgDir) {
    print("We expect this file to be called elsewhere which will do the work.");
    return false;
  }
  return true;
}

/// The `generated_files_up_to_date_git_test.dart` file imports
/// package:dart_style which imports package:analyzer --- so it's a lot of extra
/// stuff to compile (and thus an expensive script to start).
/// Therefore it's not done in the same way as the other things, but instead
/// launched separately.
bool _shouldRunGenerateFilesTest(List<String> changedFiles) {
  for (String path in changedFiles) {
    if (_generatedFilesUpToDateFiles.contains(path)) {
      return true;
    }
  }

  return false;
}

class DepsTestWork extends Work {
  DepsTestWork();

  @override
  String get name => "Deps test";

  @override
  Map<String, Object?> toJson() {
    return {
      "WorkTypeIndex": WorkEnum.DepsTest.index,
    };
  }

  static Work fromJson(Map<String, Object?> json) {
    return new DepsTestWork();
  }
}

class CompileAndLintWork extends Work {
  final Set<Uri> includedFiles;
  final Set<Uri> includedDirectoryUris;
  final Uri repoDir;

  CompileAndLintWork(
      {required this.includedFiles,
      required this.includedDirectoryUris,
      required this.repoDir});

  @override
  String get name => "compile and lint test";

  @override
  Map<String, Object?> toJson() {
    return {
      "WorkTypeIndex": WorkEnum.CompileAndLint.index,
      "includedFiles": includedFiles.map((e) => e.toString()).toList(),
      "includedDirectoryUris":
          includedDirectoryUris.map((e) => e.toString()).toList(),
      "repoDir": repoDir.toString(),
    };
  }

  static Work fromJson(Map<String, Object?> json) {
    return new CompileAndLintWork(
      includedFiles: Set<Uri>.from(
          (json["includedFiles"] as Iterable).map((e) => Uri.parse(e))),
      includedDirectoryUris: Set<Uri>.from(
          (json["includedDirectoryUris"] as Iterable).map((e) => Uri.parse(e))),
      repoDir: Uri.parse(json["repoDir"] as String),
    );
  }
}

class LintWork extends Work {
  final List<String> filters;
  final Uri repoDir;

  LintWork({required this.filters, required this.repoDir});

  @override
  String get name => "Lint test";

  @override
  Map<String, Object?> toJson() {
    return {
      "WorkTypeIndex": WorkEnum.Lint.index,
      "filters": filters,
      "repoDir": repoDir.toString(),
    };
  }

  static Work fromJson(Map<String, Object?> json) {
    return new LintWork(
      filters: List<String>.from(json["filters"] as Iterable),
      repoDir: Uri.parse(json["repoDir"] as String),
    );
  }
}

class MessagesWork extends Work {
  final Uri repoDir;

  MessagesWork({required this.repoDir});

  @override
  String get name => "messages test";

  @override
  Map<String, Object?> toJson() {
    return {
      "WorkTypeIndex": WorkEnum.Messages.index,
      "repoDir": repoDir.toString(),
    };
  }

  static Work fromJson(Map<String, Object?> json) {
    return new MessagesWork(
      repoDir: Uri.parse(json["repoDir"] as String),
    );
  }
}

class SpawnHelper {
  bool _spawned = false;
  late ReceivePort _receivePort;
  late SendPort _sendPort;
  late void Function(dynamic data) onData;
  final List<dynamic> data = [];

  void close() {
    if (!_spawned) throw "Not spawned!";
    _receivePort.close();
  }

  void send(Object? message) {
    if (!_spawned) throw "Not spawned!";
    _sendPort.send(message);
  }

  Future<void> spawn(Uri spawnUri, void Function(dynamic data) onData) async {
    if (_spawned) throw "Already spawned!";
    _spawned = true;
    this.onData = onData;
    _receivePort = ReceivePort();
    await Isolate.spawnUri(spawnUri, const [], _receivePort.sendPort);
    final Completer<SendPort> sendPortCompleter = Completer<SendPort>();
    _receivePort.listen((dynamic receivedData) {
      if (!sendPortCompleter.isCompleted) {
        sendPortCompleter.complete(receivedData);
      } else {
        onData(receivedData);
      }
    });
    _sendPort = await sendPortCompleter.future;
  }
}

class SpellNotSourceWork extends Work {
  final List<String> filters;
  final Uri repoDir;

  SpellNotSourceWork({required this.filters, required this.repoDir});

  @override
  String get name => "spell test not source";

  @override
  Map<String, Object?> toJson() {
    return {
      "WorkTypeIndex": WorkEnum.SpellingNotSource.index,
      "filters": filters,
      "repoDir": repoDir.toString(),
    };
  }

  static Work fromJson(Map<String, Object?> json) {
    return new SpellNotSourceWork(
      filters: List<String>.from(json["filters"] as Iterable),
      repoDir: Uri.parse(json["repoDir"] as String),
    );
  }
}

class SpellSourceWork extends Work {
  final List<String> filters;
  final Uri repoDir;

  SpellSourceWork({required this.filters, required this.repoDir});

  @override
  String get name => "spell test source";

  @override
  Map<String, Object?> toJson() {
    return {
      "WorkTypeIndex": WorkEnum.SpellingSource.index,
      "filters": filters,
      "repoDir": repoDir.toString(),
    };
  }

  static Work fromJson(Map<String, Object?> json) {
    return new SpellSourceWork(
      filters: List<String>.from(json["filters"] as Iterable),
      repoDir: Uri.parse(json["repoDir"] as String),
    );
  }
}

sealed class Work {
  String get name;

  Map<String, Object?> toJson();

  static Work workFromJson(Map<String, Object?> json) {
    dynamic workTypeIndex = json["WorkTypeIndex"];
    if (workTypeIndex is! int ||
        workTypeIndex < 0 ||
        workTypeIndex >= WorkEnum.values.length) {
      throw "Cannot convert to a Work object.";
    }
    WorkEnum workType = WorkEnum.values[workTypeIndex];
    switch (workType) {
      case WorkEnum.CompileAndLint:
        return CompileAndLintWork.fromJson(json);
      case WorkEnum.Messages:
        return MessagesWork.fromJson(json);
      case WorkEnum.SpellingNotSource:
        return SpellNotSourceWork.fromJson(json);
      case WorkEnum.SpellingSource:
        return SpellSourceWork.fromJson(json);
      case WorkEnum.Lint:
        return LintWork.fromJson(json);
      case WorkEnum.DepsTest:
        return DepsTestWork.fromJson(json);
    }
  }
}

enum WorkEnum {
  CompileAndLint,
  Messages,
  SpellingNotSource,
  SpellingSource,
  Lint,
  DepsTest,
}

extension on List<Work> {
  void addIfNotNull(Work? element) {
    if (element == null) return;
    add(element);
  }
}
