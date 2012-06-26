// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('dartlang_source');

#import('dart:io');
#import('dart:uri');
#import('io.dart');
#import('package.dart');
#import('source.dart');
#import('utils.dart');

/**
 * A package source that installs packages from a package repository that uses
 * the same API as pub.dartlang.org.
 */
class RepoSource extends Source {
  final String name = "repo";

  final bool shouldCache = true;

  // TODO(nweiz): update this comment once pub.dartlang.org is online
  /**
   * The URL of the default package repository.
   *
   * At time of writing, pub.dartlang.org is not yet online, but it should be
   * soon.
   */
  static final String defaultUrl = "http://pub.dartlang.org";

  RepoSource();

  /**
   * Downloads a package from a package repository and unpacks it.
   */
  Future<bool> install(PackageId id, String destPath) {
    var parsedDescription = _parseDescription(id.description);
    var name = parsedDescription.first;
    var url = parsedDescription.last;

    return ensureDir(destPath).chain((destDir) {
      var fullUrl = "$url/packages/$name/versions/${id.version}.tar.gz";
      return extractTarGz(httpGet(fullUrl), destDir);
    });
  }

  /**
   * The system cache directory for the repo source contains subdirectories for
   * each separate repository URL that's used on the system. Each of these
   * subdirectories then contains a subdirectory for each package installed from
   * that repository.
   */
  String systemCacheDirectory(PackageId id, String parent) {
    var parsed = _parseDescription(id.description);
    var url = parsed.last.replaceAll(new RegExp(@"^https?://"), "");
    var urlDir = replace(url, new RegExp(@'[<>:"\\/|?*%]'), (match) {
      return '%${match[0].charCodeAt(0)}';
    });
    return join(parent, urlDir, "${parsed.first}-${id.version}");
  }

  String packageName(PackageId id) => _parseDescription(id.description).first;

  /**
   * Ensures that [description] is a valid repo description.
   *
   * There are two valid formats. A plain string refers to a package with the
   * given name from the default repository, while a map with keys "name" and
   * "url" refers to a package with the given name from the repo at the given
   * URL.
   */
  void validateDescription(description) {
    _parseDescription(description);
  }

  /**
   * Parses the description blob for a package.
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
