// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.code_output_listener;

/// Listener interface for [CodeOutput] activity.
abstract class CodeOutputListener {
  /// Called when [text] is added to the output.
  void onText(String text);

  /// Called when the output is closed with a final length of [length].
  void onDone(int length);
}
