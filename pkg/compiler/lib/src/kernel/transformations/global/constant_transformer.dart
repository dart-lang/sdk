import 'package:front_end/src/api_unstable/dart2js.dart'
    show TryConstantEvaluator;
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import '../../../options.dart';

class ConstantTransformer extends Transformer {
  final TryConstantEvaluator constantEvaluator;
  late StaticTypeContext _staticTypeContext;

  final CompilerOptions _options;

  ConstantTransformer(this.constantEvaluator, this._options);

  Constant _evaluate(Expression node) =>
      constantEvaluator.evaluate(_staticTypeContext, node);

  Constant? _evaluateOrNull(Expression node) => constantEvaluator
      .evaluateOrNull(_staticTypeContext, node, requireConstant: false);

  ConstantExpression _evaluateAndWrap(Expression node) {
    return ConstantExpression(
        _evaluate(node), node.getStaticType(_staticTypeContext))
      ..fileOffset = node.fileOffset;
  }

  Expression _evaluateAndWrapOrNode(Expression node) {
    final constantOrNull = _evaluateOrNull(node);
    if (constantOrNull == null) return node;
    return ConstantExpression(
        constantOrNull, node.getStaticType(_staticTypeContext))
      ..fileOffset = node.fileOffset;
  }

  bool _isConstant(Expression node) => node is ConstantExpression;
  bool _isConstantArguments(Arguments arguments) =>
      arguments.positional.every(_isConstant) &&
      arguments.named.every((e) => _isConstant(e.value));

  @override
  TreeNode visitLibrary(Library node) {
    _staticTypeContext = StaticTypeContext.forAnnotations(
        node, constantEvaluator.typeEnvironment);
    node.transformChildren(this);
    return node;
  }

  @override
  TreeNode defaultMember(Member node) {
    _setupTypeContextForMember(node);
    node.transformChildren(this);
    return node;
  }

  void _setupTypeContextForMember(Member node) {
    _staticTypeContext =
        StaticTypeContext(node, constantEvaluator.typeEnvironment);
  }

  @override
  TreeNode visitFieldInitializer(FieldInitializer node) {
    node.transformChildren(this);
    final newInitializer = _evaluateAndWrapOrNode(node.value);
    if (_isConstant(newInitializer)) {
      node.value = newInitializer;
      newInitializer.parent = node;
    } else if (newInitializer is VariableGet) {
      VariableDeclaration parameter = newInitializer.variable;
      final parameterInitializer = parameter.initializer;
      if (parameterInitializer != null) {
        Expression newParameterInitializer =
            _evaluateAndWrapOrNode(parameterInitializer);

        newParameterInitializer.parent = parameter;
        parameter.initializer = newParameterInitializer;
      }
    }
    return node;
  }

  @override
  TreeNode visitField(Field node) {
    _setupTypeContextForMember(node);
    node.transformChildren(this);
    final initializer = node.initializer;
    if (initializer != null) {
      node.initializer = _evaluateAndWrapOrNode(initializer)..parent = node;
    }
    return node;
  }

  @override
  TreeNode visitSwitchCase(SwitchCase node) {
    node.transformChildren(this);
    for (int i = 0; i < node.expressions.length; i++) {
      node.expressions[i] = _evaluateAndWrap(node.expressions[i])
        ..parent = node;
    }
    return node;
  }

  @override
  TreeNode visitConstantExpression(ConstantExpression node) {
    return _evaluateAndWrap(node);
  }

  @override
  TreeNode visitIsExpression(IsExpression node) {
    node.transformChildren(this);
    if (!_options.experimentNullSafetyChecks && _isConstant(node.operand)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitAsExpression(AsExpression node) {
    node.transformChildren(this);
    if (!_options.experimentNullSafetyChecks && _isConstant(node.operand)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitNullCheck(NullCheck node) {
    node.transformChildren(this);
    if (_isConstant(node.operand)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitTypeLiteral(TypeLiteral node) => _evaluateAndWrapOrNode(node);

  @override
  TreeNode visitRecordLiteral(RecordLiteral node) {
    node.transformChildren(this);
    if (node.positional.every(_isConstant) &&
        node.named.every((e) => _isConstant(e.value))) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitNullLiteral(NullLiteral node) => _evaluateAndWrap(node);

  @override
  TreeNode visitStringLiteral(StringLiteral node) => _evaluateAndWrap(node);

  @override
  TreeNode visitIntLiteral(IntLiteral node) => _evaluateAndWrap(node);

  @override
  TreeNode visitDoubleLiteral(DoubleLiteral node) => _evaluateAndWrap(node);

  @override
  TreeNode visitSymbolLiteral(SymbolLiteral node) => _evaluateAndWrap(node);

  @override
  TreeNode visitBoolLiteral(BoolLiteral node) => _evaluateAndWrap(node);

  @override
  TreeNode visitStringConcatenation(StringConcatenation node) {
    node.transformChildren(this);
    if (node.expressions.every(_isConstant)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitStaticGet(StaticGet node) {
    node.transformChildren(this);
    final target = node.target;
    if (target is Procedure && target.kind == ProcedureKind.Method) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitStaticTearOff(StaticTearOff node) {
    node.transformChildren(this);
    return _evaluateAndWrapOrNode(node);
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    if (_isConstantArguments(node.arguments) &&
        node.target == constantEvaluator.coreTypes.identicalProcedure) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitConditionalExpression(ConditionalExpression node) {
    node.transformChildren(this);
    if (_isConstant(node.condition) &&
        _isConstant(node.then) &&
        _isConstant(node.otherwise)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitInstanceInvocation(InstanceInvocation node) {
    node.transformChildren(this);
    final interfaceTarget = node.interfaceTarget;
    if (_isConstantArguments(node.arguments) &&
        _isConstant(node.receiver) &&
        interfaceTarget.kind == ProcedureKind.Operator) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitEqualsNull(EqualsNull node) {
    node.transformChildren(this);
    if (_isConstant(node.expression)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitEqualsCall(EqualsCall node) {
    node.transformChildren(this);
    if (_isConstant(node.left) && _isConstant(node.right)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitInstanceGet(InstanceGet node) {
    node.transformChildren(this);
    if (_isConstant(node.receiver) && node.name.text == 'length') {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitDynamicGet(DynamicGet node) {
    node.transformChildren(this);
    if (_isConstant(node.receiver) && node.name.text == 'length') {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitNot(Not node) {
    node.transformChildren(this);
    if (_isConstant(node.operand)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitLogicalExpression(LogicalExpression node) {
    node.transformChildren(this);
    if (_isConstant(node.left) && _isConstant(node.right)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }

  @override
  TreeNode visitInstantiation(Instantiation node) {
    node.transformChildren(this);
    if (_isConstant(node.expression)) {
      return _evaluateAndWrapOrNode(node);
    }
    return node;
  }
}
