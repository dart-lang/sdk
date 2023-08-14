// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";

Uint32List counts = new Uint32List(0);

void initialize(int count, bool reportCandidates) {
  counts = new Uint32List(count);
}

@pragma("vm:prefer-inline")
void enter(int i) {
  counts[i]++;
}

@pragma("vm:prefer-inline")
void exit(int i) {}

void report(List<String> names) {
  List<NameWithCount> data = [];
  for (int i = 0; i < counts.length; i++) {
    int count = counts[i];
    if (count < 10000) continue;
    data.add(new NameWithCount(names[i], count));
  }
  data.sort((a, b) => a.count - b.count);
  for (NameWithCount element in data) {
    print("${_formatInt(element.count, 11)}: ${element.name}");
  }
}

class NameWithCount {
  final String name;
  final int count;

  NameWithCount(this.name, this.count);
}

String _formatInt(int input, int minLength) {
  bool negative = false;
  if (input < 0) {
    negative = true;
    input = -input;
  }
  String asString = "$input";
  int length = asString.length;
  int countSeparators = (length - 1) ~/ 3;
  int outLength = length + countSeparators;
  if (negative) outLength++;
  StringBuffer sb = new StringBuffer();
  if (outLength < minLength) {
    sb.write(" " * (minLength - outLength));
  }

  if (negative) sb.write("-");
  int end = length - (countSeparators * 3);
  sb.write(asString.substring(0, end));
  int begin = end;
  end += 3;
  while (end <= length) {
    sb.write(",");
    sb.write(asString.substring(begin, end));
    begin = end;
    end += 3;
  }

  return sb.toString();
}
