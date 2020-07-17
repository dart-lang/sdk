// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMixin extends CorrectionProducer {
  String _mixinName;

  @override
  List<Object> get fixArguments => [_mixinName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_MIXIN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Element prefixElement;
    SimpleIdentifier nameNode;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is TypeName &&
          parent.parent is ConstructorName &&
          parent.parent.parent is InstanceCreationExpression) {
        return;
      } else {
        nameNode = node;
        _mixinName = nameNode.name;
      }
    } else if (node is PrefixedIdentifier) {
      if (node.parent is InstanceCreationExpression) {
        return;
      }
      PrefixedIdentifier prefixedIdentifier = node;
      prefixElement = prefixedIdentifier.prefix.staticElement;
      if (prefixElement == null) {
        return;
      }
      nameNode = prefixedIdentifier.identifier;
      _mixinName = prefixedIdentifier.identifier.name;
    } else {
      return;
    }
    if (!mightBeTypeIdentifier(nameNode)) {
      return;
    }
    // prepare environment
    Element targetUnit;
    var prefix = '';
    var suffix = '';
    var offset = -1;
    String filePath;
    if (prefixElement == null) {
      targetUnit = unit.declaredElement;
      var enclosingMember = node.thisOrAncestorMatching((node) =>
          node is CompilationUnitMember && node.parent is CompilationUnit);
      if (enclosingMember == null) {
        return;
      }
      offset = enclosingMember.end;
      filePath = file;
      prefix = '$eol$eol';
    } else {
      for (var import in libraryElement.imports) {
        if (prefixElement is PrefixElement && import.prefix == prefixElement) {
          var library = import.importedLibrary;
          if (library != null) {
            targetUnit = library.definingCompilationUnit;
            var targetSource = targetUnit.source;
            try {
              offset = targetSource.contents.data.length;
              filePath = targetSource.fullName;
              prefix = '$eol';
              suffix = '$eol';
            } on FileSystemException {
              // If we can't read the file to get the offset, then we can't
              // create a fix.
            }
            break;
          }
        }
      }
    }
    if (offset < 0) {
      return;
    }
    await builder.addDartFileEdit(filePath, (builder) {
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateMixin newInstance() => CreateMixin();
}
