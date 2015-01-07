library ddc.src.codegen.reify_coercions;

import 'dart:collection';

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:logging/logging.dart' as logger;

import 'package:ddc/src/info.dart';

import 'ast_builder.dart';

final _log = new logger.Logger('ddc.reify_coercions');

// This class implements a pass which modifies (in place) the ast replacing
// abstract coercion nodes with their dart implementations.
class UnitCoercionReifier extends analyzer.GeneralizingAstVisitor<Object>
    with ConversionVisitor<Object> {
  CoercionManager _cm;
  VariableManager _vm;

  UnitCoercionReifier(this._vm) {
    _cm = new CoercionManager(_vm);
  }

  // This should be the entry point for this class.  Entering via the
  // visit functions directly may not do the right thing with respect
  // to discharging the collected definitions.
  void reify(CompilationUnit unit) {
    visitCompilationUnit(unit);
  }

  ///////////////// Private //////////////////////////////////

  @override
  Object visitDownCast(DownCast node) {
    Expression castNode = _cm.coerceExpression(node.node, node.cast);
    if (!NodeReplacer.replace(node, castNode)) {
      _log.severe("Failed to replace node for DownCast");
    }
    castNode.accept(this);
    return null;
  }

  // TODO(leafp): Bind the coercions at the top level
  @override
  Object visitClosureWrap(ClosureWrap node) {
    Expression newE = _cm.coerceExpression(node.node, node.wrapper);
    if (!NodeReplacer.replace(node, newE)) {
      _log.severe("Failed to replace node for Closure Wrap");
    }
    newE.accept(this);
    return null;
  }

  @override
  Object visitCompilationUnit(CompilationUnit unit) {
    _cm.enterCompilationUnit();
    Object ret = super.visitCompilationUnit(unit);
    _cm.exitCompilationUnit(unit);
    return ret;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration cl) {
    _cm.enterClass();
    Object ret = super.visitClassDeclaration(cl);
    _cm.exitClass(cl);
    return ret;
  }
}

// This provides a placeholder variable manager.  Currently it simply
// mangles names in a way unlikely (but not guaranteed) to avoid
// collisions with user variables.
// TODO(leafp): Replace this with something real.
class VariableManager {
  // FIXME(leafp): Hack, not for real.
  int _id = 0;

  Identifier freshIdentifier(String hint) {
    String n = _id.toString();
    _id++;
    String s = "__$hint$n";
    return AstBuilder.identifierFromString(s);
  }

  Identifier freshTypeIdentifier(String hint) {
    return freshIdentifier(hint);
  }
}

// This class manages the reification of coercions as dart code.  Given a
// coercion c and an expression e it will produce an expression e' which
// is the result of coercing e using c.  For closure wrappers, it maintains
// a table of wrapper functions to be hoisted out to either the enclosing
// class level, or to the top level if not in a class (hoisting only to the
// class level avoids having to close over type variables, which is not
// easily done given the lack of generic functions).  Generating the coercions
// inline is possible as well, but is quite a bit messier and harder to read
// since in general we need to bind the coerced expression to a lambda
// bound variable, both in order to deal with side-effects and to be
// able to properly record the return type of the wrapper function.
class CoercionManager {
  VariableManager _vm;
  TypeManager _tm;

  // A map containing all of the wrappers collected but not yet discharged
  Map<Identifier, Wrapper> _topWrappers = <Identifier, Wrapper>{};
  Map<Identifier, Wrapper> _classWrappers = <Identifier, Wrapper>{};
  Map<Identifier, Wrapper> _wrappers;

  CoercionManager(this._vm) {
    _tm = new TypeManager(_vm);
    _wrappers = _topWrappers;
  }

  // Call on entry to and exit from a compilation unit in order to properly
  // discharge the accumulated wrappers.
  void enterCompilationUnit() {
    _tm.enterCompilationUnit();
    _wrappers = _topWrappers;
  }
  void exitCompilationUnit(CompilationUnit unit) {
    for (Identifier i in _wrappers.keys) {
      FunctionDeclaration f = _buildCoercion(i, _wrappers[i], true);
      unit.declarations.add(f);
    }
    _wrappers.clear();
    _wrappers = _topWrappers;
    _tm.exitCompilationUnit(unit);
  }

