// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Usage: Add the following to your .gclient file (found in the parent
// of the "dart" in a gclient checkout of the Dart repositor).
//
// hooks = [
//   {
//     "pattern": ".",
//     "action": [
//       "dart/sdk/bin/dart",
//       "dart/sdk/lib/_internal/compiler/samples/darttags/darttags.dart",
//       "dart/TAGS"
//     ],
//   },
// ]
//
// Modify .emacs to contain:
//
//      (setq tags-table-list
//           '("DART_LOCATION/dart"))
//
// Where DART_LOCATION is the gclient directory where you found .gclient.

import 'dart:io';

import 'dart:mirrors';

import '../../../libraries.dart'
    show LIBRARIES, LibraryInfo;

import '../../implementation/mirrors/analyze.dart'
    show analyze;
import '../../implementation/mirrors/dart2js_mirrors.dart'
    show BackDoor;
import '../../implementation/mirrors/mirrors_util.dart' show nameOf;

import '../../implementation/filenames.dart';
import '../../implementation/source_file.dart';
import '../../implementation/source_file_provider.dart';
import '../../implementation/util/uri_extras.dart';

const DART2JS = '../../implementation/dart2js.dart';
const DART2JS_MIRROR = '../../implementation/mirrors/dart2js_mirrors.dart';
const SDK_ROOT = '../../../../../';

bool isPublicDart2jsLibrary(String name) {
  return !name.startsWith('_') && LIBRARIES[name].isDart2jsLibrary;
}

var handler;
RandomAccessFile output;
Uri outputUri;

main(List<String> arguments) {
  handler = new FormattingDiagnosticHandler()
      ..throwOnError = true;

  outputUri =
      handler.provider.cwd.resolve(nativeToUriPath(arguments.first));
  output = new File(arguments.first).openSync(mode: FileMode.WRITE);

  Uri myLocation =
      handler.provider.cwd.resolveUri(Platform.script);

  // Get the names of public dart2js libraries.
  Iterable<String> names = LIBRARIES.keys.where(isPublicDart2jsLibrary);

  // Prepend "dart:" to the names.
  List<Uri> uris = names.map((String name) => Uri.parse('dart:$name')).toList();

  // Append dart2js itself.
  uris.add(myLocation.resolve(DART2JS));
  uris.add(myLocation.resolve(DART2JS_MIRROR));

  analyze(uris, myLocation.resolve(SDK_ROOT), null, handler.provider, handler)
      .then(processMirrors);
}

processMirrors(MirrorSystem mirrors) {
  mirrors.libraries.forEach((_, LibraryMirror library) {
    BackDoor.compilationUnitsOf(library).forEach(emitTagsForCompilationUnit);
  });

  output.closeSync();
}

/**
 * From http://en.wikipedia.org/wiki/Ctags#Etags_2
 *
 * A section starts with a two line header, one line containing a
 * single <\x0c> character, followed by a line which consists of:
 *
 * {src_file},{size_of_tag_definition_data_in_bytes}
 *
 * The header is followed by tag definitions, one definition per line,
 * with the format:
 *
 * {tag_definition_text}<\x7f>{tagname}<\x01>{line_number},{byte_offset}
 */
emitTagsForCompilationUnit(compilationUnit) {
  // Certain variables in this method do not follow Dart naming
  // conventions.  This is because the format as written on Wikipedia
  // looks very similar to Dart string interpolation that the author
  // felt it would make sense to keep the names.
  Uri uri = compilationUnit.uri;
  var buffer = new StringBuffer();
  SourceFile file = handler.provider.sourceFiles['$uri'];

  compilationUnit.declarations.forEach((_, DeclarationMirror mirror) {
    var tagname = nameOf(mirror);
    var byte_offset = mirror.location.offset;
    var line_number = file.getLine(byte_offset) + 1;

    var lineStart = file.lineStarts[line_number - 1];
    // TODO(ahe): Most often an empty string.  Try to see if we can
    // get the position of the name token instead.
    var tag_definition_text = file.slowText().substring(lineStart, byte_offset);

    // One definition.
    buffer.write('${tag_definition_text}\x7f${tagname}'
                 '\x01${line_number},${byte_offset}\n');
  });

  var tag_definition_data = '$buffer';
  var src_file = relativize(outputUri, uri, false);
  var size_of_tag_definition_data_in_bytes = tag_definition_data.length;

  // The header.
  output.writeStringSync(
      '\x0c\n${src_file},${size_of_tag_definition_data_in_bytes}\n');
  output.writeStringSync(tag_definition_data);
}
