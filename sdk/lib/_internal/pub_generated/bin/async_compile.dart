import 'dart:io';
import 'package:args/args.dart';
import 'package:analyzer/src/services/formatter_impl.dart';
import 'package:async_await/async_await.dart' as async_await;
import 'package:path/path.dart' as p;
final sourceDir = p.dirname(p.dirname(p.fromUri(Platform.script)));
final sourceUrl = p.toUri(sourceDir).toString();
final generatedDir = p.join(p.dirname(sourceDir), 'pub_generated');
bool hadFailure = false;
bool verbose = false;
final _compilerPattern = new RegExp(r"import '(\.\./)+compiler");
final _commitPattern = new RegExp(r"[a-f0-9]{40}");
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
  } on FormatException catch (ex) {
    stderr.writeln(ex);
    stderr.writeln();
    stderr.writeln(
        "Usage: dart async_compile.dart [--verbose] [--force] <build dir>");
    exit(64);
  }
  var result = Process.runSync(
      "git",
      ["rev-parse", "HEAD"],
      workingDirectory: p.join(sourceDir, "../../../../third_party/pkg/async_await"));
  if (result.exitCode != 0) {
    stderr.writeln("Could not get Git revision of async_await compiler.");
    exit(1);
  }
  var currentCommit = result.stdout.trim();
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
  for (var entry in new Directory(generatedDir).listSync(recursive: true)) {
    if (p.extension(entry.path) != ".dart") continue;
    var relative = p.relative(entry.path, from: generatedDir);
    if (!sources.contains(relative)) {
      _deleteFile(entry.path);
      if (verbose) print("Deleted  $relative");
    }
  }
  if (currentCommit != lastCommit) {
    readme = readme.replaceAll(_commitPattern, currentCommit);
    _writeFile(readmePath, readme);
    if (verbose) print("Updated README.md");
  }
  if (numCompiled > 0) _generateSnapshot(buildDir);
  if (verbose) print("Compiled $numCompiled out of $numFiles files");
  if (hadFailure) exit(1);
}
void _compile(String sourcePath, String source, String destPath) {
  var destDir = new Directory(p.dirname(destPath));
  destDir.createSync(recursive: true);
  source = _translateAsyncAwait(sourcePath, source);
  if (source != null) source = _fixDart2jsImports(sourcePath, source, destPath);
  if (source == null) {
    _deleteFile(destPath);
  } else {
    _writeFile(destPath, source);
  }
}
String _translateAsyncAwait(String sourcePath, String source) {
  if (p.isWithin(p.join(sourceDir, "asset"), sourcePath)) {
    return source;
  }
  try {
    source = async_await.compile(source);
    var result = new CodeFormatter().format(CodeKind.COMPILATION_UNIT, source);
    return result.source;
  } catch (ex) {
    stderr.writeln("Async compile failed on $sourcePath:\n$ex");
    hadFailure = true;
    return null;
  }
}
String _fixDart2jsImports(String sourcePath, String source, String destPath) {
  var compilerDir = p.url.join(sourceUrl, "../compiler");
  var relative =
      p.url.relative(compilerDir, from: p.url.dirname(p.toUri(destPath).toString()));
  return source.replaceAll(_compilerPattern, "import '$relative");
}
void _generateSnapshot(String buildDir) {
  buildDir = p.normalize(buildDir);
  var entrypoint = p.join(generatedDir, 'bin/pub.dart');
  var packageRoot = p.join(buildDir, 'packages');
  var snapshot = p.join(buildDir, 'dart-sdk/bin/snapshots/pub.dart.snapshot');
  var result = Process.runSync(
      Platform.executable,
      ["--package-root=$packageRoot", "--snapshot=$snapshot", entrypoint]);
  if (result.exitCode != 0) {
    stderr.writeln("Failed to generate snapshot:");
    if (result.stderr.trim().isNotEmpty) stderr.writeln(result.stderr);
    if (result.stdout.trim().isNotEmpty) stderr.writeln(result.stdout);
    exit(result.exitCode);
  }
  if (verbose) print("Created pub snapshot");
}
void _deleteFile(String path) {
  try {
    new File(path).deleteSync();
  } on IOException catch (ex) {}
}
void _writeFile(String path, String contents) {
  try {
    new File(path).writeAsStringSync(contents);
  } on IOException catch (ex) {}
}
