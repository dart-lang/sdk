// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart' show asyncTest;

import 'package:expect/expect.dart' show Expect;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, FormattedMessage;

import 'package:front_end/src/api_prototype/memory_file_system.dart'
    show MemoryFileSystem;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

main() {
  Uri root = Uri.parse("org-dartlang-test:///");
  MemoryFileSystem fs = new MemoryFileSystem(root);
  Uri packages = root.resolve(".packages");
  fs.entityForUri(packages).writeAsStringSync("bad\n");
  List<FormattedMessage> messages = <FormattedMessage>[];
  CompilerContext c =
      new CompilerContext(new ProcessedOptions(new CompilerOptions()
        ..fileSystem = fs
        ..onProblem = (message, severity, context) {
          messages.add(message);
        }));
  asyncTest(() async {
    await c
        .runInContext<void>((_) => c.options.createPackagesFromFile(packages));
    Expect.stringEquals("PackagesFileFormat", messages.single.code.name);
    messages.clear();

    await c.runInContext<void>(
        (_) => c.options.createPackagesFromFile(root.resolve("missing-file")));
    Expect.stringEquals("CantReadFile", messages.single.code.name);
    messages.clear();
  });
}
