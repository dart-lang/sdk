// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';

void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    throw "Expected 1 or 2 argument: <dart file> and either "
        "--string or --bytes or --stringtobytes or --count";
  }
  File? f;
  ScanType scanType = ScanType.string;
  for (String arg in args) {
    if (arg == "--string") {
      scanType = ScanType.string;
    } else if (arg == "--bytes") {
      scanType = ScanType.bytes;
    } else if (arg == "--stringtobytes") {
      scanType = ScanType.stringAsBytes;
    } else if (arg == "--count") {
      scanType = ScanType.countLfs;
    } else if (arg.startsWith("--")) {
      throw "Unsupported setting: $arg";
    } else {
      f = new File(arg);
    }
  }
  if (f == null) {
    throw "No input file given.";
  }
  if (!f.existsSync()) {
    throw "File $f doesn't exist.";
  }
  String content = f.readAsStringSync();
  String contentZeroTerminated = content + '\x00';
  Uint8List contentBytes = f.readAsBytesSync();

  int numErrors = 0;
  Stopwatch stopwatch = new Stopwatch()..start();
  const int iterations = 1000;
  int lengthProcessed;
  bool hasErrors = false;

  switch (scanType) {
    case ScanType.string:
      lengthProcessed = content.length;
      for (int i = 0; i < iterations; i++) {
        hasErrors = scanString(
          content,
          configuration: new ScannerConfiguration(enableTripleShift: true),
          includeComments: true,
        ).hasErrors;
      }
    case ScanType.bytes:
      lengthProcessed = contentBytes.length;
      for (int i = 0; i < iterations; i++) {
        hasErrors = scan(
          contentBytes,
          configuration: new ScannerConfiguration(enableTripleShift: true),
          includeComments: true,
        ).hasErrors;
      }
    case ScanType.stringAsBytes:
      lengthProcessed = content.length;
      for (int i = 0; i < iterations; i++) {
        Uint8List tmp = utf8.encode(contentZeroTerminated);
        hasErrors = scan(
          tmp,
          configuration: new ScannerConfiguration(enableTripleShift: true),
          includeComments: true,
        ).hasErrors;
      }
    case ScanType.countLfs:
      lengthProcessed = contentBytes.length;
      for (int i = 0; i < iterations; i++) {
        hasErrors = false;
        int count = 0;
        for (int i = 0; i < contentBytes.length; i++) {
          if (contentBytes[i] == 10) count++;
        }
        // Make sure the above can't be optimized away.
        if (count == 42) print("Exactly 42 LFs");
      }
      if (hasErrors) {
        numErrors++;
      }
  }
  stopwatch.stop();
  print(
    "Scanned $lengthProcessed ${scanType.what} $iterations times "
    "in ${stopwatch.elapsed}",
  );
  print("Found errors $numErrors times");
  double lengthPerMicrosecond =
      (lengthProcessed * iterations) / stopwatch.elapsedMicroseconds;
  print("That's $lengthPerMicrosecond ${scanType.what} per microsecond");
  print("");
}

enum ScanType {
  string("string characters"),
  bytes("bytes"),
  stringAsBytes("string characters as bytes"),
  countLfs("bytes");

  final String what;

  const ScanType(this.what);
}
