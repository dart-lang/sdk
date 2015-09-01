// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SExpressionUnstringifier implements the inverse operation to
// [SExpressionStringifier].

library sexpr_unstringifier;

import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/dart_types.dart' as dart_types
    show DartType;
import 'package:compiler/src/diagnostics/messages.dart'
    show MessageKind;
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/modelx.dart'
    show ErroneousElementX, TypeVariableElementX;
import 'package:compiler/src/tree/tree.dart' show LiteralDartString;
import 'package:compiler/src/universe/universe.dart'
    show Selector, SelectorKind, CallStructure;
import 'package:compiler/src/cps_ir/cps_ir_nodes.dart';

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

// TODO(karlklose): we should remove all references to [ErroneousElement] from
// the CPS IR.  Instead, the builder must construct appropriate terms for ASTs
// that could not be resolved correctly.  Perhaps the IR should not rely on
// elements at all for naming.
/// Used whenever a node constructed by [SExpressionUnstringifier] requires
/// an [Element] or [FunctionElement]. Extends [ErroneousElementX] since there
/// is currently a large amount of overhead when extending the base abstract
/// classes, and erroneous elements conveniently also skip several assertion
/// checks in CPS IR nodes that are irrelevant to us.
class DummyElement extends ErroneousElementX
    implements TypeVariableElement, FieldElement {
  DummyElement(String name)
      : super(MessageKind.GENERIC, {}, name, null);

  final dart_types.DartType bound = null;
  final TypeDeclarationElement typeDeclaration = null;

  noSuchMethod(inv) => super.noSuchMethod(inv);
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
      if (current != expected) {
        print('expected "$expected", found "$current"');
        int start = _index - 15;
        String dotdotdot = '... ';
        if (start < 0) {
          start = 0;
          dotdotdot = '';
        }
        print('${dotdotdot}${_list.sublist(start, _index + 1).join(' ')}');
        assert(current == expected);
      }
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
  static const String INVOKE_STATIC = "InvokeStatic";
  static const String INVOKE_METHOD_DIRECTLY = "InvokeMethodDirectly";
  static const String INVOKE_METHOD = "InvokeMethod";
  static const String LET_PRIM = "LetPrim";
  static const String LET_CONT = "LetCont";
  static const String LET_MUTABLE = "LetMutable";
  static const String TYPE_CAST = "TypeCast";
  static const String GET_LAZY_STATIC = "GetLazyStatic";
  static const String UNREACHABLE = "Unreachable";

  // Primitives
  static const String CONSTANT = "Constant";
  static const String CREATE_FUNCTION = "CreateFunction";
  static const String GET_MUTABLE = "GetMutable";
  static const String SET_MUTABLE = "SetMutable";
  static const String LITERAL_LIST = "LiteralList";
  static const String LITERAL_MAP = "LiteralMap";
  static const String REIFY_TYPE_VAR = "ReifyTypeVar";
  static const String GET_STATIC = "GetStatic";
  static const String SET_STATIC = "SetStatic";
  static const String TYPE_TEST = "TypeTest";
  static const String APPLY_BUILTIN_OPERATOR = "ApplyBuiltinOperator";
  static const String GET_LENGTH = "GetLength";
  static const String GET_INDEX = "GetIndex";
  static const String SET_INDEX = "SetIndex";
  static const String GET_FIELD = "GetField";
  static const String SET_FIELD = "SetField";

  // Other
  static const String FUNCTION_DEFINITION = "FunctionDefinition";
  static const String IS_TRUE = "IsTrue";

  // Constants
  static const String BOOL = "Bool";
  static const String DOUBLE = "Double";
  static const String INT = "Int";
  static const String NULL = "Null";
  static const String STRING = "String";

  final Map<String, Definition> name2variable =
      <String, Definition>{ "return": new Continuation.retrn() };

  // Operator names used for canonicalization. In theory, we could simply use
  // Elements.isOperatorName() on the parsed tokens; however, comparisons are
  // done using identical() for performance reasons, which are reliable only for
  // compile-time literal strings.
  static Set<String> OPERATORS = new Set<String>.from(
      [ '~', '==', '[]', '*', '/', '%', '~/', '+', '<<', 'unary-'
      , '>>', '>=', '>', '<=', '<', '&', '^', '|', '[]=', '-'
      ]);

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
    SelectorKind kind;
    if (name == "[]") {
      kind = SelectorKind.INDEX;
    } else if (Elements.isOperatorName(name)) {
      kind = SelectorKind.OPERATOR;
    } else {
      kind = SelectorKind.CALL;
    }
    return new Selector(kind, new PublicName(name),
        new CallStructure.unnamed(argumentCount));
  }

  /// Returns the tokens in s. Note that string literals are not necessarily
  /// preserved; for instance, "(literalString)" is transformed to
  /// " ( literalString ) ".
  Tokens tokenize(String s) =>
      new Tokens(
          s.replaceAll("(", " ( ")
           .replaceAll(")", " ) ")
           .replaceAll("{", " { ")
           .replaceAll("}", " } ")
           .replaceAll(new RegExp(r"[ \t\n]+"), " ")
           .trim()
           .split(" ")
           .map(canonicalizeOperators)
           .toList());

  /// Canonicalizes strings containing operator names.
  String canonicalizeOperators(String token) {
    String opname = OPERATORS.lookup(token);
    if (opname != null) {
      return opname;
    }
    return token;
  }

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
        return parseInvokeContinuation();
      case INVOKE_METHOD:
        return parseInvokeMethod();
      case INVOKE_STATIC:
        return parseInvokeStatic();
      case INVOKE_METHOD_DIRECTLY:
        return parseInvokeMethodDirectly();
      case LET_PRIM:
        return parseLetPrim();
      case LET_CONT:
        return parseLetCont();
      case LET_MUTABLE:
        return parseLetMutable();
      case TYPE_CAST:
        return parseTypeCast();
      case GET_LAZY_STATIC:
        return parseGetLazyStatic();
      case UNREACHABLE:
        return parseUnreachable();
      default:
        assert(false);
    }

    return null;
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

  /// (FunctionDefinition name (parameters) continuation body)
  FunctionDefinition parseFunctionDefinition() {
    tokens.consumeStart(FUNCTION_DEFINITION);

    // name
    Element element = new DummyElement("");
    if (tokens.current != '(') {
      // This is a named function.
      element = new DummyElement(tokens.read());
    }

    // (this) or ()
    Definition thisParameter = null;
    tokens.consumeStart();
    if (tokens.current != ')') {
      String thisName = tokens.read();
      if (name2variable.containsKey(thisName)) {
        thisParameter = name2variable[thisName];
      } else {
        thisParameter = new Parameter(new DummyElement(thisName));
        name2variable[thisName] = thisParameter;
      }
    }
    tokens.consumeEnd();

    // (parameters)
    List<Definition> parameters = <Definition>[];
    tokens.consumeStart();
    while (tokens.current != ")") {
      String paramName = tokens.read();
      if (name2variable.containsKey(paramName)) {
        parameters.add(name2variable[paramName]);
      } else {
        Parameter param = new Parameter(new DummyElement(paramName));
        name2variable[paramName] = param;
        parameters.add(param);
      }
    }
    tokens.consumeEnd();

    // continuation
    String contName = tokens.read("return");
    Continuation cont = name2variable[contName];
    assert(cont != null);

    // body
    Expression body = parseExpression();

    tokens.consumeEnd();
    return new FunctionDefinition(element, thisParameter, parameters,
        new Body(body, cont), null, null);
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

  /// (ConcatenateStrings (args) cont)
  ConcatenateStrings parseConcatenateStrings() {
    tokens.consumeStart(CONCATENATE_STRINGS);

    List<Primitive> args = parsePrimitiveList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    return new ConcatenateStrings(args, cont);
  }

  /// (DeclareFunction name = function in body)
  DeclareFunction parseDeclareFunction() {
    tokens.consumeStart(DECLARE_FUNCTION);

    // name =
    MutableVariable local = addMutableVariable(tokens.read());
    tokens.read("=");

    // function in
    FunctionDefinition def = parseFunctionDefinition();
    tokens.read("in");

    // body
    Expression body = parseExpression();

    tokens.consumeEnd();
    return new DeclareFunction(local, def)..plug(body);
  }

  /// (InvokeConstructor name (args) cont)
  InvokeConstructor parseInvokeConstructor() {
    tokens.consumeStart(INVOKE_CONSTRUCTOR);

    String constructorName = tokens.read();
    List<String> split = constructorName.split(".");
    assert(split.length < 3);

    dart_types.DartType type = new DummyNamedType(split[0]);
    Element element = new DummyElement((split.length == 1) ? "" : split[1]);

    List<Primitive> args = parsePrimitiveList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    Selector selector = dummySelector(constructorName, args.length);
    return new InvokeConstructor(type, element, selector, args, cont);
  }

  /// (InvokeContinuation rec? name (args))
  InvokeContinuation parseInvokeContinuation() {
    tokens.consumeStart(INVOKE_CONTINUATION);
    String name = tokens.read();
    bool isRecursive = name == "rec";
    if (isRecursive) name = tokens.read();

    Continuation cont = name2variable[name];
    assert(cont != null);

    List<Primitive> args = parsePrimitiveList();

    tokens.consumeEnd();
    return new InvokeContinuation(cont, args, isRecursive: isRecursive);
  }

  /// (InvokeMethod receiver method (args) cont)
  InvokeMethod parseInvokeMethod() {
    tokens.consumeStart(INVOKE_METHOD);

    Definition receiver = name2variable[tokens.read()];
    assert(receiver != null);

    String methodName = tokens.read();

    List<Primitive> args = parsePrimitiveList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    Selector selector = dummySelector(methodName, args.length);
    return new InvokeMethod(receiver, selector, args, cont);
  }

  /// (InvokeStatic method (args) cont)
  InvokeStatic parseInvokeStatic() {
    tokens.consumeStart(INVOKE_STATIC);

    String methodName = tokens.read();

    List<Primitive> args = parsePrimitiveList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    Entity entity = new DummyEntity(methodName);
    Selector selector = dummySelector(methodName, args.length);

    tokens.consumeEnd();
    return new InvokeStatic(entity, selector, args, cont, null);
  }

  /// (InvokeMethodDirectly receiver method (args) cont)
  InvokeMethodDirectly parseInvokeMethodDirectly() {
    tokens.consumeStart(INVOKE_METHOD_DIRECTLY);

    Definition receiver = name2variable[tokens.read()];
    assert(receiver != null);

    String methodName = tokens.read();

    List<Primitive> args = parsePrimitiveList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    Element element = new DummyElement(methodName);
    Selector selector = dummySelector(methodName, args.length);
    return new InvokeMethodDirectly(receiver, element, selector, args, cont);
  }

  // (rec? name (args) body)
  Continuation parseContinuation() {
    // (rec? name
    tokens.consumeStart();
    String name = tokens.read();
    bool isRecursive = name == "rec";
    if (isRecursive) name = tokens.read();

    // (args)
    tokens.consumeStart();
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

    cont.isRecursive = isRecursive;
    // cont_body
    cont.body = parseExpression();
    tokens.consumeEnd();
    return cont;
  }

  /// (LetCont (continuations) body)
  LetCont parseLetCont() {
    tokens.consumeStart(LET_CONT);
    tokens.consumeStart();
    List<Continuation> continuations = <Continuation>[];
    while (tokens.current != ")") {
      continuations.add(parseContinuation());
    }
    tokens.consumeEnd();

    // body)
    Expression body = parseExpression();
    tokens.consumeEnd();

    return new LetCont.many(continuations, body);
  }

  /// (LetMutable (name value) body)
  LetMutable parseLetMutable() {
    tokens.consumeStart(LET_MUTABLE);

    tokens.consumeStart();
    String name = tokens.read();
    MutableVariable local = addMutableVariable(name);
    Primitive value = name2variable[tokens.read()];
    tokens.consumeEnd();

    Expression body = parseExpression();
    tokens.consumeEnd();
    return new LetMutable(local, value)..plug(body);
  }

  /// (SetMutable name value)
  SetMutable parseSetMutable() {
    tokens.consumeStart(SET_MUTABLE);

    MutableVariable local = name2variable[tokens.read()];
    Primitive value = name2variable[tokens.read()];
    assert(value != null);

    tokens.consumeEnd();
    return new SetMutable(local, value);
  }

  /// (TypeCast value type args cont)
  TypeCast parseTypeCast() {
    tokens.consumeStart(TYPE_CAST);

    Primitive value = name2variable[tokens.read()];
    assert(value != null);

    dart_types.DartType type = new DummyNamedType(tokens.read());

    List<ir.Primitive> typeArguments = parsePrimitiveList();

    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    return new TypeCast(value, type, typeArguments, cont);
  }

  /// (TypeTest value type args)
  TypeTest parseTypeTest() {
    tokens.consumeStart(TYPE_TEST);

    Primitive value = name2variable[tokens.read()];
    assert(value != null);

    dart_types.DartType type = new DummyNamedType(tokens.read());

    List<ir.Primitive> typeArguments = parsePrimitiveList();

    tokens.consumeEnd();
    return new TypeTest(value, type, typeArguments);
  }

  /// (ApplyBuiltinOperator operator args)
  ApplyBuiltinOperator parseApplyBuiltinOperator() {
    tokens.consumeStart(APPLY_BUILTIN_OPERATOR);

    String operatorName = tokens.read();
    BuiltinOperator operator;
    for (BuiltinOperator op in BuiltinOperator.values) {
      if (op.toString() == operatorName) {
        operator = op;
        break;
      }
    }
    assert(operator != null);
    List<ir.Primitive> arguments = parsePrimitiveList();

    tokens.consumeEnd();
    return new ApplyBuiltinOperator(operator, arguments);
  }

  /// (GetLength object)
  GetLength parseGetLength() {
    tokens.consumeStart(GET_LENGTH);
    Primitive object = name2variable[tokens.read()];
    tokens.consumeEnd();
    return new GetLength(object);
  }

  /// (GetIndex object index)
  GetIndex parseGetIndex() {
    tokens.consumeStart(GET_INDEX);
    Primitive object = name2variable[tokens.read()];
    Primitive index = name2variable[tokens.read()];
    tokens.consumeEnd();
    return new GetIndex(object, index);
  }

  /// (SetIndex object index value)
  SetIndex parseSetIndex() {
    tokens.consumeStart(SET_INDEX);
    Primitive object = name2variable[tokens.read()];
    Primitive index = name2variable[tokens.read()];
    Primitive value = name2variable[tokens.read()];
    tokens.consumeEnd();
    return new SetIndex(object, index, value);
  }

  /// (SetStatic field value)
  SetStatic parseSetStatic() {
    tokens.consumeStart(SET_STATIC);

    Element fieldElement = new DummyElement(tokens.read());
    Primitive value = name2variable[tokens.read()];
    assert(value != null);

    tokens.consumeEnd();
    return new SetStatic(fieldElement, value, null);
  }

  /// (GetLazyStatic field cont)
  GetLazyStatic parseGetLazyStatic() {
    tokens.consumeStart(GET_LAZY_STATIC);

    Element fieldElement = new DummyElement(tokens.read());
    Continuation cont = name2variable[tokens.read()];
    assert(cont != null);

    tokens.consumeEnd();
    return new GetLazyStatic(fieldElement, cont, null);
  }

  /// (Unreachable)
  Unreachable parseUnreachable() {
    tokens.consumeStart(UNREACHABLE);
    tokens.consumeEnd();
    return new Unreachable();
  }

  /// (LetPrim (name primitive) body)
  LetPrim parseLetPrim() {
    tokens.consumeStart(LET_PRIM);

    // (name
    tokens.consumeStart();
    String name = tokens.read();

    // primitive)
    Primitive primitive = parsePrimitive();
    name2variable[name] = primitive;
    tokens.consumeEnd();

    // body)
    Expression body = parseExpression();
    tokens.consumeEnd();

    return new LetPrim(primitive)..plug(body);
  }

  Primitive parsePrimitive() {
    assert(tokens.current == "(");

    switch (tokens.next) {
      case CONSTANT:
        return parseConstant();
      case CREATE_FUNCTION:
        return parseCreateFunction();
      case GET_MUTABLE:
        return parseGetMutable();
      case SET_MUTABLE:
        return parseSetMutable();
      case LITERAL_LIST:
        return parseLiteralList();
      case LITERAL_MAP:
        return parseLiteralMap();
      case REIFY_TYPE_VAR:
        return parseReifyTypeVar();
      case GET_STATIC:
        return parseGetStatic();
      case SET_STATIC:
        return parseSetStatic();
      case TYPE_TEST:
        return parseTypeTest();
      case APPLY_BUILTIN_OPERATOR:
        return parseApplyBuiltinOperator();
      case GET_LENGTH:
        return parseGetLength();
      case GET_INDEX:
        return parseGetIndex();
      case SET_INDEX:
        return parseSetIndex();
      case GET_FIELD:
        return parseGetField();
      case SET_FIELD:
        return parseSetField();
      default:
        assert(false);
    }

    return null;
  }

  /// (Constant (constant))
  Constant parseConstant() {
    tokens.consumeStart(CONSTANT);
    tokens.consumeStart();
    Constant result;
    String tag = tokens.read();
    switch (tag) {
      case NULL:
        result = new Constant(
            new NullConstantExpression(new NullConstantValue()));
        break;
      case BOOL:
        String value = tokens.read();
        if (value == "true") {
          result = new Constant(
              new BoolConstantExpression(true, new TrueConstantValue()));
        } else if (value == "false") {
          result = new Constant(
              new BoolConstantExpression(false, new FalseConstantValue()));
        } else {
          throw "Invalid Boolean value '$value'.";
        }
        break;
      case STRING:
        List<String> strings = <String>[];
        do {
          strings.add(tokens.read());
        } while (tokens.current != ")");
        String string = strings.join(" ");
        assert(string.startsWith('"') && string.endsWith('"'));
        String text = string.substring(1, string.length - 1);
        StringConstantValue value = new StringConstantValue(
            new LiteralDartString(text));
        result = new Constant(new StringConstantExpression(text, value));
        break;
      case INT:
        String value = tokens.read();
        int intValue = int.parse(value, onError: (_) => null);
        if (intValue == null) {
          throw "Invalid int value 'value'.";
        }
        result = new Constant(new IntConstantExpression(
            intValue, new IntConstantValue(intValue)));
        break;
      case DOUBLE:
        String value = tokens.read();
        double doubleValue = double.parse(value, (_) => null);
        if (doubleValue == null) {
          throw "Invalid double value '$value'.";
        }
        result = new Constant(new DoubleConstantExpression(
            doubleValue, new DoubleConstantValue(doubleValue)));
        break;
      default:
        throw "Unexpected constant tag '$tag'.";
    }
    tokens.consumeEnd();
    tokens.consumeEnd();
    return result;
  }

  /// (CreateFunction (definition))
  CreateFunction parseCreateFunction() {
    tokens.consumeStart(CREATE_FUNCTION);
    FunctionDefinition def = parseFunctionDefinition();
    tokens.consumeEnd();
    return new CreateFunction(def);
  }

  MutableVariable addMutableVariable(String name) {
    assert(!name2variable.containsKey(name));
    MutableVariable variable = new MutableVariable(new DummyElement(name));
    name2variable[name] = variable;
    return variable;
  }

  /// (GetMutable name)
  GetMutable parseGetMutable() {
    tokens.consumeStart(GET_MUTABLE);
    MutableVariable local = name2variable[tokens.read()];
    tokens.consumeEnd();

    return new GetMutable(local);
  }

  /// (LiteralList (values))
  LiteralList parseLiteralList() {
    tokens.consumeStart(LITERAL_LIST);
    List<Primitive> values = parsePrimitiveList();
    tokens.consumeEnd();
    return new LiteralList(null, values);
  }

  /// (LiteralMap (keys) (values))
  LiteralMap parseLiteralMap() {
    tokens.consumeStart(LITERAL_MAP);

    List<Primitive> keys   = parsePrimitiveList();
    List<Primitive> values = parsePrimitiveList();

    List<LiteralMapEntry> entries = <LiteralMapEntry>[];
    for (int i = 0; i < keys.length; i++) {
      entries.add(new LiteralMapEntry(keys[i], values[i]));
    }

    tokens.consumeEnd();
    return new LiteralMap(null, entries);
  }

  /// (ReifyTypeVar type)
  ReifyTypeVar parseReifyTypeVar() {
    tokens.consumeStart(REIFY_TYPE_VAR);

    TypeVariableElement type = new DummyElement(tokens.read());

    tokens.consumeEnd();
    return new ReifyTypeVar(type);
  }

  /// (GetStatic field)
  GetStatic parseGetStatic() {
    tokens.consumeStart(GET_STATIC);

    Element field = new DummyElement(tokens.read());

    tokens.consumeEnd();
    return new GetStatic(field, null);
  }

  /// (GetField object field)
  GetField parseGetField() {
    tokens.consumeStart(GET_FIELD);

    Primitive object = name2variable[tokens.read()];
    Element field = new DummyElement(tokens.read());

    tokens.consumeEnd();
    return new GetField(object, field);
  }

  /// (SetField object field value)
  SetField parseSetField() {
    tokens.consumeStart(SET_FIELD);

    Primitive object = name2variable[tokens.read()];
    Element field = new DummyElement(tokens.read());
    Primitive value = name2variable[tokens.read()];

    tokens.consumeEnd();
    return new SetField(object, field, value);
  }
}
