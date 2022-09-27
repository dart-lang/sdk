// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/forwarding_listener.dart'
    show ForwardingListener;
import 'package:_fe_analyzer_shared/src/parser/parser.dart' show Parser;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration, StringScanner;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

void main(List<String> args) {
  String source = """
void main(List<String> args) {
  print("Hello, World!");
}
""";

  ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
      enableExtensionMethods: true,
      enableNonNullable: true,
      enableTripleShift: true);

  StringScanner scanner = new StringScanner(
    source,
    includeComments: true,
    configuration: scannerConfiguration,
    languageVersionChanged: (scanner, languageVersion) {
      // For now don't do anything, but having it (making it non-null) means the
      // configuration won't be reset.
    },
  );
  Token firstToken = scanner.tokenize();
  ForwardingListener listener = new ForwardingListener();
  Parser parser = new Parser(listener);
  parser.parseUnit(firstToken);
  print("--- End of parsing ---");
}
