// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.codegen.reify_coercions;

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:logging/logging.dart' as logger;

import 'package:dev_compiler/devc.dart' show AbstractCompiler;
import 'package:dev_compiler/src/checker/rules.dart';
import 'package:dev_compiler/src/info.dart';

import 'ast_builder.dart';

final _log = new logger.Logger('dev_compiler.reify_coercions');

// TODO(leafp) Factor this out or use an existing library
class Tuple2<T0, T1> {
  final T0 e0;
  final T1 e1;
  Tuple2(this.e0, this.e1);
}

typedef T Function1<S, T>(S _);

class NewTypeIdDesc {
  /// If null, then this is not a library level identifier (i.e. it's
  /// a type parameter, or a special type like void, dynamic, etc)
  LibraryElement importedFrom;
  /// True => use/def in same library
  bool fromCurrent;
  /// True => not a source variable
  bool synthetic;
  NewTypeIdDesc({this.fromCurrent, this.importedFrom, this.synthetic});
}

class _Inference extends DownwardsInference {
  TypeManager _tm;

  _Inference(TypeRules rules, this._tm) : super(rules);

  @override
  void annotateCastFromDynamic(Expression e, DartType t) {
    var cast = Coercion.cast(e.staticType, t);
    var node = new DynamicCast(rules, e, cast);
    if (!NodeReplacer.replace(e, node)) {
      _log.severe("Failed to replace node for DownCast");
    }
  }

  @override
  void annotateListLiteral(ListLiteral e, List<DartType> targs) {
    var tNames = targs.map(_tm.typeNameFromDartType).toList();
    e.typeArguments = AstBuilder.typeArgumentList(tNames);
    var listT = rules.provider.listType.substitute4(targs);
    e.staticType = listT;
  }

  @override
  void annotateMapLiteral(MapLiteral e, List<DartType> targs) {
    var tNames = targs.map(_tm.typeNameFromDartType).toList();
    e.typeArguments = AstBuilder.typeArgumentList(tNames);
    var mapT = rules.provider.mapType.substitute4(targs);
    e.staticType = mapT;
  }

  @override
  void annotateInstanceCreationExpression(
      InstanceCreationExpression e, List<DartType> targs) {
    var tNames = targs.map(_tm.typeNameFromDartType).toList();
    var cName = e.constructorName;
    var id = cName.type.name;
    var typeName = AstBuilder.typeName(id, tNames);
    cName.type = typeName;
    var newType =
        (e.staticType.element as ClassElement).type.substitute4(targs);
    e.staticType = newType;
    typeName.type = newType;
  }

  @override
  void annotateFunctionExpression(FunctionExpression e, DartType returnType) {
    // Implicitly changes e.staticType
    (e.element as ExecutableElementImpl).returnType = returnType;
  }
}

