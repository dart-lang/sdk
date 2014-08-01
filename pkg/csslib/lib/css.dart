// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library css;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';

import 'parser.dart';
import 'visitor.dart';
import 'src/messages.dart';
import 'src/options.dart';

void main(List<String> arguments) {
  // TODO(jmesserly): fix this to return a proper exit code
  var options = PreprocessorOptions.parse(arguments);
  if (options == null) return;

  messages = new Messages(options: options);

  _time('Total time spent on ${options.inputFile}', () {
    _compile(options.inputFile, options.verbose);
  }, true);
}

void _compile(String inputPath, bool verbose) {
  var ext = path.extension(inputPath);
  if (ext != '.css' && ext != '.scss') {
    messages.error("Please provide a CSS/Sass file", null);
    return;
  }
  try {
    // Read the file.
    var filename = path.basename(inputPath);
    var contents = new File(inputPath).readAsStringSync();
    var file = new SourceFile(contents, url: path.toUri(inputPath));

    // Parse the CSS.
    var tree = _time('Parse $filename',
        () => new Parser(file, contents).parse(), verbose);

    _time('Analyzer $filename',
        () => new Analyzer([tree], messages), verbose).run();

    // Emit the processed CSS.
    var emitter = new CssPrinter();
    _time('Codegen $filename',
        () => emitter.visitTree(tree, pretty: true), verbose);

    // Write the contents to a file.
    var outPath = path.join(path.dirname(inputPath), '_$filename');
    new File(outPath).writeAsStringSync(emitter.toString());
  } catch (e) {
    messages.error('error processing $inputPath. Original message:\n $e', null);
  }
}

_time(String message, callback(), bool printTime) {
  if (!printTime) return callback();
  final watch = new Stopwatch();
  watch.start();
  var result = callback();
  watch.stop();
  final duration = watch.elapsedMilliseconds;
  _printMessage(message, duration);
  return result;
}

void _printMessage(String message, int duration) {
  var buf = new StringBuffer();
  buf.write(message);
  for (int i = message.length; i < 60; i++) buf.write(' ');
  buf.write(' -- ');
  if (duration < 10) buf.write(' ');
  if (duration < 100) buf.write(' ');
  buf..write(duration)..write(' ms');
  print(buf.toString());
}
