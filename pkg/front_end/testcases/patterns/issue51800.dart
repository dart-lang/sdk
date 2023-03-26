// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ExpansionTile {
  const ExpansionTile({
    this.expandedCrossAxisAlignment,
  }) : assert(expandedCrossAxisAlignment != CrossAxisAlignment.baseline);

  final CrossAxisAlignment? expandedCrossAxisAlignment;
}

enum CrossAxisAlignment {
  start,
  end,
  center,
  stretch,
  baseline,
}

void main() {
  print(const ExpansionTile(
      expandedCrossAxisAlignment: CrossAxisAlignment.start));
}
