// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command-line tool presenting combined information from dump-info and
/// coverage data.
///
/// This tool requires two input files an `.info.json` and a
/// `.coverage.json` file. To produce these files you need to follow these
/// steps:
///
///   * Compile an app with dart2js using --dump-info and defining the
///     Dart environment `traceCalls=post`:
///
///      DART_VM_OPTIONS="-DtraceCalls=post" dart2js --dump-info main.dart
///
///     Because coverage/tracing data is currently experimental, the feature is
///     not exposed as a flag in dart2js, but you can enable it using the Dart
///     environment flag. The flag only works dart2js version 1.13.0 or newer.
///
///   * Launch the coverage server tool (in this package) to serve up the
///     Javascript code in your app:
///
///      dart tool/coverage_log_server.dart main.dart.js
///
///   * (optional) If you have a complex application setup, integrate your
///     application server to proxy to the log server any GET request for the
///     .dart.js file and /coverage POST requests that send coverage data.
///
///   * Load your app and use it to exercise the entire code.
///
///   * Shut down the coverage server (Ctrl-C)
///
///   * Finally, run this tool.
library compiler.tool.live_code_size_analysis;

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';

import 'function_size_analysis.dart';
import 'usage_exception.dart';

class LiveCodeAnalysisCommand extends Command<void> with PrintUsageException {
  final String name = "coverage_analysis";
  final String description = "Analyze coverage data collected via the"
      " 'coverage_server' command";

  LiveCodeAnalysisCommand() {
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Show verbose details.');
  }

  void run() async {
    var args = argResults.rest;
    if (args.length < 2) {
      usageException('Missing arguments, expected: info.data coverage.json');
    }
    await _liveCodeAnalysis(args[0], args[1], argResults['verbose']);
  }
}

_liveCodeAnalysis(infoFile, coverageFile, bool verbose) async {
  var info = await infoFromFile(infoFile);
  var coverage = jsonDecode(new File(coverageFile).readAsStringSync());

  int realTotal = info.program.size;
  int totalLib = info.libraries.fold(0, (n, lib) => n + lib.size);

  int totalCode = 0;
  int reachableCode = 0;
  List<Info> unused = [];

  void tallyCode(Info f) {
    totalCode += f.size;

    var data = coverage[f.coverageId];
    if (data != null) {
      // Validate that the name match, it might not match if using a different
      // version of the app.
      // TODO(sigmund): use the same name.
      // TODO(sigmund): inject a time-stamp in the code and dumpinfo and
      // validate just once.
      var name = f.name;
      if (name.contains('.')) name = name.substring(name.lastIndexOf('.') + 1);
      var otherName = data['name'];
      if (otherName.contains('.')) {
        otherName = otherName.substring(otherName.lastIndexOf('.') + 1);
      }
      if (otherName != name && otherName != '') {
        print('invalid coverage: $data for $f, ($name vs $otherName)');
      }
      reachableCode += f.size;
    } else {
      // we should track more precisely data about inlined functions
      unused.add(f);
    }
  }

  info.functions.forEach(tallyCode);
  info.fields.forEach(tallyCode);

  _showHeader('', 'bytes', '%');
  _show('Program size', realTotal, realTotal);
  _show('Libraries (excluding statics)', totalLib, realTotal);
  _show('Code (functions + fields)', totalCode, realTotal);
  _show('Reachable code', reachableCode, realTotal);

  print('');
  _showHeader('', 'count', '%');
  var total = info.functions.length + info.fields.length;
  _show('Functions + fields', total, total);
  _show('Reachable', total - unused.length, total);

  // TODO(sigmund): support grouping results by package.
  if (verbose) {
    print('\nDistribution of code that was not used when running the app:');
    showCodeDistribution(info,
        filter: (f) => !coverage.containsKey(f.coverageId) && f.size > 0,
        showLibrarySizes: true);
  } else {
    print('\nUse `-v` to see details about the size of unreachable code');
  }
}

_showHeader(String msg, String header1, String header2) {
  print(' ${pad(msg, 30, right: true)} ${pad(header1, 8)} ${pad(header2, 6)}');
}

_show(String msg, int size, int total) {
  var percent = (size * 100 / total).toStringAsFixed(2);
  print(' ${pad(msg, 30, right: true)} ${pad(size, 8)} ${pad(percent, 6)}%');
}
