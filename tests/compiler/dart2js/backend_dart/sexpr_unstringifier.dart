// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SExpressionUnstringifier implements the inverse operation to
// [SExpressionStringifier].

library sexpr_unstringifier;

import 'package:compiler/implementation/dart2jslib.dart' as dart2js
  show Constant, IntConstant, NullConstant, StringConstant,
       DoubleConstant, MessageKind;
import 'package:compiler/implementation/dart_types.dart' as dart_types
  show DartType;
import 'package:compiler/implementation/elements/elements.dart'
  show Entity, Element, Elements, Local, TypeVariableElement, ErroneousElement,
       TypeDeclarationElement, ExecutableElement;
import 'package:compiler/implementation/elements/modelx.dart'
  show ErroneousElementX, TypeVariableElementX;
import 'package:compiler/implementation/tree/tree.dart'show LiteralDartString;
import 'package:compiler/implementation/universe/universe.dart'
  show Selector, SelectorKind;
import 'package:compiler/implementation/cps_ir/cps_ir_nodes.dart';

/// Used whenever a node constructed by [SExpressionUnstringifier] needs a
/// named entity.
class DummyEntity extends Entity {
  final String name;
  DummyEntity(this.name);
}

/// Used whenever a node constructed by [SExpressionUnstringifier] needs a
/// local.
class DummyLocal extends DummyEntity implements Local {
  DummyLocal(String name) : super(name);

  ExecutableElement get executableContext => null;
}

/// Used whenever a node constructed by [SExpressionUnstringifier] requires
/// an [Element] or [FunctionElement]. Extends [ErroneousElementX] since there
/// is currently a large amount of overhead when extending the base abstract
/// classes, and erroneous elements conveniently also skip several assertion
/// checks in CPS IR nodes that are irrelevant to us.
class DummyElement extends ErroneousElementX
    implements TypeVariableElement {
  DummyElement(String name)
      : super(dart2js.MessageKind.GENERIC, {}, name, null);

  final dart_types.DartType bound = null;
  final TypeDeclarationElement typeDeclaration = null;
}

/// Used whenever a node constructed by [SExpressionUnstringifier] requires
/// a named type.
class DummyNamedType extends dart_types.DartType {
  final String name;

  final kind = null;
  final element = null;

  DummyNamedType(this.name);

  subst(arguments, parameters) => null;
  unalias(compiler) => null;
  accept(visitor, argument) => null;

  String toString() => name;
}

/// Represents a list of tokens, but is basically a partial view into a list
/// with appropriate convenience methods.
class Tokens {
  final List<String> _list;
  int _index; // Current index into the list.

  Tokens(List<String> this._list) : _index = 0;

  String get current => _list[_index];
  String get next    => _list[_index + 1];

  String read([String expected]) {
    if (expected != null) {
      assert(current == expected);
    }
    return _list[_index++];
  }

  /// Consumes the preamble to a new node, consisting of an opening parenthesis
  /// and a tag.
  void consumeStart([String tag]) {
    read("(");
    if (tag != null) {
      read(tag);
    }
  }

  void consumeEnd() {
    read(")");
  }

  bool get hasNext  => _index < _list.length;
  String toString() => _list.sublist(_index).toString();
}

/// Constructs a minimal in-memory representation of the IR represented
/// by the given string. Many fields are currently simply set to null.
class SExpressionUnstringifier {

  // Expressions
  static const String BRANCH = "Branch";
  static const String CONCATENATE_STRINGS = "ConcatenateStrings";
  static const String DECLARE_FUNCTION = "DeclareFunction";
  static const String INVOKE_CONSTRUCTOR = "InvokeConstructor";
  static const String INVOKE_CONTINUATION = "InvokeContinuation";
  static const String INVOKE_CONTINUATION_RECURSIVE = "InvokeContinuation*";
  static const String INVOKE_STATIC = "InvokeStatic";
  static const String INVOKE_SUPER_METHOD = "InvokeSuperMethod";
  static const String INVOKE_METHOD = "InvokeMethod";
  static const String LET_PRIM = "LetPrim";
  static const String LET_CONT = "LetCont";
  static const String LET_CONT_RECURSIVE = "LetCont*";
  static const String SET_CLOSURE_VARIABLE = "SetClosureVariable";
  static const String TYPE_OPERATOR = "TypeOperator";

  // Primitives
  static const String CONSTANT = "Constant";
  static const String CREATE_FUNCTION = "CreateFunction";
  static const String GET_CLOSURE_VARIABLE = "GetClosureVariable";
  static const String LITERAL_LIST = "LiteralList";
  static const String LITERAL_MAP = "LiteralMap";
  static const String REIFY_TYPE_VAR = "ReifyTypeVar";
  static const String THIS = "This";

