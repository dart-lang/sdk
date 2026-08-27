// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/js/size_estimator.dart';
import 'package:compiler/src/js_backend/namer.dart';
import 'package:expect/expect.dart';
import 'package:js_ast/js_ast.dart';

/// Regression tests for size estimation during fragment merging.
///
/// With `--merge-fragments-threshold` and `--minify`, [SizeEstimator] can run
/// before all [Name] nodes have readable text. These tests construct unfinalized
/// [ModularName], [_PrefixedName], and [CompoundName] shapes directly. Without
/// the `_hasReadableNameText` guard in [SizeEstimator.literalStringToString],
/// [estimateSize] throws:
///
///     Null check operator used on a null value
///
/// Stock dart2js end-to-end compiles (including the deferred `many_parts`
/// fixture) do not hit this path; production crashes required a large minified
/// deferred program (threshold=80).
void main() {
  literalStringFromNameWithTransitivelyUnfinalizedModularName();
  literalStringFromNameWithPrefixedNameAndUnfinalizedBase();
  literalStringFromNameWithCompoundName();
  literalStringFromNameWithReadableModularName();
}

/// `###:null` — placeholder name estimate plus object-literal punctuation.
const int _placeholderPropertySize = 8;

Property _propertyWithLiteralName(Name name) {
  return Property(LiteralStringFromName(name), LiteralNull());
}

void literalStringFromNameWithTransitivelyUnfinalizedModularName() {
  final tokenName = TokenName(TokenScope(), 'testKey');
  final modularName = ModularName(ModularNameKind.asName, data: 'foo');
  modularName.value = tokenName;

  Expect.isTrue(modularName.isFinalized);
  Expect.isFalse(tokenName.isFinalized);

  final property = _propertyWithLiteralName(modularName);
  Expect.isTrue((property.name as LiteralStringFromName).isFinalized);

  // Before the fix this threw: Null check operator used on a null value.
  Expect.equals(_placeholderPropertySize, estimateSize(property));

  tokenName.finalize();
  Expect.equals(6, estimateSize(property)); // `a:null`
}

void literalStringFromNameWithPrefixedNameAndUnfinalizedBase() {
  final tokenName = TokenName(TokenScope(), 'holderKey');
  final prefixedName = GetterName(StringBackedName('h'), tokenName);
  final modularName = ModularName(ModularNameKind.asName, data: 'foo');
  modularName.value = prefixedName;

  Expect.isTrue(modularName.isFinalized);
  Expect.isFalse(prefixedName.isFinalized);
  Expect.isFalse(tokenName.isFinalized);

  // Same shape as the production crash: ModularName -> _PrefixedName -> leaf.
  Expect.equals(
    _placeholderPropertySize,
    estimateSize(_propertyWithLiteralName(modularName)),
  );

  tokenName.finalize();
  Expect.equals(8, estimateSize(_propertyWithLiteralName(modularName))); // `ha:null`
}

void literalStringFromNameWithCompoundName() {
  final tokenName = TokenName(TokenScope(), 'partKey');
  final modularName = ModularName(ModularNameKind.asName, data: 'part');
  modularName.value = tokenName;
  final compound = CompoundName([modularName, StringBackedName('suffix')]);

  Expect.isTrue(compound.isFinalized);
  Expect.isFalse(tokenName.isFinalized);

  final property = _propertyWithLiteralName(compound);
  Expect.equals(_placeholderPropertySize, estimateSize(property));

  tokenName.finalize();
  Expect.equals(12, estimateSize(property)); // `asuffix:null`
}

void literalStringFromNameWithReadableModularName() {
  final modularName = ModularName(ModularNameKind.asName, data: 'foo');
  modularName.value = StringBackedName('bar');

  Expect.equals(8, estimateSize(_propertyWithLiteralName(modularName))); // `bar:null`
}
