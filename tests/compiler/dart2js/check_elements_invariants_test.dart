// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/src/dart2jslib.dart' show NullSink;
import 'package:expect/expect.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/elements/elements.dart'
    show ClassElement;
import 'package:compiler/src/resolution/class_members.dart'
    show ClassMemberMixin;
import "package:async_helper/async_helper.dart";


const String DART2JS_SOURCE =
    'pkg/compiler/lib/src/dart2js.dart';
const List<String> DART2JS_OPTIONS = const <String>[
      '--categories=Client,Server',
      '--disable-type-inference'
    ];

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
