// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:analyzer/src/services/formatter_impl.dart';
import 'package:async_await/async_await.dart' as async_await;
import 'package:path/path.dart' as p;

/// The path to pub's root directory (sdk/lib/_internal/pub) in the Dart repo.
///
/// This assumes this script is itself being run from within the repo.
final sourceDir = p.dirname(p.dirname(p.fromUri(Platform.script)));

/// The [sourceDir] as a URL, for use in import strings.
final sourceUrl = p.toUri(sourceDir).toString();

/// The directory that compiler output should be written to.
final generatedDir = p.join(p.dirname(sourceDir), 'pub_generated');

/// `true` if any file failed to compile.
bool hadFailure = false;

bool verbose = false;

/// Prefix for imports in pub that import dart2js libraries.
final _compilerPattern = new RegExp(r"import '(\.\./)+compiler");

/// Matches the Git commit hash of the compiler stored in the README.md file.
///
/// This is used both to find the current commit and replace it with the new
/// one.
final _commitPattern = new RegExp(r"[a-f0-9]{40}");

/// This runs the async/await compiler on all of the pub source code.
///
/// It reads from the repo and writes the compiled output into the given build
/// directory (using the same file names and relative layout). Does not
/// compile files that haven't changed since the last time they were compiled.
// TODO(rnystrom): Remove this when #104 is fixed.
void main(List<String> arguments) {
  var parser = new ArgParser(allowTrailingOptions: true);

  parser.addFlag("verbose", callback: (value) => verbose = value);

  var force = false;
  parser.addFlag("force", callback: (value) => force = value);

  var buildDir;

  try {
    var rest = parser.parse(arguments).rest;
    if (rest.isEmpty) {
      throw new FormatException('Missing build directory.');
    } else if (rest.length > 1) {
      throw new FormatException(
          'Unexpected arguments: ${rest.skip(1).join(" ")}.');
    }

    buildDir = rest.first;
  } on FormatException catch(ex) {
    stderr.writeln(ex);
    stderr.writeln();
    stderr.writeln(
        "Usage: dart async_compile.dart [--verbose] [--force] <build dir>");
    exit(64);
  }

  // See what version (i.e. Git commit) of the async-await compiler we
  // currently have. If this is different from the version that was used to
  // compile the sources, recompile everything.
  var currentCommit = _getCurrentCommit();

  var readmePath = p.join(generatedDir, "README.md");
  var lastCommit;
  var readme = new File(readmePath).readAsStringSync();
  var match = _commitPattern.firstMatch(readme);
  if (match == null) {
    stderr.writeln("Could not find compiler commit hash in README.md.");
    exit(1);
  }

  lastCommit = match[0];

  var numFiles = 0;
  var numCompiled = 0;

  // Compile any modified or missing files.
  var sources = new Set();
  for (var entry in new Directory(sourceDir).listSync(recursive: true)) {
    if (p.extension(entry.path) != ".dart") continue;

    numFiles++;
    var relative = p.relative(entry.path, from: sourceDir);
    sources.add(relative);

    var sourceFile = entry as File;
    var destPath = p.join(generatedDir, relative);
    var destFile = new File(destPath);
    if (force ||
        currentCommit != lastCommit ||
        !destFile.existsSync() ||
        entry.lastModifiedSync().isAfter(destFile.lastModifiedSync())) {
      _compile(sourceFile.path, sourceFile.readAsStringSync(), destPath);
      numCompiled++;
      if (verbose) print("Compiled $relative");
    }
  }

  // Delete any previously compiled files whose source no longer exists.
  for (var entry in new Directory(generatedDir).listSync(recursive: true)) {
    if (p.extension(entry.path) != ".dart") continue;

    var relative = p.relative(entry.path, from: generatedDir);

    if (!sources.contains(relative)) {
      _deleteFile(entry.path);
      if (verbose) print("Deleted  $relative");
    }
  }

  // Update the README.
  if (currentCommit != lastCommit) {
    readme = readme.replaceAll(_commitPattern, currentCommit);
    _writeFile(readmePath, readme);
    if (verbose) print("Updated README.md");
  }

  if (numCompiled > 0) _generateSnapshot(buildDir);

  if (verbose) print("Compiled $numCompiled out of $numFiles files");

  if (hadFailure) exit(1);
}

