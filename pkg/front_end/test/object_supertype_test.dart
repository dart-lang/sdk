// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert" show json;

import "package:_fe_analyzer_shared/src/messages/diagnostic_message.dart"
    show CfeDiagnosticMessage, getMessageCodeObject;
import "package:expect/async_helper.dart" show asyncTest;
import "package:expect/expect.dart" show Expect;
import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions;
import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;
import "package:front_end/src/base/compiler_context.dart" show CompilerContext;
import "package:front_end/src/base/messages.dart"
    show Code, codeObjectExtends, codeObjectImplements, codeObjectMixesIn;
import "package:front_end/src/base/processed_options.dart"
    show ProcessedOptions;
import "package:front_end/src/kernel_generator_impl.dart";
import "package:front_end/src/source/source_loader.dart"
    show defaultDartCoreSource;

Future<List<CfeDiagnosticMessage>> outline(String objectHeader) async {
  final Uri base = Uri.parse("org-dartlang-test:///");

  final MemoryFileSystem fs = new MemoryFileSystem(base);

  final Uri librariesSpecificationUri = base.resolve("sdk/libraries.json");

  fs
      .entityForUri(librariesSpecificationUri)
      .writeAsStringSync(
        json.encode({
          "none": {
            "libraries": {
              "core": {"uri": "lib/core/core.dart"},
            },
          },
        }),
      );

  fs
      .entityForUri(base.resolve("sdk/lib/core/core.dart"))
      .writeAsStringSync(
        defaultDartCoreSource
            .replaceAll("class Object {", "$objectHeader")
            .replaceAll("const Object();", ""),
      );

  final List<CfeDiagnosticMessage> messages = <CfeDiagnosticMessage>[];

  CompilerContext context = new CompilerContext(
    new ProcessedOptions(
      options: new CompilerOptions()
        ..onDiagnostic = messages.add
        ..sdkRoot = base.resolve("sdk/")
        ..fileSystem = fs
        ..compileSdk = true
        ..librariesSpecificationUri = librariesSpecificationUri,
      inputs: [Uri.parse("dart:core"), Uri.parse("dart:collection")],
    ),
  );

  await context.runInContext<void>((CompilerContext c) async {
    await context.options.validateOptions(errorOnMissingInput: false);
    await generateKernelInternal(c, buildSummary: true);
  });
  return messages;
}

Future<void> test() async {
  Set<String> normalErrors = (await outline("class Object {"))
      .map(
        (CfeDiagnosticMessage message) => getMessageCodeObject(message)!.name,
      )
      .toSet();

  Future<void> check(String objectHeader, List<Code> expectedCodes) async {
    List<CfeDiagnosticMessage> messages = (await outline(objectHeader))
        .where(
          (CfeDiagnosticMessage message) =>
              !normalErrors.contains(getMessageCodeObject(message)!.name),
        )
        .toList();
    Expect.setEquals(
      expectedCodes,
      messages.map((CfeDiagnosticMessage m) => getMessageCodeObject(m)),
      objectHeader,
    );
  }

  await check("class Object extends String {", <Code>[codeObjectExtends]);

  await check("class Object implements String, bool {", <Code>[
    codeObjectImplements,
  ]);

  await check("class Object = Object with bool ; class Blah {", <Code>[
    codeObjectExtends,
    codeObjectMixesIn,
  ]);
}

void main() {
  asyncTest(test);
}
