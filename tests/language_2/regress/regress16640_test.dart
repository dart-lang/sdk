// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 16640.

class Segment extends SegmentGen {}

class SegmentGen extends ConceptEntity<Segment> {}

class ConceptEntity<E> {}

main() {
  new ConceptEntity<Segment>();
}
