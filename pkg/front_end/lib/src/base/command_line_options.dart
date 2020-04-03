// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Move all option strings here.
class Flags {
  // TODO(johnniwinther): What is the right name for this?
  static const String nnbdStrongMode = "--nnbd-strong";
  static const String nnbdAgnosticMode = "--nnbd-agnostic";

  static const String forceLateLowering = "--force-late-lowering";
  static const String forceNoExplicitGetterCalls =
      "--force-no-explicit-getter-calls";

  static const String target = "--target";
}
