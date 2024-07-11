// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';
import 'package:dart2js_info/src/io.dart';

import 'inject_text.dart';
import 'usage_exception.dart';

/// Converts a dump-info file emitted by dart2js in binary format to JSON.
class ToJsonCommand extends Command<void> with PrintUsageException {
  @override
  final String name = "to_json";
  @override
  final String description = "Convert any info file to JSON format.";

  ToJsonCommand() {
    argParser.addFlag('compat-mode',
        negatable: false,
        help: 'Whether to generate an older version of the JSON format.\n\n'
            'By default files are converted to the latest JSON format.\n'
            'This option enables `--inject-text` as well, but note that\n'
            'files produced in this mode do not contain all the data\n'
            'available in the input file.');
  }

  @override
  void run() async {
    final args = argResults!;
    if (args.rest.isEmpty) {
      usageException('Missing argument: <input-info>');
    }

    String filename = args.rest[0];
    bool isBackwardCompatible = args['compat-mode'];
    AllInfo info = await infoFromFile(filename);

    if (isBackwardCompatible || args['inject-text']) {
      injectText(info);
    }

    var json = AllInfoJsonCodec(isBackwardCompatible: isBackwardCompatible)
        .encode(info);
    String outputFilename = args['out'] ?? '$filename.json';
    final sink = File(outputFilename).openWrite();
    final converterSink = const JsonEncoder.withIndent("  ")
        .startChunkedConversion(_BufferedStringOutputSink(sink));
    converterSink.add(json);
    converterSink.close();
    await sink.close();
  }
}

class _BufferedStringOutputSink implements Sink<String> {
  StringBuffer buffer = StringBuffer();
  final StringSink outputSink;
  static const int _maxLength = 1024 * 1024 * 500;

  _BufferedStringOutputSink(this.outputSink);

  @override
  void add(String data) {
    buffer.write(data);
    if (buffer.length > _maxLength) {
      outputSink.write(buffer.toString());
      buffer.clear();
    }
  }

  @override
  void close() {
    outputSink.write(buffer.toString());
  }
}
