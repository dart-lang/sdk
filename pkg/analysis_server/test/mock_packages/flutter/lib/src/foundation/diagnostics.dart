// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class Diagnosticable with DiagnosticableMixin {}

mixin DiagnosticableMixin {}

class DiagnosticPropertiesBuilder {
  void add(DiagnosticsNode property) {}
}

abstract class DiagnosticsNode {}

class DiagnosticsProperty<T> extends DiagnosticsNode {
  DiagnosticsProperty(String name, T value);
}
