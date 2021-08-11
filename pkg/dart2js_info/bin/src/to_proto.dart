// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command-line tool to convert an info.json file ouputted by dart2js to the
/// alternative protobuf format.

import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:dart2js_info/proto_info_codec.dart';
import 'package:dart2js_info/src/io.dart';

import 'inject_text.dart';
import 'usage_exception.dart';

/// Converts a dump-info file emitted by dart2js to the proto format
class ToProtoCommand extends Command<void> with PrintUsageException {
  final String name = "to_proto";
  final String description = "Convert any info file to proto format.";

  void run() async {
    if (argResults.rest.length < 1) {
      usageException('Missing argument: <input-info>');
      exit(1);
    }

    String filename = argResults.rest[0];
    final info = await infoFromFile(filename);
    if (argResults['inject-text']) injectText(info);
    final proto = new AllInfoProtoCodec().encode(info);
    String outputFilename = argResults['out'] ?? '$filename.pb';
    final outputFile = new File(outputFilename);
    await outputFile.writeAsBytes(proto.writeToBuffer(), mode: FileMode.write);
  }
}
