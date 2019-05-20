// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.selector;

import '../common.dart';
import '../common/names.dart' show Names;
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../elements/names.dart';
import '../elements/operators.dart';
import '../kernel/invocation_mirror_constants.dart';
import '../serialization/serialization.dart';
import '../util/util.dart' show Hashing;
import 'call_structure.dart' show CallStructure;

class SelectorKind {
  final String name;
  @override
  final int hashCode;
  const SelectorKind(this.name, this.hashCode);

  static const SelectorKind GETTER = const SelectorKind('getter', 0);
  static const SelectorKind SETTER = const SelectorKind('setter', 1);
  static const SelectorKind CALL = const SelectorKind('call', 2);
  static const SelectorKind OPERATOR = const SelectorKind('operator', 3);
  static const SelectorKind INDEX = const SelectorKind('index', 4);
  static const SelectorKind SPECIAL = const SelectorKind('special', 5);

  int get index => hashCode;

  @override
  String toString() => name;

  static List<SelectorKind> values = const <SelectorKind>[
    GETTER,
    SETTER,
    CALL,
    OPERATOR,
    INDEX,
    SPECIAL
  ];
}

class Selector {
  /// Tag used for identifying serialized [Selector] objects in a debugging
  /// data stream.
  static const String tag = 'selector';

  final SelectorKind kind;
  final Name memberName;
  final CallStructure callStructure;

  @override
  final int hashCode;

  int get argumentCount => callStructure.argumentCount;
  int get namedArgumentCount => callStructure.namedArgumentCount;
  int get positionalArgumentCount => callStructure.positionalArgumentCount;
  int get typeArgumentCount => callStructure.typeArgumentCount;
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
      throw failedAt(element, "Can't get selector from $element");
    }
  }

  factory Selector.getter(Name name) =>
      new Selector(SelectorKind.GETTER, name.getter, CallStructure.NO_ARGS);

  factory Selector.setter(Name name) =>
      new Selector(SelectorKind.SETTER, name.setter, CallStructure.ONE_ARG);

  factory Selector.unaryOperator(String name) => new Selector(
      SelectorKind.OPERATOR,
      new PublicName(utils.constructOperatorName(name, true)),
      CallStructure.NO_ARGS);

  factory Selector.binaryOperator(String name) => new Selector(
      SelectorKind.OPERATOR,
      new PublicName(utils.constructOperatorName(name, false)),
      CallStructure.ONE_ARG);

  factory Selector.index() =>
      new Selector(SelectorKind.INDEX, Names.INDEX_NAME, CallStructure.ONE_ARG);

  factory Selector.indexSet() => new Selector(
      SelectorKind.INDEX, Names.INDEX_SET_NAME, CallStructure.TWO_ARGS);

  factory Selector.call(Name name, CallStructure callStructure) =>
      new Selector(SelectorKind.CALL, name, callStructure);

  factory Selector.callClosure(int arity,
          [List<String> namedArguments, int typeArgumentCount = 0]) =>
      new Selector(SelectorKind.CALL, Names.call,
          new CallStructure(arity, namedArguments, typeArgumentCount));

  factory Selector.callClosureFrom(Selector selector) =>
      new Selector(SelectorKind.CALL, Names.call, selector.callStructure);

  factory Selector.callConstructor(Name name,
          [int arity = 0, List<String> namedArguments]) =>
      new Selector(
          SelectorKind.CALL, name, new CallStructure(arity, namedArguments));

  factory Selector.callDefaultConstructor() => new Selector(
      SelectorKind.CALL, const PublicName(''), CallStructure.NO_ARGS);

  // TODO(31953): Remove this if we can implement via static calls.
  factory Selector.genericInstantiation(int typeArguments) => new Selector(
      SelectorKind.SPECIAL,
      Names.genericInstantiation,
      new CallStructure(0, null, typeArguments));

  /// Deserializes a [Selector] object from [source].
  factory Selector.readFromDataSource(DataSource source) {
    source.begin(tag);
    SelectorKind kind = source.readEnum(SelectorKind.values);
    bool isSetter = source.readBool();
    LibraryEntity library = source.readLibraryOrNull();
    String text = source.readString();
    CallStructure callStructure = new CallStructure.readFromDataSource(source);
    source.end(tag);
    return new Selector(
        kind, new Name(text, library, isSetter: isSetter), callStructure);
  }

  /// Serializes this [Selector] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    sink.writeBool(memberName.isSetter);
    sink.writeLibraryOrNull(memberName.library);
    sink.writeString(memberName.text);
    callStructure.writeToDataSink(sink);
    sink.end(tag);
  }

  bool get isGetter => kind == SelectorKind.GETTER;
  bool get isSetter => kind == SelectorKind.SETTER;
  bool get isCall => kind == SelectorKind.CALL;
  bool get isClosureCall => isCall && memberName == Names.CALL_NAME;

  bool get isIndex => kind == SelectorKind.INDEX && argumentCount == 1;
  bool get isIndexSet => kind == SelectorKind.INDEX && argumentCount == 2;

  bool get isOperator => kind == SelectorKind.OPERATOR;
  bool get isUnaryOperator => isOperator && argumentCount == 0;

  /// The member name for invocation mirrors created from this selector.
  String get invocationMirrorMemberName => isSetter ? '$name=' : name;

  int get invocationMirrorKind {
    int kind = invocationMirrorMethodKind;
    if (isGetter) {
      kind = invocationMirrorGetterKind;
    } else if (isSetter) {
      kind = invocationMirrorSetterKind;
    }
    return kind;
  }

  bool appliesUnnamed(MemberEntity element) {
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

  /// Whether [this] could be a valid selector on `Null` without throwing.
  bool appliesToNullWithoutThrow() {
    var name = this.name;
    if (isOperator && name == "==") return true;
    // Known getters and valid tear-offs.
    if (isGetter &&
        (name == "hashCode" ||
            name == "runtimeType" ||
            name == "toString" ||
            name == "noSuchMethod")) return true;
    // Calling toString always succeeds, calls to `noSuchMethod` (even well
    // formed calls) always throw.
    if (isCall &&
        name == "toString" &&
        positionalArgumentCount == 0 &&
        namedArgumentCount == 0) {
      return true;
    }
    return false;
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

  @override
  String toString() {
    return 'Selector($kind, $name, ${callStructure.structureToString()})';
  }

  /// Returns the normalized version of this selector.
  ///
  /// A selector is normalized if its call structure is normalized.
  // TODO(johnniwinther): Use normalized selectors as much as possible,
  // especially where selectors are used in sets or as keys in maps.
  Selector toNormalized() => callStructure.isNormalized
      ? this
      : new Selector(kind, memberName, callStructure.toNormalized());

  Selector toCallSelector() => new Selector.callClosureFrom(this);

  /// Returns the non-generic [Selector] corresponding to this selector.
  Selector toNonGeneric() {
    return callStructure.typeArgumentCount > 0
        ? new Selector(kind, memberName, callStructure.nonGeneric)
        : this;
  }
}
