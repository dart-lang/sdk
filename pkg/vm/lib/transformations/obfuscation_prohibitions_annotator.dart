// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.obfuscation_prohibitions_annotator;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

import '../metadata/obfuscation_prohibitions.dart';
import 'pragma.dart';

void transformComponent(Component component, CoreTypes coreTypes) {
  final repo = new ObfuscationProhibitionsMetadataRepository();
  component.addMetadataRepository(repo);
  final visitor =
      ObfuscationProhibitionsVisitor(ConstantPragmaAnnotationParser(coreTypes));
  visitor.visitComponent(component);
  repo.mapping[component] = visitor.metadata;
}

class ObfuscationProhibitionsVisitor extends RecursiveVisitor {
  final PragmaAnnotationParser parser;
  final metadata = ObfuscationProhibitionsMetadata();

  ObfuscationProhibitionsVisitor(this.parser);

  void _addIfEntryPoint(
      List<Expression> annotations, String name, TreeNode node) {
    for (var ann in annotations) {
      ParsedPragma pragma = parser.parsePragma(ann);
      if (pragma is ParsedEntryPointPragma) {
        metadata.protectedNames.add(name);
        if (node is Field) {
          metadata.protectedNames.add(name + "=");
        }
        final parent = node.parent;
        if (parent is Class) {
          metadata.protectedNames.add(parent.name);
        }
        break;
      }
    }
  }

  @override
  visitClass(Class klass) {
    _addIfEntryPoint(klass.annotations, klass.name, klass);
    klass.visitChildren(this);
  }

  @override
  visitConstructor(Constructor ctor) {
    _addIfEntryPoint(ctor.annotations, ctor.name.text, ctor);
  }

  @override
  visitProcedure(Procedure proc) {
    _addIfEntryPoint(proc.annotations, proc.name.text, proc);
  }

  @override
  visitField(Field field) {
    _addIfEntryPoint(field.annotations, field.name.text, field);
  }
}
