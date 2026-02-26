// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for [JsonNumericMode] parameter in [jsonDecode] and [JsonDecoder].

import "package:expect/expect.dart";
import "dart:convert";

void main() {
  testPreserveTypeDefault();
  testAllDoubleMode();
  testAllDoubleModeWithReviver();
  testAllDoubleModeEdgeCases();
  testAllDoubleModeNestedStructures();
  testAllDoubleModeJsonCodec();
  testAllDoubleModeJsonDecoder();
  testBackwardsCompatibility();
}

/// Verify that the default behavior (preserveType) is unchanged.
void testPreserveTypeDefault() {
  // Default: integers stay as int.
  var result = jsonDecode('{"x": 5}');
  Expect.isTrue(result['x'] is int);
  Expect.equals(5, result['x']);

  // Default: doubles stay as double.
  result = jsonDecode('{"x": 5.0}');
  Expect.isTrue(result['x'] is double);
  Expect.equals(5.0, result['x']);

  // Explicit preserveType: same as default.
  result = jsonDecode(
    '{"x": 5}',
    numericMode: JsonNumericMode.preserveType,
  );
  Expect.isTrue(result['x'] is int);
  Expect.equals(5, result['x']);

  // Top-level number.
  var value = jsonDecode('42');
  Expect.isTrue(value is int);
  Expect.equals(42, value);

  value = jsonDecode('42.5');
  Expect.isTrue(value is double);
  Expect.equals(42.5, value);
}

