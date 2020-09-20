// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as path;

import 'analytics.dart';
import 'events.dart';
import 'experiments.dart';
import 'sdk.dart';
import 'utils.dart';

Logger log;
bool isDiagnostics = false;

abstract class DartdevCommand<int> extends Command {
  final String _name;
  final String _description;

  Project _project;

  @override
  final bool hidden;

  DartdevCommand(this._name, this._description, {this.hidden = false});

  @override
  String get name => _name;

  @override
  String get description => _description;

  ArgParser _argParser;

  @override
  ArgParser get argParser => _argParser ??= createArgParser();

  /// This method should not be overridden by subclasses, instead classes should
  /// override [runImpl] and [createUsageEvent]. If analytics is enabled by this
  /// command and the user, a [sendScreenView] is called to analytics, and then
  /// after the command is run, an event is sent to analytics.
  ///
  /// If analytics is not enabled by this command or the user, then [runImpl] is
  /// called and the exitCode value is returned.
  @override
  FutureOr<int> run() async {
    var path = usagePath;
    if (path != null &&
        analyticsInstance != null &&
        analyticsInstance.enabled) {
      // Send the screen view to analytics
      // ignore: unawaited_futures
      analyticsInstance.sendScreenView(path);

      // Run this command
      var exitCode = await runImpl();

      // Send the event to analytics
      // ignore: unawaited_futures
      createUsageEvent(exitCode)?.send(analyticsInstance);

      // Finally return the exit code
      return exitCode;
    } else {
      // Analytics is not enabled, run the command and return the exit code
      return runImpl();
    }
  }

  UsageEvent createUsageEvent(int exitCode);

  FutureOr<int> runImpl();

  /// The command name path to send to Google Analytics. Return null to disable
  /// tracking of the command.
  String get usagePath {
    if (parent is DartdevCommand) {
      final commandParent = parent as DartdevCommand;
      final parentPath = commandParent.usagePath;
      // Don't report for parents that return null for usagePath.
      return parentPath == null ? null : '$parentPath/$name';
    } else {
      return name;
    }
  }

  /// Create the ArgParser instance for this command.
  ///
  /// Subclasses can override this in order to create a customized ArgParser.
  ArgParser createArgParser() =>
      ArgParser(usageLineLength: dartdevUsageLineLength);

  Project get project => _project ??= Project();

  /// Return whether commands should emit verbose output.
  bool get verbose => globalResults['verbose'];

  /// Return whether the tool should emit diagnostic output.
  bool get diagnosticsEnabled => globalResults['diagnostics'];

  /// Return whether any Dart experiments were specified by the user.
  bool get wereExperimentsSpecified =>
      globalResults?.wasParsed(experimentFlagName) ?? false;

  /// Return the list of Dart experiment flags specified by the user.
  List<String> get specifiedExperiments => globalResults[experimentFlagName];
}

/// A utility method to start a Dart VM instance with the given arguments and an
/// optional current working directory.
///
/// [arguments] should contain the snapshot path.
Future<Process> startDartProcess(
  Sdk sdk,
  List<String> arguments, {
  String cwd,
}) {
  log.trace('${sdk.dart} ${arguments.join(' ')}');
  return Process.start(sdk.dart, arguments, workingDirectory: cwd);
}

void routeToStdout(
  Process process, {
  bool logToTrace = false,
  void Function(String str) listener,
}) {
  if (isDiagnostics) {
    _streamLineTransform(process.stdout, (String line) {
      logToTrace ? log.trace(line.trimRight()) : log.stdout(line.trimRight());
      if (listener != null) listener(line);
    });
    _streamLineTransform(process.stderr, (String line) {
      log.stderr(line.trimRight());
      if (listener != null) listener(line);
    });
  } else {
    _streamLineTransform(process.stdout, (String line) {
      logToTrace ? log.trace(line.trimRight()) : log.stdout(line.trimRight());
      if (listener != null) listener(line);
    });

    _streamLineTransform(process.stderr, (String line) {
      log.stderr(line.trimRight());
      if (listener != null) listener(line);
    });
  }
}

void _streamLineTransform(
  Stream<List<int>> stream,
  Function(String line) handler,
) {
  stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(handler);
}

/// A representation of a project on disk.
class Project {
  final Directory dir;

  PackageConfig _packageConfig;

  Project() : dir = Directory.current;

  Project.fromDirectory(this.dir);

  bool get hasPubspecFile =>
      FileSystemEntity.isFileSync(path.join(dir.path, 'pubspec.yaml'));

  bool get hasPackageConfigFile => packageConfig != null;

  PackageConfig get packageConfig {
    if (_packageConfig == null) {
      File file =
          File(path.join(dir.path, '.dart_tool', 'package_config.json'));

      if (file.existsSync()) {
        try {
          dynamic contents = json.decode(file.readAsStringSync());
          _packageConfig = PackageConfig(contents);
        } catch (_) {}
      }
    }

    return _packageConfig;
  }
}

/// A simple representation of a `package_config.json` file.
class PackageConfig {
  final Map<String, dynamic> contents;

  PackageConfig(this.contents);

  List<Map<String, dynamic>> get packages {
    List<dynamic> _packages = contents['packages'];
    return _packages.map<Map<String, dynamic>>(castStringKeyedMap).toList();
  }

  bool hasDependency(String packageName) =>
      packages.any((element) => element['name'] == packageName);
}
