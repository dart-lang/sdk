// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/package_config_json.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:meta/meta.dart';
import 'package:package_config/packages_file.dart' as dot_packages;
import 'package:pub_semver/pub_semver.dart';

/// Parse the [file] as a `.packages` file.
Packages parseDotPackagesFile(ResourceProvider provider, File file) {
  var uri = file.toUri();
  var content = file.readAsBytesSync();
  var uriMap = dot_packages.parse(content, uri);

  var map = <String, Package>{};
  for (var name in uriMap.keys) {
    var libUri = uriMap[name];
    var libPath = fileUriToNormalizedPath(
      provider.pathContext,
      libUri,
    );
    var libFolder = provider.getFolder(libPath);
    map[name] = Package(
      name: name,
      rootFolder: libFolder,
      libFolder: libFolder,
      languageVersion: null,
    );
  }

  return Packages(map);
}

/// Parse the [file] as a `package_config.json` file.
Packages parsePackageConfigJsonFile(ResourceProvider provider, File file) {
  var uri = file.toUri();
  var content = file.readAsStringSync();
  var jsonConfig = parsePackageConfigJson(uri, content);

  var map = <String, Package>{};
  for (var jsonPackage in jsonConfig.packages) {
    var name = jsonPackage.name;

    var rootPath = fileUriToNormalizedPath(
      provider.pathContext,
      jsonPackage.rootUri,
    );

    var libPath = fileUriToNormalizedPath(
      provider.pathContext,
      jsonPackage.packageUri,
    );

    Version languageVersion;
    if (jsonPackage.languageVersion != null) {
      languageVersion = Version(
        jsonPackage.languageVersion.major,
        jsonPackage.languageVersion.minor,
        0,
      );
      // New features were added in `2.2.2` over `2.2.0`.
      // But `2.2.2` is not representable, so we special case it.
      if (languageVersion.major == 2 && languageVersion.minor == 2) {
        languageVersion = Version(2, 2, 2);
      }
    }

    map[name] = Package(
      name: name,
      rootFolder: provider.getFolder(rootPath),
      libFolder: provider.getFolder(libPath),
      languageVersion: languageVersion,
    );
  }

  return Packages(map);
}

class Package {
  final String name;
  final Folder rootFolder;
  final Folder libFolder;

  /// The language version for this package, `null` not specified explicitly.
  final Version languageVersion;

  Package({
    @required this.name,
    @required this.rootFolder,
    @required this.libFolder,
    @required this.languageVersion,
  });
}

class Packages {
  final Map<String, Package> _map;

  Packages(Map<String, Package> map) : _map = map;

  Iterable<Package> get packages => _map.values;

  /// Return the [Package] with the given [name], or `null`.
  Package operator [](String name) => _map[name];
}
