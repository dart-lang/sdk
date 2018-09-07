import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// [RecursiveAstVisitor] that delegates visit methods to functions.
class FunctionAstVisitor extends RecursiveAstVisitor<void> {
  final void Function(SimpleIdentifier) simpleIdentifier;
  final void Function(VariableDeclaration) variableDeclaration;

  FunctionAstVisitor({this.simpleIdentifier, this.variableDeclaration});

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (simpleIdentifier != null) {
      simpleIdentifier(node);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (variableDeclaration != null) {
      variableDeclaration(node);
    }
    super.visitVariableDeclaration(node);
  }
}
