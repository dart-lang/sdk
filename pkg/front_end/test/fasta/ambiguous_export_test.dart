// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart' show asyncTest;

import 'package:expect/expect.dart' show Expect;

import 'package:front_end/src/fasta/builder/declaration_builders.dart';

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/dill/dill_library_builder.dart'
    show DillLibraryBuilder;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:front_end/src/fasta/kernel/utils.dart';

import 'package:kernel/ast.dart'
    show Field, Library, Name, Component, StringLiteral;

Future<void> main() async {
  await asyncTest(() async {
    Uri uri = Uri.parse("org.dartlang.fasta:library");
    Library library = new Library(uri, fileUri: uri);
    Field field = new Field.immutable(
        new Name(unserializableExportName, library),
        initializer: new StringLiteral('{"main":"Problem with main"}'),
        fileUri: library.fileUri);
    library.addField(field);
    Component component = new Component(libraries: <Library>[library]);
    await CompilerContext.runWithDefaultOptions((CompilerContext c) async {
      DillTarget target = new DillTarget(c.options.ticker,
          await c.options.getUriTranslator(), c.options.target);
      target.loader.appendLibraries(component);
      DillLibraryBuilder builder = target.loader.read(library.importUri, -1);
      target.loader.buildOutline(builder);
      builder.markAsReadyToFinalizeExports();
      var mainExport =
          builder.exportScope.lookupLocalMember("main", setter: false);
      Expect.isTrue(mainExport is InvalidTypeDeclarationBuilder);
    });
  });
}
