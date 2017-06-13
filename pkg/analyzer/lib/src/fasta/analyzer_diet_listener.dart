// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_diet_listener;

import 'package:kernel/ast.dart' show AsyncMarker;

import 'package:front_end/src/fasta/source/stack_listener.dart'
    show StackListener;

import 'package:front_end/src/fasta/builder/builder.dart';

import 'package:front_end/src/fasta/source/source_library_builder.dart'
    show SourceLibraryBuilder;

import 'package:front_end/src/fasta/source/diet_listener.dart'
    show DietListener;

import 'element_store.dart' show ElementStore;

import 'ast_builder.dart' show AstBuilder;

class AnalyzerDietListener extends DietListener {
  final ElementStore elementStore;

  AnalyzerDietListener(SourceLibraryBuilder library, this.elementStore)
      : super(library, null, null, null);

  StackListener createListener(
      MemberBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope]) {
    return new AstBuilder(
        null, library, builder, elementStore, memberScope, false, uri);
  }

  @override
  AsyncMarker getAsyncMarker(StackListener listener) => null;
}
