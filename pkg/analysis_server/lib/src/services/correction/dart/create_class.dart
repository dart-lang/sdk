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

class CreateClass extends CorrectionProducer {
  String className = '';

  @override
  List<Object> get fixArguments => [className];

  @override
  FixKind get fixKind => DartFixKind.CREATE_CLASS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = node;
    Element? prefixElement;
    ArgumentList? arguments;

    String? className;
    bool requiresConstConstructor = false;
    if (targetNode is Annotation) {
      var name = targetNode.name;
      arguments = targetNode.arguments;
      if (name.staticElement != null || arguments == null) {
        // TODO(brianwilkerson) Consider supporting creating a class when the
        //  arguments are missing by also adding an empty argument list.
        return;
      }
      targetNode = name;
      requiresConstConstructor = true;
    }
    if (targetNode is NamedType) {
      final importPrefix = targetNode.importPrefix;
      if (importPrefix != null) {
        prefixElement = importPrefix.element;
        if (prefixElement == null) {
          return;
        }
      }
      className = targetNode.name2.lexeme;
      requiresConstConstructor |= _requiresConstConstructor(targetNode);
    } else if (targetNode is SimpleIdentifier) {
      className = nameOfType(targetNode);
      requiresConstConstructor |= _requiresConstConstructor(targetNode);
    } else if (targetNode is PrefixedIdentifier) {
      prefixElement = targetNode.prefix.staticElement;
      if (prefixElement == null) {
        return;
      }
      className = nameOfType(targetNode.identifier);
    } else {
      return;
    }

    if (className == null) {
      return;
    }
    this.className = className;

    // prepare environment
    Element targetUnit;
    var prefix = '';
    var suffix = '';
    var offset = -1;
    String? filePath;
    if (prefixElement == null) {
      targetUnit = unit.declaredElement!;
      var enclosingMember = targetNode.thisOrAncestorMatching((node) =>
          node is CompilationUnitMember && node.parent is CompilationUnit);
      if (enclosingMember == null) {
        return;
      }
      offset = enclosingMember.end;
      filePath = file;
      prefix = '$eol$eol';
    } else {
      for (var import in libraryElement.libraryImports) {
        if (prefixElement is PrefixElement &&
            import.prefix?.element == prefixElement) {
          var library = import.importedLibrary;
          if (library != null) {
            targetUnit = library.definingCompilationUnit;
            var targetSource = targetUnit.source!;
            try {
              offset = targetSource.contents.data.length;
              filePath = targetSource.fullName;
              prefix = eol;
              suffix = eol;
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

    final className2 = className;
    await builder.addDartFileEdit(filePath, (builder) {
      builder.addInsertion(offset, (builder) {
        builder.write(prefix);
        if (arguments == null && !requiresConstConstructor) {
          builder.writeClassDeclaration(className2, nameGroupName: 'NAME');
        } else {
          builder.writeClassDeclaration(className2, nameGroupName: 'NAME',
              membersWriter: () {
            builder.write('  ');
            builder.writeConstructorDeclaration(
              className2,
              argumentList: arguments,
              classNameGroupName: 'NAME',
              isConst: requiresConstConstructor,
            );
            builder.writeln();
          });
        }
        builder.write(suffix);
      });
      if (prefixElement == null) {
        builder.addLinkedPosition(range.node(targetNode), 'NAME');
      }
    });
  }

  static bool _requiresConstConstructor(AstNode node) {
    final parent = node.parent;
    // TODO(scheglov) remove after NamedType refactoring.
    if (node is SimpleIdentifier && parent is NamedType) {
      return _requiresConstConstructor(parent);
    }
    if (node is SimpleIdentifier && parent is MethodInvocation) {
      return parent.inConstantContext;
    }
    if (node is NamedType && parent is ConstructorName) {
      return _requiresConstConstructor(parent);
    }
    if (node is ConstructorName && parent is InstanceCreationExpression) {
      return parent.isConst;
    }
    return false;
  }
}
