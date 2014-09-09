library pub.system_cache;
import 'dart:async';
import 'package:path/path.dart' as path;
import 'io.dart';
import 'io.dart' as io show createTempDir;
import 'log.dart' as log;
import 'package.dart';
import 'source/cached.dart';
import 'source/git.dart';
import 'source/hosted.dart';
import 'source/path.dart';
import 'source.dart';
import 'source_registry.dart';
class SystemCache {
  final String rootDir;
  String get tempDir => path.join(rootDir, '_temp');
  final sources = new SourceRegistry();
  SystemCache(this.rootDir);
  factory SystemCache.withSources(String rootDir, {bool isOffline: false}) {
    var cache = new SystemCache(rootDir);
    cache.register(new GitSource());
    if (isOffline) {
      cache.register(new OfflineHostedSource());
    } else {
      cache.register(new HostedSource());
    }
    cache.register(new PathSource());
    cache.sources.setDefault('hosted');
    return cache;
  }
  void register(Source source) {
    source.bind(this);
    sources.register(source);
  }
  Future<bool> contains(PackageId id) {
    var source = sources[id.source];
    if (source is! CachedSource) {
      throw new ArgumentError("Package $id is not cacheable.");
    }
    return source.isInSystemCache(id);
  }
  String createTempDir() {
    var temp = ensureDir(tempDir);
    return io.createTempDir(temp, 'dir');
  }
  void deleteTempDir() {
    log.fine('Clean up system cache temp directory $tempDir.');
    if (dirExists(tempDir)) deleteEntry(tempDir);
  }
}