  // Call on entry to and exit from a class in order to properly
  // discharge the accumulated wrappers.
  void enterClass() {
    _wrappers = _classWrappers;
  }
  void exitClass(ClassDeclaration cl) {
    for (Identifier i in _wrappers.keys) {
      ClassMember f = _buildCoercion(i, _wrappers[i], false);
      cl.members.add(f);
    }
    _wrappers.clear();
    _wrappers = _topWrappers;
  }

  // The main entry point.  Coerce e using c, returning a new expression,
  // possibly recording additional coercions functions and typedefs to
  // be discharged at a higher level.
  Expression coerceExpression(Expression e, Coercion c) {
    return _coerceExpression(e, c);
  }

  ///////////////// Private //////////////////////////////////
  Expression _wrapExpression(Expression e, Wrapper w) {
    Identifier q = _addWrapper(w);
    return AstBuilder.application(q, <Expression>[e]);
  }

  Expression _castExpression(Expression e, Cast c) {
    TypeName type = _tm.typeNameFromDartType(c.toType);
    return AstBuilder
        .parenthesize(AstBuilder.asExp(AstBuilder.parenthesize(e), type));
  }

  Expression _coerceExpression(Expression e, Coercion c) {
    assert(c != null);
    assert(c is! CoercionError);
    if (e is NamedExpression) {
      Expression inner = _coerceExpression(e.expression, c);
      return new NamedExpression(e.name, inner);
    }
    if (c is Cast) return _castExpression(e, c);
    if (c is Wrapper) return _wrapExpression(e, c);
    assert(c is Identity);
    return e;
  }

  Identifier _addWrapper(Wrapper w) {
    var q = _vm.freshIdentifier("q");
    _wrappers[q] = w;
    return q;
  }

  // Choose a canonical name for the ith coercion parameter
  // with name "name".
  Identifier _coercionParameter(String name, int index) {
    String s = name + index.toString();
    return AstBuilder.identifierFromString(s);
  }

  NormalFormalParameter _coercionToFormal(Coercion c, String name, int index) {
    Identifier v = AstBuilder.identifierFromString(name + index.toString());
    return _tm.typedFormal(v, c.fromType);
  }

  List<FormalParameter> _wrapperFormalParameters(Wrapper wrapper) {
    var namedParameters = wrapper.namedParameters;
    var normalParameters = wrapper.normalParameters;
    var optionalParameters = wrapper.optionalParameters;
    var params = new List<FormalParameter>();
    for (int i = 0; i < normalParameters.length; i++) {
      Identifier x = _coercionParameter("x", i);
      // We use the toType to avoid changing the reified type
      FormalParameter fp = _tm.typedFormal(x, normalParameters[i].toType);
      params.add(AstBuilder.requiredFormal(fp));
    }
    for (int i = 0; i < optionalParameters.length; i++) {
      Identifier y = _coercionParameter("y", i);
      // We use the toType to avoid changing the reified type
      FormalParameter fp = _tm.typedFormal(y, optionalParameters[i].toType);
      params.add(AstBuilder.optionalFormal(fp));
    }
    for (String k in namedParameters.keys) {
      // FIXME(leafp): These could collide with the generated names.
      Identifier z = AstBuilder.identifierFromString(k);
      // We use the toType to avoid changing the reified type
      FormalParameter fp = _tm.typedFormal(z, namedParameters[k].toType);
      params.add(AstBuilder.namedFormal(fp));
    }
    return params;
  }

  List<Expression> _wrapperCoercedArguments(Wrapper wrapper) {
    var namedParameters = wrapper.namedParameters;
    var normalParameters = wrapper.normalParameters;
    var optionalParameters = wrapper.optionalParameters;
    var args = new List<Expression>();
    for (int i = 0; i < normalParameters.length; i++) {
      Identifier x = _coercionParameter("x", i);
      Expression e = _coerceExpression(x, normalParameters[i]);
      args.add(e);
    }
    for (int i = 0; i < optionalParameters.length; i++) {
      Identifier y = _coercionParameter("y", i);
      Expression e = _coerceExpression(y, optionalParameters[i]);
      args.add(e);
    }
    for (String k in namedParameters.keys) {
      // FIXME(leafp): These could collide with the generated names.
      Identifier z = AstBuilder.identifierFromString(k);
      Expression e = _coerceExpression(z, namedParameters[k]);
      args.add(AstBuilder.namedParameter(k, e));
    }
    return args;
  }

