// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/workspace.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:package_config/packages.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/**
 * Instances of the class `PackageBuildFileUriResolver` resolve `file` URI's by
 * first resolving file uri's in the expected way, and then by looking in the
 * corresponding generated directories.
 */
class PackageBuildFileUriResolver extends ResourceUriResolver {
  final PackageBuildWorkspace workspace;

  PackageBuildFileUriResolver(PackageBuildWorkspace workspace)
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
 * The [UriResolver] that can resolve `package` URIs in [PackageBuildWorkspace].
 */
class PackageBuildPackageUriResolver extends UriResolver {
  final PackageBuildWorkspace _workspace;
  final UriResolver _normalUriResolver;
  final Context _context;

  /**
   * The cache of absolute [Uri]s to [Source]s mappings.
   */
  final Map<Uri, Source> _sourceCache = new HashMap<Uri, Source>();

  PackageBuildPackageUriResolver(
      PackageBuildWorkspace workspace, this._normalUriResolver)
      : _workspace = workspace,
        _context = workspace.provider.pathContext;

  @override
  Source resolveAbsolute(Uri _ignore, [Uri uri]) {
    uri ??= _ignore;
    return _sourceCache.putIfAbsent(uri, () {
      if (uri.scheme != 'package') {
        return null;
      }

      Source basicResolverSource = _normalUriResolver.resolveAbsolute(uri);
      if (basicResolverSource != null && basicResolverSource.exists()) {
        return basicResolverSource;
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

      File file = _workspace.builtFile(
          _workspace.builtPackageSourcePath(filePath), packageName);
      if (file != null && file.exists) {
        return file.createSource(uri);
      }
      return basicResolverSource;
    });
  }

  @override
  Uri restoreAbsolute(Source source) {
    Context context = _workspace.provider.pathContext;
    String path = source.fullName;

    if (context.isWithin(_workspace.root, path)) {
      String relative = context.relative(path, from: _workspace.root);
      List<String> components = context.split(relative);
      if (components.length > 4 &&
          components[0] == 'build' &&
          components[1] == 'generated' &&
          components[3] == 'lib') {
        String packageName = components[2];
        String pathInLib = components.skip(4).join('/');
        return Uri.parse('package:$packageName/$pathInLib');
      }
    }
    return source.uri;
  }
}

/**
 * Information about a package:build workspace.
 */
class PackageBuildWorkspace extends Workspace {
  /**
   * The name of the directory that identifies the root of the workspace. Note,
   * the presence of this file does not show package:build is used. For that,
   * the subdirectory [_dartToolBuildName] must exist. A `pub` subdirectory
   * will usually exist in non-package:build projects too.
   */
  static const String _dartToolRootName = '.dart_tool';

  /**
   * The name of the subdirectory in [_dartToolName] that distinguishes projects
   * built with package:build.
   */
  static const String _dartToolBuildName = 'build';

  /**
   * We use pubspec.yaml to get the package name to be consistent with how
   * package:build does it.
   */
  static const String _pubspecName = 'pubspec.yaml';

  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider provider;

  /**
   * The absolute workspace root path (the directory containing the `.dart_tool`
   * directory).
   */
  final String root;

  /**
   * The name of the package under development as defined in pubspec.yaml. This
   * matches the behavior of package:build.
   */
  final String projectPackageName;

  final ContextBuilder _builder;

  /**
   * The map of package locations indexed by package name.
   *
   * This is a cached field.
   */
  Map<String, List<Folder>> _packageMap;

  /**
   * The package location strategy.
   *
   * This is a cached field.
   */
  Packages _packages;

  PackageBuildWorkspace._(
      this.provider, this.root, this.projectPackageName, this._builder);

  @override
  Map<String, List<Folder>> get packageMap {
    _packageMap ??= _builder.convertPackagesToMap(packages);
    return _packageMap;
  }

  Packages get packages {
    _packages ??= _builder.createPackageMap(root);
    return _packages;
  }

  @override
  UriResolver get packageUriResolver => new PackageBuildPackageUriResolver(
      this, new PackageMapUriResolver(provider, packageMap));

  /**
   * For some package file, which may or may not be a package source (it could
   * be in `bin/`, `web/`, etc), find where its built counterpart will exist if
   * its a generated source.
   *
   * To get a [builtPath] for a package source file to use in this method,
   * use [builtPackageSourcePath]. For `bin/`, `web/`, etc, it must be relative
   * to the project root.
   */
  File builtFile(String builtPath, String packageName) {
    if (!packageMap.containsKey(packageName)) {
      return null;
    }
    String path = context.join(
        root, _dartToolRootName, 'build', 'generated', packageName, builtPath);
    return provider.getFile(path);
  }

  /**
   * Unlike the way that sources are resolved against `.packages` (if foo points
   * to folder bar, then `foo:baz.dart` is found at `bar/baz.dart`), the built
   * sources for a package require the `lib/` prefix first. This is because
   * `bin/`, `web/`, and `test/` etc can all be built as well. This method
   * exists to give a name to that prefix processing step.
   */
  String builtPackageSourcePath(String path) {
    assert(context.isRelative(path));
    return context.join('lib', path);
  }

  @override
  SourceFactory createSourceFactory(DartSdk sdk) {
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(new DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(new PackageBuildFileUriResolver(this));
    return new SourceFactory(resolvers, packages, provider);
  }

  /**
   * Return the file with the given [path], looking first into directories for
   * source files, and then in the generated directory
   * `.dart_tool/build/generated/$projectPackageName/$FILE`. The file in the
   * workspace root is returned even if it does not exist. Return `null` if the
   * given [path] is not in the workspace [root].
   */
  File findFile(String path) {
    assert(context.isAbsolute(path));
    try {
      final String builtPath = context.relative(path, from: root);
      final File file = builtFile(builtPath, projectPackageName);

      if (file.exists) {
        return file;
      }

      return provider.getFile(path);
    } catch (_) {
      return null;
    }
  }

  /**
   * Find the package:build workspace that contains the given [path].
   *
   * Return `null` if the path is not in a package:build workspace.
   */
  static PackageBuildWorkspace find(
      ResourceProvider provider, String path, ContextBuilder builder) {
    Context context = provider.pathContext;

    // Ensure that the path is absolute and normalized.
    if (!context.isAbsolute(path)) {
      throw new ArgumentError('Not an absolute path: $path');
    }
    path = context.normalize(path);

    Folder folder = provider.getFolder(path);
    while (true) {
      Folder parent = folder.parent;
      if (parent == null) {
        return null;
      }

      final File pubspec = folder.getChildAssumingFile(_pubspecName);
      final Folder dartToolDir =
          folder.getChildAssumingFolder(_dartToolRootName);
      final Folder dartToolBuildDir =
          dartToolDir.getChildAssumingFolder(_dartToolBuildName);

      // Found the .dart_tool file, that's our project root. We also require a
      // pubspec, to know the package name that package:build will assume.
      if (dartToolBuildDir.exists && pubspec.exists) {
        try {
          final yaml = loadYaml(pubspec.readAsStringSync());
          return new PackageBuildWorkspace._(
              provider, folder.path, yaml['name'], builder);
        } on Exception {}
      }

      // Go up the folder.
      folder = parent;
    }
  }
}
