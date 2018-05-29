// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io" show File;

import "package:async_helper/async_helper.dart" show asyncTest;

import "package:expect/expect.dart" show Expect;

import "generate_messages.dart" show computeGeneratedFile, generateMessagesFile;

main() {
  asyncTest(() async {
    Uri generatedFile = await computeGeneratedFile();
    String generated = await generateMessagesFile();
    String actual = (await new File.fromUri(generatedFile).readAsString())
        .replaceAll('\r\n', '\n');
    Expect.stringEquals(
        generated, actual, "${generatedFile.path} is out of date");
  });
}