  // Given an identifier c, a value f and a coercion q : T0 -> T1 => S0 -> S1
  // wrap f using q and bind it to variable c
  // T1 c(T0 x) => (f(x as T0) as S1)
  // Note that we use the "fromType" to decorate the wrapper
  // rather than the "toType" to avoid changing the reified type
  // FIXME(leafp): If we wrap non-function literals, we can still
  // end up changing the runtime reified type, since we build a function
  // literal based on the static type.
  FunctionDeclarationStatement _wrapperMkInner(
      Identifier c, Expression f, Wrapper wrapper) {
    List<FormalParameter> params = _wrapperFormalParameters(wrapper);
    List<Expression> args = _wrapperCoercedArguments(wrapper);
    Expression app = AstBuilder.application(f, args);
    Expression body = _coerceExpression(app, wrapper.ret);
    FunctionExpression ce = AstBuilder.expressionFunction(params, body, true);
    TypeName rt =
        _tm.typeNameFromDartType((wrapper.fromType as FunctionType).returnType);
    Statement cDec = AstBuilder.functionDeclarationStatement(rt, c, ce);
    return cDec;
  }

  // Given a name g and coercion q : T0 -> T1 => S0 -> S1
  // Bind g to a function or static method which maps
  // T0 -> T1 functions to S0 -> S1 functions.
  // T0 -> T1 g(S1 f(S0)) {
  //   T1 c(T0 x) => (f(x as T0) as S1);
  //   return c;
  // }
  Declaration _buildCoercion(Identifier q, Wrapper wrapper, bool top) {
    var f = AstBuilder.identifierFromString("f");
    var c = AstBuilder.identifierFromString("c");
    var cDec = _wrapperMkInner(c, f, wrapper);
    var stmts = <Statement>[cDec, AstBuilder.returnExp(c)];
    var fp = _tm.typedFormal(f, wrapper.fromType);
    var params = <FormalParameter>[fp];
    TypeName rt = _tm.typeNameFromDartType(wrapper.toType);
    if (top) {
      return AstBuilder.blockFunctionDeclaration(rt, q, params, stmts);
    } else {
      return AstBuilder.blockMethodDeclaration(rt, q, params, stmts);
    }
  }
}

// A class for managing the interaction between the DartType hierarchy
// and the AST type representation.  It provides utilities to translate
// a DartType to AST.  In order to do so, it maintains a map of typedefs
// naming otherwise un-named types.  These must be discharged at the top
// level of the compilation unit in order to produce well-formed dart code.
// Note that in order to hoist the typedefs out of parameterized classes
// we must close over any type variables.
class TypeManager {
  VariableManager _vm;

  // A map containing new function typedefs to be introduced at the top level
  HashMap<FunctionType, FunctionTypeAlias> _typedefs =
      new HashMap<FunctionType, FunctionTypeAlias>();

  TypeManager(this._vm);

  void enterCompilationUnit() {}
  void exitCompilationUnit(CompilationUnit unit) {
    unit.declarations.addAll(_typedefs.values);
    _typedefs.clear();
  }

  TypeName typeNameFromDartType(DartType dType) {
    return _typeNameFromDartType(dType);
  }

  NormalFormalParameter typedFormal(Identifier v, DartType type) {
    return _typedFormal(v, type);
  }

  ///////////////// Private //////////////////////////////////
  List<TypeParameterType> _freeTypeVariables(DartType type) {
    var s = new Set<TypeParameterType>();

    void _ft(DartType type) {
      void _ftMap(Map<String, DartType> m) {
        if (m == null) return;
        for (var k in m.keys) _ft(m[k]);
      }
      void _ftList(List<DartType> l) {
        if (l == null) return;
        for (int i = 0; i < l.length; i++) _ft(l[i]);
      }

      if (type == null) return;
      if (type.isDynamic) return;
      if (type.isBottom) return;
      if (type.isObject) return;
      if (type is TypeParameterType) {
        s.add(type);
        return;
      }
      if (type is ParameterizedType) {
        if (type.name != null && type.name != "") {
          _ftList(type.typeArguments);
          return;
        }
        if (type is FunctionType) {
          _ftMap(type.namedParameterTypes);
          _ftList(type.normalParameterTypes);
          _ftList(type.optionalParameterTypes);
          _ft(type.returnType);
          return;
        }
        assert(type is! InterfaceType);
        assert(false);
      }
      if (type is VoidType) return;
      assert(type is! UnionType);
      print(type.toString());
      assert(false);
    }
    _ft(type);
    return s.toList();
  }

