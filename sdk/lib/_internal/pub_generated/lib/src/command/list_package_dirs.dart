library pub.command.list_package_dirs;
import 'dart:async';
import 'package:path/path.dart' as path;
import '../command.dart';
import '../log.dart' as log;
import '../utils.dart';
class ListPackageDirsCommand extends PubCommand {
  String get description => "Print local paths to dependencies.";
  String get usage => "pub list-package-dirs";
  bool get hidden => true;
  ListPackageDirsCommand() {
    commandParser.addOption(
        "format",
        help: "How output should be displayed.",
        allowed: ["json"]);
  }
  Future onRun() {
    log.json.enabled = true;
    if (!entrypoint.lockFileExists) {
      dataError('Package "myapp" has no lockfile. Please run "pub get" first.');
    }
    var output = {};
    var packages = {};
    var futures = [];
    entrypoint.lockFile.packages.forEach((name, package) {
      var source = entrypoint.cache.sources[package.source];
      futures.add(source.getDirectory(package).then((packageDir) {
        packages[name] = path.join(packageDir, "lib");
      }));
    });
    output["packages"] = packages;
    packages[entrypoint.root.name] = entrypoint.root.path("lib");
    output["input_files"] = [entrypoint.lockFilePath, entrypoint.pubspecPath];
    return Future.wait(futures).then((_) {
      log.json.message(output);
    });
  }
}
