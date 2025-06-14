// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test depends on specific line endings,
// and requires an entry in the .gitattributes file.

// dart format off

// All line endings inside string literals are Carriage Return, U+000D
const constantMultilineString = """ab""";

var nonConstantMultilineString = """ab""";

const constantRawMultilineString = r"""\a\b""";

var nonConstantRawMultilineString = r"""\a\b""";
