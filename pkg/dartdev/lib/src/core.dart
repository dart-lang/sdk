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

import 'experiments.dart';
import 'progress.dart';
import 'utils.dart';
import 'vm_interop_handler.dart';

final Ansi ansi = Ansi(Ansi.terminalSupportsAnsi);
final _defaultLogger = DartdevLogger(Logger.standard(ansi: ansi));
final _logKey = Object();

/// The [Logger] for the current [Zone].
Logger get log => Zone.current[_logKey] as Logger? ?? _defaultLogger;

/// The [DartdevLogger] for the current [Zone], or the default [DartdevLogger]
/// if the current zone's logger is not a [DartdevLogger].
DartdevLogger get dartdevLogger => switch (log) {
  final DartdevLogger logger => logger,
  _ => _defaultLogger,
};

/// Runs [callback] in a [Zone] with [logger] as the active [log].
R withLogger<R>(Logger logger, R Function() callback) =>
    runZoned(callback, zoneValues: {_logKey: logger});

/// Runs [callback] in a [Zone] with a [DartdevLogger] configured with the given
/// overrides, inheriting unspecified settings from the current [dartdevLogger].
R withDartdevLogger<R>(
  R Function() callback, {
  Logger? delegate,
  ProgressOutput? output,
}) {
  final current = dartdevLogger;
  return withLogger(
    DartdevLogger(
      delegate ?? current._delegate,
      output: output ?? current.output,
    ),
    callback,
  );
}

/// A delegating [Logger] that stops any active progress indicator whenever
/// output is printed to the terminal.
///
/// Also holds the zone-scoped [output] destination for `dartdev` status
/// messages and progress indicators.
final class DartdevLogger implements Logger {
  final Logger _delegate;

  /// Where informational output ([stdout]) and progress indicators are written.
  final ProgressOutput output;

  DartdevLogger(
    this._delegate, {
    this.output = ProgressOutput.stdout,
  });

  @override
  Ansi get ansi => _delegate.ansi;

  @override
  bool get isVerbose => _delegate.isVerbose;

  @override
  void stdout(String message) {
    switch (output) {
      case ProgressOutput.stdout:
        stopActiveProgress();
        _delegate.stdout(message);
      case ProgressOutput.stderr:
        stopActiveProgress();
        _delegate.stderr(message);
      case ProgressOutput.none:
        break;
    }
  }

  @override
  void stderr(String message) {
    stopActiveProgress();
    _delegate.stderr(message);
  }

  @override
  void trace(String message) {
    if (output == ProgressOutput.none) return;
    if (isVerbose) {
      stopActiveProgress();
    }
    _delegate.trace(message);
  }

  @override
  void write(String message) {
    switch (output) {
      case ProgressOutput.stdout:
        stopActiveProgress();
        _delegate.write(message);
      case ProgressOutput.stderr:
        stopActiveProgress();
        _delegate.stderr(message);
      case ProgressOutput.none:
        break;
    }
  }

  @override
  void writeCharCode(int charCode) {
    switch (output) {
      case ProgressOutput.stdout:
        stopActiveProgress();
        _delegate.writeCharCode(charCode);
      case ProgressOutput.stderr:
        stopActiveProgress();
        _delegate.stderr(String.fromCharCode(charCode));
      case ProgressOutput.none:
        break;
    }
  }

  @override
  Progress progress(String message) {
    stopActiveProgress();
    return _delegate.progress(message);
  }

  @override
  // ignore: deprecated_member_use, deprecated_member_use_from_same_package
  void flush() {
    // ignore: deprecated_member_use, deprecated_member_use_from_same_package
    _delegate.flush();
  }
}

bool isDiagnostics = false;

/// When set, this function is executed from the [DartdevCommand] constructor to
/// contribute additional flags.
void Function(ArgParser argParser, String cmdName)? flagContributor;

abstract class DartdevCommand extends Command<int> {
  static const errorExitCode = 65;

  final String _name;
  final String _description;
  final bool _verbose;
  final Project project = Project();

  @override
  final bool hidden;

  DartdevCommand(
    this._name,
    this._description,
    this._verbose, {
    this.hidden = false,
  }) {
    flagContributor?.call(argParser, _name);
  }

