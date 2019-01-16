// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
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

/// An abstract class for simple workspaces which do not feature any build
/// artifacts or generated files.
///
/// The [packageMap] and [packageUrlResolver] are simple derivations from the
/// [ContextBuilder] and [ResourceProvider] required for the class.
abstract class SimpleWorkspace extends Workspace {
  /// The [ResourceProvider] by which paths are converted into [Resource]s.
  final ResourceProvider provider;

  /// The absolute workspace root path.
  final String root;

  final ContextBuilder _builder;

  Map<String, List<Folder>> _packageMap;

  Packages _packages;

  SimpleWorkspace(this.provider, this.root, this._builder);

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
          'Summary files are not supported in a Pub workspace.');
    }
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(new DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(new ResourceUriResolver(provider));
    return new SourceFactory(resolvers, packages, provider);
  }
}
