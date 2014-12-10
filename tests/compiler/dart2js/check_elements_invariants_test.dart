// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:compiler/src/apiimpl.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/elements/elements.dart'
    show ClassElement;
import 'package:compiler/src/resolution/class_members.dart'
    show ClassMemberMixin;
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';


const String DART2JS_SOURCE =
    'pkg/compiler/lib/src/dart2js.dart';
const List<String> DART2JS_OPTIONS = const <String>[
      '--categories=Client,Server',
      '--disable-type-inference'
    ];

Iterable<ClassElement> computeLiveClasses(Compiler compiler) {
  return new Set<ClassElement>()
      ..addAll(compiler.resolverWorld.directlyInstantiatedClasses)
      ..addAll(compiler.codegenWorld.directlyInstantiatedClasses);
}

void checkClassInvariants(ClassElement cls) {
  ClassMemberMixin impl = cls;
  Expect.isTrue(impl.areAllMembersComputed(),
      "Not all members have been computed for $cls.");
}

Future checkElementInvariantsAfterCompiling(Uri uri) {
  var compiler = compilerFor({}, options: DART2JS_OPTIONS);
   return compiler.run(uri).then((passed) {
     Expect.isTrue(passed, "Compilation of dart2js failed.");

     computeLiveClasses(compiler).forEach(checkClassInvariants);
   });
}

void main () {
  var uri = Uri.base.resolve(DART2JS_SOURCE);
  asyncTest(() => checkElementInvariantsAfterCompiling(uri));
}
