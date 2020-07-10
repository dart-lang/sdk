// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*error: errors=LanguageVersionTooHigh*/
// @dart = 3.5

// @dart = 2.5

// If the first language version specified is not a valid language version,
// we default to the most reason one.  In the tests this is hard-coded to 2.8.

/*library: languageVersion=2.8*/

main() {}
