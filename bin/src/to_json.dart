// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';
import 'package:dart2js_info/src/io.dart';

import 'inject_text.dart';
import 'usage_exception.dart';

/// Converts a dump-info file emitted by dart2js in binary format to JSON.
class ToJsonCommand extends Command<void> with PrintUsageException {
  final String name = "to_json";
  final String description = "Convert any info file to JSON format.";

  ToJsonCommand() {
    argParser.addFlag('compat-mode',
        negatable: false,
        help: 'Whether to generate an older version of the JSON format.\n\n'
            'By default files are converted to the latest JSON format, but\n'
            'passing `--compat-mode` will produce a JSON file that may still\n'
            'work in the visualizer tool at:\n'
            'https://dart-lang.github.io/dump-info-visualizer/.\n\n'
            'This option enables `--inject-text` as well, but note that\n'
            'files produced in this mode do not contain all the data\n'
            'available in the input file.');
  }

  void run() async {
    if (argResults.rest.length < 1) {
      usageException('Missing argument: <input-info>');
    }

    String filename = argResults.rest[0];
    bool isBackwardCompatible = argResults['compat-mode'];
    AllInfo info = await infoFromFile(filename);

    if (isBackwardCompatible || argResults['inject-text']) {
      injectText(info);
    }

    var json = new AllInfoJsonCodec(isBackwardCompatible: isBackwardCompatible)
        .encode(info);
    String outputFilename = argResults['out'] ?? '$filename.json';
    new File(outputFilename)
        .writeAsStringSync(const JsonEncoder.withIndent("  ").convert(json));
  }
}
