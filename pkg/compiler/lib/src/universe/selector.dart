// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.selector;

import '../common.dart';
import '../common/names.dart' show Names;
import '../elements/elements.dart' show Elements;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/operators.dart';
import '../util/util.dart' show Hashing;
import 'call_structure.dart' show CallStructure;

class SelectorKind {
  final String name;
  final int hashCode;
  const SelectorKind(this.name, this.hashCode);

  static const SelectorKind GETTER = const SelectorKind('getter', 0);
  static const SelectorKind SETTER = const SelectorKind('setter', 1);
  static const SelectorKind CALL = const SelectorKind('call', 2);
  static const SelectorKind OPERATOR = const SelectorKind('operator', 3);
  static const SelectorKind INDEX = const SelectorKind('index', 4);

  int get index => hashCode;

  String toString() => name;

  static List<SelectorKind> values = const <SelectorKind>[
    GETTER,
    SETTER,
    CALL,
    OPERATOR,
    INDEX
  ];
}

class Selector {
  final SelectorKind kind;
  final Name memberName;
  final CallStructure callStructure;

  final int hashCode;

  int get argumentCount => callStructure.argumentCount;
  int get namedArgumentCount => callStructure.namedArgumentCount;
  int get positionalArgumentCount => callStructure.positionalArgumentCount;
  List<String> get namedArguments => callStructure.namedArguments;

  String get name => memberName.text;

  LibraryEntity get library => memberName.library;

  static bool isOperatorName(String name) {
    if (name == Names.INDEX_SET_NAME.text) {
      return true;
    } else if (name == UnaryOperator.NEGATE.selectorName) {
      return true;
    } else if (name == UnaryOperator.COMPLEMENT.selectorName) {
      return true;
    } else {
      return BinaryOperator.parseUserDefinable(name) != null;
    }
  }

  Selector.internal(
      this.kind, this.memberName, this.callStructure, this.hashCode) {
    assert(
        kind == SelectorKind.INDEX ||
            (memberName != Names.INDEX_NAME &&
                memberName != Names.INDEX_SET_NAME),
        failedAt(NO_LOCATION_SPANNABLE,
            "kind=$kind,memberName=$memberName,callStructure:$callStructure"));
    assert(
        kind == SelectorKind.OPERATOR ||
            kind == SelectorKind.INDEX ||
            !isOperatorName(memberName.text) ||
            memberName.text == '??',
        failedAt(NO_LOCATION_SPANNABLE,
            "kind=$kind,memberName=$memberName,callStructure:$callStructure"));
    assert(
        kind == SelectorKind.CALL ||
            kind == SelectorKind.GETTER ||
            kind == SelectorKind.SETTER ||
            isOperatorName(memberName.text) ||
            memberName.text == '??',
        failedAt(NO_LOCATION_SPANNABLE,
            "kind=$kind,memberName=$memberName,callStructure:$callStructure"));
  }

  // TODO(johnniwinther): Extract caching.
  static Map<int, List<Selector>> canonicalizedValues =
      new Map<int, List<Selector>>();

  factory Selector(SelectorKind kind, Name name, CallStructure callStructure) {
    // TODO(johnniwinther): Maybe use equality instead of implicit hashing.
    int hashCode = computeHashCode(kind, name, callStructure);
    List<Selector> list =
        canonicalizedValues.putIfAbsent(hashCode, () => <Selector>[]);
    for (int i = 0; i < list.length; i++) {
      Selector existing = list[i];
      if (existing.match(kind, name, callStructure)) {
        assert(existing.hashCode == hashCode);
        return existing;
      }
    }
    Selector result =
        new Selector.internal(kind, name, callStructure, hashCode);
    list.add(result);
    return result;
  }

  factory Selector.fromElement(MemberEntity element) {
    Name name = element.memberName;
    if (element.isFunction) {
      FunctionEntity function = element;
      if (name == Names.INDEX_NAME) {
        return new Selector.index();
      } else if (name == Names.INDEX_SET_NAME) {
        return new Selector.indexSet();
      }
      CallStructure callStructure = function.parameterStructure.callStructure;
      if (isOperatorName(element.name)) {
        // Operators cannot have named arguments, however, that doesn't prevent
        // a user from declaring such an operator.
        return new Selector(SelectorKind.OPERATOR, name, callStructure);
      } else {
        return new Selector.call(name, callStructure);
      }
    } else if (element.isSetter) {
      return new Selector.setter(name);
    } else if (element.isGetter) {
      return new Selector.getter(name);
    } else if (element.isField) {
      return new Selector.getter(name);
    } else if (element.isConstructor) {
      return new Selector.callConstructor(name);
    } else {
      throw new SpannableAssertionFailure(
          element, "Can't get selector from $element");
    }
  }

