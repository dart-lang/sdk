// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library hosted_source;

import 'dart:async';
import 'dart:io' as io;
import 'dart:json' as json;
import 'dart:uri';

import 'package:http/http.dart' as http;
import 'package:pathos/path.dart' as path;

import 'http.dart';
import 'io.dart';
import 'log.dart' as log;
import 'package.dart';
import 'pubspec.dart';
import 'source.dart';
import 'source_registry.dart';
import 'utils.dart';
import 'version.dart';

/// A package source that installs packages from a package hosting site that
/// uses the same API as pub.dartlang.org.
class HostedSource extends Source {
  final name = "hosted";
  final shouldCache = true;

  /// Downloads a list of all versions of a package that are available from the
  /// site.
  Future<List<Version>> getVersions(String name, description) {
    var url = _makeUrl(description,
        (server, package) => "$server/packages/$package.json");

    log.io("Get versions from $url.");
    return httpClient.read(url).then((body) {
      var doc = json.parse(body);
      return doc['versions']
          .map((version) => new Version.parse(version))
          .toList();
    }).catchError((ex) {
      var parsed = _parseDescription(description);
      _throwFriendlyError(ex, parsed.first, parsed.last);
    });
  }

  /// Downloads and parses the pubspec for a specific version of a package that
  /// is available from the site.
  Future<Pubspec> describe(PackageId id) {
    var url = _makeVersionUrl(id, (server, package, version) =>
        "$server/packages/$package/versions/$version.yaml");

    log.io("Describe package at $url.");
    return httpClient.read(url).then((yaml) {
      return new Pubspec.parse(null, yaml, systemCache.sources);
    }).catchError((ex) {
      var parsed = _parseDescription(id.description);
      _throwFriendlyError(ex, id, parsed.last);
    });
  }

  /// Downloads a package from the site and unpacks it.
  Future<bool> install(PackageId id, String destPath) {
    return new Future.sync(() {
      var url = _makeVersionUrl(id, (server, package, version) =>
          "$server/packages/$package/versions/$version.tar.gz");
      log.io("Install package from $url.");

      log.message('Downloading $id...');

      // Download and extract the archive to a temp directory.
      var tempDir = systemCache.createTempDir();
      return httpClient.send(new http.Request("GET", url))
          .then((response) => response.stream)
          .then((stream) {
        return timeout(extractTarGz(stream, tempDir), HTTP_TIMEOUT,
            'fetching URL "$url"');
      }).then((_) {
        // Now that the install has succeeded, move it to the real location in
        // the cache. This ensures that we don't leave half-busted ghost
        // directories in the user's pub cache if an install fails.
        renameDir(tempDir, destPath);
        return true;
      });
    });
  }

  /// The system cache directory for the hosted source contains subdirectories
  /// for each separate repository URL that's used on the system. Each of these
  /// subdirectories then contains a subdirectory for each package installed
  /// from that site.
  Future<String> systemCacheDirectory(PackageId id) {
    var parsed = _parseDescription(id.description);
    var url = _getSourceDirectory(parsed.last);
    var urlDir = replace(url, new RegExp(r'[<>:"\\/|?*%]'), (match) {
      return '%${match[0].codeUnitAt(0)}';
    });

    return new Future.value(
        path.join(systemCacheRoot, urlDir, "${parsed.first}-${id.version}"));
  }

  String packageName(description) => _parseDescription(description).first;

  bool descriptionsEqual(description1, description2) =>
      _parseDescription(description1) == _parseDescription(description2);

  /// Ensures that [description] is a valid hosted package description.
  ///
  /// There are two valid formats. A plain string refers to a package with the
  /// given name from the default host, while a map with keys "name" and "url"
  /// refers to a package with the given name from the host at the given URL.
  dynamic parseDescription(String containingPath, description,
                           {bool fromLockFile: false}) {
    _parseDescription(description);
    return description;
  }

  List<Package> getCachedPackages() {
    var cacheDir = path.join(systemCacheRoot,
                             _getSourceDirectory(_defaultUrl));
    if (!dirExists(cacheDir)) return [];
  
    return listDir(path.join(cacheDir)).map((entry) =>
        new Package.load(null, entry, systemCache.sources)).toList();
  }
  
  /// When an error occurs trying to read something about [package] from [url],
  /// this tries to translate into a more user friendly error message. Always
  /// throws an error, either the original one or a better one.
  void _throwFriendlyError(error, package, url) {
    if (error is PubHttpException &&
        error.response.statusCode == 404) {
      throw 'Could not find package "$package" at $url.';
    }

    if (error is TimeoutException) {
      throw 'Timed out trying to find package "$package" at $url.';
    }

    if (error is io.SocketIOException) {
      throw 'Got socket error trying to find package "$package" at $url.\n'
          '${error.osError}';
    }

    // Otherwise re-throw the original exception.
    throw error;
  }

}

/// The URL of the default package repository.
final _defaultUrl = "https://pub.dartlang.org";

String _getSourceDirectory(String url) {
  return url.replaceAll(new RegExp(r"^https?://"), "");
}

/// Parses [description] into its server and package name components, then
/// converts that to a Uri given [pattern]. Ensures the package name is
/// properly URL encoded.
Uri _makeUrl(description, String pattern(String server, String package)) {
  var parsed = _parseDescription(description);
  var server = parsed.last;
  var package = encodeUriComponent(parsed.first);
  return new Uri(pattern(server, package));
}

/// Parses [id] into its server, package name, and version components, then
/// converts that to a Uri given [pattern]. Ensures the package name is
/// properly URL encoded.
Uri _makeVersionUrl(PackageId id,
    String pattern(String server, String package, String version)) {
  var parsed = _parseDescription(id.description);
  var server = parsed.last;
  var package = encodeUriComponent(parsed.first);
  var version = encodeUriComponent(id.version.toString());
  return new Uri(pattern(server, package, version));
}

/// Parses the description for a package.
///
/// If the package parses correctly, this returns a (name, url) pair. If not,
/// this throws a descriptive FormatException.
Pair<String, String> _parseDescription(description) {
  if (description is String) {
    return new Pair<String, String>(description, _defaultUrl);
  }

  if (description is! Map) {
    throw new FormatException(
        "The description must be a package name or map.");
  }

  if (!description.containsKey("name")) {
    throw new FormatException(
    "The description map must contain a 'name' key.");
  }

  var name = description["name"];
  if (name is! String) {
    throw new FormatException("The 'name' key must have a string value.");
  }

  var url = description.containsKey("url") ? description["url"] : _defaultUrl;
  return new Pair<String, String>(name, url);
}
