// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// .packages specifies 2.5, this library tries to go above that, which is fine,
// except it still has to be within the range of the sdk. The library stays on
// the .packages specified one (2.5) and an error is issued.

/*error: errors=LanguageVersionTooHigh*/
// @dart = 2.9

/*library: languageVersion=2.5*/

foo4() {
  print("Hello from foo4!");
}
