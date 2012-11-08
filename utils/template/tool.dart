// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library templatetool;

import 'dart:io';
import 'template.dart';
import '../lib/file_system.dart';
import '../lib/file_system_vm.dart';


FileSystem files;

/** Invokes [callback] and returns how long it took to execute in ms. */
num time(callback()) {
  final watch = new Stopwatch();
  watch.start();
  callback();
  watch.stop();
  return watch.elapsedMilliseconds;
}

String GREEN_COLOR = '\u001b[32m';
String NO_COLOR = '\u001b[0m';

printStats(String phase, num elapsed, [String filename = '']) {
  print('${phase} ${GREEN_COLOR}${filename}${NO_COLOR} in ${elapsed} msec.');
}

/**
 * Run from the `utils/css` directory.
 */
void main() {
  // argument 0 - sourcefile full path
  // argument 1 - outputfile full path
  var optionArgs = new Options().arguments;

  String sourceFullFn = optionArgs[0];
  String outputFullFn = optionArgs[1];

  String sourcePath;
  String sourceFilename;
  int idxBeforeFilename = sourceFullFn.lastIndexOf('/');
  if (idxBeforeFilename >= 0) {
    sourcePath = sourceFullFn.substring(0, idxBeforeFilename + 1);
    sourceFilename = sourceFullFn.substring(idxBeforeFilename + 1);
  }

  String outPath;
  String outFilename;
  idxBeforeFilename = outputFullFn.lastIndexOf('/');
  if (idxBeforeFilename >= 0) {
    outPath = outputFullFn.substring(0, idxBeforeFilename + 1);
    outFilename = outputFullFn.substring(idxBeforeFilename + 1);
  }

  if (sourceFilename.length == 0 || outFilename.length == 0) {
    print("Unknown command:\r");
    print("    Format: sourcefile outputfile [--options]");
    print("      outputfile - template file filename.tmpl");
    print("      outputfile - generated dart source file filename.dart");
    return;
  }

//  files = new NodeFileSystem();
  files = new VMFileSystem();

  // TODO(terry): Cleanup options handling need common options between template
  //              and CSS parsers also cleanup above cruft.

  // TODO(terry): Pass on switches.
  var args = [];
  parseOptions(args, files);

  initHtmlWorld(false);

  if (!files.fileExists(sourceFullFn)) {
    // Display colored error message if file is missing.
    print(world.fatal("CSS source file missing - ${sourceFullFn}"));
  } else {

    String source = files.readAll(sourceFullFn);

    List<Template> templates;
    final parsedElapsed = time(() {
      templates = templateParseAndValidate(source);
    });

    StringBuffer code = new StringBuffer();

    num codegenElapsed;
    if (world.errors == 0) {
      // Generate the Dart class(es) for all template(s).
      codegenElapsed = time(() {
        code.add(Codegen.generate(templates, outFilename));
      });
    }

    printStats("Parsed", parsedElapsed, sourceFullFn);
    printStats("Codegen", codegenElapsed, sourceFullFn);

    final outputElapsed = time(() {
      files.writeString(outputFullFn, code.toString());
    });

    printStats("Wrote file", codegenElapsed, outputFullFn);
  }
}
