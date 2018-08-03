// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exports all API from Kernel that can be used throughout fasta.
library fasta.kernel_api;

export 'package:kernel/type_algebra.dart'
    show instantiateToBounds, Substitution;

export 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

export 'package:kernel/clone.dart' show CloneVisitor;

export 'package:kernel/core_types.dart' show CoreTypes;

export 'package:kernel/transformations/flags.dart' show TransformerFlag;

export 'package:kernel/text/ast_to_text.dart' show NameSystem;

import 'package:kernel/text/ast_to_text.dart' show NameSystem, Printer;

import 'package:kernel/ast.dart' show Class, Member, Node;

void printNodeOn(Node node, StringSink sink, {NameSystem syntheticNames}) {
  if (node == null) {
    sink.write("null");
  } else {
    syntheticNames ??= new NameSystem();
    new Printer(sink, syntheticNames: syntheticNames).writeNode(node);
  }
}

void printQualifiedNameOn(Member member, StringSink sink,
    {NameSystem syntheticNames}) {
  if (member == null) {
    sink.write("null");
  } else {
    syntheticNames ??= new NameSystem();
    sink.write(member.enclosingLibrary.importUri);
    sink.write("::");
    Class cls = member.enclosingClass;
    if (cls != null) {
      sink.write(cls.name ?? syntheticNames.nameClass(cls));
      sink.write("::");
    }
    sink.write(member.name?.name ?? syntheticNames.nameMember(member));
  }
}
