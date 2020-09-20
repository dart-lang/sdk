// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/workspace/simple.dart';
import 'package:analyzer/src/workspace/workspace.dart';

/// Information about a Pub workspace.
class PubWorkspace extends SimpleWorkspace {
  /// The name of the file that identifies the root of the workspace.
  static const String _pubspecName = 'pubspec.yaml';

  /// The singular package in this workspace.
  ///
  /// Each Pub workspace is itself one package.
  PubWorkspacePackage _theOnlyPackage;

  /// The associated pubspec file.
  final File _pubspecFile;

  PubWorkspace._(
    ResourceProvider provider,
    Map<String, List<Folder>> packageMap,
    String root,
    this._pubspecFile,
  ) : super(provider, packageMap, root);

  @override
  WorkspacePackage findPackageFor(String filePath) {
    final Folder folder = provider.getFolder(filePath);
    if (provider.pathContext.isWithin(root, folder.path)) {
      _theOnlyPackage ??= PubWorkspacePackage(root, this);
      return _theOnlyPackage;
    } else {
      return null;
    }
  }

  /// Find the pub workspace that contains the given [path].
  static PubWorkspace find(
    ResourceProvider provider,
    Map<String, List<Folder>> packageMap,
    String filePath,
  ) {
    Resource resource = provider.getResource(filePath);
    if (resource is File) {
      filePath = resource.parent.path;
    }
    Folder folder = provider.getFolder(filePath);
    while (true) {
      Folder parent = folder.parent;
      if (parent == null) {
        return null;
      }

      var pubspec = folder.getChildAssumingFile(_pubspecName);
      if (pubspec.exists) {
        // Found the pubspec.yaml file; this is our root.
        String root = folder.path;
        return PubWorkspace._(provider, packageMap, root, pubspec);
      }

      // Go up a folder.
      folder = parent;
    }
  }
}

/// Information about a package defined in a [PubWorkspace].
///
/// Separate from [Packages] or package maps, this class is designed to simply
/// understand whether arbitrary file paths represent libraries declared within
/// a given package in a [PubWorkspace].
class PubWorkspacePackage extends WorkspacePackage {
  @override
  final String root;

  Pubspec _pubspec;

  /// A flag to indicate if we've tried to parse the pubspec.
  bool _parsedPubspec = false;

  @override
  final PubWorkspace workspace;

  PubWorkspacePackage(this.root, this.workspace);

  /// Get the associated parsed [Pubspec], or `null` if there was an error in
  /// reading or parsing.
  Pubspec get pubspec {
    if (!_parsedPubspec) {
      _parsedPubspec = true;
      try {
        final content = workspace._pubspecFile.readAsStringSync();
        _pubspec = Pubspec.parse(content);
      } catch (_) {
        // Pubspec will be null.
      }
    }
    return _pubspec;
  }

  @override
  bool contains(Source source) {
    String filePath = filePathFromSource(source);
    if (filePath == null) return false;
    // There is a 1-1 relationship between [PubWorkspace]s and
    // [PubWorkspacePackage]s. If a file is in a package's workspace, then it
    // is in the package as well.
    return workspace.provider.pathContext.isWithin(root, filePath);
  }

  @override
  Map<String, List<Folder>> packagesAvailableTo(String libraryPath) {
    // TODO(brianwilkerson) Consider differentiating based on whether the
    //  [libraryPath] is inside the `lib` directory.
    return workspace.packageMap;
  }

  @override

  /// A Pub package's public API consists of libraries found in the top-level
  /// "lib" directory, and any subdirectories, excluding the "src" directory
  /// just inside the top-level "lib" directory.
  bool sourceIsInPublicApi(Source source) {
    var filePath = filePathFromSource(source);
    if (filePath == null) return false;
    var libFolder = workspace.provider.pathContext.join(root, 'lib');
    if (!workspace.provider.pathContext.isWithin(libFolder, filePath)) {
      return false;
    }
    var libSrcFolder = workspace.provider.pathContext.join(root, 'lib', 'src');
    return !workspace.provider.pathContext.isWithin(libSrcFolder, filePath);
  }
}
