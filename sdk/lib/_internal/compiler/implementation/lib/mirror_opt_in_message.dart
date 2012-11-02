// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Yeah, seriously: mirrors in dart2js are experimental...
const String MIRROR_OPT_IN_MESSAGE = """

This program is using an experimental feature called \"mirrors\".  As
currently implemented, mirrors do not work with minification, and will
cause spurious errors depending on how code was optimized.

The authors of this program are aware of these problems and have
decided the thrill of using an experimental feature is outweighing the
risks.  Furthermore, the authors of this program understand that
long-term, to fix the problems mentioned above, mirrors may have
negative impact on size and performance of Dart programs compiled to
JavaScript.
""";
