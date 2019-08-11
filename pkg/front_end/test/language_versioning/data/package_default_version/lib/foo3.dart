// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// .packages specifies 2.5, this library tries to go above that, which is an
// error. The library stays on the .packages specified one (2.5) and an error is
// issued.

/*error: LanguageVersionTooHigh*/
// @dart = 2.6

/*library: languageVersion=2.5*/

foo3() {
  print("Hello from foo3!");
}
