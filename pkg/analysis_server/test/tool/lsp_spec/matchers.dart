// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:matcher/matcher.dart';

import '../../../tool/lsp_spec/typescript_parser.dart';

Matcher isSimpleType(String name) => SimpleTypeMatcher(name);

class SimpleTypeMatcher extends Matcher {
  final String _expectedName;
  const SimpleTypeMatcher(this._expectedName);

  bool matches(item, Map matchState) {
    return item is Type && item.name == _expectedName;
  }

  Description describe(Description description) =>
      description.add('a type with the name $_expectedName');

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is Type) {
      return mismatchDescription
          .add('has the name ')
          .addDescriptionOf(item.name);
    } else {
      return mismatchDescription.add('is not a Type');
    }
  }
}

Matcher isArrayOf(Matcher matcher) => ArrayTypeMatcher(wrapMatcher(matcher));

class ArrayTypeMatcher extends Matcher {
  final Matcher _elementTypeMatcher;
  const ArrayTypeMatcher(this._elementTypeMatcher);

  bool matches(item, Map matchState) {
    return item is ArrayType &&
        _elementTypeMatcher.matches(item.elementType, matchState);
  }

  Description describe(Description description) =>
      description.add('an array of ').addDescriptionOf(_elementTypeMatcher);

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is ArrayType) {
      return _elementTypeMatcher.describeMismatch(
          item, mismatchDescription, matchState, verbose);
    } else {
      return mismatchDescription.add('is not an ArrayType');
    }
  }
}

Matcher isMapOf(Matcher indexMatcher, Matcher valueMatcher) =>
    MapTypeMatcher(wrapMatcher(indexMatcher), wrapMatcher(valueMatcher));

class MapTypeMatcher extends Matcher {
  final Matcher _indexMatcher, _valueMatcher;
  const MapTypeMatcher(this._indexMatcher, this._valueMatcher);

  bool matches(item, Map matchState) {
    return item is MapType &&
        _indexMatcher.matches(item.indexType, matchState) &&
        _valueMatcher.matches(item.valueType, matchState);
  }

  Description describe(Description description) => description
      .add('a MapType where index is ')
      .addDescriptionOf(_indexMatcher)
      .add(' and value is ')
      .addDescriptionOf(_valueMatcher);
}

Matcher isResponseError(ErrorCodes code) => const TypeMatcher<ResponseError>()
    .having((e) => e.code, 'code', equals(code));
