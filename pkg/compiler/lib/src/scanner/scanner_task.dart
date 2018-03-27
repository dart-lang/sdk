// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.scanner.task;

import '../common/tasks.dart' show CompilerTask, Measurer;
import '../diagnostics/diagnostic_listener.dart' show DiagnosticReporter;
import '../elements/elements.dart' show CompilationUnitElement, LibraryElement;
import '../parser/diet_parser_task.dart' show DietParserTask;
import '../script.dart' show Script;
import 'package:front_end/src/fasta/scanner.dart'
    show Scanner, StringScanner, Token, Utf8BytesScanner;
import '../io/source_file.dart';

class ScannerTask extends CompilerTask {
  final DietParserTask _dietParser;
  final DiagnosticReporter reporter;

  ScannerTask(this._dietParser, this.reporter, Measurer measurer)
      : super(measurer);

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

  Token scanFile(SourceFile file, {bool includeComments: false}) {
    Scanner scanner = file is Utf8BytesSourceFile
        ? new Utf8BytesScanner(file.slowUtf8ZeroTerminatedBytes(),
            includeComments: includeComments)
        : new StringScanner(file.slowText(), includeComments: includeComments);
    return measure(scanner.tokenize);
  }

  void scanElements(CompilationUnitElement compilationUnit) {
    Script script = compilationUnit.script;
    Token tokens = scanFile(script.file);
    _dietParser.dietParse(compilationUnit, tokens);
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
      return new StringScanner(source, includeComments: false).tokenize();
    });
  }
}
