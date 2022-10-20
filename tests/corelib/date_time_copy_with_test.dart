// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for DateTime.copyWith.

testCopyWith(
  DateTime original,
  int? year,
  int? month,
  int? day,
  int? hour,
  int? minute,
  int? second,
  int? millisecond,
  bool isUtc,
) {
  final result = original.copyWith(
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
    second: second,
    millisecond: millisecond,
    isUtc: isUtc,
  );
  final dateTimeConstructor = isUtc ? DateTime.utc : DateTime.new;
  final expected = dateTimeConstructor(
    year ?? original.year,
    month ?? original.month,
    day ?? original.day,
    hour ?? original.hour,
    minute ?? original.minute,
    second ?? original.second,
    millisecond ?? original.millisecond,
  );

  Expect.equals(expected, result);
}

void main() {
  final epoch = DateTime.utc(1970, 1, 1);
  final dst = DateTime.parse("2015-07-07T12:12:24Z");
  final leap = DateTime.parse("2012-02-28T12:12:24");

  for (var year in [null, -100, 1917, 2012]) {
    for (var month in [null, -1, 1, 2, 12, 14]) {
      for (var day in [null, -1, 1, 28, 29, 30, 31, 32]) {
        for (var hour in [null, -1, 0, 23, 25]) {
          for (var minute in [null, -1, 1, 59, 61]) {
            for (var second in [null, -1, 1, 59, 61]) {
              for (var millisecond in [null, -1, 1, 999, 1001]) {
                for (var isUtc in [false, true]) {
                  for (var base in [epoch, dst, leap]) {
                    testCopyWith(
                      base,
                      year,
                      month,
                      day,
                      hour,
                      minute,
                      second,
                      millisecond,
                      isUtc,
                    );
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
