// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateClass extends MultiCorrectionProducer {
  CreateClass({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var targetNode = node;
    Element? prefixElement;
    ArgumentList? arguments;

    var withKeyword = false;
    String? className;
    bool requiresConstConstructor = false;
    if (targetNode is Annotation) {
      var name = targetNode.name;
      arguments = targetNode.arguments;
      if (name.element != null || arguments == null) {
        // TODO(brianwilkerson): Consider supporting creating a class when the
        //  arguments are missing by also adding an empty argument list.
        return const [];
      }
      targetNode = name;
      requiresConstConstructor = true;
    }
    if (targetNode is NamedType) {
      var importPrefix = targetNode.importPrefix;
      if (importPrefix != null) {
        prefixElement = importPrefix.element;
        if (prefixElement == null) {
          return const [];
        }
      }
      withKeyword = node.parent is WithClause;
      className = targetNode.name.lexeme;
      requiresConstConstructor |= _requiresConstConstructor(targetNode);
    } else if (targetNode case SimpleIdentifier(
      :var parent,
    ) when parent is! PropertyAccess && parent is! PrefixedIdentifier) {
      if (parent case MethodInvocation(:var target)) {
        if (target case SimpleIdentifier(:PrefixElement element)) {
          prefixElement = element;
        } else if (target?.staticType != null) {
          return const [];
        }
      }
      className = targetNode.nameOfType ?? targetNode.name;
      requiresConstConstructor |= _requiresConstConstructor(targetNode);
    } else if (targetNode case SimpleIdentifier(
      parent: PrefixedIdentifier(:var identifier),
    ) when targetNode != identifier) {
      className = targetNode.nameOfType ?? targetNode.name;
      requiresConstConstructor |= _requiresConstConstructor(targetNode);
    } else if (targetNode is PrefixedIdentifier) {
      prefixElement = targetNode.prefix.element;
      if (prefixElement == null) {
        return const [];
      }
      className =
          targetNode.identifier.nameOfType ?? targetNode.identifier.name;
    } else {
      return const [];
    }

    if (className.isEmpty) {
      return const [];
    }
    // Lowercase class names are valid but not idiomatic so lower the priority.
    if (className.firstLetterIsLowercase) {
      return [
        _CreateClass.lowercase(
          context: context,
          targetNode: targetNode,
          prefixElement: prefixElement,
          className: className,
          requiresConstConstructor: requiresConstConstructor,
          withKeyword: withKeyword,
          arguments: arguments,
        ),
      ];
    } else {
      return [
        _CreateClass.uppercase(
          context: context,
          targetNode: targetNode,
          prefixElement: prefixElement,
          className: className,
          requiresConstConstructor: requiresConstConstructor,
          withKeyword: withKeyword,
          arguments: arguments,
        ),
      ];
    }
  }

  static bool _requiresConstConstructor(AstNode node) {
    var parent = node.parent;
    // TODO(scheglov): remove after NamedType refactoring.
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

class _CreateClass extends ResolvedCorrectionProducer {
  final ArgumentList? _arguments;
  final bool _requiresConstConstructor;
  final AstNode _targetNode;
  final Element? _prefixElement;
  final String _className;

  @override
  final FixKind fixKind;

  _CreateClass.lowercase({
    required super.context,
    required ArgumentList? arguments,
    required bool requiresConstConstructor,
    required AstNode targetNode,
    required Element? prefixElement,
    required String className,
    required bool withKeyword,
  }) : _className = className,
       _prefixElement = prefixElement,
       _targetNode = targetNode,
       _requiresConstConstructor = requiresConstConstructor,
       _arguments = arguments,
       fixKind =
           withKeyword
               ? DartFixKind.CREATE_CLASS_LOWERCASE_WITH
               : DartFixKind.CREATE_CLASS_LOWERCASE;

  _CreateClass.uppercase({
    required super.context,
    required ArgumentList? arguments,
    required bool requiresConstConstructor,
    required AstNode targetNode,
    required Element? prefixElement,
    required String className,
    required bool withKeyword,
  }) : _className = className,
       _prefixElement = prefixElement,
       _targetNode = targetNode,
       _requiresConstConstructor = requiresConstConstructor,
       _arguments = arguments,
       fixKind =
           withKeyword
               ? DartFixKind.CREATE_CLASS_UPPERCASE_WITH
               : DartFixKind.CREATE_CLASS_UPPERCASE;

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_className];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare environment
    LibraryFragment targetUnit;
    var prefix = '';
    var suffix = '';
    var offset = -1;
    String? filePath;
    if (_prefixElement == null) {
      targetUnit = unit.declaredFragment!;
      var enclosingMember = _targetNode.thisOrAncestorMatching(
        (node) =>
            node is CompilationUnitMember && node.parent is CompilationUnit,
      );
      if (enclosingMember == null) {
        return;
      }
      offset = enclosingMember.end;
      filePath = file;
      prefix = '$eol$eol';
    } else {
      for (var import in libraryElement2.firstFragment.libraryImports2) {
        if (_prefixElement is PrefixElement &&
            import.prefix2?.element == _prefixElement) {
          var library = import.importedLibrary;
          if (library != null) {
            targetUnit = library.firstFragment;
            var targetSource = targetUnit.source;
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

    var className2 = _className;
    await builder.addDartFileEdit(filePath, (builder) {
      builder.addInsertion(offset, (builder) {
        builder.write(prefix);
        if (_arguments == null && !_requiresConstConstructor) {
          builder.writeClassDeclaration(className2, nameGroupName: 'NAME');
        } else {
          builder.writeClassDeclaration(
            className2,
            nameGroupName: 'NAME',
            membersWriter: () {
              builder.write('  ');
              builder.writeConstructorDeclaration(
                className2,
                argumentList: _arguments,
                classNameGroupName: 'NAME',
                isConst: _requiresConstConstructor,
              );
              builder.writeln();
            },
          );
        }
        builder.write(suffix);
      });
      if (_prefixElement == null) {
        builder.addLinkedPosition(range.node(_targetNode), 'NAME');
      }
    });
  }
}

extension on AstNode {
  /// If this might be a type name, return its name.
  String? get nameOfType {
    var self = this;
    if (self is SimpleIdentifier) {
      var name = self.name;
      if (self.parent is NamedType || _isNameOfType(name)) {
        return name;
      }
    }
    return null;
  }

  /// Return `true` if the [name] is capitalized.
  static bool _isNameOfType(String name) {
    if (name.isEmpty) {
      return false;
    }
    var firstLetter = name.substring(0, 1);
    if (firstLetter.toUpperCase() != firstLetter) {
      return false;
    }
    return true;
  }
}