// This class implements a pass which modifies (in place) the ast replacing
// abstract coercion nodes with their dart implementations.
class CoercionReifier extends analyzer.GeneralizingAstVisitor<Object>
    with ConversionVisitor<Object> {
  final CoercionManager _cm;
  final TypeManager _tm;
  final VariableManager _vm;
  final LibraryUnit _library;
  final _Inference _inferrer;

  CoercionReifier._(
      this._cm, this._tm, this._vm, this._library, this._inferrer);

  factory CoercionReifier(LibraryUnit library, AbstractCompiler compiler) {
    var vm = new VariableManager();
    var tm = new TypeManager(library.library.element.enclosingElement, vm);
    var cm = new CoercionManager(vm, tm);
    var inferrer = new _Inference(compiler.rules, tm);
    return new CoercionReifier._(cm, tm, vm, library, inferrer);
  }

  // This should be the entry point for this class.  Entering via the
  // visit functions directly may not do the right thing with respect
  // to discharging the collected definitions.
  // Returns the set of new type identifiers added by the reifier
  Map<Identifier, NewTypeIdDesc> reify() {
    _library.partsThenLibrary.forEach(generateUnit);
    return _tm.addedTypes;
  }

  void generateUnit(CompilationUnit unit) {
    visitCompilationUnit(unit);
  }

  ///////////////// Private //////////////////////////////////

  @override
  Object visitInferredTypeBase(InferredTypeBase node) {
    var expr = node.node;
    var b = _inferrer.inferExpression(expr, node.type, <String>[]);
    assert(b);
    if (!NodeReplacer.replace(node, expr)) {
      _log.severe("Failed to replace node for InferredType");
    }
    expr.accept(this);
    return null;
  }

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
  Object visitClosureWrapBase(ClosureWrapBase node) {
    Expression newE = _cm.coerceExpression(node.node, node.wrapper);
    if (!NodeReplacer.replace(node, newE)) {
      _log.severe("Failed to replace node for Closure Wrap");
    }
    newE.accept(this);
    return null;
  }

  Object visitCompilationUnit(CompilationUnit unit) {
    _cm.enterCompilationUnit(unit);
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

  SimpleIdentifier freshIdentifier(String hint) {
    String n = _id.toString();
    _id++;
    String s = "__$hint$n";
    return AstBuilder.identifierFromString(s);
  }

  SimpleIdentifier freshTypeIdentifier(String hint) {
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

  // A map containing all of the wrappers collected but not yet discharged
  final Map<Identifier, Wrapper> _topWrappers = <Identifier, Wrapper>{};
  final Map<Identifier, Wrapper> _classWrappers = <Identifier, Wrapper>{};
  Map<Identifier, Wrapper> _wrappers;

  CoercionManager(this._vm, this._tm) {
    _wrappers = _topWrappers;
  }

  // Call on entry to and exit from a compilation unit in order to properly
  // discharge the accumulated wrappers.
  void enterCompilationUnit(CompilationUnit unit) {
    _tm.enterCompilationUnit(unit);
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
    assert(c != null);
    assert(c is! CoercionError);
    if (e is NamedExpression) {
      Expression inner = coerceExpression(e.expression, c);
      return new NamedExpression(e.name, inner);
    }
    if (c is Cast) return _castExpression(e, c);
    if (c is Wrapper) return _wrapExpression(e, c);
    assert(c is Identity);
    return e;
  }

  ///////////////// Private //////////////////////////////////

  Expression _wrapExpression(Expression e, Wrapper w) {
    var q = _addWrapper(w);
    var app = AstBuilder.application(q, <Expression>[e]);
    app.staticType = w.toType;
    return app;
  }

  Expression _castExpression(Expression e, Cast c) {
    var ttName = _tm.typeNameFromDartType(c.toType);
    var cast = AstBuilder.asExpression(e, ttName);
    cast.staticType = c.toType;
    return cast;
  }

  Expression _addWrapper(Wrapper w) {
    if (_hoistWrappers) {
      var q = _vm.freshIdentifier("q");
      _wrappers[q] = w;
      return q;
    } else {
      return _buildCoercionExpression(w);
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

  List<Expression> _wrapperCoercedArguments(Wrapper wrapper) {
    var namedParameters = wrapper.namedParameters;
    var normalParameters = wrapper.normalParameters;
    var optionalParameters = wrapper.optionalParameters;
    var args = new List<Expression>();
    for (int i = 0; i < normalParameters.length; i++) {
      Identifier x = _coercionParameter("x", i);
      Expression e = coerceExpression(x, normalParameters[i]);
      args.add(e);
    }
    for (int i = 0; i < optionalParameters.length; i++) {
      Identifier y = _coercionParameter("y", i);
      Expression e = coerceExpression(y, optionalParameters[i]);
      args.add(e);
    }
    for (String k in namedParameters.keys) {
      // TODO(leafp): These could collide with the generated names.
      Identifier z = AstBuilder.identifierFromString(k);
      Expression e = coerceExpression(z, namedParameters[k]);
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
      Identifier c, Expression f, Wrapper wrapper) {
    List<FormalParameter> params = _wrapperFormalParameters(wrapper);
    List<Expression> args = _wrapperCoercedArguments(wrapper);
    Expression app = AstBuilder.application(f, args);
    Expression body = coerceExpression(app, wrapper.ret);
    FunctionExpression ce = AstBuilder.expressionFunction(params, body, true);
    TypeName rt =
        _tm.typeNameFromDartType((wrapper.fromType as FunctionType).returnType);
    Statement cDec = AstBuilder.functionDeclarationStatement(rt, c, ce);
    return cDec;
  }

  Tuple2<List<FormalParameter>, List<Statement>> _buildCoercionBody(
      Wrapper wrapper) {
    var f = AstBuilder.identifierFromString("f");
    var c = AstBuilder.identifierFromString("c");
    var cDec = _wrapperMkInner(c, f, wrapper);
    var comp = AstBuilder.binaryExpression(f, "==", AstBuilder.nullLiteral());
    var n = AstBuilder.nullLiteral();
    var cond = AstBuilder.conditionalExpression(comp, n, c);
    var stmts = <Statement>[cDec, AstBuilder.returnExpression(cond)];
    var fp = _tm.typedFormal(f, wrapper.fromType);
    var params = <FormalParameter>[fp];
    return new Tuple2<List<FormalParameter>, List<Statement>>(params, stmts);
  }

  Expression _buildCoercionExpression(Wrapper wrapper) {
    var tup = _buildCoercionBody(wrapper);
    return AstBuilder.blockFunction(tup.e0, tup.e1);
  }

  // Given a name g and coercion q : T0 -> T1 => S0 -> S1
  // Bind g to a function or static method which maps
  // T0 -> T1 functions to S0 -> S1 functions.
  // T0 -> T1 g(S1 f(S0)) {
  //   T1 c(T0 x) => (f(x as T0) as S1);
  //   return (f == null) ? null : c;
  // }
  Declaration _buildCoercion(Identifier q, Wrapper wrapper, bool top) {
    var tup = _buildCoercionBody(wrapper);
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
  final VariableManager _vm;
  final LibraryElement _currentLibrary;
  final Map<Identifier, NewTypeIdDesc> addedTypes = {};
  CompilationUnitElement _currentUnit;

  /// A map containing new function typedefs to be introduced at the top level
  /// This uses LinkedHashMap to emit code in a consistent order.
  final Map<FunctionType, FunctionTypeAlias> _typedefs = {};

  TypeManager(this._currentLibrary, this._vm);

  void enterCompilationUnit(CompilationUnit unit) {
    _currentUnit = unit.element;
  }

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
      FormalParameter fp =
          AstBuilder.requiredFormal(_anonymousFormal(normalParameters[i]));
      _resolveFormal(fp, normalParameters[i]);
      params.add(fp);
    }
    for (int i = 0; i < optionalParameters.length; i++) {
      FormalParameter fp =
          AstBuilder.optionalFormal(_anonymousFormal(optionalParameters[i]));
      _resolveFormal(fp, optionalParameters[i]);
      params.add(fp);
    }
    for (String k in namedParameters.keys) {
      FormalParameter fp =
          AstBuilder.namedFormal(_anonymousFormal(namedParameters[k]));
      _resolveFormal(fp, namedParameters[k]);
      params.add(fp);
    }
    return params;
  }

  void _resolveFormal(FormalParameter fp, DartType type) {
    ParameterElementImpl fe = new ParameterElementImpl.forNode(fp.identifier);
    fe.parameterKind = fp.kind;
    fe.type = type;
    fp.identifier.staticElement = fe;
    fp.identifier.staticType = type;
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

  SimpleIdentifier freshTypeDefVariable(String hint) {
    var t = _vm.freshTypeIdentifier(hint);
    var desc = new NewTypeIdDesc(
        fromCurrent: true, importedFrom: _currentLibrary, synthetic: true);
    addedTypes[t] = desc;
    return t;
  }

  SimpleIdentifier typeParameterFromString(String name) =>
      AstBuilder.identifierFromString(name);

  SimpleIdentifier freshReferenceToNamedType(DartType type) {
    var name = type.name;
    assert(name != null);
    var id = AstBuilder.identifierFromString(name);
    var element = type.element;
    id.staticElement = element;
    var library = null;
    // This can happen for types like (e.g.) void
    if (element != null) library = element.library;
    var desc = new NewTypeIdDesc(
        fromCurrent: _currentLibrary == library,
        importedFrom: library,
        synthetic: false);
    addedTypes[id] = desc;
    return id;
  }

  FunctionTypeAlias _newResolvedTypedef(
      FunctionType type, List<TypeParameterType> ftvs) {

    // The name of the typedef (unresolved at this point)
    // TODO(leafp): better naming.
    SimpleIdentifier t = freshTypeDefVariable("CastType");

    // The element for the new typedef
    var element = new FunctionTypeAliasElementImpl(t.name, 0);

    // Fresh type parameter identifiers for the free type variables
    List<Identifier> tNames =
        ftvs.map((x) => typeParameterFromString(x.name)).toList();
    // The type parameters themselves
    List<TypeParameter> tps = tNames.map(AstBuilder.typeParameter).toList();
    // Allocate the elements for the type parameters, fill in their
    // type (which makes no sense) and link up the various elements
    // For each type parameter identifier, make an element and a type
    // with that element, link the two together, set the identifier element
    // to that element, and the identifier type to that type.
    List<TypeParameterElement> tElements = tNames.map((x) {
      var element = new TypeParameterElementImpl(x.name, 0);
      var type = new TypeParameterTypeImpl(element);
      element.type = type;
      x.staticElement = element;
      x.staticType = type;
      return element;
    }).toList();
    // Get the types out from the elements
    List<TypeParameterType> tTypes = tElements.map((x) => x.type).toList();
    // Take the return type from the original type, and replace the free
    // type variables with the fresh type variables
    element.returnType = type.returnType.substitute2(tTypes, ftvs);
    // Set the type parameter elements
    element.typeParameters = tElements;
    // Set the parent element to the current compilation unit
    element.enclosingElement = _currentUnit;

    // This is the type corresponding to the typedef.  Note that
    // almost all methods on this type delegate to the element, so it
    // cannot be safely be used for anything until the element is fully resolved
    FunctionTypeImpl substType = new FunctionTypeImpl.con2(element);
    element.type = substType;
    // Link the type and the element into the identifier for the typedef
    t.staticType = substType;
    t.staticElement = element;

    // Make the formal parameters for the typedef, using the original type
    // with the fresh type variables substituted in.
    List<FormalParameter> fps =
        _formalParameterListForFunctionType(type.substitute2(tTypes, ftvs));
    // Get the static elements out of the parameters, and use them to
    // initialize the parameters in the element model
    element.parameters = fps.map((x) => x.identifier.staticElement).toList();
    // Build the return type syntax
    TypeName ret = _typeNameFromDartType(substType.returnType);
    // This should now be fully resolved (or at least enough so for things
    // to work so far).
    FunctionTypeAlias alias = AstBuilder.functionTypeAlias(ret, t, tps, fps);

    return alias;
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
            ltp.map((t) => _mkNewTypeName(null, t.name, null)));
      }
      var name = alias.name;
      return _mkNewTypeName(type, name, ts);
    }

    List<TypeParameterType> ftvs = _freeTypeVariables(type);
    FunctionTypeAlias alias = _newResolvedTypedef(type, ftvs);
    _typedefs[type] = alias;

    List<TypeName> args = ftvs.map(_typeNameFromDartType).toList();
    TypeName namedType =
        _mkNewTypeName(alias.name.staticType, alias.name, args);

    return namedType;
  }

  TypeName _typeNameFromDartType(DartType dType) {
    String name = dType.name;
    if (name == null || name == "" || dType.isBottom) {
      if (dType is FunctionType) return _typeNameFromFunctionType(dType);
      _log.severe("No name for type, casting through dynamic");
      var d = AstBuilder.identifierFromString("dynamic");
      var t = _mkNewTypeName(dType, d, null);
      return t;
    }
    SimpleIdentifier id = freshReferenceToNamedType(dType);
    List<TypeName> args = null;
    if (dType is ParameterizedType) {
      List<DartType> targs = dType.typeArguments;
      args = targs.map(_typeNameFromDartType).toList();
    }
    var t = _mkNewTypeName(dType, id, args);
    return t;
  }

  TypeName _mkNewTypeName(DartType type, Identifier id, List<TypeName> args) {
    var t = AstBuilder.typeName(id, args);
    t.type = type;
    return t;
  }
}
