import 'dart:async';
import 'dart:io';

import 'package:analyzer_utilities/tools.dart';
import 'package:dart_style/dart_style.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

Future<String> _formatText(String text, {required String pkgPath}) async {
  var packageConfig = await findPackageConfig(Directory(pkgPath));
  if (packageConfig == null) {
    throw StateError(
      'Could not find the shared Dart SDK package_config.json file, for '
      '"$pkgPath"',
    );
  }
  var package = packageConfig.packageOf(
    Uri.file(join(pkgPath, 'pubspec.yaml')),
  );
  if (package == null) {
    throw StateError('Could not find the package for "$pkgPath"');
  }
  var languageVersion = package.languageVersion;
  if (languageVersion == null) {
    throw StateError('Could not find a Dart language version for "$pkgPath"');
  }
  var version = Version(languageVersion.major, languageVersion.minor, 0);
  return DartFormatter(languageVersion: version).format(text);
}

extension GeneratedContentExtension on GeneratedContent {
  /// Check whether the [output] has the correct contents, and return true if it
  /// does.
  ///
  /// [pkgRoot] is the path to the SDK's `pkg` directory.
  Future<bool> check(String pkgRoot) async {
    switch (this) {
      case GeneratedDirectory self:
        var outputDirectory = self.output(pkgRoot);
        var map = self.directoryContentsComputer(pkgRoot);
        try {
          for (var entry in map.entries) {
            var file = entry.key;
            var fileContentsComputer = entry.value;
            var expectedContents = await fileContentsComputer(pkgRoot);
            var outputFile = File(posix.join(outputDirectory.path, file));
            var actualContents = outputFile.readAsStringSync();
            // Normalize Windows line endings to Unix line endings so that the
            // comparison doesn't fail on Windows.
            actualContents = actualContents.replaceAll('\r\n', '\n');
            if (expectedContents != actualContents) {
              return false;
            }
          }
          var nonHiddenFileCount = 0;
          outputDirectory
              .listSync(recursive: false, followLinks: false)
              .forEach((FileSystemEntity fileSystemEntity) {
                if (fileSystemEntity is File &&
                    !basename(fileSystemEntity.path).startsWith('.')) {
                  nonHiddenFileCount++;
                }
              });
          if (nonHiddenFileCount != map.length) {
            // The number of files generated doesn't match the number we expected to
            // generate.
            return false;
          }
        } catch (e) {
          // There was a problem reading the file (most likely because it didn't
          // exist).  Treat that the same as if the file doesn't have the expected
          // contents.
          return false;
        }
        return true;
      case GeneratedFile self:
        var outputFile = self.output(pkgRoot);
        var expectedContents = await self.computeContents(pkgRoot);
        if (self.isDartFile) {
          expectedContents = await _formatText(
            expectedContents,
            pkgPath: dirname(outputFile.path),
          );
        }
        try {
          var actualContents = outputFile.readAsStringSync();
          // Normalize Windows line endings to Unix line endings so that the
          // comparison doesn't fail on Windows.
          actualContents = actualContents.replaceAll('\r\n', '\n');
          expectedContents = expectedContents.replaceAll('\r\n', '\n');
          return expectedContents == actualContents;
        } catch (e) {
          // There was a problem reading the file (most likely because it didn't
          // exist).  Treat that the same as if the file doesn't have the expected
          // contents.
          return false;
        }
    }
  }
}

extension GeneratedContentIterable on Iterable<GeneratedContent> {
  /// Check that all of the targets in `this` are up to date.  If they are not,
  /// print out a message instructing the user to regenerate them, and exit with
  /// a nonzero error code.
  ///
  /// [pkgRoot] is the path to the SDK's `pkg` directory.  [generatorPath] is
  /// the path to a .dart script the user may use to regenerate the targets.
  ///
  /// To avoid mistakes when run on Windows, [generatorPath] always uses
  /// POSIX directory separators.
  Future<void> check(String pkgRoot, String generatorPath) async {
    var generateNeeded = false;
    for (var target in this) {
      var ok = await target.check(pkgRoot);
      if (!ok) {
        print(
          '${normalize(target.output(pkgRoot).absolute.path)}'
          " doesn't have expected contents.",
        );
        generateNeeded = true;
      }
    }
    if (generateNeeded) {
      print('Please regenerate using:');
      var executable = Platform.executable;
      var generateScript = normalize(joinAll(posix.split(generatorPath)));
      print('  $executable $generateScript');
      fail('Generated content needs to be regenerated');
    }
  }
}
