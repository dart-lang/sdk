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

/// List of packages that front_end is allowed to directly depend on.
///
/// Note that this script only checks files in pkg/front_end/lib, so this list
/// excludes dev dependencies.
final allowedPackageDependencies = [
  'charcode',
  'convert',
  'crypto',
  'kernel',
  'meta',
  'package_config',
  'path',
  'source_span',
  'testing',
];

/// Map from subpackage name to the rules for what the subpackage is allowed to
/// depend directly on.
///
/// Each listed directory is considered a subpackage.  Each package contains all
/// of its descendant files that are not in a more deeply nested subpackage.
///
/// TODO(paulberry): stuff in lib/src shouldn't depend on lib; lib should just
/// re-export stuff in lib/src.
final subpackageRules = {
  'lib': new SubpackageRules(allowedDependencies: [
    'lib/src',
    'lib/src/base',
    'lib/src/incremental',
  ]),
  'lib/src': new SubpackageRules(allowedDependencies: [
    'lib',
    'lib/src/base',
    'lib/src/fasta',
    "lib/src/fasta/dill",
    "lib/src/fasta/kernel",
    'lib/src/fasta/source',
    'lib/src/incremental',
  ]),
  'lib/src/base': new SubpackageRules(allowedDependencies: [
    'lib',
    'lib/src',
    'lib/src/fasta',
    'lib/src/incremental'
  ]),
  'lib/src/codegen': new SubpackageRules(),
  'lib/src/fasta': new SubpackageRules(allowedDependencies: [
    'lib',
    'lib/src',
    'lib/src/base',
    'lib/src/fasta/builder',
    'lib/src/fasta/dill',
    'lib/src/fasta/kernel',
    'lib/src/fasta/parser',
    'lib/src/fasta/scanner',
    'lib/src/fasta/testing',
    'lib/src/fasta/util',
    'lib/src/scanner',
  ]),
  'lib/src/fasta/builder': new SubpackageRules(allowedDependencies: [
    'lib/src/fasta',
    'lib/src/fasta/parser',
    'lib/src/fasta/source',
    'lib/src/fasta/util',
  ]),
  'lib/src/fasta/dill': new SubpackageRules(allowedDependencies: [
    'lib/src/fasta',
    'lib/src/fasta/kernel',
  ]),
  'lib/src/fasta/kernel': new SubpackageRules(allowedDependencies: [
    'lib',
    'lib/src/fasta',
    'lib/src/base',
    'lib/src/fasta/builder',
    'lib/src/fasta/dill',
    'lib/src/fasta/parser',
    'lib/src/fasta/scanner',
    'lib/src/fasta/source',
    'lib/src/fasta/type_inference',
    'lib/src/fasta/util',
    'lib/src/scanner',
  ]),
  'lib/src/fasta/parser': new SubpackageRules(allowedDependencies: [
    'lib/src/fasta',
    'lib/src/fasta/scanner',
    'lib/src/fasta/util',
    'lib/src/scanner',
  ]),
  'lib/src/fasta/scanner': new SubpackageRules(allowedDependencies: [
    'lib/src/fasta',
    // fasta scanner produces analyzer scanner tokens
    'lib/src/scanner',
    'lib/src/fasta/util',
  ]),
  'lib/src/fasta/source': new SubpackageRules(allowedDependencies: [
    'lib',
    'lib/src/fasta',
    'lib/src/base',
    'lib/src/fasta/builder',
    'lib/src/fasta/dill',
    'lib/src/fasta/kernel',
    'lib/src/fasta/parser',
    'lib/src/fasta/type_inference',
    'lib/src/fasta/util',
    'lib/src/scanner',
  ]),
  'lib/src/fasta/testing': new SubpackageRules(allowedDependencies: [
    'lib',
    'lib/src/fasta',
    'lib/src/base',
    'lib/src/fasta/kernel',
    'lib/src/fasta/scanner',
    'lib/src/scanner',
  ]),
  'lib/src/fasta/type_inference': new SubpackageRules(allowedDependencies: [
    'lib/src',
    'lib/src/base',
    'lib/src/fasta',
    'lib/src/fasta/kernel',
  ]),
  'lib/src/fasta/util': new SubpackageRules(),
  'lib/src/incremental': new SubpackageRules(allowedDependencies: [
    'lib',
    'lib/src',
    'lib/src/base',
    'lib/src/fasta',
    'lib/src/fasta/dill',
    'lib/src/fasta/kernel',
    'lib/src/fasta/parser',
    'lib/src/fasta/scanner',
    'lib/src/fasta/source',
  ]),
  'lib/src/scanner': new SubpackageRules(allowedDependencies: [
    'lib/src/base',
    // For error codes.
    'lib/src/fasta',
    // fasta scanner produces analyzer scanner tokens
    'lib/src/fasta/scanner',
  ]),
  'lib/src/testing': new SubpackageRules(allowedDependencies: [
    'lib',
    'lib/src/fasta/testing',
  ]),
};

