// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of someimpl_dart;

class SomeClassImpl implements SomeClass {
  String message_;

  SomeClassImpl(arg) : message_ = "w00t!" { }
  String get message { return message_; }
}
