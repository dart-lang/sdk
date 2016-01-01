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
//       # Replace "xcodebuild" with "out" on Linux, and "build" on Windows.
//       "-pdart/xcodebuild/ReleaseIA32/packages/",
//       "dart/pkg/compiler/samples/darttags/darttags.dart",
//       "dart/TAGS",
//       # Modify the following list to your preferences:
//       "dart/tests/try/web/incremental_compilation_update_test.dart",
//       "package:compiler/src/dart2js.dart",
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

import 'package:sdk_library_metadata/libraries.dart'
    show libraries, LibraryInfo;

import 'package:compiler/src/mirrors/analyze.dart'
    show analyze;
import 'package:compiler/src/mirrors/dart2js_mirrors.dart'
    show BackDoor;
import 'package:compiler/src/mirrors/mirrors_util.dart' show nameOf;

import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/util/uri_extras.dart';

const DART2JS = 'package:compiler/src/dart2js.dart';
const DART2JS_MIRROR = 'package:compiler/src/mirrors/dart2js_mirrors.dart';
const SDK_ROOT = '../../../../sdk/';

bool isPublicDart2jsLibrary(String name) {
  return !name.startsWith('_') && libraries[name].isDart2jsLibrary;
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

  List<Uri> uris = <Uri>[];

  if (arguments.length > 1) {
    // Compute tags for libraries requested by the user.
    uris.addAll(
        arguments.skip(1).map((argument) => Uri.base.resolve(argument)));
  } else {
    // Compute tags for dart2js itself.
    uris.add(myLocation.resolve(DART2JS));
    uris.add(myLocation.resolve(DART2JS_MIRROR));
  }

  // Get the names of public dart2js libraries.
  Iterable<String> names = libraries.keys.where(isPublicDart2jsLibrary);

  // Prepend "dart:" to the names.
  uris.addAll(names.map((String name) => Uri.parse('dart:$name')));

  Uri platformConfigUri = myLocation.resolve(SDK_ROOT)
      .resolve("lib/dart2js_shared_sdk");
  Uri packageRoot = Uri.base.resolve(Platform.packageRoot);

  analyze(uris, platformConfigUri, packageRoot, handler.provider, handler)
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
  SourceFile file = handler.provider.sourceFiles[uri];
  String src_file = relativize(outputUri, uri, false);

  compilationUnit.declarations.forEach((_, DeclarationMirror mirror) {
    Definition definition = new Definition.from(mirror, file);
    String name = nameOf(mirror);
    definition.writeOn(buffer, name);

    if (mirror is ClassMirror) {
      emitTagsForClass(mirror, file, buffer);
    }
  });

  var tag_definition_data = '$buffer';
  var size_of_tag_definition_data_in_bytes = tag_definition_data.length;

  // The header.
  output.writeStringSync(
      '\x0c\n${src_file},${size_of_tag_definition_data_in_bytes}\n');
  output.writeStringSync(tag_definition_data);
}

void emitTagsForClass(ClassMirror cls, SourceFile file, StringBuffer buffer) {
  String className = nameOf(cls);

  cls.declarations.forEach((_, DeclarationMirror mirror) {
    Definition definition = new Definition.from(mirror, file);
    String name = nameOf(mirror);
    if (mirror is MethodMirror && mirror.isConstructor) {
      if (name == '') {
        name = className;
        definition.writeOn(buffer, 'new $className');
      } else {
        definition.writeOn(buffer, 'new $className.$name');
      }
    } else {
      definition.writeOn(buffer, '$className.$name');
    }
    definition.writeOn(buffer, name);
  });
}

class Definition {
  final int byte_offset;
  final int line_number;
  final String tag_definition_text;

  Definition(this.byte_offset, this.line_number, this.tag_definition_text);

  factory Definition.from(DeclarationMirror mirror, SourceFile file) {
    var location = mirror.location;
    int byte_offset = location.offset;
    int line_number = file.getLine(byte_offset) + 1;

    int lineStart = file.lineStarts[line_number - 1];

    int lineEnd = file.lineStarts.length > line_number
        // Subract 1 to remove trailing newline.
        ? file.lineStarts[line_number] - 1
        : null;
    String tag_definition_text = file.slowText().substring(lineStart, lineEnd);

    return new Definition(byte_offset, line_number, tag_definition_text);
  }

  void writeOn(StringBuffer buffer, String tagname) {
    buffer.write(
        '${tag_definition_text}\x7f${tagname}'
        '\x01${line_number},${byte_offset}\n');
  }
}
