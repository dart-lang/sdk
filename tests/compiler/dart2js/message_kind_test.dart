// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:async';
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/diagnostics/messages.dart'
    show MessageKind, MessageTemplate;

import 'message_kind_helper.dart';

main(List<String> arguments) {
  List<MessageTemplate> examples = <MessageTemplate>[];
  for (var kind in MessageKind.values) {
    MessageTemplate template = MessageTemplate.TEMPLATES[kind];
    Expect.isNotNull(template, "No template for $kind.");
    Expect.equals(kind, template.kind,
        "Invalid MessageTemplate.kind for $kind, found ${template.kind}.");

    String name = '${kind.toString()}'.substring('MessageKind.'.length);
    if (!arguments.isEmpty && !arguments.contains(name)) continue;
    if (name == 'GENERIC' // Shouldn't be used.
        // We can't provoke a crash.
        ||
        name == 'COMPILER_CRASHED' ||
        name == 'PLEASE_REPORT_THE_CRASH'
        // We cannot provide examples for patch errors.
        ||
        name.startsWith('PATCH_') ||
        name == 'LIBRARY_NOT_SUPPORTED'
        // TODO(johnniwinther): Remove these when [Compiler.reportUnusedCode] is
        // reenabled.
        ||
        name == 'UNUSED_METHOD' ||
        name == 'UNUSED_CLASS' ||
        name == 'UNUSED_TYPEDEF' ||

        // Fasta no longer generates EXTRANEOUS_MODIFIER_REPLACE.
        name == 'EXTRANEOUS_MODIFIER_REPLACE' ||

        // Fasta just reports EXTRANEOUS_MODIFIER.
        name == 'FORMAL_DECLARED_STATIC' ||

        // Additional warning from dart2js.
        name == 'VOID_NOT_ALLOWED') continue;
    if (template.examples != null) {
      examples.add(template);
    } else {
      print("No example in '$name'");
    }
  }
  ;
  var cachedCompiler;
  asyncTest(() => Future.forEach(examples, (MessageTemplate template) {
        print("Checking '${template.kind}'.");
        Stopwatch sw = new Stopwatch()..start();
        return check(template, cachedCompiler).then((var compiler) {
          cachedCompiler = compiler;
          sw.stop();
          print("Checked '${template.kind}' in ${sw.elapsedMilliseconds}ms.");
        });
      }));
}
