// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/pubspec.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/workspace/pub.dart';

abstract class FileStateFilter {
  /// Return a filter of files that can be accessed by the [file].
  factory FileStateFilter(FileState file) {
    var workspacePackage = file.workspacePackage;
    if (workspacePackage is PubPackage) {
      return _PubFilter(workspacePackage, file.path);
    } else {
      return _AnyFilter();
    }
  }

  /// Whether files from every package can be accessed.
  bool get includesAllPackages;

  bool shouldInclude(FileState file);

  /// Whether files in the package with the [packageName] can be accessed.
  bool shouldIncludePackage(String packageName);

  /// Whether files under `lib/src` in the package with the [packageName] can
  /// be accessed.
  bool shouldIncludePackageSrc(String packageName);

  static bool shouldIncludeSdk(FileState file, FileUriProperties uri) {
    assert(identical(file.uriProperties, uri));
    assert(uri.isDart);

    // Exclude internal libraries.
    if (uri.isDartInternal) {
      return false;
    }

    // Exclude "soft deprecated" libraries.
    if (const {
      'dart:html',
      'dart:indexed_db',
      'dart:js',
      'dart:js_util',
      'dart:svg',
      'dart:web_audio',
      'dart:web_gl',
    }.contains(file.uriStr)) {
      return false;
    }

    return true;
  }
}

class _AnyFilter implements FileStateFilter {
  @override
  int get hashCode => 0;

  @override
  bool get includesAllPackages => true;

  @override
  bool operator ==(Object other) => other is _AnyFilter;

  @override
  bool shouldInclude(FileState file) {
    var uri = file.uriProperties;
    if (uri.isDart) {
      return FileStateFilter.shouldIncludeSdk(file, uri);
    }
    return true;
  }

  @override
  bool shouldIncludePackage(String packageName) => true;

  @override
  bool shouldIncludePackageSrc(String packageName) => true;
}

class _PubFilter implements FileStateFilter {
  final PubPackage targetPackage;
  final String? targetPackageName;

  /// "Friends of `package:analyzer` see analyzer implementation libraries in
  /// completions.
  final bool targetPackageIsFriendOfAnalyzer;

  /// Whether the target can use dev dependencies.
  ///
  /// Pub requires that files in `lib` and `bin` use only non-dev dependencies,
  /// because dependent packages use these files without resolving our dev
  /// dependencies.
  final bool canUseDevDependencies;

  /// The folder containing the target package's files that are not under
  /// `lib`, so have `file:` URIs, and can be suggested to the target.
  ///
  /// `null` for targets in `lib`: they can only use `package:` URIs.
  /// For targets in `bin`, this is the `bin` folder: a file elsewhere (e.g.
  /// under `tool`) could bring in a dev dependency, which pub does not see,
  /// because it validates only `package:` imports in `lib` and `bin`.
  /// Otherwise, this is the package root.
  final Folder? fileUriFolder;

  final Set<String> dependencies;

  factory _PubFilter(PubPackage package, String path) {
    var packageRootFolder = package.root;
    var binFolder = packageRootFolder.getFolder('bin');

    bool canUseDevDependencies;
    Folder? fileUriFolder;
    if (packageRootFolder.getFolder('lib').contains(path)) {
      canUseDevDependencies = false;
      fileUriFolder = null;
    } else if (binFolder.contains(path)) {
      canUseDevDependencies = false;
      fileUriFolder = binFolder;
    } else {
      canUseDevDependencies = true;
      fileUriFolder = packageRootFolder;
    }

    var dependencies = <String>{};
    var pubspec = package.pubspec;
    if (pubspec != null) {
      dependencies.addAll(pubspec.dependencies.names);
      if (canUseDevDependencies) {
        dependencies.addAll(pubspec.devDependencies.names);
      }
    }

    var packageName = pubspec?.name?.value.text;

    return _PubFilter._(
      targetPackage: package,
      targetPackageName: packageName,
      targetPackageIsFriendOfAnalyzer:
          packageName == 'analysis_server' || packageName == 'linter',
      canUseDevDependencies: canUseDevDependencies,
      fileUriFolder: fileUriFolder,
      dependencies: dependencies,
    );
  }

  _PubFilter._({
    required this.targetPackage,
    required this.targetPackageName,
    required this.targetPackageIsFriendOfAnalyzer,
    required this.canUseDevDependencies,
    required this.fileUriFolder,
    required this.dependencies,
  });

  @override
  int get hashCode => Object.hash(
    targetPackage.root,
    targetPackage.pubspecContent,
    canUseDevDependencies,
    fileUriFolder,
  );

  @override
  bool get includesAllPackages => false;

  @override
  bool operator ==(Object other) {
    return other is _PubFilter &&
        other.targetPackage.root == targetPackage.root &&
        other.targetPackage.pubspecContent == targetPackage.pubspecContent &&
        other.canUseDevDependencies == canUseDevDependencies &&
        other.fileUriFolder == fileUriFolder;
  }

  @override
  bool shouldInclude(FileState file) {
    var uri = file.uriProperties;
    if (uri.isDart) {
      return FileStateFilter.shouldIncludeSdk(file, uri);
    }

    // Files with `file:` URIs are suggested only from this package, and only
    // under `fileUriFolder`. Nested packages are inside the package root, but
    // are different packages.
    var packageName = uri.packageName;
    if (packageName == null) {
      var filePackage = file.workspacePackage;
      return filePackage is PubPackage &&
          filePackage.root == targetPackage.root &&
          (fileUriFolder?.contains(file.path) ?? false);
    }

    return shouldIncludePackage(packageName) &&
        (!uri.isSrc || shouldIncludePackageSrc(packageName));
  }

  @override
  bool shouldIncludePackage(String packageName) {
    return packageName == targetPackageName ||
        dependencies.contains(packageName) ||
        (targetPackageIsFriendOfAnalyzer && packageName == 'analyzer');
  }

  @override
  bool shouldIncludePackageSrc(String packageName) {
    return packageName == targetPackageName ||
        (targetPackageIsFriendOfAnalyzer && packageName == 'analyzer');
  }
}

extension on PubspecDependencyList? {
  List<String> get names {
    var self = this;
    if (self == null) {
      return const [];
    } else {
      return self.map((dependency) => dependency.name?.text).nonNulls.toList();
    }
  }
}
