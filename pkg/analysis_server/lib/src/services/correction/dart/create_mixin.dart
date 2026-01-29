// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/utilities/extensions/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMixin extends MultiCorrectionProducer {
  CreateMixin({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    String mixinName = '';
    Element? prefixElement;
    var withKeyword = false;
    var node = this.node;
    Expression? expression;
    if (node is NamedType) {
      var importPrefix = node.importPrefix;
      if (importPrefix != null) {
        prefixElement = importPrefix.element;
        if (prefixElement == null) {
          return const [];
        }
      }
      withKeyword = node.parent is WithClause;
      mixinName = node.name.lexeme;
    } else if (node is SimpleIdentifier) {
      var parent = node.parent;
      switch (parent) {
        // Not the first identifier or the body of a function
        case PrefixedIdentifier(identifier: Expression invalid) ||
            PropertyAccess(propertyName: Expression invalid) ||
            ExpressionFunctionBody(expression: var invalid):
          if (invalid == node) {
            return const [];
          }
      }
      expression = stepUpNamedExpression(node);
      mixinName = node.name;
    } else if (node is PrefixedIdentifier) {
      if (node.parent is InstanceCreationExpression) {
        return const [];
      }
      prefixElement = node.prefix.element;
      if (prefixElement == null) {
        return const [];
      }
      expression = stepUpNamedExpression(node);
      mixinName = node.identifier.name;
    } else {
      return const [];
    }
    if (mixinName.isEmpty) {
      return const [];
    }
    return [
      // Lowercase mixin names are valid but not idiomatic so lower the
      // priority.
      if (mixinName.firstLetterIsLowercase)
        _CreateMixin.lowercase(
          mixinName,
          expression,
          prefixElement,
          withKeyword: withKeyword,
          context: context,
        )
      else
        _CreateMixin.uppercase(
          mixinName,
          expression,
          prefixElement,
          withKeyword: withKeyword,
          context: context,
        ),
    ];
  }
}

class _CreateMixin extends ResolvedCorrectionProducer {
  final String _mixinName;
  final Element? prefixElement;
  final Expression? _expression;

  @override
  final FixKind fixKind;

  _CreateMixin.lowercase(
    this._mixinName,
    this._expression,
    this.prefixElement, {
    required bool withKeyword,
    required super.context,
  }) : fixKind = withKeyword
           ? DartFixKind.createMixinLowercaseWith
           : DartFixKind.createMixinLowercase;

  _CreateMixin.uppercase(
    this._mixinName,
    this._expression,
    this.prefixElement, {
    required bool withKeyword,
    required super.context,
  }) : fixKind = withKeyword
           ? DartFixKind.createMixinUppercaseWith
           : DartFixKind.createMixinUppercase;

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_mixinName];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // either not expecting anything specific or expecting a type || object
    if (_expression != null) {
      var fieldType = inferUndefinedExpressionType(_expression);
      if (fieldType is InvalidType) {
        return;
      }
      if (fieldType != null &&
          (!typeSystem.isAssignableTo(fieldType, typeProvider.typeType) ||
              !typeSystem.isSubtypeOf(fieldType, typeProvider.objectType))) {
        return;
      }
    }
    // prepare environment
    LibraryFragment targetUnit;
    var offset = -1;
    String? filePath;
    if (prefixElement == null) {
      targetUnit = unit.declaredFragment!;
      var enclosingMember = node.thisOrAncestorMatching(
        (node) =>
            node is CompilationUnitMember && node.parent is CompilationUnit,
      );
      if (enclosingMember == null) {
        return;
      }
      offset = enclosingMember.end;
      filePath = file;
    } else {
      for (var import in libraryElement2.firstFragment.libraryImports) {
        if (prefixElement is PrefixElement &&
            import.prefix?.element == prefixElement) {
          var library = import.importedLibrary;
          if (library != null) {
            targetUnit = library.firstFragment;
            var targetSource = targetUnit.source;
            try {
              offset = targetSource.stringContents.length;
              filePath = targetSource.fullName;
            } on FileSystemException {
              // If we can't read the file to get the offset, then we can't
              // create a fix.
            }
            break;
          }
        }
      }
    }
    if (filePath == null || offset < 0) {
      return;
    }
    await builder.addDartFileEdit(filePath, (builder) {
      var eol = builder.eol;
      var prefix = filePath == file ? '$eol$eol' : eol;
      var suffix = filePath == file ? '' : eol;
      builder.addInsertion(offset, (builder) {
        builder.write(prefix);
        builder.writeMixinDeclaration(_mixinName, nameGroupName: 'NAME');
        builder.write(suffix);
      });
      if (prefixElement == null) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
  }
}
