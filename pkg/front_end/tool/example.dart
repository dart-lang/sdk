// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart' show Component;

Future dumpToSink(Component component, StreamSink<List<int>> sink) {
  new BinaryPrinter(sink).writeComponentFile(component);
  return sink.close();
}

Future kernelToSink(Uri entry, StreamSink<List<int>> sink) async {
  var component = await kernelForProgram(
      entry,
      new CompilerOptions()
        ..sdkRoot = new Uri.file('sdk')
        ..packagesFileUri = new Uri.file('.packages')
        ..onError = (e) => print(e.message));

  await dumpToSink(component, sink);
}

main(args) async {
  kernelToSink(
      Uri.base.resolve(args[0]),
      // TODO(sigmund,hausner): define memory type where to dump binary data.
      new StreamController<List<int>>.broadcast().sink);
}
