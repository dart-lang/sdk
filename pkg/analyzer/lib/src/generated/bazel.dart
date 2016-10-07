// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.bazel;

import 'dart:collection';
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
 * The [UriResolver] that can resolve `package` URIs in [BazelWorkspace].
 */
class BazelPackageUriResolver extends UriResolver {
  final BazelWorkspace _workspace;
  final Context _context;

  /**
   * The cache of absolute [Uri]s to [Source]s mappings.
   */
  final Map<Uri, Source> _sourceCache = new HashMap<Uri, Source>();

  BazelPackageUriResolver(BazelWorkspace workspace)
      : _workspace = workspace,
        _context = workspace.provider.pathContext;

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return _sourceCache.putIfAbsent(uri, () {
      if (uri.scheme != 'package') {
        return null;
      }
      String uriPath = uri.path;
      int slash = uriPath.indexOf('/');

      // If the path either starts with a slash or has no slash, it is invalid.
      if (slash < 1) {
        return null;
      }

      String packageName = uriPath.substring(0, slash);
      String fileUriPart = uriPath.substring(slash + 1);
      String filePath = fileUriPart.replaceAll('/', _context.separator);

      if (packageName.indexOf('.') == -1) {
        String path =
            _context.join('third_party', 'dart', packageName, 'lib', filePath);
        File file = _workspace.getFile(path);
        return file?.createSource(uri);
      } else {
        String packagePath = packageName.replaceAll('.', _context.separator);
        String path =
            _context.join(_workspace.root, packagePath, 'lib', filePath);
        File file = _workspace.findFile(path);
        return file?.createSource(uri);
      }
    });
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
   * The absolute path to the optional read only workspace root, in the
   * `READONLY` folder if a git-based workspace, or `null`.
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
      if (genfiles != null) {
        File file = provider.getFile(context.join(genfiles, relative));
        if (file.exists) {
          return file;
        }
      }
      // bin
      if (bin != null) {
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

  /**
   * Return the file for the given [pathInWorkspace]. The file is returned even
   * if it does not exist.
   */
  File getFile(String pathInWorkspace) {
    return provider.getFile(provider.pathContext.join(root, pathInWorkspace));
  }

  /**
   * Find the Bazel workspace that contains the given [path].
   *
   * Return `null` if a workspace markers, such as the `WORKSPACE` file, or
   * the sibling `READONLY` folder cannot be found.
   *
   * Return `null` if the workspace does not have `bazel-genfiles` or
   * `blaze-genfiles` folders, so we don't know where to search generated files.
   *
   * Return `null` if there is a folder 'foo' with the sibling `READONLY`
   * folder, but there is corresponding folder 'foo' in `READONLY`, i.e. the
   * corresponding readonly workspace root.
   */
  static BazelWorkspace find(ResourceProvider provider, String path) {
    Context context = provider.pathContext;

    // Ensure that the path is absolute and normalized.
    if (!context.isAbsolute(path)) {
      throw new ArgumentError('not absolute: $path');
    }
    path = context.normalize(path);

    Folder folder = provider.getFolder(path);
    while (true) {
      Folder parent = folder.parent;
      if (parent == null) {
        return null;
      }

      // Found the READONLY folder, might be a git-based workspace.
      Folder readonlyFolder = parent.getChildAssumingFolder(_READONLY);
      if (readonlyFolder.exists) {
        String root = folder.path;
        String readonlyRoot =
            context.join(readonlyFolder.path, folder.shortName);
        if (provider.getFolder(readonlyRoot).exists) {
          String symlinkPrefix = _findSymlinkPrefix(provider, root);
          if (symlinkPrefix != null) {
            return new BazelWorkspace._(
                provider,
                root,
                readonlyRoot,
                context.join(root, '$symlinkPrefix-bin'),
                context.join(root, '$symlinkPrefix-genfiles'));
          }
        }
      }

      // Found the WORKSPACE file, must be a non-git workspace.
      if (folder.getChildAssumingFile(_WORKSPACE).exists) {
        String root = folder.path;
        String symlinkPrefix = _findSymlinkPrefix(provider, root);
        if (symlinkPrefix == null) {
          return null;
        }
        return new BazelWorkspace._(
            provider,
            root,
            null,
            context.join(root, '$symlinkPrefix-bin'),
            context.join(root, '$symlinkPrefix-genfiles'));
      }

      // Go up the folder.
      folder = parent;
    }
  }

  /**
   * Return the symlink prefix for folders `X-bin` or `X-genfiles` by probing
   * the internal `blaze-genfiles` and `bazel-genfiles`. Return `null` if
   * neither of the folders exists.
   */
  static String _findSymlinkPrefix(ResourceProvider provider, String root) {
    Context context = provider.pathContext;
    if (provider.getFolder(context.join(root, 'blaze-genfiles')).exists) {
      return 'blaze';
    }
    if (provider.getFolder(context.join(root, 'bazel-genfiles')).exists) {
      return 'bazel';
    }
    return null;
  }
}
