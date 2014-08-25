// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.pub_package_provider;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../io.dart';
import '../package_graph.dart';
import '../preprocess.dart';
import '../sdk.dart' as sdk;
import '../utils.dart';

/// An implementation of barback's [PackageProvider] interface so that barback
/// can find assets within pub packages.
class PubPackageProvider implements PackageProvider {
  final PackageGraph _graph;
  final List<String> packages;

  PubPackageProvider(PackageGraph graph, [Iterable<String> packages])
      : _graph = graph,
        packages = [r"$pub", r"$sdk"]
            ..addAll(packages == null ? graph.packages.keys : packages);

  Future<Asset> getAsset(AssetId id) {
    // "$pub" is a psuedo-package that allows pub's transformer-loading
    // infrastructure to share code with pub proper.
    if (id.package == r'$pub') {
      var components = path.url.split(id.path);
      assert(components.isNotEmpty);
      assert(components.first == 'lib');
      components[0] = 'dart';
      var file = assetPath(path.joinAll(components));

      // Barback may not be in the package graph if there are no user-defined
      // transformers being used at all. The "$pub" sources are still provided,
      // but will never be loaded.
      if (!_graph.packages.containsKey("barback")) {
        return new Future.value(new Asset.fromPath(id, file));
      }

      var versions = mapMap(_graph.packages,
          value: (_, package) => package.version);
      var contents = readTextFile(file);
      contents = preprocess(contents, versions, path.toUri(file));
      return new Future.value(new Asset.fromString(id, contents));
    }

    // "$sdk" is a pseudo-package that provides access to the Dart library
    // sources in the SDK. The dart2js transformer uses this to locate the Dart
    // sources for "dart:" libraries.
    if (id.package == r'$sdk') {
      // The asset path contains two "lib" entries. The first represent's pub's
      // concept that all public assets are in "lib". The second comes from the
      // organization of the SDK itself. Strip off the first. Leave the second
      // since dart2js adds it and expects it to be there.
      var parts = path.split(path.fromUri(id.path));
      assert(parts.isNotEmpty && parts[0] == 'lib');
      parts = parts.skip(1);

      var file = path.join(sdk.rootDirectory, path.joinAll(parts));
      return new Future.value(new Asset.fromPath(id, file));
    }

    var nativePath = path.fromUri(id.path);
    var file = path.join(_graph.packages[id.package].dir, nativePath);
    return new Future.value(new Asset.fromPath(id, file));
  }
}
