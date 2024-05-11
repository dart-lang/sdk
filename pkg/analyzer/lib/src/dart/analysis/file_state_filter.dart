// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/lint/pub.dart';
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

  bool shouldInclude(FileState file);

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
      'dart:web_gl'
    }.contains(file.uriStr)) {
      return false;
    }

    return true;
  }
}

class _AnyFilter implements FileStateFilter {
  @override
  bool shouldInclude(FileState file) {
    var uri = file.uriProperties;
    if (uri.isDart) {
      return FileStateFilter.shouldIncludeSdk(file, uri);
    }
    return true;
  }
}

class _PubFilter implements FileStateFilter {
  final PubPackage targetPackage;
  final String? targetPackageName;

  /// "Friends of `package:analyzer` see analyzer implementation libraries in
  /// completions.
  final bool targetPackageIsFriendOfAnalyzer;
  final bool targetInLibOrEntryPoint;
  final Set<String> dependencies;

  factory _PubFilter(PubPackage package, String path) {
    var packageRootFolder = package.workspace.provider.getFolder(package.root);
    var inLibOrEntryPoint =
        packageRootFolder.getChildAssumingFolder('lib').contains(path) ||
            packageRootFolder.getChildAssumingFolder('bin').contains(path) ||
            packageRootFolder.getChildAssumingFolder('web').contains(path);

    var dependencies = <String>{};
    var pubspec = package.pubspec;
    if (pubspec != null) {
      dependencies.addAll(pubspec.dependencies.names);
      if (!inLibOrEntryPoint) {
        dependencies.addAll(pubspec.devDependencies.names);
      }
    }

    var packageName = pubspec?.name?.value.text;

    return _PubFilter._(
      targetPackage: package,
      targetPackageName: packageName,
      targetPackageIsFriendOfAnalyzer:
          packageName == 'analysis_server' || packageName == 'linter',
      targetInLibOrEntryPoint: inLibOrEntryPoint,
      dependencies: dependencies,
    );
  }

  _PubFilter._({
    required this.targetPackage,
    required this.targetPackageName,
    required this.targetPackageIsFriendOfAnalyzer,
    required this.targetInLibOrEntryPoint,
    required this.dependencies,
  });

  @override
  bool shouldInclude(FileState file) {
    var uri = file.uriProperties;
    if (uri.isDart) {
      return FileStateFilter.shouldIncludeSdk(file, uri);
    }

    // Normally only package URIs are available.
    // But outside of lib/ and entry points we allow any files of this package.
    var packageName = uri.packageName;
    if (packageName == null) {
      if (targetInLibOrEntryPoint) {
        return false;
      } else {
        var filePackage = file.workspacePackage;
        return filePackage is PubPackage &&
            filePackage.root == targetPackage.root;
      }
    }

    // Any `package:` library from the same package.
    if (packageName == targetPackageName) {
      return true;
    }

    // If not the same package, must be public.
    if (uri.isSrc) {
      // Special case access to `analyzer` to allow privileged access
      // from "friends" like `analysis_server` and `linter`.
      if (targetPackageIsFriendOfAnalyzer && packageName == 'analyzer') {
        return true;
      }
      return false;
    }

    return dependencies.contains(packageName);
  }
}

extension on PSDependencyList? {
  List<String> get names {
    var self = this;
    if (self == null) {
      return const [];
    } else {
      return self.map((dependency) => dependency.name?.text).nonNulls.toList();
    }
  }
}
