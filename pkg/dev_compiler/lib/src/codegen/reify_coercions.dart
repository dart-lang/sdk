library ddc.src.codegen.reify_coercions;

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:logging/logging.dart' as logger;
import 'package:source_span/source_span.dart' show SourceFile;

import 'package:ddc/src/checker/rules.dart';
import 'package:ddc/src/info.dart';
import 'package:ddc/src/utils.dart' as utils;

import 'ast_builder.dart';

final _log = new logger.Logger('ddc.reify_coercions');

// TODO(leafp) Factor this out or use an existing library
class Tuple2<T0, T1> {
  final T0 e0;
  final T1 e1;
  Tuple2(this.e0, this.e1);
}

typedef T Function1<S, T>(S _);

class _LocatedWrapper {
  final String loc;
  final Wrapper wrapper;
  _LocatedWrapper(this.wrapper, this.loc);
}

// This class implements a pass which modifies (in place) the ast replacing
// abstract coercion nodes with their dart implementations.
class UnitCoercionReifier extends analyzer.GeneralizingAstVisitor<Object>
    with ConversionVisitor<Object> {
  CoercionManager _cm;
  final TypeManager _tm;
  final VariableManager _vm;
  SourceFile _file;
  bool _skipCoercions = false;
  final TypeRules _rules;

  UnitCoercionReifier(this._tm, this._vm, this._rules) {
    _cm = new CoercionManager(_vm, _tm, _rules);
  }

  // This should be the entry point for this class.  Entering via the
  // visit functions directly may not do the right thing with respect
  // to discharging the collected definitions.
  void reify(CompilationUnit unit) {
    _file = new SourceFile(unit.element.source.contents.data,
        url: unit.element.source.uri);
    visitCompilationUnit(unit);
  }

  ///////////////// Private //////////////////////////////////

  String _locationInfo(Expression e) {
    if (_file != null) {
      final begin = e is AnnotatedNode
          ? (e as AnnotatedNode).firstTokenAfterCommentAndMetadata.offset
          : e.offset;
      if (begin != 0) {
        var span = _file.span(begin, e.end);
        var s = span.message("Cast");
        return s.substring(0, s.indexOf("Cast"));
      }
    }
    return null;
  }

  static String _conversionKind(Conversion node) {
    if (node is ClosureWrapLiteral) return "WrapLiteral";
    if (node is ClosureWrap) return "Wrap";
    if (node is DownCastDynamic) return "CastDynamic";
    if (node is DownCastLiteral) return "CastLiteral";
    if (node is DownCastExact) return "CastExact";
    if (node is DownCast) return "CastGeneral";
    assert(false);
    return "";
  }

  @override
  Object visitAsExpression(AsExpression e) {
    var cast = Coercion.cast(_rules.getStaticType(e.expression), e.type.type);
    var loc = _locationInfo(e);
    Expression castNode =
        _cm.coerceExpression(e.expression, cast, "CastUser", loc);
    if (!NodeReplacer.replace(e, castNode)) {
      _log.severe("Failed to replace node for DownCast");
    }
    castNode.accept(this);
    return null;
  }

  @override
  Object visitDownCastBase(DownCastBase node) {
    if (_skipCoercions) {
      _log.severe("Skipping runtime downcast in constant context");
      return null;
    }
    String kind = _conversionKind(node);
    var loc = _locationInfo(node);
    Expression castNode = _cm.coerceExpression(node.node, node.cast, kind, loc);
    if (!NodeReplacer.replace(node, castNode)) {
      _log.severe("Failed to replace node for DownCast");
    }
    castNode.accept(this);
    return null;
  }

  // TODO(leafp): Bind the coercions at the top level
  @override
  Object visitClosureWrapBase(ClosureWrapBase node) {
    if (_skipCoercions) {
      _log.severe("Skipping coercion wrap in constant context");
      return null;
    }
    String kind = _conversionKind(node);
    var loc = _locationInfo(node);
    Expression newE = _cm.coerceExpression(node.node, node.wrapper, kind, loc);
    if (!NodeReplacer.replace(node, newE)) {
      _log.severe("Failed to replace node for Closure Wrap");
    }
    newE.accept(this);
    return null;
  }

  @override
  Object visitNode(AstNode n) {
    var o = _skipCoercions;
    if (!o) {
      if (n is VariableDeclarationList) {
        _skipCoercions = o || n.isConst;
      } else if (n is VariableDeclaration) {
        _skipCoercions = o || n.isConst;
      } else if (n is FormalParameter) {
        _skipCoercions = o || n.isConst;
      } else if (n is InstanceCreationExpression) {
        _skipCoercions = o || n.isConst;
      } else if (n is ConstructorDeclaration) {
        _skipCoercions = o || n.element.isConst;
      }
    }
    Object ret = super.visitNode(n);
    _skipCoercions = o;
    return ret;
  }

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
  // TODO(leafp): Hack, not for real.
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
  bool _hoistWrappers = false;
  TypeRules _rules;

  // A map containing all of the wrappers collected but not yet discharged
  final Map<Identifier, _LocatedWrapper> _topWrappers =
      <Identifier, _LocatedWrapper>{};
  final Map<Identifier, _LocatedWrapper> _classWrappers =
      <Identifier, _LocatedWrapper>{};
  Map<Identifier, _LocatedWrapper> _wrappers;

  CoercionManager(this._vm, this._tm, this._rules) {
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
      FunctionDeclaration f =
          _buildCoercion(i, _wrappers[i].wrapper, _wrappers[i].loc, true);
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
      ClassMember f =
          _buildCoercion(i, _wrappers[i].wrapper, _wrappers[i].loc, false);
      cl.members.add(f);
    }
    _wrappers.clear();
    _wrappers = _topWrappers;
  }

  // The main entry point.  Coerce e using c, returning a new expression,
  // possibly recording additional coercions functions and typedefs to
  // be discharged at a higher level.
  Expression coerceExpression(
      Expression e, Coercion c, String kind, String loc) {
    return _coerceExpression(e, c, kind, loc);
  }

  ///////////////// Private //////////////////////////////////
  Tuple2<Identifier, Function1<Expression, Expression>> _bindExpression(
      String hint, Expression e1) {
    if (e1 is Identifier) {
      return new Tuple2(e1, (e2) => e2);
    }
    var id = _vm.freshIdentifier(hint);
    var fp = AstBuilder.simpleFormal(id, null);
    f(e2) => AstBuilder.parenthesize(AstBuilder.letExpression(fp, e1, e2));
    return new Tuple2(id, f);
  }

  Expression _wrapExpression(Expression e, Wrapper w, String k, String loc) {
    var q = _addWrapper(w, loc);
    var ttName = _tm.typeNameFromDartType(w.toType);
    var tt = _tm.typeExpression(ttName);
    var ft = _tm.typeExpressionFromDartType(w.fromType);
    if (w.fromType.element.library != null &&
        utils.isDartPrivateLibrary(w.fromType.element.library)) {
      ft = AstBuilder.nullLiteral();
    }
    var tup = _bindExpression("x", e);
    var id = tup.e0;
    var binder = tup.e1;
    var kind = AstBuilder.stringLiteral(k);
    var key = AstBuilder.multiLineStringLiteral(loc);
    var dartIs = AstBuilder.isExpression(AstBuilder.parenthesize(id), ttName);
    var arguments = <Expression>[q, id, ft, tt, kind, key, dartIs];
    return binder(new RuntimeOperation("wrap", arguments));
  }

  Expression _castExpression(Expression e, Cast c, String k, String loc) {
    var ttName = _tm.typeNameFromDartType(c.toType);
    var tt = _tm.typeExpression(ttName);
    var ft = _tm.typeExpressionFromDartType(c.fromType);
    if (c.fromType.element.library != null &&
        utils.isDartPrivateLibrary(c.fromType.element.library)) {
      ft = AstBuilder.nullLiteral();
    }
    var tup = _bindExpression("x", e);
    var id = tup.e0;
    var binder = tup.e1;
    var kind = AstBuilder.stringLiteral(k);
    var key = AstBuilder.multiLineStringLiteral(loc);
    var dartIs = AstBuilder.isExpression(AstBuilder.parenthesize(id), ttName);
    var ground = AstBuilder.booleanLiteral(_rules.isGroundType(c.toType));
    var arguments = <Expression>[id, ft, tt, kind, key, dartIs, ground];
    return binder(new RuntimeOperation("cast", arguments));
  }

  Expression _coerceExpression(
      Expression e, Coercion c, String kind, String loc) {
    assert(c != null);
    assert(c is! CoercionError);
    if (e is NamedExpression) {
      Expression inner = _coerceExpression(e.expression, c, kind, loc);
      return new NamedExpression(e.name, inner);
    }
    if (c is Cast) return _castExpression(e, c, kind, loc);
    if (c is Wrapper) return _wrapExpression(e, c, kind, loc);
    assert(c is Identity);
    return e;
  }

  Expression _addWrapper(Wrapper w, String loc) {
    if (_hoistWrappers) {
      var q = _vm.freshIdentifier("q");
      _wrappers[q] = new _LocatedWrapper(w, loc);
      return q;
    } else {
      return _buildCoercionExpression(w, loc);
    }
  }

  // Choose a canonical name for the ith coercion parameter
  // with name "name".
  Identifier _coercionParameter(String name, int index) {
    String s = name + index.toString();
    return AstBuilder.identifierFromString(s);
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
      // TODO(leafp): These could collide with the generated names.
      Identifier z = AstBuilder.identifierFromString(k);
      // We use the toType to avoid changing the reified type
      FormalParameter fp = _tm.typedFormal(z, namedParameters[k].toType);
      params.add(AstBuilder.namedFormal(fp));
    }
    return params;
  }

  List<Expression> _wrapperCoercedArguments(Wrapper wrapper, String loc) {
    var namedParameters = wrapper.namedParameters;
    var normalParameters = wrapper.normalParameters;
    var optionalParameters = wrapper.optionalParameters;
    var args = new List<Expression>();
    for (int i = 0; i < normalParameters.length; i++) {
      Identifier x = _coercionParameter("x", i);
      Expression e =
          _coerceExpression(x, normalParameters[i], "CastParam", loc);
      args.add(e);
    }
    for (int i = 0; i < optionalParameters.length; i++) {
      Identifier y = _coercionParameter("y", i);
      Expression e =
          _coerceExpression(y, optionalParameters[i], "CastParam", loc);
      args.add(e);
    }
    for (String k in namedParameters.keys) {
      // TODO(leafp): These could collide with the generated names.
      Identifier z = AstBuilder.identifierFromString(k);
      Expression e = _coerceExpression(z, namedParameters[k], "CastParam", loc);
      args.add(AstBuilder.namedParameter(k, e));
    }
    return args;
  }

  // Given an identifier c, a value f and a coercion q : T0 -> T1 => S0 -> S1
  // wrap f using q and bind it to variable c
  // T1 c(T0 x) => (f(x as T0) as S1)
  // Note that we use the "fromType" to decorate the wrapper
  // rather than the "toType" to avoid changing the reified type
  // TODO(leafp): If we wrap non-function literals, we can still
  // end up changing the runtime reified type, since we build a function
  // literal based on the static type.
  FunctionDeclarationStatement _wrapperMkInner(
      Identifier c, Expression f, Wrapper wrapper, String loc) {
    List<FormalParameter> params = _wrapperFormalParameters(wrapper);
    List<Expression> args = _wrapperCoercedArguments(wrapper, loc);
    Expression app = AstBuilder.application(f, args);
    Expression body = _coerceExpression(app, wrapper.ret, "CastResult", loc);
    FunctionExpression ce = AstBuilder.expressionFunction(params, body, true);
    TypeName rt =
        _tm.typeNameFromDartType((wrapper.fromType as FunctionType).returnType);
    Statement cDec = AstBuilder.functionDeclarationStatement(rt, c, ce);
    return cDec;
  }

  Tuple2<List<FormalParameter>, List<Statement>> _buildCoercionBody(
      Wrapper wrapper, String loc) {
    var f = AstBuilder.identifierFromString("f");
    var c = AstBuilder.identifierFromString("c");
    var cDec = _wrapperMkInner(c, f, wrapper, loc);
    var comp = AstBuilder.binaryExpression(f, "==", AstBuilder.nullLiteral());
    var n = AstBuilder.nullLiteral();
    var cond = AstBuilder.conditionalExpression(comp, n, c);
    var stmts = <Statement>[cDec, AstBuilder.returnExpression(cond)];
    var fp = _tm.typedFormal(f, wrapper.fromType);
    var params = <FormalParameter>[fp];
    return new Tuple2<List<FormalParameter>, List<Statement>>(params, stmts);
  }

  Expression _buildCoercionExpression(Wrapper wrapper, String loc) {
    var tup = _buildCoercionBody(wrapper, loc);
    return AstBuilder.blockFunction(tup.e0, tup.e1);
  }

  // Given a name g and coercion q : T0 -> T1 => S0 -> S1
  // Bind g to a function or static method which maps
  // T0 -> T1 functions to S0 -> S1 functions.
  // T0 -> T1 g(S1 f(S0)) {
  //   T1 c(T0 x) => (f(x as T0) as S1);
  //   return (f == null) ? null : c;
  // }
  Declaration _buildCoercion(
      Identifier q, Wrapper wrapper, String loc, bool top) {
    var tup = _buildCoercionBody(wrapper, loc);
    var params = tup.e0;
    var stmts = tup.e1;
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
  Set<TypeName> _newTypes = new Set<TypeName>();

  /// A map containing new function typedefs to be introduced at the top level
  /// This uses LinkedHashMap to emit code in a consistent order.
  final Map<FunctionType, FunctionTypeAlias> _typedefs =
      new Map<FunctionType, FunctionTypeAlias>();

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

  Expression typeExpressionFromDartType(DartType t) =>
      typeExpression(typeNameFromDartType(t));

  Expression typeExpression(TypeName t) => _typeExpression(t);

  Set<TypeName> get addedTypes => _newTypes;

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
        // TODO(leafp): The inner conditional (testing FunctionType, etc)
        // can be eliminated after the roll to the next analyzer which fixes
        // a bug in how they resolve type names.
        if (type.name != null && type.name != "") {
          if (type is! FunctionType ||
              (type.element != null && type.element is FunctionTypeAlias)) {
            _ftList(type.typeArguments);
            return;
          }
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
        ts = new List<TypeName>.from(
            ltp.map((t) => _mkNewTypeName(t.name, null)));
      }
      var name = alias.name;
      return _mkNewTypeName(name, ts);
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
    TypeName namedType = _mkNewTypeName(t, args);

    return namedType;
  }

  TypeName _typeNameFromDartType(DartType dType) {
    // TODO(leafp) This doesn't re-use the name when the function type
    // is derived from a typedef, since I've moved it above the check
    // for a name.  I think there's a bug in the resolver here: I
    // sometimes see function types named not with a typedef name,
    // but rather with the name of the function that they classify.
    if (dType is FunctionType) return _typeNameFromFunctionType(dType);
    String name = dType.name;
    if (name == null || name == "") {
      _log.severe("No name for type, casting through dynamic");
      var d = AstBuilder.identifierFromString("dynamic");
      var t = _mkNewTypeName(d, null);
      t.type = dType;
      return t;
    }
    SimpleIdentifier id = AstBuilder.identifierFromString(name);
    id.staticElement = dType.element;
    List<TypeName> args = null;
    if (dType is ParameterizedType) {
      List<DartType> targs = dType.typeArguments;
      args = targs.map(_typeNameFromDartType).toList();
    }
    var t = _mkNewTypeName(id, args);
    t.type = dType;
    return t;
  }

  TypeName _mkNewTypeName(Identifier id, List<TypeName> args) {
    var t = AstBuilder.typeName(id, args);
    _newTypes.add(t);
    return t;
  }

  Expression _typeExpression(TypeName t) {
    if (t.typeArguments != null && t.typeArguments.length > 0) {
      var w = AstBuilder.identifierFromString("_");
      var fp = AstBuilder.simpleFormal(w, t);
      var f = AstBuilder.blockFunction(<FormalParameter>[fp], <Statement>[]);
      return new RuntimeOperation("type", <Expression>[f]);
    }
    return t.name;
  }
}
