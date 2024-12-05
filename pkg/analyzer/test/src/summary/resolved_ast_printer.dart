// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';

import '../../util/element_printer.dart';

/// Prints AST as a tree, with properties and children.
class ResolvedAstPrinter extends ThrowingAstVisitor<void> {
  final TreeStringSink _sink;
  final ElementPrinter _elementPrinter;
  final ResolvedNodeTextConfiguration configuration;

  /// If `true`, selected tokens and nodes should be printed with offsets.
  final bool _withOffsets;

  /// If `true`, resolution should be printed.
  final bool _withResolution;

  final Map<Token, String> _tokenIdMap = Map.identity();

  ResolvedAstPrinter({
    required TreeStringSink sink,
    required ElementPrinter elementPrinter,
    required this.configuration,
    bool withOffsets = false,
    bool withResolution = true,
  })  : _sink = sink,
        _elementPrinter = elementPrinter,
        _withOffsets = withOffsets,
        _withResolution = withResolution;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _sink.writeln('AdjacentStrings');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
      _writeRaw('stringValue', node.stringValue);
    });
  }

  @override
  void visitAnnotation(Annotation node) {
    _sink.writeln('Annotation');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeElement2('element2', node.element2);
    });
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _sink.writeln('ArgumentList');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitAsExpression(AsExpression node) {
    _sink.writeln('AsExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _sink.writeln('AssertInitializer');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _sink.writeln('AssertStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitAssignedVariablePattern(
    covariant AssignedVariablePatternImpl node,
  ) {
    _sink.writeln('AssignedVariablePattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('element', node.element);
        _writeElement2('element2', node.element2);
        _writePatternMatchedValueType(node);
      }
    });
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _sink.writeln('AssignmentExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeElement('readElement', node.readElement);
      _writeElement2('readElement2', node.readElement2);
      _writeType('readType', node.readType);
      _writeElement('writeElement', node.writeElement);
      _writeElement2('writeElement2', node.writeElement2);
      _writeType('writeType', node.writeType);
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitAugmentedExpression(AugmentedExpression node) {
    _sink.writeln('AugmentedExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeElement2('element2', node.element2);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitAugmentedInvocation(AugmentedInvocation node) {
    _sink.writeln('AugmentedInvocation');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeElement2('element2', node.element2);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _sink.writeln('AwaitExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _sink.writeln('BinaryExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
      _writeType('staticInvokeType', node.staticInvokeType);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitBlock(Block node) {
    _sink.writeln('Block');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _sink.writeln('BlockFunctionBody');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _sink.writeln('BooleanLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _sink.writeln('BreakStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _sink.writeln('CascadeExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitCaseClause(CaseClause node) {
    _sink.writeln('CaseClause');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitCastPattern(CastPattern node) {
    _sink.writeln('CastPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitCatchClause(CatchClause node) {
    _sink.writeln('CatchClause');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    _sink.writeln('CatchClauseParameter');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _sink.writeln('ClassDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _sink.writeln('ClassTypeAlias');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitComment(Comment node) {
    _sink.writeln('Comment');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      if (node.codeBlocks.isNotEmpty) {
        _sink.writelnWithIndent('codeBlocks');
        _sink.withIndent(() {
          for (var codeBlock in node.codeBlocks) {
            _writeMdCodeBlock(codeBlock);
          }
        });
      }
      if (node.docImports.isNotEmpty) {
        _sink.writelnWithIndent('docImports');
        _sink.withIndent(() {
          for (var docImport in node.docImports) {
            _writeDocImport(docImport);
          }
        });
      }
      if (node.docDirectives.isNotEmpty) {
        _sink.writelnWithIndent('docDirectives');
        _sink.withIndent(() {
          for (var docDirective in node.docDirectives) {
            switch (docDirective) {
              case SimpleDocDirective():
                _sink.writelnWithIndent('SimpleDocDirective');
                _sink.withIndent(() {
                  _sink.writelnWithIndent('tag');
                  _writeDocDirectiveTag(docDirective.tag);
                });
              case BlockDocDirective(:var openingTag, :var closingTag):
                _sink.writelnWithIndent('BlockDocDirective');
                _sink.withIndent(() {
                  _sink.writelnWithIndent('openingTag');
                  _writeDocDirectiveTag(openingTag);
                  if (closingTag != null) {
                    _sink.writelnWithIndent('closingTag');
                    _writeDocDirectiveTag(closingTag);
                  }
                });
            }
          }
        });
      }
      if (node.hasNodoc) {
        _sink.writelnWithIndent('hasNodoc: true');
      }
    });
  }

  @override
  void visitCommentReference(CommentReference node) {
    _sink.writeln('CommentReference');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _sink.writeln('CompilationUnit');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _sink.writeln('ConditionalExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitConfiguration(Configuration node) {
    _sink.writeln('Configuration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
    _sink.withIndent(() {
      _sink.writeWithIndent('resolvedUri: ');
      _elementPrinter.writeDirectiveUri(node.resolvedUri);
    });
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    _sink.writeln('ConstantPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _sink.writeln('ConstructorDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _sink.writeln('ConstructorFieldInitializer');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _sink.writeln('ConstructorName');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
    });
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _sink.writeln('ConstructorReference');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    _checkChildrenEntitiesLinking(node);
    _sink.writeln('ConstructorSelector');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _sink.writeln('ContinueStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _sink.writeln('DeclaredIdentifier');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitDeclaredVariablePattern(
    covariant DeclaredVariablePatternImpl node,
  ) {
    _sink.writeln('DeclaredVariablePattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        var element = node.declaredElement;
        if (element != null) {
          _sink.writeWithIndent('declaredElement: ');
          _sink.writeIf(element.hasImplicitType, 'hasImplicitType ');
          _sink.writeIf(element.isFinal, 'isFinal ');
          _sink.writeln('${element.name}@${element.nameOffset}');
          _sink.withIndent(() {
            _writeType('type', element.type);
          });
        }
        _writePatternMatchedValueType(node);
      }
    });
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _sink.writeln('DefaultFormalParameter');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _assertFormalParameterDeclaredElement(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitDoStatement(DoStatement node) {
    _sink.writeln('DoStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitDottedName(DottedName node) {
    _sink.writeln('DottedName');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _sink.writeln('DoubleLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    _sink.writeln('EmptyFunctionBody');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitEnumConstantArguments(EnumConstantArguments node) {
    if (configuration.withCheckingLinking) {
      _checkChildrenEntitiesLinking(node);
    }
    _sink.writeln('EnumConstantArguments');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _checkChildrenEntitiesLinking(node);
    _sink.writeln('EnumConstantDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('constructorElement', node.constructorElement);
        _writeElement2('constructorElement2', node.constructorElement2);
        _writeDeclaredElement(node.declaredElement);
      }
    });
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _sink.writeln('EnumDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _sink.writeln('ExportDirective');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
    });
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _sink.writeln('ExpressionFunctionBody');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _sink.writeln('ExpressionStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _sink.writeln('ExtendsClause');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _sink.writeln('ExtensionDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    _sink.writeln('ExtensionOnClause');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _sink.writeln('ExtensionOverride');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeElement2('element2', node.element2);
      _writeType('extendedType', node.extendedType);
      _writeType('staticType', node.staticType);
      _writeTypeList('typeArgumentTypes', node.typeArgumentTypes);
    });
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _sink.writeln('ExtensionTypeDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _sink.writeln('FieldDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _sink.writeln('FieldFormalParameter');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _assertFormalParameterDeclaredElement(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _sink.writeln('ForEachPartsWithDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _sink.writeln('ForEachPartsWithIdentifier');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    _sink.writeln('ForEachPartsWithPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForElement(ForElement node) {
    _sink.writeln('ForElement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _sink.writeln('FormalParameterList');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _sink.writeln('ForPartsWithDeclarations');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _sink.writeln('ForPartsWithExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForPartsWithPattern(ForPartsWithPattern node) {
    _sink.writeln('ForPartsWithPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForStatement(ForStatement node) {
    _sink.writeln('ForStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _sink.writeln('FunctionDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _sink.writeln('FunctionDeclarationStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _sink.writeln('FunctionExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _sink.writeln('FunctionExpressionInvocation');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
      _writeType('staticInvokeType', node.staticInvokeType);
      _writeType('staticType', node.staticType);
      _writeTypeList('typeArgumentTypes', node.typeArgumentTypes);
    });
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _sink.writeln('FunctionReference');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
      _writeTypeList('typeArgumentTypes', node.typeArgumentTypes);
    });
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _sink.writeln('FunctionTypeAlias');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _sink.writeln('FunctionTypedFormalParameter');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _assertFormalParameterDeclaredElement(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    _sink.writeln('GenericFunctionType');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeGenericFunctionTypeElement(
          'declaredElement',
          node.declaredElement,
        );
      }
      _writeType('type', node.type);
    });
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _sink.writeln('GenericTypeAlias');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitGuardedPattern(GuardedPattern node) {
    _sink.writeln('GuardedPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _sink.writeln('HideCombinator');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitIfElement(IfElement node) {
    _sink.writeln('IfElement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitIfStatement(IfStatement node) {
    _sink.writeln('IfStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _sink.writeln('ImplementsClause');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    _sink.writeln('ImplicitCallReference');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
      _writeType('staticType', node.staticType);
      _writeTypeList('typeArgumentTypes', node.typeArgumentTypes);
    });
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _sink.writeln('ImportDirective');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
    });
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _sink.writeln('ImportPrefixReference');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeElement2('element2', node.element2);
    });
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _sink.writeln('IndexExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _sink.writeln('InstanceCreationExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _sink.writeln('IntegerLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _sink.writeln('InterpolationExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _sink.writeln('InterpolationString');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitIsExpression(IsExpression node) {
    _sink.writeln('IsExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitLabel(Label node) {
    _sink.writeln('Label');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _sink.writeln('LabeledStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _sink.writeln('LibraryDirective');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeElement2('element2', node.element2);
    });
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _sink.writeln('LibraryIdentifier');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _sink.writeln('ListLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitListPattern(ListPattern node) {
    _sink.writeln('ListPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
      _writeType('requiredType', node.requiredType);
    });
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    _sink.writeln('LogicalAndPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    _sink.writeln('LogicalOrPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _sink.writeln('MapLiteralEntry');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitMapPattern(MapPattern node) {
    _sink.writeln('MapPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
      _writeType('requiredType', node.requiredType);
    });
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    _sink.writeln('MapPatternEntry');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _sink.writeln('MethodDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _sink.writeln('MethodInvocation');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticInvokeType', node.staticInvokeType);
      _writeType('staticType', node.staticType);
      _writeTypeList('typeArgumentTypes', node.typeArgumentTypes);
    });
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _sink.writeln('MixinDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitMixinOnClause(MixinOnClause node) {
    _sink.writeln('MixinOnClause');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _sink.writeln('NamedExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      // Types of the node and its expression must be the same.
      if (node.expression.staticType != node.staticType) {
        var nodeType = node.staticType;
        var expressionType = node.expression.staticType;
        fail(
          'Must be the same:\n'
          'nodeType: $nodeType\n'
          'expressionType: $expressionType',
        );
      }
    });
  }

  @override
  void visitNamedType(NamedType node) {
    _sink.writeln('NamedType');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeElement2('element2', node.element2);
      _writeType('type', node.type);
    });
  }

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    _sink.writeln('NullAssertPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitNullAwareElement(NullAwareElement node) {
    _sink.writeln('NullAwareElement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitNullCheckPattern(NullCheckPattern node) {
    _sink.writeln('NullCheckPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _sink.writeln('NullLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    _sink.writeln('ObjectPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _sink.writeln('ParenthesizedExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    _sink.writeln('ParenthesizedPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitPartDirective(PartDirective node) {
    _sink.writeln('PartDirective');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
    });
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _sink.writeln('PartOfDirective');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
    });
  }

  @override
  void visitPatternAssignment(covariant PatternAssignmentImpl node) {
    _sink.writeln('PatternAssignment');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('patternTypeSchema', node.patternTypeSchema);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitPatternField(PatternField node) {
    _sink.writeln('PatternField');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeElement2('element2', node.element2);
    });
  }

  @override
  void visitPatternFieldName(PatternFieldName node) {
    _sink.writeln('PatternFieldName');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitPatternVariableDeclaration(
    covariant PatternVariableDeclarationImpl node,
  ) {
    _sink.writeln('PatternVariableDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('patternTypeSchema', node.patternTypeSchema);
    });
  }

  @override
  void visitPatternVariableDeclarationStatement(
      PatternVariableDeclarationStatement node) {
    _sink.writeln('PatternVariableDeclarationStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _sink.writeln('PostfixExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      if (node.operator.type.isIncrementOperator) {
        _writeElement('readElement', node.readElement);
        _writeElement2('readElement2', node.readElement2);
        _writeType('readType', node.readType);
        _writeElement('writeElement', node.writeElement);
        _writeElement2('writeElement2', node.writeElement2);
        _writeType('writeType', node.writeType);
      }
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _sink.writeln('PrefixedIdentifier');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeElement('staticElement', node.staticElement);
      try {
        _writeElement2('element', node.element);
      } catch (_) {
        // TODO(scheglov): fix it
        _sink.writeln('<exception>');
      }
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _sink.writeln('PrefixExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      if (node.operator.type.isIncrementOperator) {
        _writeElement('readElement', node.readElement);
        _writeElement2('readElement2', node.readElement2);
        _writeType('readType', node.readType);
        _writeElement('writeElement', node.writeElement);
        _writeElement2('writeElement2', node.writeElement2);
        _writeType('writeType', node.writeType);
      }
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _sink.writeln('PropertyAccess');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    _sink.writeln('RecordLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    _sink.writeln('RecordPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    _sink.writeln('RecordTypeAnnotation');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('type', node.type);
    });
  }

  @override
  void visitRecordTypeAnnotationNamedField(
      RecordTypeAnnotationNamedField node) {
    _sink.writeln('RecordTypeAnnotationNamedField');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
      RecordTypeAnnotationNamedFields node) {
    _sink.writeln('RecordTypeAnnotationNamedFields');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
      RecordTypeAnnotationPositionalField node) {
    _sink.writeln('RecordTypeAnnotationPositionalField');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _sink.writeln('RedirectingConstructorInvocation');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
    });
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    _sink.writeln('RelationalPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeElement2('element2', node.element2);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitRepresentationConstructorName(RepresentationConstructorName node) {
    _sink.writeln('RepresentationConstructorName');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitRepresentationDeclaration(RepresentationDeclaration node) {
    _sink.writeln('RepresentationDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('fieldElement', node.fieldElement);
      // TODO(scheglov): add it
      // _writeFragment('fieldElement2', node.fieldFragment);
      _writeElement('constructorElement', node.constructorElement);
      // TODO(scheglov): add it
      // _writeFragment('constructorElement', node.constructorFragment);
    });
  }

  @override
  void visitRestPatternElement(RestPatternElement node) {
    _sink.writeln('RestPatternElement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _sink.writeln('RethrowExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _sink.writeln('ReturnStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _sink.writeln('SetOrMapLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeRaw('isMap', node.isMap);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _sink.writeln('ShowCombinator');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _sink.writeln('SimpleFormalParameter');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _sink.writeln('SimpleIdentifier');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeElement('staticElement', node.staticElement);
      try {
        _writeElement2('element', node.element);
      } catch (_) {
        // TODO(scheglov): fix it
        _sink.writeln('<exception>');
      }
      _writeType('staticType', node.staticType);
      _writeTypeList(
        'tearOffTypeArgumentTypes',
        node.tearOffTypeArgumentTypes,
      );
    });
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _sink.writeln('SimpleStringLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _sink.writeln('SpreadElement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _sink.writeln('StringInterpolation');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
      _writeRaw('stringValue', node.stringValue);
    });
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _sink.writeln('SuperConstructorInvocation');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeElement2('element', node.element);
    });
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _sink.writeln('SuperExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    if (configuration.withCheckingLinking) {
      _checkChildrenEntitiesLinking(node);
    }
    _sink.writeln('SuperFormalParameter');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _assertFormalParameterDeclaredElement(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _sink.writeln('SwitchCase');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _sink.writeln('SwitchDefault');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _sink.writeln('SwitchExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    _sink.writeln('SwitchExpressionCase');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    _sink.writeln('SwitchPatternCase');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _sink.writeln('SwitchStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _sink.writeln('SymbolLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
    });
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _sink.writeln('ThisExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _sink.writeln('ThrowExpression');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _sink.writeln('TopLevelVariableDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitTryStatement(TryStatement node) {
    _sink.writeln('TryStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _sink.writeln('TypeArgumentList');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _sink.writeln('TypeLiteral');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeParameterElement(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _sink.writeln('TypeParameter');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _sink.writeln('TypeParameterList');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _sink.writeln('VariableDeclaration');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writeDeclaredElement(node.declaredElement);
    });
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _sink.writeln('VariableDeclarationList');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _sink.writeln('VariableDeclarationStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitWhenClause(WhenClause node) {
    _sink.writeln('WhenClause');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _sink.writeln('WhileStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitWildcardPattern(
    covariant WildcardPatternImpl node,
  ) {
    _sink.writeln('WildcardPattern');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
      _writePatternMatchedValueType(node);
    });
  }

  @override
  void visitWithClause(WithClause node) {
    _sink.writeln('WithClause');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _sink.writeln('YieldStatement');
    _sink.withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  void _assertFormalParameterDeclaredElement(FormalParameter node) {
    if (_withResolution) {
      var declaredElement = node.declaredElement;
      var expected = _expectedFormalParameterElements(node);
      _assertHasIdenticalElement(expected, declaredElement);
    }
  }

  /// Check that children entities of the [node] link to each other.
  void _checkChildrenEntitiesLinking(AstNode node) {
    Token? lastEnd;
    for (var entity in node.childEntities) {
      if (lastEnd != null) {
        var begin = _entityBeginToken(entity);
        expect(lastEnd.next, begin);
        expect(begin.previous, lastEnd);
      }
      lastEnd = _entityEndToken(entity);
    }
  }

  /// Check that the actual parent of [child] is [parent].
  void _checkParentOfChild(AstNode parent, AstNode child) {
    var actualParent = child.parent;
    if (actualParent == null) {
      fail('''
No parent.
Child: (${child.runtimeType}) $child
Expected parent: (${parent.runtimeType}) $parent
''');
    } else if (actualParent != parent) {
      fail('''
Wrong parent.
Child: (${child.runtimeType}) $child
Actual parent: (${actualParent.runtimeType}) $actualParent
Expected parent: (${parent.runtimeType}) $parent
''');
    }
  }

  String _getTokenId(Token? token) {
    if (token == null) {
      return '<null>';
    }
    return _tokenIdMap[token] ??= 'T${_tokenIdMap.length}';
  }

  void _writeDeclaredElement(Element? element) {
    if (_withResolution) {
      if (element is LocalVariableElement) {
        _sink.writeWithIndent('declaredElement:');
        _sink.writeIf(element.hasImplicitType, ' hasImplicitType');
        _sink.writeIf(element.isConst, ' isConst');
        _sink.writeIf(element.isFinal, ' isFinal');
        _sink.writeIf(element.isLate, ' isLate');
        // TODO(scheglov): This crashes.
        // _writeIf(element.hasInitializer, ' hasInitializer');
        _sink.writeln(' ${element.name}@${element.nameOffset}');
        _sink.withIndent(() {
          _writeType('type', element.type);
        });
      } else {
        _writeElement('declaredElement', element);
        if (element is ExecutableElement) {
          _sink.withIndent(() {
            _writeType('type', element.type);
          });
        } else if (element is ParameterElement) {
          _sink.withIndent(() {
            _writeType('type', element.type);
          });
        }
      }
    }
  }

  void _writeDocDirectiveTag(DocDirectiveTag docDirective) {
    _sink.withIndent(() {
      _sink.writelnWithIndent(
          'offset: [${docDirective.offset}, ${docDirective.end}]');
      _sink.writelnWithIndent('type: [${docDirective.type}]');
      if (docDirective.positionalArguments.isNotEmpty) {
        _sink.writelnWithIndent('positionalArguments');
        _sink.withIndent(() {
          for (var argument in docDirective.positionalArguments) {
            _sink.writelnWithIndent(argument.value);
          }
        });
      }
      if (docDirective.namedArguments.isNotEmpty) {
        _sink.writelnWithIndent('namedArguments');
        _sink.withIndent(() {
          for (var argument in docDirective.namedArguments) {
            _sink.writeWithIndent(argument.name);
            _sink.writeln('=${argument.value}');
          }
        });
      }
    });
  }

  void _writeDocImport(DocImport docImport) {
    _sink.writelnWithIndent('DocImport');
    _sink.withIndent(() {
      _sink.writelnWithIndent('offset: ${docImport.offset}');
      _writeNode('import', docImport.import);
    });
  }

  void _writeElement(String name, Element? element) {
    if (_withResolution) {
      _elementPrinter.writeNamedElement(name, element);
    }
  }

  void _writeElement2(String name, Element2? element) {
    if (_withResolution) {
      _elementPrinter.writelnNamedElement2(name, element);
    }
  }

  void _writeGenericFunctionTypeElement(
    String name,
    GenericFunctionTypeElement? element,
  ) {
    _sink.writeWithIndent('$name: ');
    if (element == null) {
      _sink.writeln('<null>');
    } else {
      _sink.withIndent(() {
        _sink.writeln('GenericFunctionTypeElement');
        _writeParameterElements(element.parameters);
        _writeType('returnType', element.returnType);
        _writeType('type', element.type);
      });
    }
  }

  void _writeMdCodeBlock(MdCodeBlock codeBlock) {
    _sink.writelnWithIndent('MdCodeBlock');
    _sink.withIndent(() {
      var infoString = codeBlock.infoString;
      _sink.writelnWithIndent('infoString: ${infoString ?? '<empty>'}');
      _sink.writelnWithIndent('type: ${codeBlock.type}');
      assert(codeBlock.lines.isNotEmpty);
      _sink.writelnWithIndent('lines');
      _sink.withIndent(() {
        for (var line in codeBlock.lines) {
          _sink.writelnWithIndent('MdCodeBlockLine');
          _sink.withIndent(() {
            _sink.writelnWithIndent('offset: ${line.offset}');
            _sink.writelnWithIndent('length: ${line.length}');
          });
        }
      });
    });
  }

  void _writeNamedChildEntities(AstNode node) {
    node as AstNodeImpl;
    for (var entity in node.namedChildEntities) {
      var value = entity.value;
      if (value is Token) {
        _writeToken(entity.name, value);
      } else if (value is AstNode) {
        _checkParentOfChild(node, value);
        if (value is ArgumentList && configuration.skipArgumentList) {
        } else {
          _writeNode(entity.name, value);
        }
      } else if (value is List<Token>) {
        _writeTokenList(entity.name, value);
      } else if (value is List<AstNode>) {
        _writeNodeList(node, entity.name, value);
      } else {
        throw UnimplementedError('(${value.runtimeType}) $value');
      }
    }
  }

  void _writeNode(String name, AstNode? node) {
    if (node != null) {
      _sink.writeWithIndent('$name: ');
      node.accept(this);
    }
  }

  void _writeNodeList(AstNode parent, String name, List<AstNode> nodeList) {
    if (nodeList.isNotEmpty) {
      _sink.writelnWithIndent(name);
      _sink.withIndent(() {
        for (var node in nodeList) {
          _checkParentOfChild(parent, node);
          _sink.writeIndent();
          node.accept(this);
        }
      });
    }
  }

  void _writeOffset(String name, int offset) {
    _sink.writelnWithIndent('$name: $offset');
  }

  /// If [node] is at a position where it is an argument for an invocation,
  /// writes the corresponding parameter element.
  void _writeParameterElement(Expression node) {
    if (configuration.withParameterElements) {
      var parent = node.parent;
      if (parent is ArgumentList ||
          parent is AssignmentExpression && parent.rightHandSide == node ||
          parent is BinaryExpression && parent.rightOperand == node ||
          parent is IndexExpression && parent.index == node) {
        _writeElement('parameter', node.staticParameterElement);
      }
    }
  }

  void _writeParameterElements(List<ParameterElement> parameters) {
    _sink.writelnWithIndent('parameters');
    _sink.withIndent(() {
      for (var parameter in parameters) {
        var name = parameter.name;
        _sink.writelnWithIndent(name.isNotEmpty ? name : '<empty>');
        _sink.withIndent(() {
          _writeParameterKind(parameter);
          _writeType('type', parameter.type);
        });
      }
    });
  }

  void _writeParameterKind(ParameterElement parameter) {
    if (parameter.isOptionalNamed) {
      _sink.writelnWithIndent('kind: optional named');
    } else if (parameter.isOptionalPositional) {
      _sink.writelnWithIndent('kind: optional positional');
    } else if (parameter.isRequiredNamed) {
      _sink.writelnWithIndent('kind: required named');
    } else if (parameter.isRequiredPositional) {
      _sink.writelnWithIndent('kind: required positional');
    } else {
      throw StateError('Unknown kind: $parameter');
    }
  }

  void _writePatternMatchedValueType(DartPattern node) {
    if (_withResolution) {
      var matchedValueType = node.matchedValueType;
      if (matchedValueType != null) {
        _writeType('matchedValueType', matchedValueType);
      } else {
        fail('No matchedValueType: $node');
      }
    }
  }

  void _writeRaw(String name, Object? value) {
    _sink.writelnWithIndent('$name: $value');
  }

  void _writeToken(String name, Token? token) {
    if (token == null) {
      return;
    }

    _sink.writeIndentedLine(() {
      _sink.write('$name: ');
      if (configuration.withTokenPreviousNext) {
        _sink.write(_getTokenId(token));
        _sink.write(' ');
      }
      _sink.write(token.lexeme.ifNotEmptyOrElse('<empty>'));
      if (_withOffsets) {
        _sink.write(' @${token.offset}');
      }
      if (token.isSynthetic) {
        _sink.write(' <synthetic>');
      }
    });

    if (configuration.withTokenPreviousNext) {
      _sink.withIndent(() {
        if (token.previous case var previous?) {
          if (!previous.isEof) {
            if (_tokenIdMap[previous] == null) {
              _writeToken('previousX', previous);
            } else {
              _sink.writelnWithIndent(
                'previous: ${_getTokenId(previous)} |${previous.lexeme}|',
              );
            }
          }
        } else {
          _sink.writelnWithIndent('previous: <null>');
        }

        if (token.next case var next?) {
          _sink.writelnWithIndent(
            'next: ${_getTokenId(next)} |${next.lexeme}|',
          );
        } else {
          _sink.writelnWithIndent('next: <null>');
        }
      });
    }
  }

  void _writeTokenList(String name, List<Token> tokens) {
    if (tokens.isNotEmpty) {
      _sink.writelnWithIndent(name);
      _sink.withIndent(() {
        for (var token in tokens) {
          _sink.writelnWithIndent(token.lexeme);
          if (_withOffsets) {
            _sink.withIndent(() {
              _writeOffset('offset', token.offset);
            });
          }
        }
      });
    }
  }

  void _writeType(String name, DartType? type) {
    if (_withResolution) {
      _elementPrinter.writeNamedType(name, type);
    }
  }

  void _writeTypeList(String name, List<DartType>? types) {
    if (_withResolution) {
      _elementPrinter.writeTypeList(name, types);
    }
  }

  static void _assertHasIdenticalElement<T>(List<T> elements, T expected) {
    for (var element in elements) {
      if (identical(element, expected)) {
        return;
      }
    }
    fail('No $expected in $elements');
  }

  static Token _entityBeginToken(SyntacticEntity entity) {
    if (entity is Token) {
      return entity;
    } else if (entity is AstNode) {
      return entity.beginToken;
    } else {
      throw UnimplementedError('(${entity.runtimeType}) $entity');
    }
  }

  static Token _entityEndToken(SyntacticEntity entity) {
    if (entity is Token) {
      return entity;
    } else if (entity is AstNode) {
      return entity.endToken;
    } else {
      throw UnimplementedError('(${entity.runtimeType}) $entity');
    }
  }

  /// Every [FormalParameter] declares an element, and this element must be
  /// in the list of formal parameter elements of some declaration, e.g. of
  /// [ConstructorDeclaration], [MethodDeclaration], or a local
  /// [FunctionDeclaration].
  static List<ParameterElement> _expectedFormalParameterElements(
    FormalParameter node,
  ) {
    var parametersParent = node.parentFormalParameterList.parent;
    if (parametersParent is ConstructorDeclaration) {
      var declaredElement = parametersParent.declaredElement!;
      return declaredElement.parameters;
    } else if (parametersParent is FormalParameter) {
      var declaredElement = parametersParent.declaredElement!;
      return declaredElement.parameters;
    } else if (parametersParent is FunctionExpression) {
      var declaredElement = parametersParent.declaredElement!;
      return declaredElement.parameters;
    } else if (parametersParent is GenericFunctionTypeImpl) {
      var declaredElement = parametersParent.declaredElement!;
      return declaredElement.parameters;
    } else if (parametersParent is MethodDeclaration) {
      var declaredElement = parametersParent.declaredElement!;
      return declaredElement.parameters;
    }
    throw UnimplementedError(
      '(${parametersParent.runtimeType}) $parametersParent',
    );
  }
}

class ResolvedNodeTextConfiguration {
  bool skipArgumentList = false;

  /// If `true`, linking of [EnumConstantDeclaration] will be checked
  // TODO(scheglov): Remove after https://github.com/dart-lang/sdk/issues/48380
  bool withCheckingLinking = false;

  /// If `true`, elements of [InterfaceType] should be printed.
  bool withInterfaceTypeElements = false;

  /// If `true`, [Expression.staticParameterElement] should be printed.
  bool withParameterElements = true;

  /// If `true`, `redirectedConstructor` properties of [ConstructorElement]s
  /// should be printer.
  bool withRedirectedConstructors = false;

  /// If `true`, print IDs of each token, `previous` and `next` tokens.
  bool withTokenPreviousNext = false;
}
