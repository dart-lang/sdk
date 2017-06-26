// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

/// A class that can return memory and cpu usage information for a given
/// process.
abstract class ProcessProfiler {
  ProcessProfiler._();

  Future<UsageInfo> getProcessUsage(int processId);

  UsageInfo getProcessUsageSync(int processId);

  /// Return a [ProcessProfiler] instance suitable for the current host
  /// platform. This can return `null` if we're not able to gather memory and
  /// cpu information for the current platform.
  static ProcessProfiler getProfilerForPlatform() {
    if (Platform.isLinux || Platform.isMacOS) {
      return new _PosixProcessProfiler();
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

  String toString() => '$cpuPercentage% ${memoryMB.toStringAsFixed(1)}MB';
}

class _PosixProcessProfiler extends ProcessProfiler {
  static final RegExp stringSplitRegExp = new RegExp(r'\s+');

  _PosixProcessProfiler() : super._();

  @override
  Future<UsageInfo> getProcessUsage(int processId) {
    try {
      // Execution time is typically 2-4ms.
      Future<ProcessResult> future =
          Process.run('ps', ['-o', '%cpu=,rss=', processId.toString()]);
      return future.then((ProcessResult result) {
        if (result.exitCode != 0) {
          return new Future.value(null);
        }

        return new Future.value(_parse(result.stdout));
      });
    } catch (e) {
      return new Future.error(e);
    }
  }

  UsageInfo getProcessUsageSync(int processId) {
    try {
      // Execution time is typically 2-4ms.
      ProcessResult result =
          Process.runSync('ps', ['-o', '%cpu=,rss=', processId.toString()]);
      return result.exitCode == 0 ? _parse(result.stdout) : null;
    } catch (e) {
      return null;
    }
  }

  UsageInfo _parse(String psResults) {
    try {
      // "  0.0 378940"
      String line = psResults.split('\n').first.trim();
      List<String> values = line.split(stringSplitRegExp);
      return new UsageInfo(double.parse(values[0]), int.parse(values[1]));
    } catch (e) {
      return null;
    }
  }
}
