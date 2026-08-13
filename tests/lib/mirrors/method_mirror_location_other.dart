// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Don't let the formatter change the location of things.
// dart format off

part of test.method_location;

class ClassInOtherFile {
  ClassInOtherFile();

  method() {}
}

topLevelInOtherFile() {}

  spaceIndentedInOtherFile() {}

	tabIndentedInOtherFile() {}
