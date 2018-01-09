// Copyright (c) 2015, the Fletch project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import "package:compiler/src/platform_configuration.dart";
import "package:compiler/src/source_file_provider.dart";
import "package:compiler/compiler_new.dart";
import "package:expect/expect.dart";

main() async {
  CompilerInput input = new CompilerSourceFileProvider();
  Map<String, Uri> client =
      await load(Uri.base.resolve("sdk/lib/dart_client.platform"), input);
  Map<String, Uri> server =
      await load(Uri.base.resolve("sdk/lib/dart_server.platform"), input);
  Map<String, Uri> shared =
      await load(Uri.base.resolve("sdk/lib/dart_shared.platform"), input);
  Expect.setEquals(new Set.from(shared.keys), new Set.from(client.keys));
  Expect.setEquals(new Set.from(shared.keys), new Set.from(server.keys));

  for (String libraryName in shared.keys) {
    test(Map<String, Uri> m) {
      if (m[libraryName].scheme != 'unsupported' &&
          shared[libraryName].scheme != 'unsupported') {
        Expect.equals(shared[libraryName], m[libraryName]);
      }
    }

    test(client);
    test(server);
  }
}
