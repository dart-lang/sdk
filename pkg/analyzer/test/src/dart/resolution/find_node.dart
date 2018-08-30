import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:test/test.dart';

class FindNode {
  final String content;
  final CompilationUnit unit;

  FindNode(this.content, this.unit);

  LibraryDirective get libraryDirective {
    return unit.directives.singleWhere((d) => d is LibraryDirective);
  }

  AssignmentExpression assignment(String search) {
    return _node(search).getAncestor((n) => n is AssignmentExpression);
  }

  CascadeExpression cascade(String search) {
    return _node(search).getAncestor((n) => n is CascadeExpression);
  }

  ExportDirective export(String search) {
    return _node(search).getAncestor((n) => n is ExportDirective);
  }

  FunctionExpression functionExpression(String search) {
    return _node(search).getAncestor((n) => n is FunctionExpression);
  }

  GenericFunctionType genericFunctionType(String search) {
    return _node(search).getAncestor((n) => n is GenericFunctionType);
  }

  ImportDirective import(String search) {
    return _node(search).getAncestor((n) => n is ImportDirective);
  }

  InstanceCreationExpression instanceCreation(String search) {
    return _node(search).getAncestor((n) => n is InstanceCreationExpression);
  }

  ListLiteral listLiteral(String search) {
    return _node(search).getAncestor((n) => n is ListLiteral);
  }

  MapLiteral mapLiteral(String search) {
    return _node(search).getAncestor((n) => n is MapLiteral);
  }

  MethodInvocation methodInvocation(String search) {
    return _node(search).getAncestor((n) => n is MethodInvocation);
  }

  ParenthesizedExpression parenthesized(String search) {
    return _node(search).getAncestor((n) => n is ParenthesizedExpression);
  }

  PartDirective part(String search) {
    return _node(search).getAncestor((n) => n is PartDirective);
  }

  PartOfDirective partOf(String search) {
    return _node(search).getAncestor((n) => n is PartOfDirective);
  }

  PostfixExpression postfix(String search) {
    return _node(search).getAncestor((n) => n is PostfixExpression);
  }

  PrefixExpression prefix(String search) {
    return _node(search).getAncestor((n) => n is PrefixExpression);
  }

  PrefixedIdentifier prefixed(String search) {
    return _node(search).getAncestor((n) => n is PrefixedIdentifier);
  }

  RethrowExpression rethrow_(String search) {
    return _node(search).getAncestor((n) => n is RethrowExpression);
  }

  SimpleIdentifier simple(String search) {
    return _node(search);
  }

  SimpleFormalParameter simpleParameter(String search) {
    return _node(search).getAncestor((n) => n is SimpleFormalParameter);
  }

  StringLiteral stringLiteral(String search) {
    return _node(search).getAncestor((n) => n is StringLiteral);
  }

  SuperExpression super_(String search) {
    return _node(search).getAncestor((n) => n is SuperExpression);
  }

  ThisExpression this_(String search) {
    return _node(search).getAncestor((n) => n is ThisExpression);
  }

  ThrowExpression throw_(String search) {
    return _node(search).getAncestor((n) => n is ThrowExpression);
  }

  TypeName typeName(String search) {
    return _node(search).getAncestor((n) => n is TypeName);
  }

  TypeParameter typeParameter(String search) {
    return _node(search).getAncestor((n) => n is TypeParameter);
  }

  VariableDeclaration variableDeclaration(String search) {
    return _node(search).getAncestor((n) => n is VariableDeclaration);
  }

  AstNode _node(String search) {
    var index = content.indexOf(search);
    if (content.indexOf(search, index + 1) != -1) {
      fail('The pattern |$search| is not unique in:\n$content');
    }
    expect(index, greaterThanOrEqualTo(0));
    return new NodeLocator2(index).searchWithin(unit);
  }
}
