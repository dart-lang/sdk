// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:test/test.dart';

/// Used in [ResolvedAstPrinter] to print lines of code that corresponding
/// to a subtree of AST. This help to make the bulky presentation of AST a
/// bit more understandable.
abstract class CodeLinesProvider {
  /// If the [offset] corresponds to a new, never requested before line,
  /// return this line, otherwise return `null`.
  String nextLine(int offset);
}

/// Prints AST as a tree, with properties and children.
class ResolvedAstPrinter extends ThrowingAstVisitor<void> {
  /// The URI of the library that contains the AST being printed.
  final String? _selfUriStr;

  /// The target sink to print AST.
  final StringSink _sink;

  /// The optional provider for code lines, might be `null`.
  final CodeLinesProvider? _codeLinesProvider;

  /// If `true`, linking of [EnumConstantDeclaration] will be checked
  /// TODO(scheglov) Remove after https://github.com/dart-lang/sdk/issues/48380
  final bool withCheckingLinking;

  /// If `true`, selected tokens and nodes should be printed with offsets.
  final bool _withOffsets;

  /// If `true`, resolution should be printed.
  final bool _withResolution;

  String _indent = '';

  ResolvedAstPrinter({
    required String? selfUriStr,
    required StringSink sink,
    required String indent,
    CodeLinesProvider? codeLinesProvider,
    this.withCheckingLinking = false,
    bool withOffsets = false,
    bool withResolution = true,
  })  : _selfUriStr = selfUriStr,
        _sink = sink,
        _codeLinesProvider = codeLinesProvider,
        _withOffsets = withOffsets,
        _withResolution = withResolution,
        _indent = indent;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _writeNextCodeLine(node);
    _writeln('AdjacentStrings');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
      _writeRaw('stringValue', node.stringValue);
    });
  }

  @override
  void visitAnnotation(Annotation node) {
    _writeNextCodeLine(node);
    _writeln('Annotation');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
    });
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _writeNextCodeLine(node);
    _writeln('ArgumentList');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitAsExpression(AsExpression node) {
    _writeNextCodeLine(node);
    _writeln('AsExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _writeNextCodeLine(node);
    _writeln('AssertInitializer');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _writeNextCodeLine(node);
    _writeln('AssertStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _writeNextCodeLine(node);
    _writeln('AssignmentExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('readElement', node.readElement);
      _writeType('readType', node.readType);
      _writeElement('writeElement', node.writeElement);
      _writeType('writeType', node.writeType);
      _writeElement('staticElement', node.staticElement);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _writeNextCodeLine(node);
    _writeln('AwaitExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _writeNextCodeLine(node);
    _writeln('BinaryExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeType('staticInvokeType', node.staticInvokeType);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitBlock(Block node) {
    _writeNextCodeLine(node);
    _writeln('Block');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _writeNextCodeLine(node);
    _writeln('BlockFunctionBody');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _writeNextCodeLine(node);
    _writeln('BooleanLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _writeNextCodeLine(node);
    _writeln('BreakStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _writeNextCodeLine(node);
    _writeln('CascadeExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitCatchClause(CatchClause node) {
    _writeNextCodeLine(node);
    _writeln('CatchClause');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('ClassDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitComment(Comment node) {
    _writeNextCodeLine(node);
    _writeln('Comment');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _writeNextCodeLine(node);
    _writeln('CompilationUnit');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _writeNextCodeLine(node);
    _writeln('ConditionalExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('ConstructorDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _writeNextCodeLine(node);
    _writeln('ConstructorFieldInitializer');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _writeNextCodeLine(node);
    _writeln('ConstructorName');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
    });
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _writeln('ConstructorReference');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    _checkChildrenEntitiesLinking(node);
    _writeln('ConstructorSelector');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _writeNextCodeLine(node);
    _writeln('ContinueStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('DeclaredIdentifier');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _writeNextCodeLine(node);
    _writeln('DefaultFormalParameter');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
        _writeType('declaredElementType', node.declaredElement!.type);
      }
    });
  }

  @override
  void visitDoStatement(DoStatement node) {
    _writeNextCodeLine(node);
    _writeln('DoStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _writeNextCodeLine(node);
    _writeln('DoubleLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    _writeNextCodeLine(node);
    _writeln('EmptyFunctionBody');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitEnumConstantArguments(EnumConstantArguments node) {
    if (withCheckingLinking) {
      _checkChildrenEntitiesLinking(node);
    }
    _writeln('EnumConstantArguments');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _checkChildrenEntitiesLinking(node);
    _writeNextCodeLine(node);
    _writeln('EnumConstantDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('EnumDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _writeNextCodeLine(node);
    _writeln('ExportDirective');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeSource('selectedSource', node.selectedSource);
      _writeRaw('selectedUriContent', node.selectedUriContent);
      _writeRaw('uriContent', node.uriContent);
      _writeElement('uriElement', node.uriElement);
      _writeSource('uriSource', node.uriSource);
    });
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _writeNextCodeLine(node);
    _writeln('ExpressionFunctionBody');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _writeNextCodeLine(node);
    _writeln('ExpressionStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _writeNextCodeLine(node);
    _writeln('ExtendsClause');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('FieldDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _writeNextCodeLine(node);
    _writeln('FieldFormalParameter');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
        _writeType('declaredElementType', node.declaredElement!.type);
      }
    });
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('ForEachPartsWithDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('ForEachPartsWithIdentifier');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _writeNextCodeLine(node);
    _writeln('FormalParameterList');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _writeNextCodeLine(node);
    _writeln('ForPartsWithDeclarations');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _writeNextCodeLine(node);
    _writeln('ForPartsWithExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitForStatement(ForStatement node) {
    _writeNextCodeLine(node);
    _writeln('ForStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('FunctionDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
        _writeType('declaredElementType', node.declaredElement!.type);
      }
    });
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _writeNextCodeLine(node);
    _writeln('FunctionDeclarationStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _writeNextCodeLine(node);
    _writeln('FunctionExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _writeNextCodeLine(node);
    _writeln('FunctionExpressionInvocation');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeType('staticInvokeType', node.staticInvokeType);
      _writeType('staticType', node.staticType);
      _writeTypeList('typeArgumentTypes', node.typeArgumentTypes);
    });
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _writeln('FunctionReference');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
      _writeTypeList('typeArgumentTypes', node.typeArgumentTypes);
    });
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _writeNextCodeLine(node);
    _writeln('FunctionTypeAlias');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _writeNextCodeLine(node);
    _writeln('FunctionTypedFormalParameter');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
        _writeType('declaredElementType', node.declaredElement!.type);
      }
    });
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    _writeNextCodeLine(node);
    _writeln('GenericFunctionType');
    _withIndent(() {
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
    _writeNextCodeLine(node);
    _writeln('GenericTypeAlias');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _writeNextCodeLine(node);
    _writeln('HideCombinator');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitIfElement(IfElement node) {
    _writeln('IfElement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitIfStatement(IfStatement node) {
    _writeNextCodeLine(node);
    _writeln('IfStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _writeNextCodeLine(node);
    _writeln('ImplementsClause');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    _writeln('ImplicitCallReference');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
      _writeTypeList('typeArgumentTypes', node.typeArgumentTypes);
    });
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _writeNextCodeLine(node);
    _writeln('ImportDirective');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeSource('selectedSource', node.selectedSource);
      _writeRaw('selectedUriContent', node.selectedUriContent);
      _writeRaw('uriContent', node.uriContent);
      _writeElement('uriElement', node.uriElement);
      _writeSource('uriSource', node.uriSource);
    });
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _writeNextCodeLine(node);
    _writeln('IndexExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
      _writeElement('staticElement', node.staticElement);
    });
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _writeNextCodeLine(node);
    _writeln('InstanceCreationExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _writeNextCodeLine(node);
    _writeln('IntegerLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _writeNextCodeLine(node);
    _writeln('InterpolationExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _writeNextCodeLine(node);
    _writeln('InterpolationString');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitIsExpression(IsExpression node) {
    _writeNextCodeLine(node);
    _writeln('IsExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitLabel(Label node) {
    _writeNextCodeLine(node);
    _writeln('Label');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _writeNextCodeLine(node);
    _writeln('LibraryDirective');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
    });
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('LibraryIdentifier');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _writeNextCodeLine(node);
    _writeln('ListLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _writeNextCodeLine(node);
    _writeln('SetOrMapLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('MethodDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
        _writeType('declaredElementType', node.declaredElement!.type);
      }
    });
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _writeNextCodeLine(node);
    _writeln('MethodInvocation');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticInvokeType', node.staticInvokeType);
      _writeType('staticType', node.staticType);
      _writeTypeList('typeArgumentTypes', node.typeArgumentTypes);
    });
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('MixinDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _writeNextCodeLine(node);
    _writeln('NamedExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitNamedType(NamedType node) {
    _writeNextCodeLine(node);
    _writeln('NamedType');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('type', node.type);
    });
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _writeNextCodeLine(node);
    _writeln('NullLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitOnClause(OnClause node) {
    _writeNextCodeLine(node);
    _writeln('OnClause');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _writeNextCodeLine(node);
    _writeln('ParenthesizedExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitPartDirective(PartDirective node) {
    _writeNextCodeLine(node);
    _writeln('PartDirective');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
      _writeRaw('uriContent', node.uriContent);
      _writeElement('uriElement', node.uriElement);
      _writeSource('uriSource', node.uriSource);
    });
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _writeNextCodeLine(node);
    _writeln('PartOfDirective');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('element', node.element);
    });
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _writeNextCodeLine(node);
    _writeln('PostfixExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (node.operator.type.isIncrementOperator) {
        _writeElement('readElement', node.readElement);
        _writeType('readType', node.readType);
        _writeElement('writeElement', node.writeElement);
        _writeType('writeType', node.writeType);
      }
      _writeElement('staticElement', node.staticElement);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('PrefixedIdentifier');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _writeNextCodeLine(node);
    _writeln('PrefixExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (node.operator.type.isIncrementOperator) {
        _writeElement('readElement', node.readElement);
        _writeType('readType', node.readType);
        _writeElement('writeElement', node.writeElement);
        _writeType('writeType', node.writeType);
      }
      _writeElement('staticElement', node.staticElement);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _writeNextCodeLine(node);
    _writeln('PropertyAccess');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _writeNextCodeLine(node);
    _writeln('RedirectingConstructorInvocation');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
    });
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _writeNextCodeLine(node);
    _writeln('ReturnStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _writeNextCodeLine(node);
    _writeln('SetOrMapLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeRaw('isMap', node.isMap);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _writeNextCodeLine(node);
    _writeln('ShowCombinator');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _writeNextCodeLine(node);
    _writeln('SimpleFormalParameter');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
        _writeType('declaredElementType', node.declaredElement!.type);
      }
    });
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _writeNextCodeLine(node);
    _writeln('SimpleIdentifier');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
      _writeType('staticType', node.staticType);
      _writeTypeList(
        'tearOffTypeArgumentTypes',
        node.tearOffTypeArgumentTypes,
      );
    });
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _writeNextCodeLine(node);
    _writeln('SimpleStringLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _writeln('SpreadElement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _writeNextCodeLine(node);
    _writeln('StringInterpolation');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
      _writeRaw('stringValue', node.stringValue);
    });
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writeNextCodeLine(node);
    _writeln('SuperConstructorInvocation');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeElement('staticElement', node.staticElement);
    });
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _writeNextCodeLine(node);
    _writeln('SuperExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    if (withCheckingLinking) {
      _checkChildrenEntitiesLinking(node);
    }
    _writeNextCodeLine(node);
    _writeln('SuperFormalParameter');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
        _writeType('declaredElementType', node.declaredElement!.type);
      }
    });
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _writeNextCodeLine(node);
    _writeln('SwitchCase');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _writeNextCodeLine(node);
    _writeln('SwitchDefault');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _writeNextCodeLine(node);
    _writeln('SwitchStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _writeln('SymbolLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _writeNextCodeLine(node);
    _writeln('ThisExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _writeNextCodeLine(node);
    _writeln('ThrowExpression');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('TopLevelVariableDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitTryStatement(TryStatement node) {
    _writeNextCodeLine(node);
    _writeln('TryStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _writeNextCodeLine(node);
    _writeln('TypeArgumentList');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _writeln('TypeLiteral');
    _withIndent(() {
      _writeNamedChildEntities(node);
      _writeType('staticType', node.staticType);
    });
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _writeNextCodeLine(node);
    _writeln('TypeParameter');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _writeNextCodeLine(node);
    _writeln('TypeParameterList');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _writeNextCodeLine(node);
    _writeln('VariableDeclaration');
    _withIndent(() {
      _writeNamedChildEntities(node);
      if (_withResolution) {
        _writeElement('declaredElement', node.declaredElement);
      }
    });
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _writeNextCodeLine(node);
    _writeln('VariableDeclarationList');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _writeNextCodeLine(node);
    _writeln('VariableDeclarationStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _writeNextCodeLine(node);
    _writeln('WhileStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitWithClause(WithClause node) {
    _writeNextCodeLine(node);
    _writeln('WithClause');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _writeNextCodeLine(node);
    _writeln('YieldStatement');
    _withIndent(() {
      _writeNamedChildEntities(node);
    });
  }

  void writeElement(String name, Element? element) {
    _writeElement(name, element);
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

  String _referenceToString(Reference reference) {
    var parent = reference.parent!;
    if (parent.parent == null) {
      var libraryUriStr = reference.name;
      if (libraryUriStr == _selfUriStr) {
        return 'self';
      }

      // TODO(scheglov) Make it precise again, after Windows.
      if (libraryUriStr.startsWith('file:')) {
        return libraryUriStr.substring(libraryUriStr.lastIndexOf('/') + 1);
      }

      return libraryUriStr;
    }

    // Ignore the unit, skip to the library.
    if (parent.name == '@unit') {
      return _referenceToString(parent.parent!);
    }

    var name = reference.name;
    if (name.isEmpty) {
      name = '•';
    }
    return _referenceToString(parent) + '::$name';
  }

  String _substitutionMapStr(Map<TypeParameterElement, DartType> map) {
    var entriesStr = map.entries.map((entry) {
      return '${entry.key.name}: ${_typeStr(entry.value)}';
    }).join(', ');
    return '{$entriesStr}';
  }

  /// TODO(scheglov) Make [type] non-nullable?
  String? _typeStr(DartType? type) {
    return type?.getDisplayString(withNullability: true);
  }

  void _withIndent(void Function() f) {
    var indent = _indent;
    _indent = '$_indent  ';
    f();
    _indent = indent;
  }

  void _writeElement(String name, Element? element) {
    if (_withResolution) {
      _sink.write(_indent);
      _sink.write('$name: ');
      _writeElement0(element);
    }
  }

  void _writeElement0(Element? element) {
    if (element == null) {
      _sink.writeln('<null>');
      return;
    } else if (element is Member) {
      _sink.writeln(_nameOfMemberClass(element));
      _withIndent(() {
        _writeElement('base', element.declaration);
        var map = element.substitution.map;
        var mapStr = _substitutionMapStr(map);
        _writelnWithIndent('substitution: $mapStr');
      });
    } else if (element is MultiplyDefinedElement) {
      _sink.writeln('<null>');
    } else {
      var reference = (element as ElementImpl).reference;
      if (reference != null) {
        var referenceStr = _referenceToString(reference);
        _sink.writeln(referenceStr);
      } else {
        _sink.writeln('${element.name}@${element.nameOffset}');
      }
    }
  }

  void _writeGenericFunctionTypeElement(
    String name,
    GenericFunctionTypeElement? element,
  ) {
    _sink.write(_indent);
    _sink.write('$name: ');
    if (element == null) {
      _sink.writeln('<null>');
    } else {
      _withIndent(() {
        _sink.writeln('GenericFunctionTypeElement');
        _writeParameterElements(element.parameters);
        _writeType('returnType', element.returnType);
        _writeType('type', element.type);
      });
    }
  }

  void _writeln(String line) {
    _sink.writeln(line);
  }

  void _writelnWithIndent(String line) {
    _sink.write(_indent);
    _sink.writeln(line);
  }

  void _writeNamedChildEntities(AstNode node) {
    node as AstNodeImpl;
    for (var entity in node.namedChildEntities) {
      var value = entity.value;
      if (value is Token) {
        _writeToken(entity.name, value);
      } else if (value is AstNode) {
        _writeNode(entity.name, value);
      } else if (value is List<Token>) {
        _writeTokenList(entity.name, value);
      } else if (value is List<AstNode>) {
        _writeNodeList(entity.name, value);
      } else {
        throw UnimplementedError('(${value.runtimeType}) $value');
      }
    }
  }

  void _writeNextCodeLine(AstNode node) {
    var nextCodeLine = _codeLinesProvider?.nextLine(node.offset);
    if (nextCodeLine != null) {
      nextCodeLine = nextCodeLine.trim();
      _sink.writeln('// $nextCodeLine');
      _sink.write(_indent);
    }
  }

  void _writeNode(String name, AstNode? node) {
    if (node != null) {
      _sink.write(_indent);
      _sink.write('$name: ');
      node.accept(this);
    }
  }

  void _writeNodeList(String name, List<AstNode> nodeList) {
    if (nodeList.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var node in nodeList) {
          _sink.write(_indent);
          node.accept(this);
        }
      });
    }
  }

  void _writeOffset(String name, int offset) {
    _writelnWithIndent('$name: $offset');
  }

  void _writeParameterElements(List<ParameterElement> parameters) {
    _writelnWithIndent('parameters');
    _withIndent(() {
      for (var parameter in parameters) {
        _writelnWithIndent(parameter.name);
        _withIndent(() {
          _writeParameterKind(parameter);
          _writeType('type', parameter.type);
        });
      }
    });
  }

  void _writeParameterKind(ParameterElement parameter) {
    if (parameter.isOptionalNamed) {
      _writelnWithIndent('kind: optional named');
    } else if (parameter.isOptionalPositional) {
      _writelnWithIndent('kind: optional positional');
    } else if (parameter.isRequiredNamed) {
      _writelnWithIndent('kind: required named');
    } else if (parameter.isRequiredPositional) {
      _writelnWithIndent('kind: required positional');
    } else {
      throw StateError('Unknown kind: $parameter');
    }
  }

  void _writeRaw(String name, Object? value) {
    _writelnWithIndent('$name: $value');
  }

  void _writeSource(String name, Source? source) {
    if (source != null) {
      _writelnWithIndent('$name: ${source.uri}');
    } else {
      _writelnWithIndent('$name: <null>');
    }
  }

  void _writeToken(String name, Token? token) {
    if (token != null) {
      _sink.write(_indent);
      _sink.write('$name: ');
      _sink.write(token.lexeme.isNotEmpty ? token : '<empty>');
      if (_withOffsets) {
        _sink.write(' @${token.offset}');
      }
      if (token.isSynthetic) {
        _sink.write(' <synthetic>');
      }
      _sink.writeln();
    }
  }

  /// TODO(scheglov) maybe inline?
  void _writeTokenList(String name, List<Token> tokens) {
    if (tokens.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var token in tokens) {
          _writelnWithIndent('$name: $token');
          _withIndent(() {
            _writeOffset('offset', token.offset);
          });
        }
      });
    }
  }

  void _writeType(String name, DartType? type) {
    if (_withResolution) {
      var typeStr = _typeStr(type);
      _writelnWithIndent('$name: $typeStr');
    }
  }

  void _writeTypeList(String name, List<DartType>? types) {
    if (types != null && types.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var type in types) {
          var typeStr = _typeStr(type);
          _writelnWithIndent('$typeStr');
        }
      });
    }
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

  static String _nameOfMemberClass(Member member) {
    return '${member.runtimeType}';
  }
}
