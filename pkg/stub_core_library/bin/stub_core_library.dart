// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stub_core_library.bin;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'package:stub_core_library/src/utils.dart';
import 'package:stub_core_library/stub_core_library.dart';

/// A map from Dart core library sources to the filenames into which they should
/// be generated.
///
/// The source paths are URL-formatted and relative to the Dart SDK root.
const CORE_LIBRARIES = const {
  'lib/io/io.dart': 'dart_io.dart',
  'lib/html/html_common/html_common.dart': 'dart_html_common.dart',
  'lib/html/html_common/metadata.dart': 'metadata.dart',
  'lib/html/dartium/html_dartium.dart': 'dart_html.dart',
  'lib/indexed_db/dartium/indexed_db_dartium.dart': 'dart_indexed_db.dart',
  'lib/js/dartium/js_dartium.dart': 'dart_js.dart',
  'lib/svg/dartium/svg_dartium.dart': 'dart_svg.dart',
  'lib/web_audio/dartium/web_audio_dartium.dart': 'dart_web_audio.dart',
  'lib/web_gl/dartium/web_gl_dartium.dart': 'dart_web_gl.dart',
  'lib/web_sql/dartium/web_sql_dartium.dart': 'dart_web_sql.dart'
};

/// A map from stubbable "dart:" URLs to the names of the stub files they should
/// be replaced with.
const IMPORT_REPLACEMENTS = const {
  'dart:io': 'dart_io.dart',
  'dart:html_common': 'dart_html_common.dart',
  'dart:html': 'dart_html.dart',
  'dart:indexed_db': 'dart_indexed_db.dart',
  'dart:js': 'dart_js.dart',
  'dart:svg': 'dart_svg.dart',
  'dart:web_audio': 'dart_web_audio.dart',
  'dart:web_gl': 'dart_web_gl.dart',
  'dart:web_sql': 'dart_web_sql.dart'
};

/// The exit code for a usage error.
const USAGE_ERROR = 64;

/// The root directory of the SDK.
String get sdkRoot => p.join(
    p.dirname(p.fromUri(Platform.script)), '..', '..', '..', 'sdk');

/// The argument parser.
final argParser = new ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Print this usage information.');

/// The usage string.
String get usage => """
Generate Dart core library stubs.

Usage: stub_core_libraries.dart <directory>

${argParser.getUsage()}""";

void main(List<String> arguments) {
  var options;
  try {
    options = argParser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(usage);
    exitCode = USAGE_ERROR;
    return;
  }

  if (options['help']) {
    print(usage);
    return;
  }

  var destination = options.rest.isEmpty ? p.current : options.rest.first;

  // Don't allow extra arguments.
  if (options.rest.length > 1) {
    var unexpected = options.rest.skip(1).map((arg) => '"$arg"');
    var arguments = pluralize("argument", unexpected.length);
    stderr.writeln("Unexpected $arguments ${toSentence(unexpected)}.");
    stderr.writeln(usage);
    exitCode = USAGE_ERROR;
    return;
  }

  new Directory(destination).createSync(recursive: true);

  // TODO(nweiz): Tree-shake these libraries when issue 19896 is fixed.
  CORE_LIBRARIES.forEach((path, output) {
    path = p.join(sdkRoot, p.fromUri(path));
    new File(p.join(destination, output))
        .writeAsStringSync(stubFile(path, IMPORT_REPLACEMENTS));
  });
}
