// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show CfeDiagnosticMessage, getMessageCodeObject;
import 'package:expect/async_helper.dart' show asyncTest;
import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;
import 'package:front_end/src/api_prototype/memory_file_system.dart'
    show MemoryFileSystem;
import 'package:front_end/src/base/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;
import 'package:front_end/src/codes/diagnostic.dart' as diag;

void main() {
  Uri root = Uri.parse("org-dartlang-test:///");
  MemoryFileSystem fs = new MemoryFileSystem(root);
  Uri packages = root.resolve(".dart_tool/package_config.json");
  fs.entityForUri(packages).writeAsStringSync("bad\n");
  List<CfeDiagnosticMessage> messages = <CfeDiagnosticMessage>[];
  CompilerContext c = new CompilerContext(
    new ProcessedOptions(
      options: new CompilerOptions()
        ..fileSystem = fs
        ..onDiagnostic = (message) {
          messages.add(message);
        },
    ),
  );
  asyncTest(() async {
    await c.runInContext<void>(
      (_) => c.options.createPackagesFromFile(packages),
    );
    Expect.identical(
      diag.packagesFileFormat,
      getMessageCodeObject(messages.single),
    );
    messages.clear();

    await c.runInContext<void>(
      (_) => c.options.createPackagesFromFile(root.resolve("missing-file")),
    );
    Expect.identical(diag.cantReadFile, getMessageCodeObject(messages.single));
    messages.clear();
  });
}
