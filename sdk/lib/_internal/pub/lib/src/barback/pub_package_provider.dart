// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.pub_package_provider;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../package_graph.dart';

/// An implementation of barback's [PackageProvider] interface so that barback
/// can find assets within pub packages.
class PubPackageProvider implements PackageProvider {
  final PackageGraph _graph;

  PubPackageProvider(this._graph);

  Iterable<String> get packages => _graph.packages.keys;

  Future<Asset> getAsset(AssetId id) {
    var file = path.join(_graph.packages[id.package].dir, id.path);
    return new Future.value(new Asset.fromPath(id, file));
  }
}
