// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
class Uninitialized {
  int x;
}

class PartiallyInitialized {
  int x;
  PartiallyInitialized(this.x);
  PartiallyInitialized.noInitializer();
}

class Initialized {
  int x;
  Initialized(this.x);
}

class Forwarding {
  int x;
  Forwarding.initialize(this.x);
  Forwarding(int arg) : this.initialize(arg);
}

int uninitializedTopLevel;
int initializedTopLevel = 4;

main() {}
