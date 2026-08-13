// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/66765
// Verifies that AOT compiler doesn't crash on a particular flow graph.

class TutorialBloc {
  TutorialBloc();

  Stream<TutorialStates> mapEventToState(TutorialEvents event) async* {
    switch (event.action) {
      default:
        yield TutorialInitState();
    }
  }
}

enum TutorialAction { dummyData }

class TutorialEvents {
  final TutorialAction action;
  const TutorialEvents(this.action);
}

abstract class TutorialStates {}

class TutorialInitState extends TutorialStates {}

List<dynamic> l = [TutorialBloc()];

void main() async {
  if (l.length > 1) {
    l[0].mapEventToState(42);
  }
}
