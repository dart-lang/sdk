import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';

class AsyncReturnVisitor extends SimpleAstVisitor2<void> {
  final Diagnostic? Function(Token token) _reportAtToken;
  final TypeSystem _typeSystem;
  final TypeProvider _typeProvider;
  final bool _withinTryBlock;

  AsyncReturnVisitor({
    required Diagnostic? Function(Token token) reportAtToken,
    required TypeSystem typeSystem,
    required TypeProvider typeProvider,
    bool withinTryBlock = false,
  }) : _withinTryBlock = withinTryBlock,
       _typeProvider = typeProvider,
       _typeSystem = typeSystem,
       _reportAtToken = reportAtToken;

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (_withinTryBlock) return;
    var expression = node.expression;
    var expressionType = expression.staticType ?? DynamicTypeImpl.instance;
    var body = node.withAncestors.whereType<FunctionBody>().firstOrNull;
    _report(body, expressionType, node.functionDefinition);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    var expression = node.expression;
    if (expression == null) return;
    if (_withinTryBlock != node.isWithinTryBlock) return;
    var expressionType = expression.staticType ?? DynamicTypeImpl.instance;
    var body = node.withAncestors.whereType<FunctionBody>().firstOrNull;
    _report(body, expressionType, node.returnKeyword);
  }

  void _report(FunctionBody? body, DartType expressionType, Token reportAt) {
    if (body == null) return;
    if (expressionType == DynamicTypeImpl.instance ||
        expressionType == InvalidTypeImpl.instance) {
      return;
    }
    if (expressionType.asInstanceOf(_typeProvider.futureElement) == null &&
        expressionType.asInstanceOf(_typeProvider.futureOrElement) == null) {
      return;
    }
    if (body.isGenerator) {
      return;
    }
    if (body.isAsynchronous) {
      var returnType = body.returnType;
      if (returnType == null) return;
      if (_typeSystem.isAssignableTo(
        expressionType,
        _typeProvider.futureOrType(_typeSystem.futureValueType(returnType)),
      )) {
        _reportAtToken(reportAt);
      }
    }
  }
}

extension on ReturnStatement {
  bool get isWithinTryBlock {
    for (var ancestor in withAncestors) {
      if (ancestor case Block(:var parent)) {
        if (parent is BlockFunctionBody) {
          return false;
        }
        if (parent case TryStatement(:var body) when body == ancestor) {
          return true;
        }
      }
    }
    return false;
  }
}

extension on FunctionBody {
  DartType? get returnType => switch (parent) {
    MethodDeclaration(:var declaredFragment) ||
    FunctionDeclaration(:var declaredFragment) ||
    FunctionExpression(
      :var declaredFragment,
    ) => declaredFragment?.element.returnType,
    _ => null,
  };
}
