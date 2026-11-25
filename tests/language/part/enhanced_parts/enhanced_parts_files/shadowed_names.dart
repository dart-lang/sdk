// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Names shadowed by declarations of the test library.
// If these declarations are accessed from anywhere, it's an error.

dynamic get partA => throw "Unreachable";
dynamic get partAA => throw "Unreachable";
dynamic get partAAA => throw "Unreachable";
dynamic get partAB => throw "Unreachable";
dynamic get partB => throw "Unreachable";

dynamic get mainVar => throw "Unreachable";
dynamic get partAVar => throw "Unreachable";
dynamic get partAAVar => throw "Unreachable";
dynamic get partAAAVar => throw "Unreachable";
dynamic get partABVar => throw "Unreachable";
dynamic get partBVar => throw "Unreachable";

void main() => throw "Unreachable";

final bool isShadowedNamesImported = true;
