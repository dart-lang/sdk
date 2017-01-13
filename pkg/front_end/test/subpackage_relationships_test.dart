// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/dependency_grapher.dart';
import 'package:path/path.dart' as pathos;

main() async {
  exit(await new _SubpackageRelationshipsTest().run());
}

/// Map from subpackage name to the rules for what the subpackage is allowed to
/// depend directly on.
///
/// Each subdirectory of `lib/src` is considered a subpackage.  Files in
/// `lib/src` but not in a subdirectory are considered to be in the `lib/src`
/// subpackage.  Files outside of `lib/src` (but still in `lib`) are considered
/// to be in the `lib` subpackage.
///
/// TODO(paulberry): stuff in lib/src shouldn't depend on lib; lib should just
/// re-export stuff in lib/src.
/// TODO(paulberry): remove dependencies on analyzer.
final subpackageRules = {
  'lib': new SubpackageRules(
      mayImportAnalyzer: true,
      allowedDependencies: ['lib/src', 'lib/src/base']),
  'lib/src': new SubpackageRules(
      mayImportAnalyzer: true,
      allowedDependencies: ['lib', 'lib/src/base', 'lib/src/scanner']),
  'lib/src/base': new SubpackageRules(
      mayImportAnalyzer: true, allowedDependencies: ['lib']),
  'lib/src/scanner': new SubpackageRules(allowedDependencies: ['lib/src/base']),
};

/// Rules for what a subpackage may depend directly on.
class SubpackageRules {
  /// Indicates whether the subpackage may directly depend on analyzer.
  final bool mayImportAnalyzer;

  /// Indicates which other subpackages a given subpackage may directly depend
  /// on.
  final List<String> allowedDependencies;

  SubpackageRules(
      {this.mayImportAnalyzer: false, this.allowedDependencies: const []});
}

class _SubpackageRelationshipsTest {
  /// File uri of the front_end package's "lib" directory.
  final frontEndLibUri = Platform.script.resolve('../lib/');

  /// Indicates whether any problems have been reported yet.
  bool problemsReported = false;

  /// Check for problems resulting from URI [src] having a direct dependency on
  /// URI [dst].
  void checkDependency(Uri src, Uri dst) {
    if (dst.scheme == 'dart') return;
    if (dst.scheme != 'package') {
      problem('$src depends on $dst, which is neither a package: or dart: URI');
      return;
    }
    var srcSubpackage = subpackageForUri(src);
    if (srcSubpackage == null) return;
    var srcSubpackageRules = subpackageRules[srcSubpackage];
    if (srcSubpackageRules == null) {
      problem('$src is in subpackage "$srcSubpackage", which is not found in '
          'subpackageRules');
      return;
    }
    if (!srcSubpackageRules.mayImportAnalyzer &&
        dst.pathSegments[0] == 'analyzer') {
      problem('$src depends on $dst, but subpackage "$srcSubpackage" may not '
          'import analyzer');
    }
    var dstSubPackage = subpackageForUri(dst);
    if (dstSubPackage == null) return;
    if (dstSubPackage == srcSubpackage) return;
    if (!srcSubpackageRules.allowedDependencies.contains(dstSubPackage)) {
      problem('$src depends on $dst, but subpackage "$srcSubpackage" is not '
          'allowed to depend on subpackage "$dstSubPackage"');
    }
  }

  /// Finds all files in the front_end's "lib" directory and returns their Uris
  /// (as "package:" URIs).
  List<Uri> findFrontEndUris() {
    var frontEndUris = <Uri>[];
    var frontEndLibPath = pathos.fromUri(frontEndLibUri);
    for (var entity in new Directory(frontEndLibPath)
        .listSync(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        var posixRelativePath = pathos.url.joinAll(
            pathos.split(pathos.relative(entity.path, from: frontEndLibPath)));
        frontEndUris.add(Uri.parse('package:front_end/$posixRelativePath'));
      }
    }
    return frontEndUris;
  }

  /// Reports a single problem.
  void problem(String description) {
    print(description);
    problemsReported = true;
  }

  /// Tests all subpackage relationships in the front end, and returns an
  /// appropriate exit code.
  Future<int> run() async {
    var frontEndUris = await findFrontEndUris();
    var packagesFileUri = frontEndLibUri.resolve('../../../.packages');
    var graph = await graphForProgram(
        frontEndUris,
        new CompilerOptions()
          ..packagesFileUri = packagesFileUri
          ..chaseDependencies = true);
    for (var i = 0; i < graph.topologicallySortedCycles.length; i++) {
      for (var library in graph.topologicallySortedCycles[i].libraries.values) {
        for (var dependency in library.dependencies) {
          checkDependency(library.uri, dependency.uri);
        }
      }
    }
    return problemsReported ? 1 : 0;
  }

  /// Determines which subpackage [src] is in.
  ///
  /// If [src] is not part of the front end, `null` is returned.
  String subpackageForUri(Uri src) {
    if (src.scheme != 'package') return null;
    if (src.pathSegments[0] != 'front_end') return null;
    if (src.pathSegments[1] != 'src') return 'lib';
    if (src.pathSegments.length == 3) return 'lib/src';
    return 'lib/src/${src.pathSegments[2]}';
  }
}
