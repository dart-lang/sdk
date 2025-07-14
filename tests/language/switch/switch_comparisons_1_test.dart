// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for the SDK issue #61098, originally reported as
// Flutter issue #171803.
//
// Tests that the right comparison method (`identical` or `operator ==`) is used
// when comparing strings in switch statements and expressions.
//
// This is the smaller version of the original repro. More tests in
// `switch_comparisons_2_test.dart`.

import 'dart:convert';
import 'package:expect/expect.dart';

void main() {
  _option = utf8.decoder.convert([
    80,
    104,
    111,
    116,
    111,
    103,
    114,
    97,
    112,
    104,
    105,
    99,
    66,
    111,
    120,
  ]);

  Expect.isTrue(infoSwitchCaseWithNull);
  Expect.isTrue(infoSwitchCaseWithoutNull);
  Expect.isTrue(infoSwitchExpression);
  Expect.isTrue(infoIfCase);
  Expect.isTrue(infoIfEquals);
}

const kTypeString = 'PhotographicBox';

String? _option;

String? get type => _option;

bool get infoSwitchCaseWithNull {
  switch (type) {
    case kTypeString:
      return true;
    case null:
      throw 'Type is null on SWITCH CASE WITH NULL';
    default:
      throw 'Unexpected type on SWITCH CASE WITH NULL: $type';
  }
}

bool get infoSwitchCaseWithoutNull {
  switch (type) {
    case kTypeString:
      return true;
    default:
      throw 'Unexpected type on SWITCH CASE WITHOUT NULL: $type';
  }
}

bool get infoSwitchExpression {
  return switch (type) {
    kTypeString => true,
    null => throw 'Type is null with SWITCH EXPRESSION',
    _ => throw 'Unexpected type with SWITCH EXPRESSION: $type',
  };
}

bool get infoIfCase {
  if (type case kTypeString) {
    return true;
  } else if (type case null) {
    throw 'Type is null with IF CASE';
  } else {
    throw 'Unexpected type with IF CASE: $type';
  }
}

bool get infoIfEquals {
  if (type == kTypeString) {
    return true;
  } else if (type == null) {
    throw 'Type is null with IF';
  } else {
    throw 'Unexpected type with IF: $type';
  }
}
