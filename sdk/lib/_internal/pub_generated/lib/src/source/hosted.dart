library pub.source.hosted;
import 'dart:async';
import 'dart:io' as io;
import "dart:convert";
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../exceptions.dart';
import '../http.dart';
import '../io.dart';
import '../log.dart' as log;
import '../package.dart';
import '../pubspec.dart';
import '../utils.dart';
import '../version.dart';
import 'cached.dart';
class HostedSource extends CachedSource {
  final name = "hosted";
  final hasMultipleVersions = true;
  static String get defaultUrl {
    var url = io.Platform.environment["PUB_HOSTED_URL"];
    if (url != null) return url;
    return "https://pub.dartlang.org";
  }
  Future<List<Version>> getVersions(String name, description) {
    var url =
        _makeUrl(description, (server, package) => "$server/api/packages/$package");
    log.io("Get versions from $url.");
    return httpClient.read(url, headers: PUB_API_HEADERS).then((body) {
      var doc = JSON.decode(body);
      return doc['versions'].map(
          (version) => new Version.parse(version['version'])).toList();
    }).catchError((ex, stackTrace) {
      var parsed = _parseDescription(description);
      _throwFriendlyError(ex, stackTrace, parsed.first, parsed.last);
    });
  }
  Future<Pubspec> describeUncached(PackageId id) {
    var url = _makeVersionUrl(
        id,
        (server, package, version) =>
            "$server/api/packages/$package/versions/$version");
    log.io("Describe package at $url.");
    return httpClient.read(url, headers: PUB_API_HEADERS).then((version) {
      version = JSON.decode(version);
      return new Pubspec.fromMap(
          version['pubspec'],
          systemCache.sources,
          expectedName: id.name,
          location: url);
    }).catchError((ex, stackTrace) {
      var parsed = _parseDescription(id.description);
      _throwFriendlyError(ex, stackTrace, id.name, parsed.last);
    });
  }
  Future<Package> downloadToSystemCache(PackageId id) {
    return isInSystemCache(id).then((inCache) {
      if (inCache) return true;
      var packageDir = _getDirectory(id);
      ensureDir(path.dirname(packageDir));
      var parsed = _parseDescription(id.description);
      return _download(parsed.last, parsed.first, id.version, packageDir);
    }).then((found) {
      if (!found) fail('Package $id not found.');
      return new Package.load(id.name, _getDirectory(id), systemCache.sources);
    });
  }
  Future<String> getDirectory(PackageId id) =>
      new Future.value(_getDirectory(id));
  String _getDirectory(PackageId id) {
    var parsed = _parseDescription(id.description);
    var dir = _urlToDirectory(parsed.last);
    return path.join(systemCacheRoot, dir, "${parsed.first}-${id.version}");
  }
  String packageName(description) => _parseDescription(description).first;
  bool descriptionsEqual(description1, description2) =>
      _parseDescription(description1) == _parseDescription(description2);
  dynamic parseDescription(String containingPath, description,
      {bool fromLockFile: false}) {
    _parseDescription(description);
    return description;
  }
  Future<Pair<int, int>> repairCachedPackages() {
    if (!dirExists(systemCacheRoot)) return new Future.value(new Pair(0, 0));
    var successes = 0;
    var failures = 0;
    return Future.wait(listDir(systemCacheRoot).map((serverDir) {
      var url = _directoryToUrl(path.basename(serverDir));
      var packages = _getCachedPackagesInDirectory(path.basename(serverDir));
      packages.sort(Package.orderByNameAndVersion);
      return Future.wait(packages.map((package) {
        return _download(
            url,
            package.name,
            package.version,
            package.dir).then((_) {
          successes++;
        }).catchError((error, stackTrace) {
          failures++;
          var message =
              "Failed to repair ${log.bold(package.name)} " "${package.version}";
          if (url != defaultUrl) message += " from $url";
          log.error("$message. Error:\n$error");
          log.fine(stackTrace);
        });
      }));
    })).then((_) => new Pair(successes, failures));
  }
  List<Package> getCachedPackages() {
    return _getCachedPackagesInDirectory(_urlToDirectory(defaultUrl));
  }
  List<Package> _getCachedPackagesInDirectory(String dir) {
    var cacheDir = path.join(systemCacheRoot, dir);
    if (!dirExists(cacheDir)) return [];
    return listDir(
        cacheDir).map(
            (entry) => new Package.load(null, entry, systemCache.sources)).toList();
  }
  Future<bool> _download(String server, String package, Version version,
      String destPath) {
    return new Future.sync(() {
      var url = Uri.parse("$server/packages/$package/versions/$version.tar.gz");
      log.io("Get package from $url.");
      log.message('Downloading ${log.bold(package)} ${version}...');
      var tempDir = systemCache.createTempDir();
      return httpClient.send(
          new http.Request(
              "GET",
              url)).then((response) => response.stream).then((stream) {
        return timeout(
            extractTarGz(stream, tempDir),
            HTTP_TIMEOUT,
            url,
            'downloading $url');
      }).then((_) {
        if (dirExists(destPath)) deleteEntry(destPath);
        renameDir(tempDir, destPath);
        return true;
      });
    });
  }
  void _throwFriendlyError(error, StackTrace stackTrace, String package,
      String url) {
    if (error is PubHttpException && error.response.statusCode == 404) {
      throw new PackageNotFoundException(
          "Could not find package $package at $url.",
          error,
          stackTrace);
    }
    if (error is TimeoutException) {
      fail(
          "Timed out trying to find package $package at $url.",
          error,
          stackTrace);
    }
    if (error is io.SocketException) {
      fail(
          "Got socket error trying to find package $package at $url.",
          error,
          stackTrace);
    }
    throw error;
  }
}
class OfflineHostedSource extends HostedSource {
  Future<List<Version>> getVersions(String name, description) {
    return newFuture(() {
      var parsed = _parseDescription(description);
      var server = parsed.last;
      log.io(
          "Finding versions of $name in " "$systemCacheRoot/${_urlToDirectory(server)}");
      return _getCachedPackagesInDirectory(
          _urlToDirectory(
              server)).where(
                  (package) => package.name == name).map((package) => package.version).toList();
    }).then((versions) {
      if (versions.isEmpty) fail("Could not find package $name in cache.");
      return versions;
    });
  }
  Future<bool> _download(String server, String package, Version version,
      String destPath) {
    throw new UnsupportedError("Cannot download packages when offline.");
  }
  Future<Pubspec> doDescribeUncached(PackageId id) {
    throw new UnsupportedError("Cannot describe packages when offline.");
  }
}
String _urlToDirectory(String url) {
  url = url.replaceAllMapped(
      new RegExp(r"^https?://(127\.0\.0\.1|\[::1\])?"),
      (match) => match[1] == null ? '' : 'localhost');
  return replace(
      url,
      new RegExp(r'[<>:"\\/|?*%]'),
      (match) => '%${match[0].codeUnitAt(0)}');
}
String _directoryToUrl(String url) {
  var chars = '<>:"\\/|?*%';
  for (var i = 0; i < chars.length; i++) {
    var c = chars.substring(i, i + 1);
    url = url.replaceAll("%${c.codeUnitAt(0)}", c);
  }
  var scheme = "https";
  if (isLoopback(url.replaceAll(new RegExp(":.*"), ""))) scheme = "http";
  return "$scheme://$url";
}
Uri _makeUrl(description, String pattern(String server, String package)) {
  var parsed = _parseDescription(description);
  var server = parsed.last;
  var package = Uri.encodeComponent(parsed.first);
  return Uri.parse(pattern(server, package));
}
Uri _makeVersionUrl(PackageId id, String pattern(String server, String package,
    String version)) {
  var parsed = _parseDescription(id.description);
  var server = parsed.last;
  var package = Uri.encodeComponent(parsed.first);
  var version = Uri.encodeComponent(id.version.toString());
  return Uri.parse(pattern(server, package, version));
}
Pair<String, String> _parseDescription(description) {
  if (description is String) {
    return new Pair<String, String>(description, HostedSource.defaultUrl);
  }
  if (description is! Map) {
    throw new FormatException("The description must be a package name or map.");
  }
  if (!description.containsKey("name")) {
    throw new FormatException("The description map must contain a 'name' key.");
  }
  var name = description["name"];
  if (name is! String) {
    throw new FormatException("The 'name' key must have a string value.");
  }
  var url = description["url"];
  if (url == null) url = HostedSource.defaultUrl;
  return new Pair<String, String>(name, url);
}
