// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;

import 'package:kernel/kernel.dart'
    show Class, Component, EmptyStatement, Library, Procedure, Reference;

List<int> postProcess(Component c) {
  c.libraries.sort((l1, l2) {
    return "${l1.fileUri}".compareTo("${l2.fileUri}");
  });

  c.problemsAsJson?.sort();

  c.computeCanonicalNames();
  for (Library library in c.libraries) {
    library.additionalExports.sort((Reference r1, Reference r2) {
      return "${r1.canonicalName}".compareTo("${r2.canonicalName}");
    });
    library.problemsAsJson?.sort();
  }

  return serializeComponent(c);
}

void throwOnEmptyMixinBodies(Component component) {
  int empty = countEmptyMixinBodies(component);
  if (empty != 0) {
    throw "Expected 0 empty bodies in mixins, but found $empty";
  }
}

int countEmptyMixinBodies(Component component) {
  int empty = 0;
  for (Library lib in component.libraries) {
    for (Class c in lib.classes) {
      if (c.isAnonymousMixin) {
        for (Procedure p in c.procedures) {
          if (p.function.body is EmptyStatement) {
            empty++;
          }
        }
      }
    }
  }
  return empty;
}
