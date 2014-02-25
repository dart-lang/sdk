// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library that automatically initializes polymer elements without having to
/// write a main for your application.
///
/// If a polymer application is written entirely with `<polymer-element>` tags
/// and there is no initialization code that needs to happen before these
/// elements are created, then, instead of creating your own `main`, you can
/// simply include a script tag loading this library:
///
///    <script type="application/dart">import "package:polymer/init.dart";
///    </script>
///
/// This script tag should be placed after all HTML imports on your page.
library polymer.init;

import 'package:polymer/polymer.dart';

main() => initPolymer();