  // Other
  static const String FUNCTION_DEFINITION = "FunctionDefinition";
  static const String IS_TRUE = "IsTrue";

  final Map<String, Definition> name2variable =
      <String, Definition>{ "return": new Continuation.retrn() };

  // The tokens currently being parsed.
  Tokens tokens;

  FunctionDefinition unstringify(String s) {
    tokens = tokenize(s);
    FunctionDefinition def = parseFunctionDefinition();
    assert(!tokens.hasNext);
    return def;
  }

  /// Returns a new named dummy selector with a roughly appropriate kind.
  Selector dummySelector(String name, int argumentCount) {
    SelectorKind kind = Elements.isOperatorName(name)
        ? SelectorKind.OPERATOR : SelectorKind.CALL;
    return new Selector(kind, name, null, argumentCount);
  }

  /// Returns the tokens in s. Note that string literals are not necessarily
  /// preserved; for instance, "(literalString)" is transformed to
  /// " ( literalString ) ".
  Tokens tokenize(String s) =>
      new Tokens(
          s.replaceAll("(", " ( ")
           .replaceAll(")", " ) ")
           .replaceAll(new RegExp(r"[ \t\n]+"), " ")
           .trim()
           .split(" "));

  Expression parseExpression() {
    assert(tokens.current == "(");

    switch (tokens.next) {
      case BRANCH:
        return parseBranch();
      case CONCATENATE_STRINGS:
        return parseConcatenateStrings();
      case DECLARE_FUNCTION:
        return parseDeclareFunction();
      case INVOKE_CONSTRUCTOR:
        return parseInvokeConstructor();
      case INVOKE_CONTINUATION:
        return parseInvokeContinuation(false);
      case INVOKE_CONTINUATION_RECURSIVE:
        return parseInvokeContinuation(true);
      case INVOKE_METHOD:
        return parseInvokeMethod();
      case INVOKE_STATIC:
        return parseInvokeStatic();
      case INVOKE_SUPER_METHOD:
        return parseInvokeSuperMethod();
      case LET_PRIM:
        return parseLetPrim();
      case LET_CONT:
        return parseLetCont(false);
      case LET_CONT_RECURSIVE:
        return parseLetCont(true);
      case SET_CLOSURE_VARIABLE:
        return parseSetClosureVariable();
      case TYPE_OPERATOR:
        return parseTypeOperator();
      default:
        assert(false);
    }

    return null;
  }

  /// def1 def2 ... defn cont )
  /// Note that cont is *not* included in the returned list and not consumed.
  List<Definition> parseDefinitionList() {
    List<Definition> defs = <Definition>[];
    while (tokens.next != ")") {
      Definition def = name2variable[tokens.read()];
      assert(def != null);
      defs.add(def);
    }
    return defs;
  }

  /// (prim1 prim2 ... primn)
  List<Primitive> parsePrimitiveList() {
    tokens.consumeStart();
    List<Primitive> prims = <Primitive>[];
    while (tokens.current != ")") {
      Primitive prim = name2variable[tokens.read()];
      assert(prim != null);
      prims.add(prim);
    }
    tokens.consumeEnd();
    return prims;
  }

  /// (FunctionDefinition name (args cont) body)
  FunctionDefinition parseFunctionDefinition() {
    tokens.consumeStart(FUNCTION_DEFINITION);

    // name
    Element element = new DummyElement("");
    if (tokens.current != "(") {
      // This is a named function.
      element = new DummyElement(tokens.read());
    }

    // (args cont)
    List<Parameter> parameters = <Parameter>[];
    tokens.consumeStart();
    while (tokens.next != ")") {
      String paramName = tokens.read();
      Parameter param = new Parameter(new DummyElement(paramName));
      name2variable[paramName] = param;
      parameters.add(param);
    }

    String contName = tokens.read("return");
    Continuation cont = name2variable[contName];
    assert(cont != null);
    tokens.consumeEnd();

    // body
    Expression body = parseExpression();

    tokens.consumeEnd();
    return new FunctionDefinition(element, cont, parameters, body, null, null);
  }

  /// (IsTrue arg)
  Condition parseCondition() {
    // Handles IsTrue only for now.
    tokens.consumeStart(IS_TRUE);

    Definition value = name2variable[tokens.read()];
    assert(value != null);

    tokens.consumeEnd();
    return new IsTrue(value);
  }

