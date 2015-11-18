// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.scanner.task;

import '../common/tasks.dart' show
    CompilerTask;
import '../compiler.dart' show
    Compiler;
import '../elements/elements.dart' show
    CompilationUnitElement,
    LibraryElement;
import '../script.dart' show
    Script;
import '../tokens/token.dart' show
    Token;

import 'scanner.dart' show
    Scanner;
import 'string_scanner.dart' show
    StringScanner;

class ScannerTask extends CompilerTask {
  ScannerTask(Compiler compiler) : super(compiler);
  String get name => 'Scanner';

  void scanLibrary(LibraryElement library) {
    CompilationUnitElement compilationUnit = library.entryCompilationUnit;
    String canonicalUri = library.canonicalUri.toString();
    String resolvedUri = compilationUnit.script.resourceUri.toString();
    if (canonicalUri == resolvedUri) {
      reporter.log("Scanning library $canonicalUri");
    } else {
      reporter.log("Scanning library $canonicalUri ($resolvedUri)");
    }
    scan(compilationUnit);
  }

  void scan(CompilationUnitElement compilationUnit) {
    measure(() {
      scanElements(compilationUnit);
    });
  }

  void scanElements(CompilationUnitElement compilationUnit) {
    Script script = compilationUnit.script;
    Token tokens = new Scanner(script.file,
        includeComments: compiler.preserveComments).tokenize();
    if (compiler.preserveComments) {
      tokens = compiler.processAndStripComments(tokens);
    }
    compiler.dietParser.dietParse(compilationUnit, tokens);
  }

  /**
   * Returns the tokens for the [source].
   *
   * The [StringScanner] implementation works on strings that end with a '0'
   * value ('\x00'). If [source] does not end with '0', the string is copied
   * before scanning.
   */
  Token tokenize(String source) {
    return measure(() {
      return new StringScanner.fromString(source, includeComments: false)
          .tokenize();
    });
  }
}
