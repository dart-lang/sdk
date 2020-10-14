// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterConvertToStatefulWidget extends CorrectionProducer {
  @override
  AssistKind get assistKind =>
      DartAssistKind.FLUTTER_CONVERT_TO_STATEFUL_WIDGET;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetClass = node.thisOrAncestorOfType<ClassDeclaration>();
    var superclass = widgetClass?.extendsClause?.superclass;
    if (widgetClass == null || superclass == null) {
      return;
    }

    // Don't spam, activate only from the `class` keyword to the class body.
    if (selectionOffset < widgetClass.classKeyword.offset ||
        selectionOffset > widgetClass.leftBracket.end) {
      return;
    }

    // Find the build() method.
    MethodDeclaration buildMethod;
    for (var member in widgetClass.members) {
      if (member is MethodDeclaration &&
          member.name.name == 'build' &&
          member.parameters != null &&
          member.parameters.parameters.length == 1) {
        buildMethod = member;
        break;
      }
    }
    if (buildMethod == null) {
      return;
    }

    // Must be a StatelessWidget subclasses.
    var widgetClassElement = widgetClass.declaredElement;
    if (!flutter.isExactlyStatelessWidgetType(widgetClassElement.supertype)) {
      return;
    }

    var widgetName = widgetClassElement.displayName;
    var stateName = '_${widgetName}State';

    // Find fields assigned in constructors.
    var visitor = _FieldFinder();
    for (var member in widgetClass.members) {
      if (member is ConstructorDeclaration) {
        member.accept(visitor);
      }
    }
    var fieldsAssignedInConstructors = visitor.fieldsAssignedInConstructors;

    // Prepare nodes to move.
    var nodesToMove = <ClassMember>{};
    var elementsToMove = <Element>{};
    for (var member in widgetClass.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (var fieldNode in member.fields.variables) {
          FieldElement fieldElement = fieldNode.declaredElement;
          if (!fieldsAssignedInConstructors.contains(fieldElement)) {
            nodesToMove.add(member);
            elementsToMove.add(fieldElement);
            elementsToMove.add(fieldElement.getter);
            if (fieldElement.setter != null) {
              elementsToMove.add(fieldElement.setter);
            }
          }
        }
      }
      if (member is MethodDeclaration && !member.isStatic) {
        nodesToMove.add(member);
        elementsToMove.add(member.declaredElement);
      }
    }

    /// Return the code for the [movedNode] which is suitable to be used
    /// inside the `State` class, so that references to the widget fields and
    /// methods, that are not moved, are qualified with the corresponding
    /// instance `widget.`, or static `MyWidgetClass.` qualifier.
    String rewriteWidgetMemberReferences(AstNode movedNode) {
      var linesRange = utils.getLinesRange(range.node(movedNode));
      var text = utils.getRangeText(linesRange);

      // Insert `widget.` before references to the widget instance members.
      var visitor = _ReplacementEditBuilder(
          widgetClassElement, elementsToMove, linesRange);
      movedNode.accept(visitor);
      return SourceEdit.applySequence(text, visitor.edits.reversed);
    }

    var statefulWidgetClass = await sessionHelper.getClass(
      flutter.widgetsUri,
      'StatefulWidget',
    );
    var stateClass = await sessionHelper.getClass(
      flutter.widgetsUri,
      'State',
    );
    if (statefulWidgetClass == null || stateClass == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(superclass), (builder) {
        builder.writeReference(statefulWidgetClass);
      });

      var replaceOffset = 0;
      var hasBuildMethod = false;

      var typeParams = '';
      if (widgetClass.typeParameters != null) {
        typeParams = utils.getNodeText(widgetClass.typeParameters);
      }

      /// Replace code between [replaceOffset] and [replaceEnd] with
      /// `createState()`, empty line, or nothing.
      void replaceInterval(int replaceEnd,
          {bool replaceWithEmptyLine = false,
          bool hasEmptyLineBeforeCreateState = false,
          bool hasEmptyLineAfterCreateState = true}) {
        var replaceLength = replaceEnd - replaceOffset;
        builder.addReplacement(
          SourceRange(replaceOffset, replaceLength),
          (builder) {
            if (hasBuildMethod) {
              if (hasEmptyLineBeforeCreateState) {
                builder.writeln();
              }
              builder.writeln('  @override');
              builder.writeln(
                  '  $stateName$typeParams createState() => $stateName$typeParams();');
              if (hasEmptyLineAfterCreateState) {
                builder.writeln();
              }
              hasBuildMethod = false;
            } else if (replaceWithEmptyLine) {
              builder.writeln();
            }
          },
        );
        replaceOffset = 0;
      }

      // Remove continuous ranges of lines of nodes being moved.
      var lastToRemoveIsField = false;
      var endOfLastNodeToKeep = 0;
      for (var node in widgetClass.members) {
        if (nodesToMove.contains(node)) {
          if (replaceOffset == 0) {
            var linesRange = utils.getLinesRange(range.node(node));
            replaceOffset = linesRange.offset;
          }
          if (node == buildMethod) {
            hasBuildMethod = true;
          }
          lastToRemoveIsField = node is FieldDeclaration;
        } else {
          var linesRange = utils.getLinesRange(range.node(node));
          endOfLastNodeToKeep = linesRange.end;
          if (replaceOffset != 0) {
            replaceInterval(linesRange.offset,
                replaceWithEmptyLine:
                    lastToRemoveIsField && node is! FieldDeclaration);
          }
        }
      }

      // Remove nodes at the end of the widget class.
      if (replaceOffset != 0) {
        // Remove from the last node to keep, so remove empty lines.
        if (endOfLastNodeToKeep != 0) {
          replaceOffset = endOfLastNodeToKeep;
        }
        replaceInterval(widgetClass.rightBracket.offset,
            hasEmptyLineBeforeCreateState: endOfLastNodeToKeep != 0,
            hasEmptyLineAfterCreateState: false);
      }

      // Create the State subclass.
      builder.addInsertion(widgetClass.end, (builder) {
        builder.writeln();
        builder.writeln();

        builder.write('class $stateName$typeParams extends ');
        builder.writeReference(stateClass);

        // Write just param names (and not bounds, metadata and docs).
        builder.write('<${widgetClass.name}');
        if (widgetClass.typeParameters != null) {
          builder.write('<');
          var first = true;
          for (var param in widgetClass.typeParameters.typeParameters) {
            if (!first) {
              builder.write(', ');
              first = false;
            }
            builder.write(param.name.name);
          }
          builder.write('>');
        }

        builder.writeln('> {');

        var writeEmptyLine = false;
        for (var member in nodesToMove) {
          if (writeEmptyLine) {
            builder.writeln();
          }
          var text = rewriteWidgetMemberReferences(member);
          builder.write(text);
          // Write empty lines between members, but not before the first.
          writeEmptyLine = true;
        }

        builder.write('}');
      });
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static FlutterConvertToStatefulWidget newInstance() =>
      FlutterConvertToStatefulWidget();
}

