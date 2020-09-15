// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// A class that can return memory and cpu usage information for a given
/// process.
abstract class ProcessProfiler {
  ProcessProfiler._();

  Future<UsageInfo> getProcessUsage(int processId);

  /// Return a [ProcessProfiler] instance suitable for the current host
  /// platform. This can return `null` if we're not able to gather memory and
  /// cpu information for the current platform.
  static ProcessProfiler getProfilerForPlatform() {
    if (Platform.isLinux || Platform.isMacOS) {
      return _PosixProcessProfiler();
    }

    // Not a supported platform.
    return null;
  }
}

class UsageInfo {
  /// A number between 0.0 and 100.0 * the number of host CPUs (but typically
  /// never more than slightly above 100.0).
  final double cpuPercentage;

  /// The process memory usage in kilobytes.
  final int memoryKB;

  UsageInfo(this.cpuPercentage, this.memoryKB);

  double get memoryMB => memoryKB / 1024;

  @override
  String toString() => '$cpuPercentage% ${memoryMB.toStringAsFixed(1)}MB';
}

class _PosixProcessProfiler extends ProcessProfiler {
  static final RegExp stringSplitRegExp = RegExp(r'\s+');

  _PosixProcessProfiler() : super._();

  @override
  Future<UsageInfo> getProcessUsage(int processId) {
    try {
      // Execution time is typically 2-4ms.
      var future =
          Process.run('ps', ['-o', '%cpu=,rss=', processId.toString()]);
      return future.then((ProcessResult result) {
        if (result.exitCode != 0) {
          return Future.value(null);
        }

        return Future.value(_parse(result.stdout));
      });
    } catch (e) {
      return Future.error(e);
    }
  }

  UsageInfo _parse(String psResults) {
    try {
      // "  0.0 378940"
      var line = psResults.split('\n').first.trim();
      var values = line.split(stringSplitRegExp);
      return UsageInfo(double.parse(values[0]), int.parse(values[1]));
    } catch (e) {
      return null;
    }
  }
}
