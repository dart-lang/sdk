// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io" show File;

import "package:async_helper/async_helper.dart" show asyncTest;

import "package:expect/expect.dart" show Expect;

import "generate_messages.dart";

main() {
  asyncTest(() async {
    Messages messages = await generateMessagesFiles();

    Uri generatedFile = await computeSharedGeneratedFile();
    String sharedActual = (await new File.fromUri(generatedFile).readAsString())
        .replaceAll('\r\n', '\n');
    Expect.stringEquals(messages.sharedMessages, sharedActual,
        "${generatedFile.path} is out of date");

    Uri cfeGeneratedFile = await computeCfeGeneratedFile();
    String cfeActual = (await new File.fromUri(cfeGeneratedFile).readAsString())
        .replaceAll('\r\n', '\n');
    Expect.stringEquals(messages.cfeMessages, cfeActual,
        "${cfeGeneratedFile.path} is out of date");
  });
}
