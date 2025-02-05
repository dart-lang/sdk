// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*error: errors=LanguageVersionTooHighExplicit*/
// @dart = %TOO_HIGH_VERSION_MARKER%

// If no valid language version is specified, we default to the most recent one.

/*library: languageVersion=%CURRENT_VERSION_MARKER%*/

main() {}