  List<FormalParameter> _formalParameterListForFunctionType(FunctionType type) {
    var namedParameters = type.namedParameterTypes;
    var normalParameters = type.normalParameterTypes;
    var optionalParameters = type.optionalParameterTypes;
    var params = new List<FormalParameter>();
    for (int i = 0; i < normalParameters.length; i++) {
      FormalParameter fp = _anonymousFormal(normalParameters[i]);
      params.add(AstBuilder.requiredFormal(fp));
    }
    for (int i = 0; i < optionalParameters.length; i++) {
      FormalParameter fp = _anonymousFormal(optionalParameters[i]);
      params.add(AstBuilder.optionalFormal(fp));
    }
    for (String k in namedParameters.keys) {
      FormalParameter fp = _anonymousFormal(namedParameters[k]);
      params.add(AstBuilder.namedFormal(fp));
    }
    return params;
  }

  FormalParameter _functionTypedFormal(Identifier v, FunctionType type) {
    assert(v != null);
    var params = _formalParameterListForFunctionType(type);
    var ret = typeNameFromDartType(type.returnType);
    return AstBuilder.functionTypedFormal(ret, v, params);
  }

  NormalFormalParameter _anonymousFormal(DartType type) {
    Identifier u = _vm.freshIdentifier("u");
    return _typedFormal(u, type);
  }

  NormalFormalParameter _typedFormal(Identifier v, DartType type) {
    if (type is FunctionType) {
      return _functionTypedFormal(v, type);
    }
    assert(type.name != null);
    TypeName t = typeNameFromDartType(type);
    return AstBuilder.simpleFormal(v, t);
  }

  // I think we can avoid alpha-varying type parameters, since
  // the binding forms are so limited, so we just re-use the
  // the original names for the formals and the actuals.
  TypeName _typeNameFromFunctionType(FunctionType type) {
    if (_typedefs.containsKey(type)) {
      var alias = _typedefs[type];
      var ts = null;
      var tpl = alias.typeParameters;
      if (tpl != null) {
        var ltp = tpl.typeParameters;
        var ts = ltp.map((t) => AstBuilder.typeName(t.name, null));
      }
      var name = alias.name;
      return AstBuilder.typeName(name, ts);
    }

    List<TypeParameterType> ftvs = _freeTypeVariables(type);
    Identifier t = _vm.freshTypeIdentifier("t");

    Iterable<Identifier> tNames =
        ftvs.map((x) => AstBuilder.identifierFromString(x.name));
    List<TypeParameter> tps = tNames.map(AstBuilder.typeParameter).toList();
    List<FormalParameter> fps = _formalParameterListForFunctionType(type);
    TypeName ret = _typeNameFromDartType(type.returnType);
    FunctionTypeAlias alias = AstBuilder.functionTypeAlias(ret, t, tps, fps);

    _typedefs[type] = alias;

    List<TypeName> args = ftvs.map(_typeNameFromDartType).toList();
    TypeName namedType = AstBuilder.typeName(t, args);

    return namedType;
  }

  TypeName _typeNameFromDartType(DartType dType) {
    String name = dType.name;
    if (name == null || name == "") {
      if (dType is FunctionType) return _typeNameFromFunctionType(dType);
      _log.severe("No name for type, casting through dynamic");
      var d = AstBuilder.identifierFromString("dynamic");
      return AstBuilder.typeName(d, null);
    }
    Identifier id = AstBuilder.identifierFromString(name);
    List<TypeName> args = null;
    if (dType is ParameterizedType) {
      List<DartType> targs = dType.typeArguments;
      args = targs.map(_typeNameFromDartType).toList();
    }
    return AstBuilder.typeName(id, args);
  }
}