/// Rules for what a subpackage may depend directly on.
class SubpackageRules {
  /// Indicates whether dart files may exist in subdirectories of this
  /// subpackage.
  ///
  /// If `false`, any subdirectory of this subpackage must be a separate
  /// subpackage.
  final bool allowSubdirs;

  /// Indicates which other subpackages a given subpackage may directly depend
  /// on.
  final List<String> allowedDependencies;

  var actuallyContainsFiles = false;

  var actuallyHasSubdirs = false;

  var actualDependencies = new Set<String>();

  SubpackageRules(
      {this.allowSubdirs: false, this.allowedDependencies: const []});
}

class _SubpackageRelationshipsTest {
  /// File uri of the front_end package's "lib" directory.
  final frontEndLibUri = Platform.script.resolve('../lib/');

  /// Indicates whether any problems have been reported yet.
  bool problemsReported = false;

  /// Package dependencies that were actually discovered
  final actualPackageDependencies = <String>[];

  /// Check for problems resulting from URI [src] having a direct dependency on
  /// URI [dst].
  void checkDependency(Uri src, Uri dst) {
    if (dst.scheme == 'dart') return;
    if (dst.scheme != 'package') {
      problem('$src depends on $dst, which is neither a package: or dart: URI');
      return;
    }
    if (src.scheme == 'package' &&
        src.pathSegments[0] == 'front_end' &&
        dst.scheme == 'package' &&
        dst.pathSegments[0] != 'front_end') {
      if (allowedPackageDependencies.contains(dst.pathSegments[0])) {
        actualPackageDependencies.add(dst.pathSegments[0]);
      } else {
        problem('$src depends on package "${dst.pathSegments[0]}", which is '
            'not found in allowedPackageDependencies');
      }
    }
    var srcSubpackage = subpackageForUri(src);
    if (srcSubpackage == null) return;
    var srcSubpackageRules = subpackageRules[srcSubpackage];
    if (srcSubpackageRules == null) {
      problem('$src is in subpackage "$srcSubpackage", which is not found in '
          'subpackageRules');
      return;
    }
    srcSubpackageRules.actuallyContainsFiles = true;
    var dstSubPackage = subpackageForUri(dst);
    if (dstSubPackage == null) return;
    if (dstSubPackage == srcSubpackage) return;
    if (srcSubpackageRules.allowedDependencies.contains(dstSubPackage)) {
      srcSubpackageRules.actualDependencies.add(dstSubPackage);
    } else {
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
    for (var package in allowedPackageDependencies) {
      if (!actualPackageDependencies.contains(package)) {
        problem('$package is listed in allowedPackageDependencies, '
            'but is not used');
      }
    }
    subpackageRules.forEach((subpackage, rule) {
      if (!rule.actuallyContainsFiles) {
        problem("$subpackage contains no files");
      }
      if (rule.allowSubdirs && !rule.actuallyHasSubdirs) {
        problem("$subpackage is allowed to have subdirectories, but doesn't");
      }
      for (var dep in rule.allowedDependencies
          .toSet()
          .difference(rule.actualDependencies)) {
        problem("$subpackage lists $dep as a dependency, but doesn't use it");
      }
    });
    return problemsReported ? 1 : 0;
  }

  /// Determines which subpackage [src] is in.
  ///
  /// If [src] is not part of the front end, `null` is returned.
  String subpackageForUri(Uri src) {
    if (src.scheme != 'package') return null;
    if (src.pathSegments[0] != 'front_end') return null;
    var pathWithLib = 'lib/${src.pathSegments.skip(1).join('/')}';
    String subpackage;
    String pathWithinSubpackage;
    for (var subpackagePath in subpackageRules.keys) {
      var subpackagePathWithSlash = '$subpackagePath/';
      if (pathWithLib.startsWith(subpackagePathWithSlash) &&
          (subpackage == null || subpackage.length < subpackagePath.length)) {
        subpackage = subpackagePath;
        pathWithinSubpackage =
            pathWithLib.substring(subpackagePathWithSlash.length);
      }
    }
    if (subpackage == null) {
      problem('Uri $src is inside package:front_end but is not in any known '
          'subpackage');
    } else if (pathWithinSubpackage.contains('/')) {
      if (subpackageRules[subpackage].allowSubdirs) {
        subpackageRules[subpackage].actuallyHasSubdirs = true;
      } else {
        problem('Uri $src is in a subfolder of $subpackage, but that '
            'subpackage does not allow dart files in subdirectories.');
      }
    }
    return subpackage;
  }
}
