// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';

/// A utility class to get information about the Dart related process running on
/// this machine.
class ProcessInfo {
  static final wsRegex = RegExp(r'\s+');

  final String command;
  final String commandLine;
  final int memoryMb;
  final double? cpuPercent;
  final String? elapsedTime;

  @visibleForTesting
  static ProcessInfo parseMacos(String line, {bool elideFilePaths = true}) {
    // "33712   0.0 01-19:07:19 launchd ..."
    line = line.replaceAll(wsRegex, ' ');

    String nextWord() {
      var index = line.indexOf(' ');
      var word = line.substring(0, index);
      line = line.substring(index + 1);
      return word;
    }

    var mb = nextWord();
    var cpu = nextWord();
    var elapsedTime = nextWord();
    var commandLine = line.trim();

    if (elideFilePaths) {
      return ProcessInfo.create(
        command: _getCommandFrom(commandLine),
        commandLine: _sanitizeCommandLine(commandLine, preferSnapshot: true),
        memoryMb: int.parse(mb) ~/ 1024,
        cpuPercent: double.tryParse(cpu.replaceAll(',', '.')),
        elapsedTime: elapsedTime,
      );
    } else {
      return ProcessInfo.create(
        command: _getCommandFrom(commandLine),
        commandLine: commandLine,
        memoryMb: int.parse(mb) ~/ 1024,
        cpuPercent: double.tryParse(cpu.replaceAll(',', '.')),
        elapsedTime: elapsedTime,
      );
    }
  }

  static ProcessInfo? _parseLinux(String line, {bool elideFilePaths = true}) {
    // "33712   0.0 01-19:07:19 launchd ..."
    line = line.replaceAll(wsRegex, ' ');

    String nextWord() {
      var index = line.indexOf(' ');
      var word = line.substring(0, index);
      line = line.substring(index + 1);
      return word;
    }

    var mb = nextWord();
    var cpu = nextWord();
    var elapsedTime = nextWord();
    var commandLine = line.trim();

    if (commandLine.startsWith('[') && commandLine.endsWith(']')) {
      return null;
    }

    if (elideFilePaths) {
      return ProcessInfo.create(
        command: _getCommandFrom(commandLine),
        commandLine: _sanitizeCommandLine(commandLine, preferSnapshot: true),
        memoryMb: int.parse(mb) ~/ 1024,
        cpuPercent: double.tryParse(cpu.replaceAll(',', '.')),
        elapsedTime: elapsedTime,
      );
    } else {
      return ProcessInfo.create(
        command: _getCommandFrom(commandLine),
        commandLine: commandLine,
        memoryMb: int.parse(mb) ~/ 1024,
        cpuPercent: double.tryParse(cpu.replaceAll(',', '.')),
        elapsedTime: elapsedTime,
      );
    }
  }

  @visibleForTesting
  static ProcessInfo? parseWindows(String line) {
    String stripQuotes(String item) {
      if (item.startsWith('"')) item = item.substring(1);
      if (item.endsWith('"')) item = item.substring(0, item.length - 1);
      return item;
    }

    // "dart.exe","12068","Console","1","233,384 K"
    var items = stripQuotes(line).split('","');

    if (items.isEmpty) {
      return null;
    }

    int parseMemory(String value) {
      if (value.contains(' ')) value = value.substring(0, value.indexOf(' '));
      value = value.replaceAll(',', '');
      return (int.tryParse(value) ?? 0) ~/ 1024;
    }

    return ProcessInfo.create(
      command: items.first,
      commandLine: items.first,
      memoryMb: parseMemory(items.length >= 5 ? items[4] : '0'),
      cpuPercent: null,
      elapsedTime: null,
    );
  }

  factory ProcessInfo.create({
    required String command,
    required String commandLine,
    required int memoryMb,
    required double? cpuPercent,
    required String? elapsedTime,
  }) {
    // Patch up the name if necessary (spaces in the path can throw off the
    // parsers).
    if (command.endsWith('.snapshot')) {
      commandLine = '$command $commandLine'.trim();
      command = 'dart';
    }

    return ProcessInfo._(
      command: command,
      commandLine: commandLine,
      memoryMb: memoryMb,
      cpuPercent: cpuPercent,
      elapsedTime: elapsedTime,
    );
  }

  const ProcessInfo._({
    required this.command,
    required this.commandLine,
    required this.memoryMb,
    required this.cpuPercent,
    required this.elapsedTime,
  });