/// Verify that allDouble mode converts all numbers to double.
void testAllDoubleMode() {
  // Integer without decimal should become double.
  var result = jsonDecode(
    '{"x": 5}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['x'] is double);
  Expect.equals(5.0, result['x']);

  // Already a double should stay double.
  result = jsonDecode(
    '{"x": 5.0}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['x'] is double);
  Expect.equals(5.0, result['x']);

  // Zero.
  result = jsonDecode(
    '{"x": 0}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['x'] is double);
  Expect.equals(0.0, result['x']);

  // Negative integer.
  result = jsonDecode(
    '{"x": -42}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['x'] is double);
  Expect.equals(-42.0, result['x']);

  // Top-level integer.
  var value = jsonDecode('42', numericMode: JsonNumericMode.allDouble);
  Expect.isTrue(value is double);
  Expect.equals(42.0, value);

  // Top-level zero.
  value = jsonDecode('0', numericMode: JsonNumericMode.allDouble);
  Expect.isTrue(value is double);
  Expect.equals(0.0, value);

  // Scientific notation (already double in preserveType mode).
  result = jsonDecode(
    '{"x": 5e2}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['x'] is double);
  Expect.equals(500.0, result['x']);
}

/// Verify that allDouble mode works with a reviver.
void testAllDoubleModeWithReviver() {
  var keys = <Object?>[];
  var values = <Object?>[];

  var result = jsonDecode(
    '{"price": 5, "name": "item"}',
    reviver: (key, value) {
      keys.add(key);
      values.add(value);
      return value;
    },
    numericMode: JsonNumericMode.allDouble,
  );

  // The reviver should receive the double-converted value.
  Expect.isTrue(result['price'] is double);
  Expect.equals(5.0, result['price']);
  Expect.equals('item', result['name']);
}

/// Edge cases for allDouble mode.
void testAllDoubleModeEdgeCases() {
  // Large integer.
  var result = jsonDecode(
    '{"x": 9007199254740992}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['x'] is double);
  Expect.equals(9007199254740992.0, result['x']);

  // Negative zero (already double).
  result = jsonDecode(
    '{"x": -0.0}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['x'] is double);

  // Very small double.
  result = jsonDecode(
    '{"x": 0.001}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['x'] is double);
  Expect.equals(0.001, result['x']);

  // Multiple numbers in an object.
  result = jsonDecode(
    '{"a": 1, "b": 2.5, "c": 3, "d": 4.0}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['a'] is double);
  Expect.isTrue(result['b'] is double);
  Expect.isTrue(result['c'] is double);
  Expect.isTrue(result['d'] is double);
  Expect.equals(1.0, result['a']);
  Expect.equals(2.5, result['b']);
  Expect.equals(3.0, result['c']);
  Expect.equals(4.0, result['d']);

  // null, bool, string should not be affected.
  result = jsonDecode(
    '{"a": null, "b": true, "c": "hello", "d": 5}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isNull(result['a']);
  Expect.isTrue(result['b'] is bool);
  Expect.isTrue(result['c'] is String);
  Expect.isTrue(result['d'] is double);
}

/// Nested structures in allDouble mode.
void testAllDoubleModeNestedStructures() {
  // Array of integers.
  var result = jsonDecode(
    '[1, 2, 3]',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result is List);
  for (var item in result) {
    Expect.isTrue(item is double, "Expected double but got ${item.runtimeType}");
  }
  Expect.equals(1.0, result[0]);
  Expect.equals(2.0, result[1]);
  Expect.equals(3.0, result[2]);

  // Nested object with integers.
  result = jsonDecode(
    '{"outer": {"inner": 42}}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['outer']['inner'] is double);
  Expect.equals(42.0, result['outer']['inner']);

  // Array inside object.
  result = jsonDecode(
    '{"items": [1, 2, 3]}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['items'][0] is double);
  Expect.isTrue(result['items'][1] is double);
  Expect.isTrue(result['items'][2] is double);

  // Deeply nested.
  result = jsonDecode(
    '{"a": {"b": {"c": [1, {"d": 2}]}}}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['a']['b']['c'][0] is double);
  Expect.equals(1.0, result['a']['b']['c'][0]);
  Expect.isTrue(result['a']['b']['c'][1]['d'] is double);
  Expect.equals(2.0, result['a']['b']['c'][1]['d']);
}

/// Test using JsonCodec directly.
void testAllDoubleModeJsonCodec() {
  var codec = JsonCodec();

  var result = codec.decode(
    '{"x": 5}',
    numericMode: JsonNumericMode.allDouble,
  );
  Expect.isTrue(result['x'] is double);
  Expect.equals(5.0, result['x']);

  // Default mode.
  result = codec.decode('{"x": 5}');
  Expect.isTrue(result['x'] is int);
  Expect.equals(5, result['x']);
}

/// Test using JsonDecoder directly.
void testAllDoubleModeJsonDecoder() {
  var decoder = JsonDecoder(null, JsonNumericMode.allDouble);
  var result = decoder.convert('{"x": 5, "y": 3.14}');
  Expect.isTrue(result['x'] is double);
  Expect.equals(5.0, result['x']);
  Expect.isTrue(result['y'] is double);
  Expect.equals(3.14, result['y']);

  // Default decoder should preserve types.
  decoder = JsonDecoder();
  result = decoder.convert('{"x": 5}');
  Expect.isTrue(result['x'] is int);
  Expect.equals(5, result['x']);
}

/// Verify full backwards compatibility when numericMode is not specified.
void testBackwardsCompatibility() {
  // These should all work exactly as before.

  // jsonDecode without numericMode.
  var result = jsonDecode('{"a": 1, "b": 2.5}');
  Expect.isTrue(result['a'] is int);
  Expect.isTrue(result['b'] is double);

  // json.decode without numericMode.
  result = json.decode('{"a": 1, "b": 2.5}');
  Expect.isTrue(result['a'] is int);
  Expect.isTrue(result['b'] is double);

  // JsonDecoder without numericMode.
  var decoder = JsonDecoder();
  result = decoder.convert('{"a": 1, "b": 2.5}');
  Expect.isTrue(result['a'] is int);
  Expect.isTrue(result['b'] is double);

  // With reviver, no numericMode.
  result = jsonDecode('{"a": 1}', reviver: (k, v) => v);
  Expect.isTrue(result['a'] is int);

  // Verify the enum values exist.
  Expect.equals(JsonNumericMode.preserveType, JsonNumericMode.preserveType);
  Expect.equals(JsonNumericMode.allDouble, JsonNumericMode.allDouble);
  Expect.notEquals(JsonNumericMode.preserveType, JsonNumericMode.allDouble);
}
