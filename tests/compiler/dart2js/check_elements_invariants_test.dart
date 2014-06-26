// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:compiler/implementation/apiimpl.dart';
import 'package:compiler/implementation/dart2jslib.dart' show NullSink;
import 'package:expect/expect.dart';
import 'package:compiler/implementation/filenames.dart';
import 'package:compiler/implementation/source_file_provider.dart';
import 'package:compiler/implementation/elements/elements.dart'
    show ClassElement;
import 'package:compiler/implementation/resolution/class_members.dart'
    show ClassMemberMixin;
import "package:async_helper/async_helper.dart";


const String DART2JS_SOURCE =
    'sdk/lib/_internal/compiler/implementation/dart2js.dart';
const List<String> DART2JS_OPTIONS = const ['--categories=Client,Server'];

Iterable<ClassElement> computeLiveClasses(Compiler compiler) {
  return new Set<ClassElement>()
      ..addAll(compiler.resolverWorld.instantiatedClasses)
      ..addAll(compiler.codegenWorld.instantiatedClasses);
}

void checkClassInvariants(ClassElement cls) {
  ClassMemberMixin impl = cls;
  Expect.isTrue(impl.areAllMembersComputed(),
      "Not all members have been computed for $cls.");
}

Future checkElementInvariantsAfterCompiling(Uri uri) {
  var inputProvider = new CompilerSourceFileProvider();
  var handler = new FormattingDiagnosticHandler(inputProvider);
  var compiler = new Compiler(inputProvider.readStringFromUri,
                              NullSink.outputProvider,
                              handler,
                              currentDirectory.resolve('sdk/'),
                              currentDirectory.resolve('sdk/'),
                              DART2JS_OPTIONS,
                              {});

   return compiler.run(uri).then((passed) {
     Expect.isTrue(passed, "Compilation of dart2js failed.");

     computeLiveClasses(compiler).forEach(checkClassInvariants);
   });
}

void main () {
  var uri = currentDirectory.resolve(DART2JS_SOURCE);
  asyncTest(() => checkElementInvariantsAfterCompiling(uri));
}