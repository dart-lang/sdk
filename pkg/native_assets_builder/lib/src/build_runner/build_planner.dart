// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:graphs/graphs.dart' as graphs;
import 'package:package_config/package_config.dart';

class NativeAssetsBuildPlanner {
  final PackageGraph packageGraph;
  final List<Package> packagesWithNativeAssets;
  final Uri dartExecutable;

  NativeAssetsBuildPlanner({
    required this.packageGraph,
    required this.packagesWithNativeAssets,
    required this.dartExecutable,
  });

  static Future<NativeAssetsBuildPlanner> fromRootPackageRoot({
    required Uri rootPackageRoot,
    required List<Package> packagesWithNativeAssets,
    required Uri dartExecutable,
  }) async {
    final result = await Process.run(
      dartExecutable.toFilePath(),
      [
        'pub',
        'deps',
        '--json',
      ],
      workingDirectory: rootPackageRoot.toFilePath(),
    );
    final packageGraph = PackageGraph.fromPubDepsJsonString(result.stdout);
    return NativeAssetsBuildPlanner(
      packageGraph: packageGraph,
      packagesWithNativeAssets: packagesWithNativeAssets,
      dartExecutable: dartExecutable,
    );
  }

  List<Package> plan() {
    final packageMap = {
      for (final package in packagesWithNativeAssets) package.name: package
    };
    final packagesToBuild = packageMap.keys.toSet();
    final stronglyConnectedComponents = packageGraph.computeStrongComponents();
    final result = <Package>[];
    for (final stronglyConnectedComponent in stronglyConnectedComponents) {
      final stronglyConnectedComponentWithNativeAssets = [
        for (final packageName in stronglyConnectedComponent)
          if (packagesToBuild.contains(packageName)) packageName
      ];
      if (stronglyConnectedComponentWithNativeAssets.length > 1) {
        throw Exception(
          'Cyclic dependency for native asset builds in the following '
          'packages: $stronglyConnectedComponent.',
        );
      } else if (stronglyConnectedComponentWithNativeAssets.length == 1) {
        result.add(
            packageMap[stronglyConnectedComponentWithNativeAssets.single]!);
      }
    }
    return result;
  }
}

class PackageGraph {
  final Map<String, List<String>> map;

  PackageGraph(this.map);

  /// Construct a graph from the JSON produced by `dart pub deps --json`.
  factory PackageGraph.fromPubDepsJsonString(String json) =>
      PackageGraph.fromPubDepsJson(jsonDecode(json) as Map<dynamic, dynamic>);

  /// Construct a graph from the JSON produced by `dart pub deps --json`.
  factory PackageGraph.fromPubDepsJson(Map<dynamic, dynamic> map) {
    final result = <String, List<String>>{};
    final packages = map['packages'] as List<dynamic>;
    for (final package in packages) {
      final package_ = package as Map<dynamic, dynamic>;
      final name = package_['name'] as String;
      final dependencies = (package_['dependencies'] as List<dynamic>)
          .whereType<String>()
          .toList();
      result[name] = dependencies;
    }
    return PackageGraph(result);
  }

  Iterable<String> neighborsOf(String vertex) => map[vertex] ?? [];

  Iterable<String> get vertices => map.keys;

  List<List<String>> computeStrongComponents() =>
      graphs.stronglyConnectedComponents(vertices, neighborsOf);
}
