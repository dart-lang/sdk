// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.terminal_color_support;

import 'dart:convert' show jsonEncode;

import 'dart:io' show Platform, Process, ProcessResult, stderr, stdout;

import '../fasta/colors.dart' show ALL_CODES, TERMINAL_CAPABILITIES;

import 'diagnostic_message.dart' show DiagnosticMessage;

/// True if we should enable colors in output.
///
/// We enable colors only when both [stdout] and [stderr] support ANSI escapes.
final bool enableTerminalColors = _computeEnableColors();

void printDiagnosticMessage(
    DiagnosticMessage message, void Function(String) println) {
  if (enableTerminalColors) {
    message.ansiFormatted.forEach(println);
  } else {
    message.plainTextFormatted.forEach(println);
  }
}

/// On Windows, colors are enabled if both stdout and stderr supports ANSI
/// escapes.  On other platforms, we rely on the external programs `tty` and
/// `tput` to compute if ANSI colors are supported.
bool _computeEnableColors() {
  const bool debug =
      const bool.fromEnvironment("front_end.debug_compute_enable_colors");

  if (Platform.isWindows) {
    if (!stdout.supportsAnsiEscapes || !stderr.supportsAnsiEscapes) {
      // In this case, either [stdout] or [stderr] did not support the property
      // `supportsAnsiEscapes`. Since we do not have another way to determine
      // support for colors, we disable them.
      if (debug) {
        print("Not enabling colors as ANSI is not supported.");
      }
      return false;
    }
    if (debug) {
      print("Enabling colors as OS is Windows.");
    }
    return true;
  }

  // We have to check if the terminal actually supports colors. Currently, to
  // avoid linking the Dart VM with ncurses, ANSI escape support is reduced to
  // `Platform.environment['TERM'].contains("xterm")`.

  // Check if stdin is a terminal (TTY).
  ProcessResult result =
      Process.runSync("/bin/sh", ["-c", "tty > /dev/null 2> /dev/null"]);

  if (result.exitCode != 0) {
    if (debug) {
      print("Not enabling colors, stdin isn't a terminal.");
    }
    return false;
  }

  // The `-S` option of `tput` allows us to query multiple capabilities at
  // once.
  result = Process.runSync(
      "/bin/sh", ["-c", "printf '%s' '$TERMINAL_CAPABILITIES' | tput -S"]);

  if (result.exitCode != 0) {
    if (debug) {
      print("Not enabling colors, running tput failed.");
    }
    return false;
  }

  List<String> lines = result.stdout.split("\n");

  if (lines.length != 2) {
    if (debug) {
      print("Not enabling colors, unexpected output from tput: "
          "${jsonEncode(result.stdout)}.");
    }
    return false;
  }

  String numberOfColors = lines[0];
  if ((int.tryParse(numberOfColors) ?? -1) < 8) {
    if (debug) {
      print("Not enabling colors, less than 8 colors supported: "
          "${jsonEncode(numberOfColors)}.");
    }
    return false;
  }

  String allCodes = lines[1].trim();
  if (ALL_CODES != allCodes) {
    if (debug) {
      print("Not enabling colors, color codes don't match: "
          "${jsonEncode(ALL_CODES)} != ${jsonEncode(allCodes)}.");
    }
    return false;
  }

  if (debug) {
    print("Enabling colors.");
  }
  return true;
}
