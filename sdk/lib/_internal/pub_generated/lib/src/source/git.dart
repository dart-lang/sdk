library pub.source.git;
import 'dart:async';
import 'package:path/path.dart' as path;
import '../git.dart' as git;
import '../io.dart';
import '../log.dart' as log;
import '../package.dart';
import '../pubspec.dart';
import '../utils.dart';
import 'cached.dart';
class GitSource extends CachedSource {
  static String urlFromDescription(description) => description["url"];
  final name = "git";
  final _updatedRepos = new Set<String>();
  Future<String> getPackageNameFromRepo(String repo) {
    return withTempDir((tempDir) {
      return _clone(repo, tempDir, shallow: true).then((_) {
        var pubspec = new Pubspec.load(tempDir, systemCache.sources);
        return pubspec.name;
      });
    });
  }
  Future<Pubspec> describeUncached(PackageId id) {
    return downloadToSystemCache(id).then((package) => package.pubspec);
  }
  Future<Package> downloadToSystemCache(PackageId id) {
    var revisionCachePath;
    if (!git.isInstalled) {
      fail(
          "Cannot get ${id.name} from Git (${_getUrl(id)}).\n"
              "Please ensure Git is correctly installed.");
    }
    ensureDir(path.join(systemCacheRoot, 'cache'));
    return _ensureRevision(id).then((_) => getDirectory(id)).then((path) {
      revisionCachePath = path;
      if (entryExists(revisionCachePath)) return null;
      return _clone(_repoCachePath(id), revisionCachePath, mirror: false);
    }).then((_) {
      var ref = _getEffectiveRef(id);
      if (ref == 'HEAD') return null;
      return _checkOut(revisionCachePath, ref);
    }).then((_) {
      return new Package.load(id.name, revisionCachePath, systemCache.sources);
    });
  }
  Future<String> getDirectory(PackageId id) {
    return _ensureRevision(id).then((rev) {
      var revisionCacheName = '${id.name}-$rev';
      return path.join(systemCacheRoot, revisionCacheName);
    });
  }
  dynamic parseDescription(String containingPath, description,
      {bool fromLockFile: false}) {
    if (description is String) return description;
    if (description is! Map || !description.containsKey('url')) {
      throw new FormatException(
          "The description must be a Git URL or a map " "with a 'url' key.");
    }
    var parsed = new Map.from(description);
    parsed.remove('url');
    parsed.remove('ref');
    if (fromLockFile) parsed.remove('resolved-ref');
    if (!parsed.isEmpty) {
      var plural = parsed.length > 1;
      var keys = parsed.keys.join(', ');
      throw new FormatException("Invalid key${plural ? 's' : ''}: $keys.");
    }
    return description;
  }
  bool descriptionsEqual(description1, description2) {
    return _getUrl(description1) == _getUrl(description2) &&
        _getRef(description1) == _getRef(description2);
  }
  Future<PackageId> resolveId(PackageId id) {
    return _ensureRevision(id).then((revision) {
      var description = {
        'url': _getUrl(id),
        'ref': _getRef(id)
      };
      description['resolved-ref'] = revision;
      return new PackageId(id.name, name, id.version, description);
    });
  }
  List<Package> getCachedPackages() {
    throw new UnimplementedError(
        "The git source doesn't support listing its cached packages yet.");
  }
  Future<Pair<int, int>> repairCachedPackages() {
    if (!dirExists(systemCacheRoot)) return new Future.value(new Pair(0, 0));
    var successes = 0;
    var failures = 0;
    var packages = listDir(
        systemCacheRoot).where(
            (entry) =>
                dirExists(
                    path.join(
                        entry,
                        ".git"))).map(
                            (packageDir) =>
                                new Package.load(null, packageDir, systemCache.sources)).toList();
    packages.sort(Package.orderByNameAndVersion);
    return Future.wait(packages.map((package) {
      log.message(
          "Resetting Git repository for "
              "${log.bold(package.name)} ${package.version}...");
      return git.run(
          ["clean", "-d", "--force", "-x"],
          workingDir: package.dir).then((_) {
        return git.run(["reset", "--hard", "HEAD"], workingDir: package.dir);
      }).then((_) {
        successes++;
      }).catchError((error, stackTrace) {
        failures++;
        log.error(
            "Failed to reset ${log.bold(package.name)} "
                "${package.version}. Error:\n$error");
        log.fine(stackTrace);
        failures++;
      }, test: (error) => error is git.GitException);
    })).then((_) => new Pair(successes, failures));
  }
  Future<String> _ensureRevision(PackageId id) {
    return new Future.sync(() {
      var path = _repoCachePath(id);
      if (!entryExists(path)) {
        return _clone(
            _getUrl(id),
            path,
            mirror: true).then((_) => _revParse(id));
      }
      var description = id.description;
      if (description is! Map || !description.containsKey('resolved-ref')) {
        return _updateRepoCache(id).then((_) => _revParse(id));
      }
      return _revParse(id).catchError((error) {
        if (error is! git.GitException) throw error;
        return _updateRepoCache(id).then((_) => _revParse(id));
      });
    });
  }
  Future _updateRepoCache(PackageId id) {
    var path = _repoCachePath(id);
    if (_updatedRepos.contains(path)) return new Future.value();
    return git.run(["fetch"], workingDir: path).then((_) {
      _updatedRepos.add(path);
    });
  }
  Future<String> _revParse(PackageId id) {
    return git.run(
        ["rev-parse", _getEffectiveRef(id)],
        workingDir: _repoCachePath(id)).then((result) => result.first);
  }
  Future _clone(String from, String to, {bool mirror: false, bool shallow:
      false}) {
    return new Future.sync(() {
      ensureDir(to);
      var args = ["clone", from, to];
      if (mirror) args.insert(1, "--mirror");
      if (shallow) args.insertAll(1, ["--depth", "1"]);
      return git.run(args);
    }).then((result) => null);
  }
  Future _checkOut(String repoPath, String ref) {
    return git.run(
        ["checkout", ref],
        workingDir: repoPath).then((result) => null);
  }
  String _repoCachePath(PackageId id) {
    var repoCacheName = '${id.name}-${sha1(_getUrl(id))}';
    return path.join(systemCacheRoot, 'cache', repoCacheName);
  }
  String _getUrl(description) {
    description = _getDescription(description);
    if (description is String) return description;
    return description['url'];
  }
  String _getEffectiveRef(description) {
    description = _getDescription(description);
    if (description is Map && description.containsKey('resolved-ref')) {
      return description['resolved-ref'];
    }
    var ref = _getRef(description);
    return ref == null ? 'HEAD' : ref;
  }
  String _getRef(description) {
    description = _getDescription(description);
    if (description is String) return null;
    return description['ref'];
  }
  _getDescription(description) {
    if (description is PackageId) return description.description;
    return description;
  }
}