  /// Return the Dart related processes.
  ///
  /// This will try to exclude the process for the VM currently running
  /// 'dart info'.
  ///
  /// This will return `null` if we don't support listing the process on the
  /// current platform.
  static List<ProcessInfo>? getProcessInfo({bool elideFilePaths = true}) {
    List<ProcessInfo>? processInfo;

    if (Platform.isMacOS) {
      processInfo = _getProcessInfoMacOS(elideFilePaths: elideFilePaths);
    } else if (Platform.isLinux) {
      processInfo = _getProcessInfoLinux(elideFilePaths: elideFilePaths);
    } else if (Platform.isWindows) {
      processInfo = _getProcessInfoWindows();
    }

    if (processInfo != null) {
      // Remove the 'dart info' entry.
      processInfo = processInfo
          .where((process) => process.commandLine != 'dart info')
          .toList();

      // Sort.
      processInfo.sort((a, b) => a.commandLine.compareTo(b.commandLine));
    }

    return processInfo;
  }

  /// Return the given [commandLine] with path-like elements replaced with
  /// shorter placeholders.
  static String _sanitizeCommandLine(
    String commandLine, {
    bool preferSnapshot = true,
  }) {
    final sep = Platform.pathSeparator;

    var args = commandLine.split(' ');

    // If we're running 'dart foo.snapshot ...', and we're already adjusting
    // the command line, shorten the command line so it appears that the
    // snapshot is being run directly (some command lines can be very long
    // otherwise).
    var index = args.indexWhere((arg) => arg.endsWith('.snapshot'));
    if (index != -1) {
      args = args.skip(index).toList();
    }

    String sanitizeArg(String arg) {
      if (!arg.contains(sep)) return arg;

      int start = arg.indexOf(sep);
      int end = arg.lastIndexOf(sep);
      if (start == end) return arg;

      return '${arg.substring(0, start)}<path>${arg.substring(end)}';
    }

    return [
      args.first.split(sep).last,
      ...args.skip(1).map(sanitizeArg),
    ].join(' ');
  }

  @override
  String toString() =>
      'ProcessInfo(memoryMb: $memoryMb, cpuPercent: $cpuPercent, elapsedTime:'
      ' $elapsedTime, command: $command, commandLine: $commandLine)';
}

List<ProcessInfo> _getProcessInfoMacOS({bool elideFilePaths = true}) {
  var result = Process.runSync('ps', ['-eo', 'rss,pcpu,etime,args']);
  if (result.exitCode != 0) {
    return const [];
  }

  //    RSS  %CPU     ELAPSED ARGS
  //  33712   0.0 01-19:07:19 launchd
  //  52624   0.0 01-19:06:18 logd
  //   4848   0.0 01-19:06:18 smd

  var lines = (result.stdout as String).split('\n');
  return lines
      .skip(1)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) =>
          ProcessInfo.parseMacos(line, elideFilePaths: elideFilePaths))
      .where(_isProcessDartRelated)
      .toList();
}

List<ProcessInfo> _getProcessInfoLinux({bool elideFilePaths = true}) {
  var result = Process.runSync('ps', ['-eo', 'rss,pcpu,etime,args']);
  if (result.exitCode != 0) {
    return const [];
  }

  var lines = (result.stdout as String).split('\n');
  return lines
      .skip(1)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) =>
          ProcessInfo._parseLinux(line, elideFilePaths: elideFilePaths))
      .whereType<ProcessInfo>()
      .where(_isProcessDartRelated)
      .toList();
}

List<ProcessInfo> _getProcessInfoWindows() {
  // TODO(devoncarew): Use tasklist /v to retrieve process elapsed time info.
  var result = Process.runSync('tasklist', ['/nh', '/fo', 'csv']);
  if (result.exitCode != 0) {
    return const [];
  }

  // "smss.exe","608","Services","0","288 K"
  // "csrss.exe","888","Services","0","3,084 K"
  // "wininit.exe","628","Services","0","1,104 K"
  // "dart.exe","12068","Console","1","233,384 K"

  var lines = (result.stdout as String).split('\n');
  return lines
      .skip(1)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => ProcessInfo.parseWindows(line))
      .whereType<ProcessInfo>()
      .where(_isProcessDartRelated)
      .toList();
}

bool _isProcessDartRelated(ProcessInfo process) {
  return process.command == 'dart' || process.command == 'dart.exe';
}

String _getCommandFrom(String commandLine) {
  var command = commandLine.split(' ').first;
  return command.split(Platform.pathSeparator).last;
}
