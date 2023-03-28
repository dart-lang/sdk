// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:matcher/matcher.dart';

import '../../../tool/lsp_spec/meta_model.dart';

Matcher isArrayOf(Matcher matcher) => ArrayTypeMatcher(wrapMatcher(matcher));

Matcher isLiteralOf(Matcher typeMatcher, String value) =>
    LiteralTypeMatcher(typeMatcher, value);

Matcher isMapOf(Matcher indexMatcher, Matcher valueMatcher) =>
    MapTypeMatcher(wrapMatcher(indexMatcher), wrapMatcher(valueMatcher));

Matcher isResponseError(ErrorCodes code, {String? message}) {
  final matcher = const TypeMatcher<ResponseError>()
      .having((e) => e.code, 'code', equals(code));
  return message != null
      ? matcher.having((e) => e.message, 'message', equals(message))
      : matcher;
}

Matcher isSimpleType(String name) => SimpleTypeMatcher(name);

class ArrayTypeMatcher extends Matcher {
  final Matcher _elementTypeMatcher;
  const ArrayTypeMatcher(this._elementTypeMatcher);

  @override
  Description describe(Description description) =>
      description.add('an array of ').addDescriptionOf(_elementTypeMatcher);

  @override
  Description describeMismatch(item, Description mismatchDescription,
      Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is ArrayType) {
      return _elementTypeMatcher.describeMismatch(
          item, mismatchDescription, matchState, verbose);
    } else {
      return mismatchDescription.add('is not an ArrayType');
    }
  }

  @override
  bool matches(item, Map<dynamic, dynamic> matchState) {
    return item is ArrayType &&
        _elementTypeMatcher.matches(item.elementType, matchState);
  }
}

class LiteralTypeMatcher extends Matcher {
  final Matcher _typeMatcher;
  final String _value;
  LiteralTypeMatcher(this._typeMatcher, this._value);

  @override
  Description describe(Description description) => description
      .add('a literal where type is ')
      .addDescriptionOf(_typeMatcher)
      .add(' and value is $_value');

  @override
  bool matches(item, Map<dynamic, dynamic> matchState) {
    return item is LiteralType &&
        _typeMatcher.matches(item.type, matchState) &&
        item.valueAsLiteral == _value;
  }
}

class MapTypeMatcher extends Matcher {
  final Matcher _indexMatcher, _valueMatcher;
  const MapTypeMatcher(this._indexMatcher, this._valueMatcher);

  @override
  Description describe(Description description) => description
      .add('a MapType where index is ')
      .addDescriptionOf(_indexMatcher)
      .add(' and value is ')
      .addDescriptionOf(_valueMatcher);

  @override
  bool matches(item, Map<dynamic, dynamic> matchState) {
    return item is MapType &&
        _indexMatcher.matches(item.indexType, matchState) &&
        _valueMatcher.matches(item.valueType, matchState);
  }
}

class SimpleTypeMatcher extends Matcher {
  final String _expectedName;
  const SimpleTypeMatcher(this._expectedName);

  @override
  Description describe(Description description) =>
      description.add('a type with the name $_expectedName');

  @override
  Description describeMismatch(item, Description mismatchDescription,
      Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is TypeReference) {
      return mismatchDescription
          .add('has the name ')
          .addDescriptionOf(item.name);
    } else {
      return mismatchDescription.add('is not a Type');
    }
  }

  @override
  bool matches(item, Map<dynamic, dynamic> matchState) {
    return item is TypeReference && item.name == _expectedName;
  }
}
