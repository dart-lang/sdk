#!/usr/bin/env dart

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:utf';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:analyzer_experimental/src/services/formatter_impl.dart';


const BINARY_NAME = 'dartfmt';
final dartFileRegExp = new RegExp(r'^[^.].*\.dart$', caseSensitive: false);
final argParser = _initArgParser();

bool overwriteFileContents;
const followLinks = false;

main() {
  var options = argParser.parse(new Options().arguments);
  if (options['help']) {
    _printUsage();
    return;
  }
  overwriteFileContents = options['write'];

  if (options.rest.isEmpty) {
    _formatStdin(options);
  } else {
    _formatPaths(options.rest);
  }
}

_formatPaths(paths) {
  paths.forEach((path) {
    if (FileSystemEntity.isDirectorySync(path)) {
      _formatDirectory(new Directory(path));
    } else {
      _formatFile(new File(path));
    }
  });
}

_formatResource(resource) {
  if (resource is Directory) {
    _formatDirectory(resource);
  } else if (resource is File) {
    _formatFile(resource);
  }
}

_formatDirectory(dir) => dir.listSync(followLinks: followLinks)
    .forEach((resource) => _formatResource(resource));

_formatFile(file) {
  if (_isDartFile(file)) {
    try {
      var buffer = new StringBuffer();
      var rawSource = file.readAsStringSync();
      var formatted = _formatCU(rawSource);
      if (overwriteFileContents) {
        file.writeAsStringSync(formatted);
      } else {
        print(formatted);
      }
    } catch (e) {
      _log('Unable to format "${file.path}": $e');
    }
  }
}

_isDartFile(file) => dartFileRegExp.hasMatch(path.basename(file.path));

_formatStdin(options) {
  var input = new StringBuffer();
  stdin.transform(new Utf8DecoderTransformer())
      .listen((data) => input.write(data),
        onError: (error) => _log('Error reading from stdin'),
        onDone: () => print(_formatCU(input.toString())));
}

/// Initialize the arg parser instance.
ArgParser _initArgParser() {
  // NOTE: these flags are placeholders only!
  var parser = new ArgParser();
  parser.addFlag('write', abbr: 'w', negatable: false,
      help: 'Write reformatted sources to files (overwriting contents).  '
            'Do not print reformatted sources to standard output.');
  parser.addFlag('help', abbr: 'h', negatable: false,
      help: 'Print this usage information.');
  return parser;
}


/// Displays usage information.
_printUsage() {
  var buffer = new StringBuffer();
  buffer..write('$BINARY_NAME formats Dart programs.')
        ..write('\n\n')
        ..write('Without an explicit path, $BINARY_NAME processes the standard '
                'input.  Given a file, it operates on that file; given a '
                'directory, it operates on all .dart files in that directory, '
                'recursively. (Files starting with a period are ignored.) By '
                'default, $BINARY_NAME prints the reformatted sources to '
                'standard output.')
        ..write('\n\n')
        ..write('Supported flags are:')
        ..write('Usage: $BINARY_NAME [flags] [path...]\n\n')
        ..write('${argParser.getUsage()}\n\n');
  _log(buffer.toString());
}

/// Format the given [src] as a compilation unit.
String _formatCU(src, {options: const FormatterOptions()}) =>
    new CodeFormatter(options).format(CodeKind.COMPILATION_UNIT, src).source;

/// Log the given [msg].
_log(String msg) {
  //TODO(pquitslund): add proper log support
  print(msg);
}