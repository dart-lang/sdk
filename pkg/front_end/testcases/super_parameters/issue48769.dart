// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NumProperty extends DiagnosticsProperty {
  NumProperty({
    super.showName,
  });

  NumProperty.lazy({
    super.showName,
  }) : super.lazy();
}

class DiagnosticsProperty extends DiagnosticsNode {
  DiagnosticsProperty({
    super.showName,
  });

  DiagnosticsProperty.lazy({
    super.showName,
  });
}

abstract class DiagnosticsNode {
  DiagnosticsNode({
    this.showName = true,
  });

  final bool showName;
}

void main() {
  print('hello');
}
