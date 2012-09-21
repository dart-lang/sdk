// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('hosted_source');

#import('dart:io', prefix: 'io');
#import('dart:json');
#import('dart:uri');

#import('io.dart');
#import('package.dart');
#import('pubspec.dart');
#import('source.dart');
#import('source_registry.dart');
#import('utils.dart');
#import('version.dart');

/**
 * A package source that installs packages from a package hosting site that
 * uses the same API as pub.dartlang.org.
 */
class HostedSource extends Source {
  final name = "hosted";
  final shouldCache = true;

  /**
   * The URL of the default package repository.
   */
  static final defaultUrl = "http://pub.dartlang.org";

  /**
   * Downloads a list of all versions of a package that are available from the
   * site.
   */
  Future<List<Version>> getVersions(String name, description) {
    var parsed = _parseDescription(description);
    var fullUrl = "${parsed.last}/packages/${parsed.first}.json";

    return httpGetString(fullUrl).transform((body) {
      var doc = JSON.parse(body);
      return doc['versions'].map((version) => new Version.parse(version));
    }).transformException((ex) {
      if (ex is PubHttpException && ex.statusCode == 404) {
        throw 'Could not find package "${parsed.first}" on ${parsed.last}.';
      }

      // Otherwise re-throw the original exception.
      throw ex;
    });
  }

  /**
   * Downloads and parses the pubspec for a specific version of a package that
   * is available from the site.
   */
  Future<Pubspec> describe(PackageId id) {
    var parsed = _parseDescription(id.description);
    var fullUrl = "${parsed.last}/packages/${parsed.first}/versions/"
      "${id.version}.yaml";
    return httpGetString(fullUrl).transform((yaml) {
      return new Pubspec.parse(yaml, systemCache.sources);
    });
  }

  /**
   * Downloads a package from the site and unpacks it.
   */
  Future<bool> install(PackageId id, String destPath) {
    var parsedDescription = _parseDescription(id.description);
    var name = parsedDescription.first;
    var url = parsedDescription.last;

    var fullUrl = "$url/packages/$name/versions/${id.version}.tar.gz";

    return Futures.wait([httpGet(fullUrl), ensureDir(destPath)]).chain((args) {
      return timeout(extractTarGz(args[0], args[1]), HTTP_TIMEOUT,
          'Timed out while fetching URL "$fullUrl".');
    }).transformException((ex) {
      // If the install failed, delete the directory. Prevents leaving a ghost
      // directory in the system cache which would later make pub think the
      // install succeeded.
      // TODO(rnystrom): Use deleteDir() here when transformException() supports
      // returning a future. Also remove dart:io import then.
      new io.Directory(destPath).deleteRecursivelySync();

      throw ex;
    });
  }

  /**
   * The system cache directory for the hosted source contains subdirectories
   * for each separate repository URL that's used on the system. Each of these
   * subdirectories then contains a subdirectory for each package installed
   * from that site.
   */
  String systemCacheDirectory(PackageId id) {
    var parsed = _parseDescription(id.description);
    var url = parsed.last.replaceAll(new RegExp(@"^https?://"), "");
    var urlDir = replace(url, new RegExp(@'[<>:"\\/|?*%]'), (match) {
      return '%${match[0].charCodeAt(0)}';
    });
    return join(systemCacheRoot, urlDir, "${parsed.first}-${id.version}");
  }

  String packageName(description) => _parseDescription(description).first;

  bool descriptionsEqual(description1, description2) =>
      _parseDescription(description1) == _parseDescription(description2);

  /**
   * Ensures that [description] is a valid hosted package description.
   *
   * There are two valid formats. A plain string refers to a package with the
   * given name from the default host, while a map with keys "name" and "url"
   * refers to a package with the given name from the host at the given URL.
   */
  void validateDescription(description, [bool fromLockFile=false]) {
    _parseDescription(description);
  }

  /**
   * Parses the description for a package.
   *
   * If the package parses correctly, this returns a (name, url) pair. If not,
   * this throws a descriptive FormatException.
   */
  Pair<String, String> _parseDescription(description) {
    if (description is String) {
      return new Pair<String, String>(description, defaultUrl);
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

    var url = description.containsKey("url") ? description["url"] : defaultUrl;
    return new Pair<String, String>(name, url);
  }
}
