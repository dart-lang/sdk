// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.declarations_location;

import "dart:mirrors";
import "package:expect/expect.dart";
import "library_without_declaration.dart";
import "library_with_annotated_declaration.dart";

const metadata = 'metadata';

class C<S, @metadata T> {
  var a;
  final b = 2;
  static var c;
  static final d = 4;
  @metadata
  var e;
  List<C> f;
}

// We only check for a suffix of the uri because the test might be run from
// any number of absolute paths.
expectLocation(
    DeclarationMirror mirror, String uriSuffix, int line, int column) {
  Uri uri = mirror.location.sourceUri;
  Expect.isTrue(
      uri.toString().endsWith(uriSuffix), "Expected suffix $uriSuffix in $uri");
  Expect.equals(line, mirror.location.line, "line");
  Expect.equals(column, mirror.location.column, "column");
}

main() {
  String mainSuffix = 'other_declarations_location_test.dart';

  // Fields.
  expectLocation(reflectClass(C).declarations[#a], mainSuffix, 15, 7);
  expectLocation(reflectClass(C).declarations[#b], mainSuffix, 16, 9);
  expectLocation(reflectClass(C).declarations[#c], mainSuffix, 17, 14);
  expectLocation(reflectClass(C).declarations[#d], mainSuffix, 18, 16);
  expectLocation(reflectClass(C).declarations[#e], mainSuffix, 20, 7);
  expectLocation(reflectClass(C).declarations[#f], mainSuffix, 21, 11);

  // Type variables.
  expectLocation(reflectClass(C).declarations[#S], mainSuffix, 14, 9);
  expectLocation(reflectClass(C).declarations[#T], mainSuffix, 14, 12);

  // Libraries.
  expectLocation(reflectClass(C).owner, mainSuffix, 5, 1);
  expectLocation(reflectClass(ClassInLibraryWithoutDeclaration).owner,
      "library_without_declaration.dart", 1, 1);
  expectLocation(reflectClass(ClassInLibraryWithAnnotatedDeclaration).owner,
      "library_with_annotated_declaration.dart", 5, 1);
}
