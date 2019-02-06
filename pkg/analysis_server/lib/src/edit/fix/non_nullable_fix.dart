// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// [NonNullableFix] visits each named type in a resolved compilation unit
/// and determines whether the associated variable or parameter can be null
/// then adds or removes a '?' trailing the named type as appropriate.
class NonNullableFix {
  final DartFixListener listener;

  /// The current source being "fixed"
  Source source;

  /// The source file change or `null` if none
  SourceFileEdit fileEdit;

  int firstOffset;
  int firstLength;

  NonNullableFix(this.listener);

  void addEdit(int offset, int length, String replacementText) {
    fileEdit ??= new SourceFileEdit(source.fullName, 0);
    fileEdit.edits.add(new SourceEdit(offset, length, replacementText));
  }

  /// Update the source to be non-nullable by
  /// 1) adding trailing '?' to type references of nullable variables, and
  /// 2) removing trailing '?' from type references of non-nullable variables.
  void applyLocalFixes(ResolvedUnitResult result) {
    final context = result.session.analysisContext;
    AnalysisOptionsImpl options = context.analysisOptions;
    if (!options.experimentStatus.non_nullable) {
      return;
    }

    final unit = result.unit;
    source = unit.declaredElement.source;

    // find and fix types
    unit.accept(new _NonNullableTypeVisitor(this));

    // add source changes to the collection of fixes
    source = null;
    if (fileEdit != null) {
      listener.addSourceFileEdit('Update non-nullable type references',
          listener.locationFor(result, firstOffset, firstLength), fileEdit);
    }
  }

  void applyRemainingFixes() {}
}

class _NonNullableTypeVisitor extends RecursiveAstVisitor<void> {
  final NonNullableFix fix;

  _NonNullableTypeVisitor(this.fix);

  @override
  void visitConstructorName(ConstructorName node) {
    // skip the type name associated with the constructor
    node.type?.typeArguments?.accept(this);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    // skip the type name associated with the extends clause
    node.superclass?.typeArguments?.accept(this);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    // skip the type names in the implements clause
    for (TypeName typeName in node.interfaces) {
      typeName.typeArguments?.accept(this);
    }
  }

  @override
  void visitOnClause(OnClause node) {
    // skip the type name in the clause
    for (TypeName typeName in node.superclassConstraints) {
      typeName.typeArguments?.accept(this);
    }
  }

  @override
  void visitTypeName(TypeName node) {
    // TODO(danrubel): Replace this braindead implementation
    // with something that determines whether or not the type should be nullable
    // and adds or removes the trailing `?` to match.
    if (node.question == null) {
      final identifier = node.name;
      if (identifier is SimpleIdentifier) {
        if (identifier.name == 'void') {
          return;
        }
      }
      fix.addEdit(node.end, 0, '?');
      fix.firstOffset ??= node.offset;
      fix.firstLength ??= node.length;
    }
    super.visitTypeName(node);
  }

  @override
  void visitWithClause(WithClause node) {
    // skip the type names associated with this clause
    for (TypeName typeName in node.mixinTypes) {
      typeName.typeArguments?.accept(this);
    }
  }
}