  /// (Branch condition cont cont)
  Branch parseBranch() {
    tokens.consumeStart(BRANCH);

    Condition cond = parseCondition();
    Continuation trueCont = name2variable[tokens.read()];
    Continuation falseCont = name2variable[tokens.read()];
    assert(trueCont != null && falseCont != null);

    tokens.consumeEnd();
    return new Branch(cond, trueCont, falseCont);
  }

  /// (ConcatenateStrings args cont)
  ConcatenateStrings parseConcatenateStrings() {
    tokens.consumeStart(CONCATENATE_STRINGS);

    List<Definition> args = parseDefinitionList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    return new ConcatenateStrings(cont, args);
  }

  /// (DeclareFunction name = function in body)
  DeclareFunction parseDeclareFunction() {
    tokens.consumeStart(DECLARE_FUNCTION);

    // name =
    Local local = new DummyLocal(tokens.read());
    tokens.read("=");

    // function in
    FunctionDefinition def = parseFunctionDefinition();
    tokens.read("in");

    // body
    Expression body = parseExpression();

    tokens.consumeEnd();
    return new DeclareFunction(local, def)..plug(body);
  }

  /// (InvokeConstructor name args cont)
  InvokeConstructor parseInvokeConstructor() {
    tokens.consumeStart(INVOKE_CONSTRUCTOR);

    String constructorName = tokens.read();
    List<String> split = constructorName.split(".");
    assert(split.length < 3);

    dart_types.DartType type = new DummyNamedType(split[0]);
    Element element = new DummyElement((split.length == 1) ? "" : split[1]);

    List<Definition> args = parseDefinitionList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    Selector selector = dummySelector(constructorName, args.length);
    return new InvokeConstructor(type, element, selector, cont, args);
  }

  /// (InvokeContinuation name args)
  InvokeContinuation parseInvokeContinuation(bool recursive) {
    tokens.consumeStart(recursive
        ? INVOKE_CONTINUATION_RECURSIVE : INVOKE_CONTINUATION);

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    List<Definition> args = <Definition>[];
    while (tokens.current != ")") {
      Definition def = name2variable[tokens.read()];
      assert(def != null);
      args.add(def);
    }

    tokens.consumeEnd();
    return new InvokeContinuation(cont, args, recursive: recursive);
  }

  /// (InvokeMethod receiver method args cont)
  InvokeMethod parseInvokeMethod() {
    tokens.consumeStart(INVOKE_METHOD);

    Definition receiver = name2variable[tokens.read()];
    assert(receiver != null);

    String methodName = tokens.read();

    List<Definition> args = parseDefinitionList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    Selector selector = dummySelector(methodName, args.length);
    return new InvokeMethod(receiver, selector, cont, args);
  }

  /// (InvokeStatic method args cont)
  InvokeStatic parseInvokeStatic() {
    tokens.consumeStart(INVOKE_STATIC);

    String methodName = tokens.read();

    List<Definition> args = parseDefinitionList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    Entity entity = new DummyEntity(methodName);
    Selector selector = dummySelector(methodName, args.length);

    tokens.consumeEnd();
    return new InvokeStatic(entity, selector, cont, args);
  }

  /// (InvokeSuperMethod method args cont)
  InvokeSuperMethod parseInvokeSuperMethod() {
    tokens.consumeStart(INVOKE_SUPER_METHOD);

    String methodName = tokens.read();

    List<Definition> args = parseDefinitionList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    Selector selector = dummySelector(methodName, args.length);
    return new InvokeSuperMethod(selector, cont, args);
  }

  /// (LetCont (cont args) (cont_body)) body
  LetCont parseLetCont(bool recursive) {
    tokens.consumeStart(recursive ? LET_CONT_RECURSIVE : LET_CONT);

    // (name args) (cont_body))
    tokens.consumeStart();
    String name = tokens.read();

    List<Parameter> params = <Parameter>[];
    while (tokens.current != ")") {
      String paramName = tokens.read();
      Parameter param = new Parameter(new DummyElement(paramName));
      name2variable[paramName] = param;
      params.add(param);
    }
    tokens.consumeEnd();

    Continuation cont = new Continuation(params);
    name2variable[name] = cont;

    cont.isRecursive = recursive;
    cont.body = parseExpression();
    tokens.consumeEnd();

    // body
    Expression body = parseExpression();

    return new LetCont(cont, body);
  }

