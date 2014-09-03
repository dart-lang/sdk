// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:async_await/async_await.dart' as async_await;
import 'package:path/path.dart' as p;

/// A changing string that indicates the "version" or timestamp of the compiler
/// that the current sources were compiled against.
///
/// Increment this whenever a meaningful change in the async/await compiler
/// itself is landed. Bumping this will force all previously compiled files
/// that were compiled against an older compiler to be recompiled.
const COMPILER_VERSION = "1";

/// The path to pub's root directory (sdk/lib/_internal/pub) in the Dart repo.
///
/// This assumes this script is itself being run from within the repo.
final sourceDir = p.dirname(p.dirname(p.fromUri(Platform.script)));

/// The [sourceDir] as a URL, for use in import strings.
final sourceUrl = p.toUri(sourceDir).toString();

/// The directory that compiler output should be written to.
String buildDir;

/// `true` if any file failed to compile.
bool hadFailure = false;

final _compilerPattern = new RegExp(r"import '(\.\./)+compiler");

/// This runs the async/await compiler on all of the pub source code.
///
/// It reads from the repo and writes the compiled output into the given build
/// directory (using the same file names and relative layout). Does not
/// compile files that haven't changed since the last time they were compiled.
// TODO(rnystrom): Remove this when #104 is fixed.
void main(List<String> arguments) {
  _validate(arguments.isNotEmpty, "Missing build directory.");
  _validate(arguments.length <= 2, "Unexpected arguments.");
  if (arguments.length == 2) {
    _validate(arguments[1] == "--silent",
        "Invalid argument '${arguments[1]}");
  }

  // Create the build output directory if it's not already there.
  buildDir = p.join(p.normalize(arguments[0]), "pub_async");
  new Directory(buildDir).createSync(recursive: true);

  // See if the current sources were compiled against a different version of the
  // compiler.
  var versionPath = p.join(buildDir, "compiler.version");
  var version = "none";
  try {
    version = new File(versionPath).readAsStringSync();
  } on IOException catch (ex) {
    // Do nothing. The version file didn't exist.
  }

  var silent = arguments.length == 2 && arguments[1] == "--silent";
  var numFiles = 0;
  var numCompiled = 0;

  // Compile any modified or missing files.
  for (var entry in new Directory(sourceDir).listSync(recursive: true)) {
    if (p.extension(entry.path) != ".dart") continue;

    // Skip tests.
    // TODO(rnystrom): Do we want to use this for tests too?
    if (p.isWithin(p.join(sourceDir, "test"), entry.path)) continue;

    numFiles++;
    var relative = p.relative(entry.path, from: sourceDir);

    var sourceFile = entry as File;
    var destPath = p.join(buildDir, relative);
    var destFile = new File(destPath);
    if (version != COMPILER_VERSION ||
        !destFile.existsSync() ||
        entry.lastModifiedSync().isAfter(destFile.lastModifiedSync())) {
      _compile(sourceFile.path, sourceFile.readAsStringSync(), destPath);
      numCompiled++;
      if (!silent) print("Compiled ${sourceFile.path}.");
    }
  }

  _writeFile(versionPath, COMPILER_VERSION);

  if (!silent) print("Compiled $numCompiled out of $numFiles files.");

  if (hadFailure) exit(1);
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
    return async_await.compile(source);
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
  var relative = p.url.relative(compilerDir, from: p.dirname(destPath));
  return source.replaceAll(_compilerPattern, "import '$relative");
}

/// Validates command-line argument usage and exits with [message] if [valid]
/// is `false`.
void _validate(bool valid, String message) {
  if (valid) return;

  stderr.writeln(message);
  stderr.writeln();
  stderr.writeln("Usage: dart async_compile.dart <build dir> [--silent]");
  exit(64);
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