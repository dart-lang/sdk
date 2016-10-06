// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.bazel;

import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart';

/**
 * Instances of the class `BazelFileUriResolver` resolve `file` URI's by first
 * resolving file uri's in the expected way, and then by looking in the
 * corresponding generated directories.
 */
class BazelFileUriResolver extends ResourceUriResolver {
  final BazelWorkspace workspace;

  BazelFileUriResolver(BazelWorkspace workspace)
      : workspace = workspace,
        super(workspace.provider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (!ResourceUriResolver.isFileUri(uri)) {
      return null;
    }
    String path = provider.pathContext.fromUri(uri);
    File file = workspace.findFile(path);
    if (file != null) {
      return file.createSource(actualUri ?? uri);
    }
    return null;
  }
}

/**
 * Information about a Bazel workspace.
 */
class BazelWorkspace {
  static const String _WORKSPACE = 'WORKSPACE';
  static const String _READONLY = 'READONLY';

  final ResourceProvider provider;

  /**
   * The absolute workspace root path.
   *
   * It contains the `WORKSPACE` file or its parent contains the `READONLY`
   * folder.
   */
  final String root;

  /**
   * The absolute path to the optional `READONLY` folder if a git-based
   * workspace, or `null`.
   */
  final String readonly;

  /**
   * The absolute path to the `bazel-bin` folder.
   */
  final String bin;

  /**
   * The absolute path to the `bazel-genfiles` folder.
   */
  final String genfiles;

  /**
   * Create a new Bazel workspace that contains the given [path].
   *
   * The [symlinkPrefix] is the prefix for names of symlinks like `bazel-bin`,
   * `bazel-genfiles`, etc.
   */
  factory BazelWorkspace(ResourceProvider provider, String path,
      {String symlinkPrefix: 'bazel', String readonlySuffix}) {
    Context context = provider.pathContext;

    // Ensure that the path is absolute and normalized.
    if (!context.isAbsolute(path)) {
      throw new ArgumentError('not absolute: $path');
    }
    path = context.normalize(path);

    Folder folder = provider.getFolder(path);
    while (true) {
      Folder parent = folder.parent;

      // Found the READONLY folder, must be a git-based workspace.
      if (readonlySuffix != null) {
        Folder readonlyFolder = parent.getChildAssumingFolder(_READONLY);
        if (parent != null && readonlyFolder.exists) {
          String root = folder.path;
          String readonly = readonlyFolder.path;
          return new BazelWorkspace._(
              provider,
              root,
              context.join(readonly, readonlySuffix),
              context.join(root, '$symlinkPrefix-bin'),
              context.join(root, '$symlinkPrefix-genfiles'));
        }
      }

      // Found the WORKSPACE file, must be a non-git workspace.
      if (folder.getChildAssumingFile(_WORKSPACE).exists) {
        String root = folder.path;
        return new BazelWorkspace._(
            provider,
            root,
            null,
            context.join(root, '$symlinkPrefix-bin'),
            context.join(root, '$symlinkPrefix-genfiles'));
      }

      // Go up the folder.
      folder = parent;
      if (folder == null) {
        return null;
      }
    }
  }

  BazelWorkspace._(
      this.provider, this.root, this.readonly, this.bin, this.genfiles);

  /**
   * Return the file with the given [absolutePath], looking first into
   * directories for generated files: `bazel-bin` and `bazel-genfiles`, and
   * then into the workspace root. The file in the workspace root is returned
   * even if it does not exist. Return `null` if the given [absolutePath] is
   * not in the workspace [root].
   */
  File findFile(String absolutePath) {
    Context context = provider.pathContext;
    try {
      String relative = context.relative(absolutePath, from: root);
      // genfiles
      {
        File file = provider.getFile(context.join(genfiles, relative));
        if (file.exists) {
          return file;
        }
      }
      // bin
      {
        File file = provider.getFile(context.join(bin, relative));
        if (file.exists) {
          return file;
        }
      }
      // READONLY
      if (readonly != null) {
        File file = provider.getFile(context.join(readonly, relative));
        if (file.exists) {
          return file;
        }
      }
      // Not generated, return the default one.
      return provider.getFile(absolutePath);
    } catch (_) {
      return null;
    }
  }
}
