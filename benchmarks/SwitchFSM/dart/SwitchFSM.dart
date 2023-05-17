// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This benchmark compares a large switch statement on various kinds of
/// values. The switch statement is part of a finite-state-machine (FSM)
/// recognizer.
///
/// There are four copies of the same code, differing only by importing
/// different declarations of the type `State` which makes the same constant
/// names available using different types.
///
/// The switch dispatch on the following types is benchmarked:
///
///   - a compact range of `int` values,
///   - an enum,
///   - a class that is a bit like an `enum` but not declared as an enum,
///   - strings.
///
/// The actual state-machine is somewhat aritificial. It recognizes a character
/// string of '0' and '1' character 'bits' that encode a valid UTF-8 string. The
/// state machine has 48 states and minimal logic in most states, so that as
/// much time as possible is executing the switch dispatch.
///
/// The data is passed to the recogizer as a Uint8List to minimize the time to
/// access the bytes of the ASCII '0' / '1' character input sequence.

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:expect/expect.dart';

import 'match_class.dart' as match_class;
import 'match_enum.dart' as match_enum;
import 'match_int.dart' as match_int;
import 'match_string.dart' as match_string;

class Benchmark extends BenchmarkBase {
  final bool Function(Uint8List) match;

  Benchmark(String kind, this.match) : super('SwitchFSM.$kind');

  void validation() {
    void check(String s, bool expected) {
      Expect.equals(expected, match(convert(s)), '"$s"');
    }

    check('', true);
    check('0', false);
    check('00', false);
    check('000', false);
    check('0000', false);
    check('00000', false);
    check('000000', false);
    check('0000000', false);
    check('00000000', true);
    check('01010101', true);
    check('10000000', false);
    check('001010101', false);
    check('11000000' '00000000', false);
    check('11000000' '10111111', true);
    check('11000000' '11111111', false);
    check('11100000' '00000000' '00000000', false);
    check('11100000' '10000000' '00000000', false);
    check('11100000' '10111111' '10111111', true);
    check('11110111' '10111111' '10111111' '01111111', false);
    check('11110111' '10111111' '10111111' '10111111', true);
    Expect.equals(testInputLength, testInput.length);
  }

  static const testInputLength = 1000;
  static final Uint8List testInput = convert(makeTestInput(testInputLength));

  static String makeTestInput(int length) {
    // The test input uses most states of the FSM. It is repeated and padded to
    // make the length 1000.
    final testPattern = ''
        '11110111101111111011111110111111'
        '111011111011111110111111'
        '1101111110111111';
    final paddingPattern = '00000000';
    final repeats = testPattern * (length ~/ testPattern.length);
    final padding =
        paddingPattern * ((length - repeats.length) ~/ paddingPattern.length);
    return repeats + padding;
  }

  static Uint8List convert(String s) => Uint8List.fromList(s.codeUnits);

  @override
  void run() {
    Expect.equals(true, match(testInput));
  }
}

enum SomeEnum { element }

void main() {
  // TODO(http://dartbug.com/51657): dart2js will remove `_Enum.index` in simple
  // programs that don't appear to use the field. This defeats the enum-switch
  // optimization that works more reliably in larger programs. Remove this code
  // that marks `_Enum.index` as used when #51657 is fixed.
  Expect.equals(0, SomeEnum.element.index);

  final benchmarks = [
    Benchmark('enum', match_enum.match),
    Benchmark('int', match_int.match),
    Benchmark('class', match_class.match),
    Benchmark('string', match_string.match),
  ];

  for (final benchmark in benchmarks) {
    benchmark.validation();
  }

  for (final benchmark in benchmarks) {
    benchmark.warmup();
  }

  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
