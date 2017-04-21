// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// PackageRoot=none

import 'dart:io';
import 'dart:isolate';

import "package:flu";

var PACKAGE_FLU = "package:flu";
var FLU_TEXT = "flu.text";

testShortResolution(package_uri) async {
  var fluPackage = await Isolate.resolvePackageUri(Uri.parse(package_uri));
  print("Resolved $package_uri to $fluPackage");
  var fluText = fluPackage.resolve(FLU_TEXT);
  print("Resolved $FLU_TEXT from $package_uri to $fluText");
  var fluFile = new File.fromUri(fluText);
  var fluString = await fluFile.readAsString();
  if (fluString != "Bar") {
    throw "Contents of $FLU_TEXT not matching.\n"
        "Got: $fluString\n"
        "Expected: Bar";
  }
}

main([args, port]) async {
  if (Flu.value != "Flu") {
    throw "Import of wrong Flu package.";
  }
  await testShortResolution(PACKAGE_FLU);
  await testShortResolution(PACKAGE_FLU + "/");
  await testShortResolution(PACKAGE_FLU + "/abc.def");
  print("SUCCESS");
}