  factory Selector.getter(Name name) =>
      new Selector(SelectorKind.GETTER, name.getter, CallStructure.NO_ARGS);

  factory Selector.setter(Name name) =>
      new Selector(SelectorKind.SETTER, name.setter, CallStructure.ONE_ARG);

  factory Selector.unaryOperator(String name) => new Selector(
      SelectorKind.OPERATOR,
      new PublicName(Elements.constructOperatorName(name, true)),
      CallStructure.NO_ARGS);

  factory Selector.binaryOperator(String name) => new Selector(
      SelectorKind.OPERATOR,
      new PublicName(Elements.constructOperatorName(name, false)),
      CallStructure.ONE_ARG);

  factory Selector.index() =>
      new Selector(SelectorKind.INDEX, Names.INDEX_NAME, CallStructure.ONE_ARG);

  factory Selector.indexSet() => new Selector(
      SelectorKind.INDEX, Names.INDEX_SET_NAME, CallStructure.TWO_ARGS);

  factory Selector.call(Name name, CallStructure callStructure) =>
      new Selector(SelectorKind.CALL, name, callStructure);

  factory Selector.callClosure(int arity, [List<String> namedArguments]) =>
      new Selector(SelectorKind.CALL, Names.call,
          new CallStructure(arity, namedArguments));

  factory Selector.callClosureFrom(Selector selector) =>
      new Selector(SelectorKind.CALL, Names.call, selector.callStructure);

  factory Selector.callConstructor(Name name,
          [int arity = 0, List<String> namedArguments]) =>
      new Selector(
          SelectorKind.CALL, name, new CallStructure(arity, namedArguments));

  factory Selector.callDefaultConstructor() => new Selector(
      SelectorKind.CALL, const PublicName(''), CallStructure.NO_ARGS);

  bool get isGetter => kind == SelectorKind.GETTER;
  bool get isSetter => kind == SelectorKind.SETTER;
  bool get isCall => kind == SelectorKind.CALL;
  bool get isClosureCall => isCall && memberName == Names.CALL_NAME;

  bool get isIndex => kind == SelectorKind.INDEX && argumentCount == 1;
  bool get isIndexSet => kind == SelectorKind.INDEX && argumentCount == 2;

  bool get isOperator => kind == SelectorKind.OPERATOR;
  bool get isUnaryOperator => isOperator && argumentCount == 0;

  /**
   * The member name for invocation mirrors created from this selector.
   */
  String get invocationMirrorMemberName => isSetter ? '$name=' : name;

  int get invocationMirrorKind {
    const int METHOD = 0;
    const int GETTER = 1;
    const int SETTER = 2;
    int kind = METHOD;
    if (isGetter) {
      kind = GETTER;
    } else if (isSetter) {
      kind = SETTER;
    }
    return kind;
  }

  bool appliesUnnamed(MemberEntity element) {
    assert(name == element.name);
    return appliesUntyped(element);
  }

  bool appliesUntyped(MemberEntity element) {
    assert(name == element.name);
    if (memberName.isPrivate && memberName.library != element.library) {
      // TODO(johnniwinther): Maybe this should be
      // `memberName != element.memberName`.
      return false;
    }
    if (element.isSetter) return isSetter;
    if (element.isGetter) return isGetter || isCall;
    if (element.isField) {
      return isSetter ? element.isAssignable : isGetter || isCall;
    }
    if (isGetter) return true;
    if (isSetter) return false;
    return signatureApplies(element);
  }

  bool signatureApplies(FunctionEntity function) {
    return callStructure.signatureApplies(function.parameterStructure);
  }

  bool applies(MemberEntity element) {
    if (name != element.name) return false;
    return appliesUnnamed(element);
  }

  bool match(SelectorKind kind, Name memberName, CallStructure callStructure) {
    return this.kind == kind &&
        this.memberName == memberName &&
        this.callStructure.match(callStructure);
  }

  static int computeHashCode(
      SelectorKind kind, Name name, CallStructure callStructure) {
    // Add bits from name and kind.
    int hash = Hashing.mixHashCodeBits(name.hashCode, kind.hashCode);
    // Add bits from the call structure.
    return Hashing.mixHashCodeBits(hash, callStructure.hashCode);
  }

  String toString() {
    return 'Selector($kind, $name, ${callStructure.structureToString()})';
  }

  Selector toCallSelector() => new Selector.callClosureFrom(this);
}
