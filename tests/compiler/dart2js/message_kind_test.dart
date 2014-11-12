// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:async';
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/dart2jslib.dart' show
    DualKind,
    MessageKind;

import 'message_kind_helper.dart';

import 'dart:mirrors';

main(List<String> arguments) {
  ClassMirror cls = reflectClass(MessageKind);
  Map<String, MessageKind> kinds = <String, MessageKind>{};
  cls.declarations.forEach((Symbol name, DeclarationMirror declaration) {
    if (declaration is! VariableMirror) return;
    VariableMirror variable = declaration;
    if (variable.isStatic) {
      var value = cls.getField(name).reflectee;
      if (value is MessageKind) {
        kinds[MirrorSystem.getName(name)] = value;
      } else {
        Expect.fail("Weird static field: '${MirrorSystem.getName(name)}'.");
      }
    }
  });
  List<String> names = kinds.keys.toList()..sort();
  List<String> examples = <String>[];
  for (String name in names) {
    if (!arguments.isEmpty && !arguments.contains(name)) continue;
    MessageKind kind = kinds[name];
    if (name == 'GENERIC' // Shouldn't be used.
        // We can't provoke a crash.
        || name == 'COMPILER_CRASHED'
        || name == 'PLEASE_REPORT_THE_CRASH'
        // We cannot provide examples for patch errors.
        || name.startsWith('PATCH_')) continue;
    if (kind.examples != null) {
      examples.add(name);
    } else {
      print("No example in '$name'");
    }
  };
  var cachedCompiler;
  asyncTest(() => Future.forEach(examples, (String name) {
    print("Checking '$name'.");
    Stopwatch sw = new Stopwatch()..start();
    return check(kinds[name], cachedCompiler).then((var compiler) {
      cachedCompiler = compiler;
      sw.stop();
      print("Checked '$name' in ${sw.elapsedMilliseconds}ms.");
    });
  }));
}
