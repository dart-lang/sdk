// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;

import 'package:kernel/ast.dart' show Component;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/target/targets.dart' show NoneTarget, TargetFlags;

import 'incremental_load_from_dill_suite.dart'
    show checkIsEqual, getOptions, normalCompilePlain;

main() async {
  final Uri dart2jsUrl = Uri.base.resolve("pkg/compiler/bin/dart2js.dart");
  Stopwatch stopwatch = new Stopwatch()..start();
  Component compiledComponent = await normalCompilePlain(dart2jsUrl,
      options: getOptions()
        ..target = new NoneTarget(new TargetFlags())
        ..omitPlatform = false);
  print("Compiled dart2js in ${stopwatch.elapsedMilliseconds} ms");
  stopwatch.reset();

  List<int> bytes = serializeComponent(compiledComponent);
  print("Serialized dart2js in ${stopwatch.elapsedMilliseconds} ms");
  print("Output is ${bytes.length} bytes long.");
  print("");
  stopwatch.reset();

  print("Round-tripping with lazy disabled");
  roundTrip(
      new BinaryBuilder(bytes,
          disableLazyReading: true, disableLazyClassReading: true),
      bytes);

  print("Round-tripping with lazy enabled");
  roundTrip(
      new BinaryBuilder(bytes,
          disableLazyReading: false, disableLazyClassReading: false),
      bytes);

  print("OK");
}

void roundTrip(BinaryBuilder binaryBuilder, List<int> bytes) {
  Stopwatch stopwatch = new Stopwatch()..start();
  Component c = new Component();
  binaryBuilder.readComponent(c);
  List<int> bytesRoundTripped = serializeComponent(c);
  print("Loaded and serialized in ${stopwatch.elapsedMilliseconds} ms");
  stopwatch.reset();

  checkIsEqual(bytes, bytesRoundTripped);
  print("Checked equal in ${stopwatch.elapsedMilliseconds} ms");
  stopwatch.reset();
  print("");
}
