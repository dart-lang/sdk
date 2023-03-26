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
  final int index;
  const SelectorKind(this.name, this.index);

  static const SelectorKind GETTER = SelectorKind('getter', 0);
  static const SelectorKind SETTER = SelectorKind('setter', 1);
  static const SelectorKind CALL = SelectorKind('call', 2);
  static const SelectorKind OPERATOR = SelectorKind('operator', 3);
  static const SelectorKind INDEX = SelectorKind('index', 4);
  static const SelectorKind SPECIAL = SelectorKind('special', 5);

  @override
  int get hashCode => index;

  @override
  String toString() => name;

  static const List<SelectorKind> values = [
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

  static bool isOperatorName(String name) {
    return instanceMethodOperatorNames.contains(name);
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
      Map<int, List<Selector>>();

  factory Selector(SelectorKind kind, Name name, CallStructure callStructure) {
    // TODO(johnniwinther): Maybe use equality instead of implicit hashing.
    int hashCode = computeHashCode(kind, name, callStructure);
    List<Selector> list = canonicalizedValues.putIfAbsent(hashCode, () => []);
    for (int i = 0; i < list.length; i++) {
      Selector existing = list[i];
      if (existing.match(kind, name, callStructure)) {
        assert(existing.hashCode == hashCode);
        return existing;
      }
    }
    Selector result = Selector.internal(kind, name, callStructure, hashCode);
    list.add(result);
    return result;
  }

  factory Selector.fromElement(MemberEntity element) {
    Name name = element.memberName;
    if (element.isFunction) {
      FunctionEntity function = element as FunctionEntity;
      if (name == Names.INDEX_NAME) {
        return Selector.index();
      } else if (name == Names.INDEX_SET_NAME) {
        return Selector.indexSet();
      }
      CallStructure callStructure = function.parameterStructure.callStructure;
      if (isOperatorName(element.name!)) {
        // Operators cannot have named arguments, however, that doesn't prevent
        // a user from declaring such an operator.
        return Selector(SelectorKind.OPERATOR, name, callStructure);
      } else {
        return Selector.call(name, callStructure);
      }
    } else if (element.isSetter) {
      return Selector.setter(name);
    } else if (element.isGetter) {
      return Selector.getter(name);
    } else if (element is FieldEntity) {
      return Selector.getter(name);
    } else if (element is ConstructorEntity) {
      return Selector.callConstructor(name);
    } else {
      throw failedAt(element, "Cannot get selector from $element");
    }
  }

  factory Selector.getter(Name name) =>
      Selector(SelectorKind.GETTER, name.getter, CallStructure.NO_ARGS);

  factory Selector.setter(Name name) =>
      Selector(SelectorKind.SETTER, name.setter, CallStructure.ONE_ARG);

  factory Selector.unaryOperator(String name) => Selector(
      SelectorKind.OPERATOR,
      PublicName(utils.constructOperatorName(name, true)),
      CallStructure.NO_ARGS);

  factory Selector.binaryOperator(String name) => Selector(
      SelectorKind.OPERATOR,
      PublicName(utils.constructOperatorName(name, false)),
      CallStructure.ONE_ARG);

  factory Selector.index() =>
      Selector(SelectorKind.INDEX, Names.INDEX_NAME, CallStructure.ONE_ARG);

  factory Selector.indexSet() => Selector(
      SelectorKind.INDEX, Names.INDEX_SET_NAME, CallStructure.TWO_ARGS);

  factory Selector.call(Name name, CallStructure callStructure) =>
      Selector(SelectorKind.CALL, name, callStructure);

  factory Selector.callClosure(int arity,
          [List<String>? namedArguments, int typeArgumentCount = 0]) =>
      Selector(SelectorKind.CALL, Names.call,
          CallStructure(arity, namedArguments, typeArgumentCount));

  factory Selector.callClosureFrom(Selector selector) =>
      Selector(SelectorKind.CALL, Names.call, selector.callStructure);

  factory Selector.callConstructor(Name name,
          [int arity = 0, List<String>? namedArguments]) =>
      Selector(SelectorKind.CALL, name, CallStructure(arity, namedArguments));

  factory Selector.callDefaultConstructor() =>
      Selector(SelectorKind.CALL, const PublicName(''), CallStructure.NO_ARGS);

  // TODO(31953): Remove this if we can implement via static calls.
  factory Selector.genericInstantiation(int typeArguments) => Selector(
      SelectorKind.SPECIAL,
      Names.genericInstantiation,
      CallStructure(0, null, typeArguments));

  /// Deserializes a [Selector] object from [source].
  factory Selector.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    SelectorKind kind = source.readEnum(SelectorKind.values);
    Name memberName = source.readMemberName();
    CallStructure callStructure = CallStructure.readFromDataSource(source);
    source.end(tag);
    return Selector(kind, memberName, callStructure);
  }

  /// Serializes this [Selector] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    sink.writeMemberName(memberName);
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
    if (!memberName.matches(element.memberName)) {
      return false;
    }
    return appliesStructural(element);
  }

  bool appliesStructural(MemberEntity element) {
    assert(name == element.name);
    if (element.isSetter) return isSetter;
    if (element.isGetter) return isGetter || isCall;
    if (element is FieldEntity) {
      return isSetter ? element.isAssignable : isGetter || isCall;
    }
    if (isGetter) return true;
    if (isSetter) return false;
    return signatureApplies(element as FunctionEntity);
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
      : Selector(kind, memberName, callStructure.toNormalized());

  Selector toCallSelector() => Selector.callClosureFrom(this);

  /// Returns the non-generic [Selector] corresponding to this selector.
  Selector toNonGeneric() {
    return callStructure.typeArgumentCount > 0
        ? Selector(kind, memberName, callStructure.nonGeneric)
        : this;
  }
}
