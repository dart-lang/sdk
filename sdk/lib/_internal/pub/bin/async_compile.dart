// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

/// The path to pub's root directory (sdk/lib/_internal/pub) in the Dart repo.
///
/// This assumes this script is itself being run from within the repo.
final sourceDir = p.dirname(p.dirname(p.fromUri(Platform.script)));

/// The [sourceDir] as a URL, for use in import strings.
final sourceUrl = p.toUri(sourceDir).toString();

/// The directory that compiler output should be written to.
String buildDir;

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
    if (!destFile.existsSync() ||
        entry.lastModifiedSync().isAfter(destFile.lastModifiedSync())) {
      compile(sourceFile.path, sourceFile.readAsStringSync(), destPath);
      numCompiled++;
      if (!silent) print("Compiled ${sourceFile.path}.");
    }
  }

  if (!silent) print("Compiled $numCompiled out of $numFiles files.");
}

final _compilerPattern = new RegExp(r"import '(\.\./)+compiler");

void compile(String sourcePath, String source, String destPath) {
  var destDir = new Directory(p.dirname(destPath));
  destDir.createSync(recursive: true);

  // TODO(rnystrom): Do real async/await transformation here!
  source = source.replaceAll("ASYNC!", "");

  // Pub imports dart2js using relative imports that reach outside of pub's
  // source tree. Since the build directory is in a different location, we need
  // to fix those to be valid relative imports from the build directory.
  var compilerDir = p.url.join(sourceUrl, "../compiler");
  var relative = p.url.relative(compilerDir, from: destDir.path);
  source = source.replaceAll(_compilerPattern, "import '$relative");

  try {
    new File(destPath).writeAsStringSync(source);
  } on IOException catch (ex) {
    // Do nothing. This may happen if two instances of the compiler are running
    // concurrently and compile the same file. The second one to try to write
    // the output may fail if the file is still open. Since they are producing
    // the same output anyway, just ignore it when the second one fails.
  }
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