class _FieldFinder extends RecursiveAstVisitor<void> {
  Set<FieldElement> fieldsAssignedInConstructors = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent is FieldFormalParameter) {
      var element = node.staticElement;
      if (element is FieldFormalParameterElement) {
        fieldsAssignedInConstructors.add(element.field);
      }
    }
    if (node.parent is ConstructorFieldInitializer) {
      var element = node.staticElement;
      if (element is FieldElement) {
        fieldsAssignedInConstructors.add(element);
      }
    }
    if (node.inSetterContext()) {
      var element = node.writeOrReadElement;
      if (element is PropertyAccessorElement) {
        var field = element.variable;
        if (field is FieldElement) {
          fieldsAssignedInConstructors.add(field);
        }
      }
    }
  }
}

class _ReplacementEditBuilder extends RecursiveAstVisitor<void> {
  final ClassElement widgetClassElement;

  final Set<Element> elementsToMove;

  final SourceRange linesRange;

  List<SourceEdit> edits = [];

  _ReplacementEditBuilder(
      this.widgetClassElement, this.elementsToMove, this.linesRange);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    var element = node.staticElement;
    if (element is ExecutableElement &&
        element?.enclosingElement == widgetClassElement &&
        !elementsToMove.contains(element)) {
      var offset = node.offset - linesRange.offset;
      var qualifier =
          element.isStatic ? widgetClassElement.displayName : 'widget';

      var parent = node.parent;
      if (parent is InterpolationExpression &&
          parent.leftBracket.type ==
              TokenType.STRING_INTERPOLATION_IDENTIFIER) {
        edits.add(SourceEdit(offset, 0, '{$qualifier.'));
        edits.add(SourceEdit(offset + node.length, 0, '}'));
      } else {
        edits.add(SourceEdit(offset, 0, '$qualifier.'));
      }
    }
  }
}
