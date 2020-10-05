// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_builder;

import 'package:kernel/ast.dart'
    show
        Combinator,
        Constructor,
        Initializer,
        Procedure,
        RedirectingInitializer;

import '../combinator.dart' as fasta;

export 'class_hierarchy_builder.dart'
    show ClassHierarchyBuilder, ClassMember, DelayedCheck;

export 'implicit_field_type.dart' show ImplicitFieldType;

export 'kernel_variable_builder.dart' show VariableBuilderImpl;

export 'load_library_builder.dart' show LoadLibraryBuilder;

int compareProcedures(Procedure a, Procedure b) {
  int i = "${a.fileUri}".compareTo("${b.fileUri}");
  if (i != 0) return i;
  return a.fileOffset.compareTo(b.fileOffset);
}

bool isRedirectingGenerativeConstructorImplementation(Constructor constructor) {
  List<Initializer> initializers = constructor.initializers;
  return initializers.length == 1 &&
      initializers.single is RedirectingInitializer;
}

List<Combinator> toKernelCombinators(List<fasta.Combinator> fastaCombinators) {
  if (fastaCombinators == null) {
    // Note: it's safe to return null here as Kernel's LibraryDependency will
    // convert null to an empty list.
    return null;
  }

  List<Combinator> result = new List<Combinator>.filled(
      fastaCombinators.length, null,
      growable: true);
  for (int i = 0; i < fastaCombinators.length; i++) {
    fasta.Combinator combinator = fastaCombinators[i];
    List<String> nameList = combinator.names.toList();
    result[i] = combinator.isShow
        ? new Combinator.show(nameList)
        : new Combinator.hide(nameList);
  }
  return result;
}
