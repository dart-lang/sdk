// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: This test relies on LF line endings in the source file.
// It requires an entry in the .gitattributes file.

library multiline_newline_crlf;

const constantMultilineString = """
a
b
""";

var nonConstantMultilineString = """
a
b
""";

const constantRawMultilineString = r"""
\a
\b
""";

var nonConstantRawMultilineString = r"""
\a
\b
""";
