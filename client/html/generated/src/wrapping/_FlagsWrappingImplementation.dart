// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FlagsWrappingImplementation extends DOMWrapperBase implements Flags {
  FlagsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get create() { return _ptr.create; }

  void set create(bool value) { _ptr.create = value; }

  bool get exclusive() { return _ptr.exclusive; }

  void set exclusive(bool value) { _ptr.exclusive = value; }

  String get typeName() { return "Flags"; }
}
