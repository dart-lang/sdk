// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/workspace/simple.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:analyzer/src/context/packages.dart';

/// Information about a Pub workspace.
class PubWorkspace extends SimpleWorkspace {
  /// The name of the file that identifies the root of the workspace.
  static const String _pubspecName = 'pubspec.yaml';

  /// The singular package in this workspace.
  ///
  /// Each Pub workspace is itself one package.
  PubWorkspacePackage _theOnlyPackage;

  PubWorkspace._(
    ResourceProvider provider,
    Map<String, List<Folder>> packageMap,
    String root,
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

      if (folder.getChildAssumingFile(_pubspecName).exists) {
        // Found the pubspec.yaml file; this is our root.
        String root = folder.path;
        return PubWorkspace._(provider, packageMap, root);
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

  @override
  final PubWorkspace workspace;

  PubWorkspacePackage(this.root, this.workspace);

  @override
  bool contains(Source source) {
    String filePath = filePathFromSource(source);
    if (filePath == null) return false;
    // There is a 1-1 relationship between [PubWorkspace]s and
    // [PubWorkspacePackage]s. If a file is in a package's workspace, then it
    // is in the package as well.
    return workspace.provider.pathContext.isWithin(root, filePath);
  }
}
