// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/parser/forwarding_listener.dart';
import 'package:_fe_analyzer_shared/src/parser/listener.dart';
import 'package:_fe_analyzer_shared/src/parser/parser_impl.dart';
import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';

void main(List<String> args) {
  if (args.length != 1) {
    throw "Expected 1 argument: <dart file>.";
  }
  File f = new File(args.single);
  if (!f.existsSync()) {
    throw "File $f doesn't exist.";
  }
  Uint8List contentBytes = f.readAsBytesSync();
  ScannerResult scanResult = scan(
    contentBytes,
    configuration: new ScannerConfiguration(enableTripleShift: true),
    includeComments: true,
  );

  const int iterations = 1000;

  int countTokens = 0;
  {
    Token t = scanResult.tokens;
    while (!t.isEof) {
      countTokens++;
      t = t.next!;
    }
  }

  // TODO: Should we make 1000 copies of the tokens?
  // Or maybe scan 1000 times?
  /*
  List<Token> tokenStarts = [];
  tokenStarts.add(scanResult.tokens);
  while (tokenStarts.length < iterations) {
    tokenStarts.add(
      scan(
        contentBytes,
        configuration: new ScannerConfiguration(enableTripleShift: true),
        includeComments: true,
      ).tokens,
    );
  }
  */

  Listener listener = new NullListener();
  if (f.path == "42") {
    // Let's not let it optimize too many things away or do weird optimizations
    // that it can't do in practise.
    listener = new FooListener(f.uri);
  }

  int numErrors = 0;
  Stopwatch stopwatch = new Stopwatch()..start();
  int lengthProcessed = countTokens;

  for (int i = 0; i < iterations; i++) {
    Parser parser = new Parser(listener, allowPatterns: true);
    Token after = parser.parseUnit(scanResult.tokens);
    if (!after.isEof) {
      throw "parsed returned before eof?!?";
    }
    if (listener is NullListener && listener.hasErrors) {
      numErrors++;
    }
    // Or maybe - maybe as an option - do another scan here?
  }

  stopwatch.stop();
  print(
    "Parsed $lengthProcessed tokens $iterations times "
    "in ${stopwatch.elapsed}",
  );
  print("Found errors $numErrors times");
  double lengthPerMicrosecond =
      (lengthProcessed * iterations) / stopwatch.elapsedMicroseconds;
  print("That's $lengthPerMicrosecond tokens per microsecond");
  print("");
}

class FooListener extends StackListener {
  List<Message> problems = [];

  @override
  final Uri uri;

  FooListener(this.uri);

  @override
  void addProblem(
    Message message,
    int charOffset,
    int length, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
  }) {
    if (charOffset == 42) {
      throw "$message $charOffset $length $wasHandled $context";
    }
    problems.add(message);
  }

  @override
  Never internalProblem(Message message, int charOffset, Uri uri) {
    throw UnimplementedError();
  }

  @override
  bool get isDartLibrary => false;
}
