library dart_codegen;

import 'dart_tree.dart' as tree;
import 'dart_printer.dart';
import 'dart_tree_printer.dart' show TreePrinter;
import '../tree/tree.dart' as frontend;
import '../dart2jslib.dart' as dart2js;
import '../elements/elements.dart';
import '../dart_types.dart';
import '../elements/modelx.dart' as modelx;

/// Translates the dart_tree IR to Dart frontend AST.
frontend.FunctionExpression emit(FunctionElement element,
                                 dart2js.TreeElementMapping treeElements,
                                 tree.FunctionDefinition definition) {
  FunctionExpression fn = new ASTEmitter().emit(element, definition);
  return new TreePrinter(treeElements).makeExpression(fn);
}

/// Translates the dart_tree IR to Dart backend AST.
class ASTEmitter extends tree.Visitor<dynamic, Expression> {
  /// Variables to be hoisted at the top of the current function.
  List<VariableDeclaration> variables;
  
  /// Statements emitted by the most recent call to [visitStatement].
  List<Statement> statementBuffer;
  
  /// The function currently being emitted.
  FunctionElement functionElement;
  
  FunctionExpression emit(FunctionElement element,
                          tree.FunctionDefinition definition) {
    functionElement = element;
    variables = <VariableDeclaration>[];
    statementBuffer = <Statement>[];
    tree.Variable.counter = 0;
    
    Parameters parameters = emitParameters(definition.parameters);
    visitStatement(definition.body);
    removeTrailingReturn();
    Statement body = new Block(statementBuffer);
    if (variables.length > 0) {
      Statement head = new VariableDeclarations(variables);
      body = new Block([head, body]);
    }
    
    FunctionType functionType = element.type;
    
    variables = null;
    statementBuffer = null;
    functionElement = null;
    
    return new FunctionExpression(
        parameters, 
        body,
        name: element.name,
        returnType: emitOptionalType(functionType.returnType))
        ..element = element;
  }
  
  /// Removes a trailing "return null" from [statementBuffer].
  void removeTrailingReturn() {
    if (statementBuffer.isEmpty) return;
    if (statementBuffer.last is! Return) return;
    Return ret = statementBuffer.last;
    Expression expr = ret.expression;
    if (expr is Literal && expr.value is dart2js.NullConstant) {
      statementBuffer.removeLast();
    }
  }
  
  Parameter emitParameter(tree.Variable param) {
    ParameterElement element = param.element;
    TypeAnnotation type = emitOptionalType(element.type);
    return new Parameter(element.name, type:type)
               ..element = element;
  }
  
  Parameters emitParameters(List<tree.Variable> params) {
    return new Parameters(params.map(emitParameter).toList(growable:false));
  }
  
  void visitExpressionStatement(tree.ExpressionStatement stmt) {
    Expression e = visitExpression(stmt.expression);
    statementBuffer.add(new ExpressionStatement(e));
    visitStatement(stmt.next);
  }
  
  void visitLetVal(tree.LetVal stmt) {
    // Synthesize an element for the variable, if necessary.
    if (stmt.variable.element == null) {
      stmt.variable.element = new modelx.VariableElementX.synthetic(
          stmt.variable.name,
          ElementKind.VARIABLE,
          functionElement);
    }
    variables.add(new VariableDeclaration(stmt.variable.name));
    Expression def = visitExpression(stmt.definition);
    statementBuffer.add(new ExpressionStatement(new Assignment(
        visitVariable(stmt.variable), 
        '=', 
        def)));
    visitStatement(stmt.body);
  }
  
  void visitReturn(tree.Return stmt) {
    Expression inner = visitExpression(stmt.value);
    statementBuffer.add(new Return(inner));
  }
  
  Expression visitConstant(tree.Constant exp) {
    return emitConstant(exp.value);
  }
  
  Expression visitInvokeStatic(tree.InvokeStatic exp) {
    List args = exp.arguments.map(visitExpression).toList(growable:false);
    return new CallStatic(null, exp.target.name, args)
               ..element = exp.target;
  }
  
  Expression visitVariable(tree.Variable exp) {
    return new Identifier(exp.name)
               ..element = exp.element;
  }
  
  TypeAnnotation emitType(DartType type) {
    if (type is GenericType) { // TODO(asgerf): faster Link.map
      return new TypeAnnotation(
          type.element.name, 
          type.typeArguments.toList(growable:false) 
              .map(emitType).toList(growable:false))
          ..dartType = type;
    } else if (type is VoidType) {
      return new TypeAnnotation('void')
          ..dartType = type;
    } else if (type is TypeVariableType) {
      return new TypeAnnotation(type.name)
          ..dartType = type;
    } else {
      throw "Unsupported type annotation: ${type.runtimeType}";
    }
  }
  
  /// Like [emitType] except the dynamic type is converted to null.
  TypeAnnotation emitOptionalType(DartType type) {
    if (type.isDynamic) {
      return null;
    } else {
      return emitType(type);
    }
  }
  
  Expression emitConstant(dart2js.Constant constant) {
    if (constant is dart2js.PrimitiveConstant) {
      return new Literal(constant);
    } else if (constant is dart2js.ListConstant) {
      return new LiteralList(constant.entries.map(emitConstant), isConst: true);
    } else if (constant is dart2js.MapConstant) {
      List<LiteralMapEntry> entries = <LiteralMapEntry>[];
      for (var i = 0; i < constant.keys.length; i++) {
        entries.add(new LiteralMapEntry(
            emitConstant(constant.keys.entries[i]), 
            emitConstant(constant.values[i])));
      }
      return new LiteralMap(entries, isConst: true);
    } else {
      throw "Unsupported constant: ${constant.runtimeType}";
    }
  }
}

