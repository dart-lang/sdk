// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.bazel;

import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';

/**
 * Instances of the class `BazelFileUriResolver` resolve `file` URI's by first
 * resolving file uri's in the expected way, and then by looking in the
 * corresponding generated directories.
 */
class BazelFileUriResolver extends ResourceUriResolver {
  /**
   * The Bazel workspace directory.
   */
  final Folder _workspaceDir;

  /**
   * The build directories that relative `file` URI's should use to resolve
   * relative URIs.
   */
  final List<Folder> _buildDirectories;

  BazelFileUriResolver(
      ResourceProvider provider, this._workspaceDir, this._buildDirectories)
      : super(provider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!ResourceUriResolver.isFileUri(uri)) {
      return null;
    }

    File uriFile = provider.getFile(provider.pathContext.fromUri(uri));
    if (uriFile.exists) {
      return uriFile.createSource(actualUri ?? uri);
    }

    String relativeFromWorkspaceDir = _getPathFromWorkspaceDir(uri);
    if (_buildDirectories.isEmpty || relativeFromWorkspaceDir.isEmpty) {
      return null;
    }

    for (Folder buildDir in _buildDirectories) {
      File file = buildDir.getChildAssumingFile(relativeFromWorkspaceDir);
      if (file.exists) {
        return file.createSource(actualUri ?? uri);
      }
    }
    return null;
  }

  String _getPathFromWorkspaceDir(Uri uri) {
    String uriPath = uri.path;
    String workspacePath = _workspaceDir.path;

    if (uriPath.startsWith(workspacePath) &&
        workspacePath.length < uriPath.length) {
      return uriPath.substring(workspacePath.length + 1);
    }
    return '';
  }
}
