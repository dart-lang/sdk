library pub.command.cache_list;
import 'dart:async';
import 'dart:convert';
import '../command.dart';
import '../log.dart' as log;
import '../source/cached.dart';
class CacheListCommand extends PubCommand {
  String get description => "List packages in the system cache.";
  String get usage => "pub cache list";
  bool get hidden => true;
  Future onRun() {
    var packagesObj = <String, Map>{};
    var source = cache.sources.defaultSource as CachedSource;
    for (var package in source.getCachedPackages()) {
      var packageInfo = packagesObj.putIfAbsent(package.name, () => {});
      packageInfo[package.version.toString()] = {
        'location': package.dir
      };
    }
    log.message(JSON.encode({
      'packages': packagesObj
    }));
    return null;
  }
}
