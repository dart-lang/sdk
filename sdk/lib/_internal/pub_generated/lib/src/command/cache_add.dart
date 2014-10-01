library pub.command.cache_add;
import 'dart:async';
import 'package:pub_semver/pub_semver.dart';
import '../command.dart';
import '../log.dart' as log;
import '../package.dart';
import '../utils.dart';
class CacheAddCommand extends PubCommand {
  String get description => "Install a package.";
  String get usage =>
      "pub cache add <package> [--version <constraint>] [--all]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-cache.html";
  bool get takesArguments => true;
  CacheAddCommand() {
    commandParser.addFlag(
        "all",
        help: "Install all matching versions.",
        negatable: false);
    commandParser.addOption("version", abbr: "v", help: "Version constraint.");
  }
  Future onRun() {
    if (commandOptions.rest.isEmpty) {
      usageError("No package to add given.");
    }
    if (commandOptions.rest.length > 1) {
      var unexpected = commandOptions.rest.skip(1).map((arg) => '"$arg"');
      var arguments = pluralize("argument", unexpected.length);
      usageError("Unexpected $arguments ${toSentence(unexpected)}.");
    }
    var package = commandOptions.rest.single;
    var constraint = VersionConstraint.any;
    if (commandOptions["version"] != null) {
      try {
        constraint = new VersionConstraint.parse(commandOptions["version"]);
      } on FormatException catch (error) {
        usageError(error.message);
      }
    }
    var source = cache.sources["hosted"];
    return source.getVersions(package, package).then((versions) {
      versions = versions.where(constraint.allows).toList();
      if (versions.isEmpty) {
        fail("Package $package has no versions that match $constraint.");
      }
      downloadVersion(Version version) {
        var id = new PackageId(package, source.name, version, package);
        return cache.contains(id).then((contained) {
          if (contained) {
            log.message("Already cached ${id.name} ${id.version}.");
            return null;
          }
          return source.downloadToSystemCache(id);
        });
      }
      if (commandOptions["all"]) {
        versions.sort();
        return Future.forEach(versions, downloadVersion);
      } else {
        versions.sort(Version.prioritize);
        return downloadVersion(versions.last);
      }
    });
  }
}
