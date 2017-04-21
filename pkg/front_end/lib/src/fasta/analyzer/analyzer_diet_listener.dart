// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_diet_listener;

import 'package:kernel/ast.dart' show AsyncMarker;

import '../source/stack_listener.dart' show StackListener;

import '../builder/builder.dart';

import '../builder/scope.dart' show Scope;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../source/diet_listener.dart' show DietListener;

import 'package:analyzer/src/fasta/element_store.dart' show ElementStore;

import 'package:analyzer/src/fasta/ast_builder.dart' show AstBuilder;

class AnalyzerDietListener extends DietListener {
  final ElementStore elementStore;

  AnalyzerDietListener(SourceLibraryBuilder library, this.elementStore)
      : super(library, null, null);

  StackListener createListener(
      MemberBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope]) {
    return new AstBuilder(
        null, library, builder, elementStore, memberScope, uri);
  }

  @override
  AsyncMarker getAsyncMarker(StackListener listener) => null;
}
