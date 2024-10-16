// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// .dart_tool/package_config.json specifies %VERSION_MARKER1%, this library
// tries to go above that, which is fine, except it still has to be within the
// range of the sdk. The library stays on the .dart_tool/package_config.json
// specified one (%VERSION_MARKER1%) and an error is issued.

/*error: errors=LanguageVersionTooHighExplicit*/
// @dart = %TOO_HIGH_VERSION_MARKER%

/*library: languageVersion=%VERSION_MARKER1%*/

foo4() {
  print("Hello from foo4!");
}
