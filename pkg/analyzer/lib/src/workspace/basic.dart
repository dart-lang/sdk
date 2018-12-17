// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:package_config/packages.dart';

/**
 * Information about a default Dart workspace.
 */
class BasicWorkspace extends Workspace {
  /**
   * The [ResourceProvider] by which paths are converted into [Resource]s.
   */
  final ResourceProvider provider;

  /**
   * The absolute workspace root path.
   */
  final String root;

  final ContextBuilder _builder;

  Map<String, List<Folder>> _packageMap;

  Packages _packages;

  /**
   * The singular package in this workspace.
   *
   * Each basic workspace is itself one package.
   */
  BasicWorkspacePackage _theOnlyPackage;

  BasicWorkspace._(this.provider, this.root, this._builder);

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
  UriResolver get packageUriResolver =>
      new PackageMapUriResolver(provider, packageMap);

  @override
  SourceFactory createSourceFactory(DartSdk sdk, SummaryDataStore summaryData) {
    if (summaryData != null) {
      throw new UnsupportedError(
          'Summary files are not supported in a basic workspace.');
    }
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(new DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(new ResourceUriResolver(provider));
    return new SourceFactory(resolvers, packages, provider);
  }

  @override
  WorkspacePackage findPackageFor(String filePath) {
    final Folder folder = provider.getFolder(filePath);
    if (provider.pathContext.isWithin(root, folder.path)) {
      _theOnlyPackage ??= new BasicWorkspacePackage(root, this);
      return _theOnlyPackage;
    } else {
      return null;
    }
  }

  /**
   * Find the basic workspace that contains the given [path].
   */
  static BasicWorkspace find(
      ResourceProvider provider, String path, ContextBuilder builder) {
    Resource resource = provider.getResource(path);
    if (resource is File) {
      path = resource.parent.path;
    }
    return new BasicWorkspace._(provider, path, builder);
  }
}

/**
 * Information about a package defined in a _BasicWorkspace.
 *
 * Separate from [Packages] or package maps, this class is designed to simply
 * understand whether arbitrary file paths represent libraries declared within
 * a given package in a _BasicWorkspace.
 */
class BasicWorkspacePackage extends WorkspacePackage {
  final String root;

  final BasicWorkspace workspace;

  BasicWorkspacePackage(this.root, this.workspace);

  @override
  bool contains(String path) {
    // There is a 1-1 relationship between _BasicWorkspaces and
    // _BasicWorkspacePackages. If a file is in a package's workspace,
    // then it is in the package as well.
    return workspace.provider.pathContext.isWithin(root, path);
  }
}
