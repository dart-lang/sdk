// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/48323.
// Verifies that class finalization doesn't crash when seeing
// superclass with type arguments which were not finalized yet.

abstract class GraphNode extends Comparable<dynamic> {
  int compareTo(dynamic other) => 0;
}

abstract class StreamNode<T> extends GraphNode {}

class TransformNode<S, T> extends StreamNode<T> {}

main() {
  print(TransformNode());
}
