// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert" show json;

import "package:_fe_analyzer_shared/src/messages/diagnostic_message.dart"
    show DiagnosticMessage, getMessageCodeObject;

import "package:async_helper/async_helper.dart" show asyncTest;

import "package:expect/expect.dart" show Expect;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;

import "package:front_end/src/base/processed_options.dart"
    show ProcessedOptions;

import "package:front_end/src/fasta/compiler_context.dart" show CompilerContext;

import "package:front_end/src/fasta/messages.dart"
    show Code, codeObjectExtends, codeObjectImplements, codeObjectMixesIn;

import "package:front_end/src/fasta/source/source_loader.dart"
    show defaultDartCoreSource;

import "package:front_end/src/fasta/ticker.dart" show Ticker;

import "../../tool/_fasta/entry_points.dart" show CompileTask;

Future<List<DiagnosticMessage>> outline(String objectHeader) async {
  final Ticker ticker = new Ticker(isVerbose: false);
  final Uri base = Uri.parse("org-dartlang-test:///");

  final MemoryFileSystem fs = new MemoryFileSystem(base);

  final Uri librariesSpecificationUri = base.resolve("sdk/libraries.json");

  fs.entityForUri(librariesSpecificationUri).writeAsStringSync(json.encode({
        "none": {
          "libraries": {
            "core": {
              "uri": "lib/core/core.dart",
            },
          },
        },
      }));

  fs.entityForUri(base.resolve("sdk/lib/core/core.dart")).writeAsStringSync(
      defaultDartCoreSource
          .replaceAll("class Object {", "$objectHeader")
          .replaceAll("const Object();", ""));

  final List<DiagnosticMessage> messages = <DiagnosticMessage>[];

  CompilerContext context = new CompilerContext(new ProcessedOptions(
      options: new CompilerOptions()
        ..onDiagnostic = messages.add
        ..sdkRoot = base.resolve("sdk/")
        ..fileSystem = fs
        ..compileSdk = true
        ..librariesSpecificationUri = librariesSpecificationUri,
      inputs: [Uri.parse("dart:core"), Uri.parse("dart:collection")]));

  await context.runInContext<void>((_) async {
    CompileTask task = new CompileTask(context, ticker);
    await task.buildOutline();
  });
  return messages;
}

test() async {
  Set<String> normalErrors = (await outline("class Object {"))
      .map((DiagnosticMessage message) => getMessageCodeObject(message).name)
      .toSet();

  check(String objectHeader, List<Code> expectedCodes) async {
    List<DiagnosticMessage> messages = (await outline(objectHeader))
        .where((DiagnosticMessage message) =>
            !normalErrors.contains(getMessageCodeObject(message).name))
        .toList();
    Expect.setEquals(
        expectedCodes,
        messages.map((DiagnosticMessage m) => getMessageCodeObject(m)),
        objectHeader);
  }

  await check("class Object extends String {", <Code>[codeObjectExtends]);

  await check(
      "class Object implements String, bool {", <Code>[codeObjectImplements]);

  await check("class Object = Object with bool ; class Blah {",
      <Code>[codeObjectExtends, codeObjectMixesIn]);
}

main() {
  asyncTest(test);
}