String _getCurrentCommit() {
  var command = "git";
  var args = ["rev-parse", "HEAD"];

  // Spawning a process on Windows will not look for the executable in the
  // system path so spawn git through a shell to find it.
  if (Platform.operatingSystem == "windows") {
    command = "cmd";
    args = ["/c", "git"]..addAll(args);
  }

  var result = Process.runSync(command, args, workingDirectory:
      p.join(sourceDir, "../../../../third_party/pkg/async_await"));
  if (result.exitCode != 0) {
    stderr.writeln("Could not get Git revision of async_await compiler.");
    exit(1);
  }

  return result.stdout.trim();
}

void _compile(String sourcePath, String source, String destPath) {
  var destDir = new Directory(p.dirname(destPath));
  destDir.createSync(recursive: true);

  source = _translateAsyncAwait(sourcePath, source);
  if (source != null) source = _fixDart2jsImports(sourcePath, source, destPath);

  if (source == null) {
    // If the async compile fails, delete the file so that we don't try to
    // run the stale previous output and so that we try to recompile it later.
    _deleteFile(destPath);
  } else {
    _writeFile(destPath, source);
  }
}

/// Runs the async/await compiler on [source].
///
/// Returns the translated Dart code or `null` if the compiler failed.
String _translateAsyncAwait(String sourcePath, String source) {
  if (p.isWithin(p.join(sourceDir, "asset"), sourcePath)) {
    // Don't run the async compiler on the special "asset" source files. These
    // have preprocessor comments that get discarded by the compiler.
    return source;
  }

  try {
    source = async_await.compile(source);

    // Reformat the result since the compiler ditches all whitespace.
    // TODO(rnystrom): Remove when this is fixed:
    // https://github.com/dart-lang/async_await/issues/12
    var result = new CodeFormatter().format(CodeKind.COMPILATION_UNIT, source);
    return result.source;
  } catch (ex) {
    stderr.writeln("Async compile failed on $sourcePath:\n$ex");
    hadFailure = true;
    return null;
  }
}

/// Fix relative imports to dart2js libraries.
///
/// Pub imports dart2js using relative imports that reach outside of pub's
/// source tree. Since the build directory is in a different location, we need
/// to fix those to be valid relative imports from the build directory.
String _fixDart2jsImports(String sourcePath, String source, String destPath) {
  var compilerDir = p.url.join(sourceUrl, "../compiler");
  var relative = p.url.relative(compilerDir,
      from: p.url.dirname(p.toUri(destPath).toString()));
  return source.replaceAll(_compilerPattern, "import '$relative");
}

/// Regenerate the pub snapshot from the async/await-compiled output. We do
/// this here since the tests need it and it's faster than doing a full SDK
/// build.
void _generateSnapshot(String buildDir) {
  buildDir = p.normalize(buildDir);

  var entrypoint = p.join(generatedDir, 'bin/pub.dart');
  var packageRoot = p.join(buildDir, 'packages');
  var snapshot = p.join(buildDir, 'dart-sdk/bin/snapshots/pub.dart.snapshot');

  var result = Process.runSync(Platform.executable, [
    "--package-root=$packageRoot",
    "--snapshot=$snapshot",
    entrypoint
  ]);

  if (result.exitCode != 0) {
    stderr.writeln("Failed to generate snapshot:");
    if (result.stderr.trim().isNotEmpty) stderr.writeln(result.stderr);
    if (result.stdout.trim().isNotEmpty) stderr.writeln(result.stdout);
    exit(result.exitCode);
  }

  if (verbose) print("Created pub snapshot");
}

/// Deletes the file at [path], ignoring any IO errors that occur.
///
/// This swallows errors to accommodate multiple compilers running concurrently.
/// Since they will produce the same output anyway, a failure of one is fine.
void _deleteFile(String path) {
  try {
    new File(path).deleteSync();
  } on IOException catch (ex) {
    // Do nothing.
  }
}

/// Writes [contents] to [path], ignoring any IO errors that occur.
///
/// This swallows errors to accommodate multiple compilers running concurrently.
/// Since they will produce the same output anyway, a failure of one is fine.
void _writeFile(String path, String contents) {
  try {
    new File(path).writeAsStringSync(contents);
  } on IOException catch (ex) {
    // Do nothing.
  }
}