  /// Experiments enabled for this command (both from command-specific flags
  /// and global/VM flags passed before the subcommand).
  List<String> get enabledExperiments => {
    ...?argResults?.enabledExperiments,
    ...parseVmEnabledExperiments(Platform.executableArguments),
  }.toList();

  @override
  String get name => _name;

  @override
  String get description => _description;

  ArgParser? _argParser;

  @override
  ArgParser get argParser => _argParser ??= createArgParser();

  @override
  String get category {
    if (parent != null) {
      // Subcommands should not have a top level command category.
      assert(commandCategory == null);
      return '';
    }
    return commandCategory!.name;
  }

  CommandCategory? get commandCategory => null;

  @override
  String get invocation {
    String result = super.invocation;
    if (_verbose) {
      var firstSpace = result.indexOf(' ');
      if (firstSpace < 0) firstSpace = result.length;
      result = result.replaceRange(firstSpace, firstSpace, ' [vm-options]');
    }
    return result;
  }

  /// Create the ArgParser instance for this command.
  ///
  /// Subclasses can override this in order to create a customized ArgParser.
  ArgParser createArgParser() =>
      ArgParser(usageLineLength: dartdevUsageLineLength);

  /// Returns a [FileSystemEntity] (either [Directory] or [File]) corresponding
  /// to the single path specified in [arguments], or the current working
  /// directory if [arguments] is empty.
  ///
  /// Throws a [UsageException] if more than one argument is provided.
  FileSystemEntity getTarget(List<String> arguments) {
    final argumentCount = arguments.length;
    if (argumentCount > 1) {
      usageException('Only one file or directory is expected.');
    }

    final basePath = argumentCount == 0
        ? Directory.current.absolute.path
        : arguments.first;
    final normalizedPath = path.canonicalize(path.normalize(basePath));
    return FileSystemEntity.isDirectorySync(normalizedPath)
        ? Directory(normalizedPath)
        : File(normalizedPath);
  }
}

enum CommandCategory {
  global('Global'),
  project('Project'),
  sourceCode('Source code'),
  tools('Tools');

  final String name;

  const CommandCategory(this.name);
}

extension DartDevCommand<T> on Command<T> {
  /// Return whether commands should emit verbose output.
  bool get verbose => globalResults!.flag('verbose');

  /// Return whether the tool should emit diagnostic output.
  bool get diagnosticsEnabled => globalResults!.flag('diagnostics');

  /// Return whether any Dart experiments were specified by the user.
  bool get wereExperimentsSpecified =>
      globalResults?.wasParsed(experimentFlagName) ?? false;

  List<String> get specifiedExperiments =>
      globalResults!.multiOption(experimentFlagName);
}

Future<int> runProcess(
  List<String> command, {
  String? cwd,
  Map<String, String>? environment,
  void Function(String str)? listener,
  bool logToTrace = false,
}) async {
  Future<void> forward(Stream<List<int>> output, bool isStderr) {
    return _streamLineTransform(output, (line) {
      final trimmed = line.trimRight();
      logToTrace
          ? log.trace(trimmed)
          : (isStderr ? log.stderr(trimmed) : log.stdout(trimmed));
      if (listener != null) listener(line);
    });
  }

  log.trace(command.join(' '));
  final process = await Process.start(
    command.first,
    command.skip(1).toList(),
    workingDirectory: cwd,
    environment: {
      ...VmInteropHandler.environmentOverrides,
      ...?environment,
    },
  );
  final (_, _, exitCode) = await (
    forward(process.stdout, false),
    forward(process.stderr, true),
    process.exitCode,
  ).wait;
  return exitCode;
}

Future<void> _streamLineTransform(
  Stream<List<int>> stream,
  Function(String line) handler,
) {
  return stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(handler)
      .asFuture();
}

/// A representation of a project on disk.
class Project {
  final Directory dir;

  Project() : dir = Directory.current;

  Project.fromDirectory(this.dir);

  bool get hasPubspecFile =>
      FileSystemEntity.isFileSync(path.join(dir.path, 'pubspec.yaml'));

  File get pubspecFile => File(path.join(dir.path, 'pubspec.yaml'));
}
