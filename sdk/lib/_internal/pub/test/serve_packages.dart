// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serve_packages;

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:yaml/yaml.dart';

import '../lib/src/io.dart';
import '../lib/src/utils.dart';
import '../lib/src/version.dart';
import 'descriptor.dart' as d;
import 'test_pub.dart';

/// The [d.DirectoryDescriptor] describing the server layout of `/api/packages`
/// on the test server.
///
/// This contains metadata for packages that are being served via
/// [servePackages]. It's `null` if [servePackages] has not yet been called for
/// this test.
d.DirectoryDescriptor _servedApiPackageDir;

/// The [d.DirectoryDescriptor] describing the server layout of `/packages` on
/// the test server.
///
/// This contains the tarballs for packages that are being served via
/// [servePackages]. It's `null` if [servePackages] has not yet been called for
/// this test.
d.DirectoryDescriptor _servedPackageDir;

/// The current [PackageServerBuilder] that a user uses to specify which package
/// to serve.
///
/// This is preserved over multiple calls to [servePackages] within the same
/// test so that additional packages can be added.
PackageServerBuilder _builder;

/// Creates an HTTP server that replicates the structure of pub.dartlang.org.
///
/// Calls [callback] with a [PackageServerBuilder] that's used to specify
/// which packages to serve.
///
/// If [replace] is false, subsequent calls to [servePackages] will add to the
/// set of packages that are being served. Previous packages will continue to be
/// served. Otherwise, the previous packages will no longer be served.
void servePackages(void callback(PackageServerBuilder builder),
    {bool replace: false}) {
  if (_servedPackageDir == null) {
    _builder = new PackageServerBuilder();
    _servedApiPackageDir = d.dir('packages', []);
    _servedPackageDir = d.dir('packages', []);
    serve([
      d.dir('api', [_servedApiPackageDir]),
      _servedPackageDir
    ]);

    currentSchedule.onComplete.schedule(() {
      _builder = null;
      _servedApiPackageDir = null;
      _servedPackageDir = null;
    }, 'cleaning up served packages');
  }

  schedule(() {
    if (replace) _builder = new PackageServerBuilder();
    callback(_builder);
    return _builder._await().then((resolvedPubspecs) {
      _servedApiPackageDir.contents.clear();
      _servedPackageDir.contents.clear();
      _builder._packages.forEach((name, versions) {
        _servedApiPackageDir.contents.addAll([
          d.file('$name', JSON.encode({
            'name': name,
            'uploaders': ['nweiz@google.com'],
            'versions': versions.map((version) =>
                packageVersionApiMap(version.pubspec)).toList()
          })),
          d.dir(name, [
            d.dir('versions', versions.map((version) {
              return d.file(version.version.toString(), JSON.encode(
                  packageVersionApiMap(version.pubspec, full: true)));
            }))
          ])
        ]);

        _servedPackageDir.contents.add(d.dir(name, [
          d.dir('versions', versions.map((version) =>
              d.tar('${version.version}.tar.gz', version.contents)))
        ]));
      });
    });
  }, 'initializing the package server');
}

/// Like [servePackages], but instead creates an empty server with no packages
/// registered.
///
/// This will always replace a previous server.
void serveNoPackages() => servePackages((_) {}, replace: true);

/// A builder for specifying which packages should be served by [servePackages].
class PackageServerBuilder {
  /// A map from package names to a list of concrete packages to serve.
  final _packages = new Map<String, List<_ServedPackage>>();

  /// A group of futures from [serve] calls.
  ///
  /// This should be accessed by calling [_awair].
  var _futures = new FutureGroup();

  /// Specifies that a package named [name] with [version] should be served.
  ///
  /// If [deps] is passed, it's used as the "dependencies" field of the pubspec.
  /// If [pubspec] is passed, it's used as the rest of the pubspec. Either of
  /// these may recursively contain Futures.
  ///
  /// If [contents] is passed, it's used as the contents of the package. By
  /// default, a package just contains a dummy lib directory.
  void serve(String name, String version, {Map deps, Map pubspec,
      Iterable<d.Descriptor> contents}) {
    _futures.add(Future.wait([
      awaitObject(deps),
      awaitObject(pubspec)
    ]).then((pair) {
      var resolvedDeps = pair.first;
      var resolvedPubspec = pair.last;

      var pubspecFields = {
        "name": name,
        "version": version
      };
      if (resolvedPubspec != null) pubspecFields.addAll(resolvedPubspec);
      if (resolvedDeps != null) pubspecFields["dependencies"] = resolvedDeps;

      if (contents == null) contents = [d.libDir(name, "$name $version")];
      contents = [d.file("pubspec.yaml", yaml(pubspecFields))]
          ..addAll(contents);

      var packages = _packages.putIfAbsent(name, () => []);
      packages.add(new _ServedPackage(pubspecFields, contents));
    }));
  }

  /// Serves the versions of [package] and all its dependencies that are
  /// currently checked into the Dart repository.
  void serveRepoPackage(String package) {
    _addPackage(name) {
      if (_packages.containsKey(name)) return;
      _packages[name] = [];

      var pubspec = new Map.from(loadYaml(
          readTextFile(p.join(repoRoot, 'pkg', name, 'pubspec.yaml'))));

      // Remove any SDK constraints since we don't have a valid SDK version
      // while testing.
      pubspec.remove('environment');

      _packages[name].add(new _ServedPackage(pubspec, [
        d.file('pubspec.yaml', yaml(pubspec)),
        new d.DirectoryDescriptor.fromFilesystem('lib',
            p.join(repoRoot, 'pkg', name, 'lib'))
      ]));

      if (pubspec.containsKey('dependencies')) {
        pubspec['dependencies'].keys.forEach(_addPackage);
      }
    }

    _addPackage(package);
  }

  /// Returns a Future that completes once all the [serve] calls have been fully
  /// processed.
  Future _await() {
    if (_futures.futures.isEmpty) return new Future.value();
    return _futures.future.then((_) {
      _futures = new FutureGroup();
    });
  }
}

/// A package that's intended to be served.
class _ServedPackage {
  final Map pubspec;
  final List<d.Descriptor> contents;

  Version get version => new Version.parse(pubspec['version']);

  _ServedPackage(this.pubspec, this.contents);
}
