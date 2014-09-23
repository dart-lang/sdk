library pub.command.build;
import 'dart:async';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import '../barback/asset_environment.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'barback.dart';
final _arrow = getSpecial('\u2192', '=>');
class BuildCommand extends BarbackCommand {
  String get description => "Apply transformers to build a package.";
  String get usage => "pub build [options] [directories...]";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-build.html";
  List<String> get aliases => const ["deploy", "settle-up"];
  String get outputDirectory => commandOptions["output"];
  List<String> get defaultSourceDirectories => ["web"];
  int builtFiles = 0;
  BuildCommand() {
    commandParser.addOption(
        "format",
        help: "How output should be displayed.",
        allowed: ["text", "json"],
        defaultsTo: "text");
    commandParser.addOption(
        "output",
        abbr: "o",
        help: "Directory to write build outputs to.",
        defaultsTo: "build");
  }
  Future onRunTransformerCommand() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        cleanDir(outputDirectory);
        var errorsJson = [];
        var logJson = [];
        completer0.complete(
            AssetEnvironment.create(
                entrypoint,
                mode,
                useDart2JS: true).then(((environment) {
          environment.barback.errors.listen((error) {
            log.error(log.red("Build error:\n$error"));
            if (log.json.enabled) {
              errorsJson.add({
                "error": error.toString()
              });
            }
          });
          if (log.json.enabled) {
            environment.barback.log.listen(
                (entry) => logJson.add(_logEntryToJson(entry)));
          }
          return log.progress("Building ${entrypoint.root.name}", () {
            return Future.wait(
                sourceDirectories.map((dir) => environment.serveDirectory(dir))).then((_) {
              return environment.barback.getAllAssets();
            });
          }).then((assets) {
            var dart2JSEntrypoints = assets.where(
                (asset) => asset.id.path.endsWith(".dart.js")).map((asset) => asset.id);
            return Future.wait(assets.map(_writeAsset)).then((_) {
              builtFiles += _copyBrowserJsFiles(dart2JSEntrypoints);
              log.message(
                  'Built $builtFiles ${pluralize('file', builtFiles)} ' 'to "$outputDirectory".');
              log.json.message({
                "buildResult": "success",
                "outputDirectory": outputDirectory,
                "numFiles": builtFiles,
                "log": logJson
              });
            });
          });
        })).catchError(((error) {
          if (error is! BarbackException) throw error;
          log.error(log.red("Build failed."));
          log.json.message({
            "buildResult": "failure",
            "errors": errorsJson,
            "log": logJson
          });
          return flushThenExit(exit_codes.DATA);
        })));
      } catch (e0) {
        completer0.completeError(e0);
      }
    });
    return completer0.future;
  }
  Future _writeAsset(Asset asset) {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        join0() {
          var destPath = _idToPath(asset.id);
          join1() {
            completer0.complete(_writeOutputFile(asset, destPath));
          }
          if (path.isWithin("packages", destPath)) {
            completer0.complete(
                Future.wait(
                    sourceDirectories.map(
                        ((buildDir) => _writeOutputFile(asset, path.join(buildDir, destPath))))));
          } else {
            join1();
          }
        }
        if (mode == BarbackMode.RELEASE && asset.id.extension == ".dart") {
          completer0.complete(null);
        } else {
          join0();
        }
      } catch (e0) {
        completer0.completeError(e0);
      }
    });
    return completer0.future;
  }
  String _idToPath(AssetId id) {
    var parts = path.split(path.fromUri(id.path));
    if (parts.length < 2) {
      throw new FormatException(
          "Can not build assets from top-level directory.");
    }
    if (parts[0] == "lib") {
      return path.join("packages", id.package, path.joinAll(parts.skip(1)));
    }
    assert(id.package == entrypoint.root.name);
    return path.joinAll(parts);
  }
  Future _writeOutputFile(Asset asset, String relativePath) {
    builtFiles++;
    var destPath = path.join(outputDirectory, relativePath);
    ensureDir(path.dirname(destPath));
    return createFileFromStream(asset.read(), destPath);
  }
  int _copyBrowserJsFiles(Iterable<AssetId> entrypoints) {
    if (!entrypoint.root.immediateDependencies.any(
        (dep) => dep.name == 'browser' && dep.source == 'hosted')) {
      return 0;
    }
    var entrypointDirs = entrypoints.map(
        (id) =>
            path.dirname(
                path.fromUri(id.path))).where((dir) => path.split(dir).length > 1).toSet();
    for (var dir in entrypointDirs) {
      _addBrowserJs(dir, "dart");
      _addBrowserJs(dir, "interop");
    }
    return entrypointDirs.length * 2;
  }
  void _addBrowserJs(String directory, String name) {
    var jsPath = entrypoint.root.path(
        outputDirectory,
        directory,
        'packages',
        'browser',
        '$name.js');
    ensureDir(path.dirname(jsPath));
    copyFile(path.join(entrypoint.packagesDir, 'browser', '$name.js'), jsPath);
  }
  Map _logEntryToJson(LogEntry entry) {
    var data = {
      "level": entry.level.name,
      "transformer": {
        "name": entry.transform.transformer.toString(),
        "primaryInput": {
          "package": entry.transform.primaryId.package,
          "path": entry.transform.primaryId.path
        }
      },
      "assetId": {
        "package": entry.assetId.package,
        "path": entry.assetId.path
      },
      "message": entry.message
    };
    if (entry.span != null) {
      data["span"] = {
        "url": entry.span.sourceUrl,
        "start": {
          "line": entry.span.start.line,
          "column": entry.span.start.column
        },
        "end": {
          "line": entry.span.end.line,
          "column": entry.span.end.column
        }
      };
    }
    return data;
  }
}
