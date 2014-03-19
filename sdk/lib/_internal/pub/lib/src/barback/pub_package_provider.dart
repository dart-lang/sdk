// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.pub_package_provider;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../package_graph.dart';
import '../io.dart';

/// An implementation of barback's [PackageProvider] interface so that barback
/// can find assets within pub packages.
class PubPackageProvider implements PackageProvider {
  final PackageGraph _graph;
  final List<String> packages;

  PubPackageProvider(PackageGraph graph)
      : _graph = graph,
        packages = new List.from(graph.packages.keys)..add(r"$pub");

  Future<Asset> getAsset(AssetId id) {
    if (id.package != r'$pub') {
      var nativePath = path.fromUri(id.path);
      var file = path.join(_graph.packages[id.package].dir, nativePath);
      return new Future.value(new Asset.fromPath(id, file));
    }

    // "$pub" is a psuedo-package that allows pub's transformer-loading
    // infrastructure to share code with pub proper.
    var components = path.url.split(id.path);
    assert(components.isNotEmpty);
    assert(components.first == 'lib');
    components[0] = 'dart';
    var file = assetPath(path.joinAll(components));
    return new Future.value(new Asset.fromPath(id, file));
  }
}