  /// (SetClosureVariable name value body)
  SetClosureVariable parseSetClosureVariable() {
    tokens.consumeStart(SET_CLOSURE_VARIABLE);

    Local local = new DummyLocal(tokens.read());
    Primitive value = name2variable[tokens.read()];
    assert(value != null);

    Expression body = parseExpression();

    tokens.consumeEnd();
    return new SetClosureVariable(local, value)
                  ..plug(body);
  }

  /// (TypeOperator operator recv type cont)
  TypeOperator parseTypeOperator() {
    tokens.consumeStart(TYPE_OPERATOR);

    String operator = tokens.read();

    Primitive recv = name2variable[tokens.read()];
    assert(recv != null);

    dart_types.DartType type = new DummyNamedType(tokens.read());

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    return new TypeOperator(operator, recv, type, cont);
  }

  /// (LetPrim name (primitive)) body
  LetPrim parseLetPrim() {
    tokens.consumeStart(LET_PRIM);

    // name
    String name = tokens.read();

    // (primitive)
    Primitive primitive = parsePrimitive();
    name2variable[name] = primitive;
    tokens.consumeEnd();

    // body
    Expression body = parseExpression();

    return new LetPrim(primitive)..plug(body);
  }

  Primitive parsePrimitive() {
    assert(tokens.current == "(");

    switch (tokens.next) {
      case CONSTANT:
        return parseConstant();
      case CREATE_FUNCTION:
        return parseCreateFunction();
      case GET_CLOSURE_VARIABLE:
        return parseGetClosureVariable();
      case LITERAL_LIST:
        return parseLiteralList();
      case LITERAL_MAP:
        return parseLiteralMap();
      case REIFY_TYPE_VAR:
        return parseReifyTypeVar();
      case THIS:
        return parseThis();
      default:
        assert(false);
    }

    return null;
  }

  /// (Constant (constant))
  Constant parseConstant() {
    tokens.consumeStart(CONSTANT);
    String tag = tokens.read();

    if (tag == "null") {
      tokens.consumeEnd();
      return new Constant(null, new dart2js.NullConstant());
    }

    if (tag == "StringConstant") {
      tokens.consumeStart();
      List<String> strings = <String>[];
      do {
        strings.add(tokens.read());
      } while (tokens.current != ")");
      tokens.consumeEnd();

      String string = strings.join(" ");
      assert(string.startsWith('"') && string.endsWith('"'));

      dart2js.StringConstant value = new dart2js.StringConstant(
          new LiteralDartString(string.substring(1, string.length - 1)));

      tokens.consumeEnd();
      return new Constant(null, value);
    }

    // IntConstant.
    int intValue = int.parse(tag, onError: (_) => null);
    if (intValue != null) {
      tokens.consumeEnd();
      return new Constant(null, new dart2js.IntConstant(intValue));
    }

    // DoubleConstant.
    double doubleValue = double.parse(tag, (_) => null);
    if (doubleValue != null) {
      tokens.consumeEnd();
      return new Constant(null, new dart2js.DoubleConstant(doubleValue));
    }

    assert(false);
    return null;
  }

  /// (CreateFunction (definition))
  CreateFunction parseCreateFunction() {
    tokens.consumeStart(CREATE_FUNCTION);
    FunctionDefinition def = parseFunctionDefinition();
    tokens.consumeEnd();
    return new CreateFunction(def);
  }

  /// (GetClosureVariable name)
  GetClosureVariable parseGetClosureVariable() {
    tokens.consumeStart(GET_CLOSURE_VARIABLE);

    Local local = new DummyLocal(tokens.read());
    tokens.consumeEnd();

    return new GetClosureVariable(local);
  }

  /// (LiteralList values)
  LiteralList parseLiteralList() {
    tokens.consumeStart(LITERAL_LIST);
    List<Primitive> values = parsePrimitiveList();
    tokens.consumeEnd();
    return new LiteralList(null, values);
  }

  /// (LiteralMap keys values)
  LiteralMap parseLiteralMap() {
    tokens.consumeStart(LITERAL_MAP);

    List<Primitive> keys   = parsePrimitiveList();
    List<Primitive> values = parsePrimitiveList();

    tokens.consumeEnd();
    return new LiteralMap(null, keys, values);
  }

  /// (ReifyTypeVar type)
  ReifyTypeVar parseReifyTypeVar() {
    tokens.consumeStart(REIFY_TYPE_VAR);

    TypeVariableElement type = new DummyElement(tokens.read());

    tokens.consumeEnd();
    return new ReifyTypeVar(type);
  }

  /// (This)
  This parseThis() {
    tokens.consumeStart(THIS);
    tokens.consumeEnd();
    return new This();
  }
}
