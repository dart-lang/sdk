// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:record_use/record_use_internal.dart';
import 'package:test/test.dart';

void main() {
  group('Signature.parseMethodSignature', () {
    test('positional and optional positional parameters', () {
      final signature =
          'String greet(String name, [String? greeting = "Hello"])';
      final expected = const Signature(
        positionalParameters: ['name'],
        positionalOptionalParameters: ['greeting'],
        namedParameters: [],
        namedOptionalParameters: [],
      );
      expect(Signature.parseMethodSignature(signature), expected);
    });

    test('only named parameters (required and optional)', () {
      final signature =
          'void process({required int id, String? label, double value = 0.0})';
      final expected = const Signature(
        positionalParameters: [],
        positionalOptionalParameters: [],
        namedParameters: ['id'],
        namedOptionalParameters: ['label', 'value'],
      );
      expect(Signature.parseMethodSignature(signature), expected);
    });

    test(
      'positional and optional positional parameters (without default values)',
      () {
        final signature = '''
Future<void> fetchData(String url, int retries, [bool? cache, Duration? timeout])''';
        final expected = const Signature(
          positionalParameters: ['url', 'retries'],
          positionalOptionalParameters: ['cache', 'timeout'],
          namedParameters: [],
          namedOptionalParameters: [],
        );
        expect(Signature.parseMethodSignature(signature), expected);
      },
    );

    test('positional and named parameters (with default values)', () {
      final signature =
          'void log(String message, {int? level = 0, DateTime? timestamp})';
      final expected = const Signature(
        positionalParameters: ['message'],
        positionalOptionalParameters: [],
        namedParameters: [],
        namedOptionalParameters: ['level', 'timestamp'],
      );
      expect(Signature.parseMethodSignature(signature), expected);
    });

    test('only positional parameters', () {
      final signature = 'int add(int a, int b)';
      final expected = const Signature(
        positionalParameters: ['a', 'b'],
        positionalOptionalParameters: [],
        namedParameters: [],
        namedOptionalParameters: [],
      );
      expect(Signature.parseMethodSignature(signature), expected);
    });

    test('only optional positional parameters', () {
      final signature = 'String format([String? prefix, String? suffix])';
      final expected = const Signature(
        positionalParameters: [],
        positionalOptionalParameters: ['prefix', 'suffix'],
        namedParameters: [],
        namedOptionalParameters: [],
      );
      expect(Signature.parseMethodSignature(signature), expected);
    });

    test('only required named parameters', () {
      final signature =
          'void config({required String apiKey, required String apiUrl})';
      final expected = const Signature(
        positionalParameters: [],
        positionalOptionalParameters: [],
        namedParameters: ['apiKey', 'apiUrl'],
        namedOptionalParameters: [],
      );
      expect(Signature.parseMethodSignature(signature), expected);
    });

    test('mixed parameters', () {
      final signature = 'void config(String apiKey, {required String apiUrl})';
      final parsed = Signature.parseMethodSignature(signature).parseArguments(
        const CallWithArguments(
          positionalArguments: [StringConstant('value')],
          namedArguments: {'apiUrl': StringConstant('value2')},
          loadingUnit: null,
          location: Location(uri: ''),
        ),
      );
      expect(parsed.named.entries.single.value?.toValue(), 'value2');
      expect(parsed.positional.single?.toValue(), 'value');
    });

    test('handles signatures with no parameters', () {
      final signature = 'void doSomething()';
      final expected = const Signature(
        positionalParameters: [],
        positionalOptionalParameters: [],
        namedParameters: [],
        namedOptionalParameters: [],
      );
      expect(Signature.parseMethodSignature(signature), expected);
    });

    test('handles signatures with complex type annotations', () {
      final signature = '''
List<Map<String, int>> processData(Map<String, List<int>> input, [Set<String>? filter])''';
      final expected = const Signature(
        positionalParameters: ['input'],
        positionalOptionalParameters: ['filter'],
        namedParameters: [],
        namedOptionalParameters: [],
      );
      expect(Signature.parseMethodSignature(signature), expected);
    });

    test('handles signatures with complex type annotations', () {
      final signature = '''
void test(Object? description, dynamic Function() body,
    {String? testOn,
    Timeout? timeout,
    Object? skip,
    Object? tags,
    Map<String, Object?>? onPlatform,
    int? retry,
    // TODO(https://github.com/dart-lang/test/issues/2205): Remove deprecated.
    // Map<String, Object?>? error,
    @Deprecated('Debug only') @doNotSubmit bool solo = false})''';
      final expected = const Signature(
        positionalParameters: ['description', 'body'],
        positionalOptionalParameters: [],
        namedParameters: [],
        namedOptionalParameters: [
          'testOn',
          'timeout',
          'skip',
          'tags',
          'onPlatform',
          'retry',
          'solo',
        ],
      );
      expect(Signature.parseMethodSignature(signature), expected);
    });
  });
}
