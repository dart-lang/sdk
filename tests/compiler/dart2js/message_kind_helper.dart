// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.message_kind_helper;

import 'package:expect/expect.dart';

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart' show
    Compiler,
    MessageKind;

import 'memory_compiler.dart';

const String ESCAPE_REGEXP = r'[[\]{}()*+?.\\^$|]';

Compiler check(MessageKind kind, Compiler cachedCompiler,
               {bool expectNoHowToFix: false}) {
  if (expectNoHowToFix) {
    Expect.isNull(kind.howToFix);
  } else {
    Expect.isNotNull(kind.howToFix);
  }
  Expect.isFalse(kind.examples.isEmpty);

  for (String example in kind.examples) {
    List<String> messages = <String>[];
    void collect(Uri uri, int begin, int end, String message, kind) {
      if (kind.name == 'verbose info') {
        return;
      }
      messages.add(message);
    }

    Compiler compiler = compilerFor(
        {'main.dart': example},
        diagnosticHandler: collect,
        options: ['--analyze-only'],
        cachedCompiler: cachedCompiler);

    compiler.run(Uri.parse('memory:main.dart'));

    Expect.isFalse(messages.isEmpty, 'No messages in """$example"""');

    String expectedText = kind.howToFix == null
        ? kind.template : '${kind.template}\n${kind.howToFix}';
    String pattern = expectedText.replaceAllMapped(
        new RegExp(ESCAPE_REGEXP), (m) => '\\${m[0]}');
    pattern = pattern.replaceAll(new RegExp(r'#\\\{[^}]*\\\}'), '.*');

    for (String message in messages) {
      Expect.isTrue(new RegExp('^$pattern\$').hasMatch(message),
                    '"$pattern" does not match "$message"');
    }
    return compiler;
  }
}
