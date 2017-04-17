// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.method_location;

import "dart:mirrors";
import "package:expect/expect.dart";

part 'method_mirror_location_other.dart';

// We only check for a suffix of the uri because the test might be run from
// any number of absolute paths.
expectLocation(Mirror mirror, String uriSuffix, int line, int column) {
  MethodMirror methodMirror;
  if (mirror is ClosureMirror) {
    methodMirror = mirror.function;
  } else {
    methodMirror = mirror as MethodMirror;
  }
  Expect.isTrue(methodMirror is MethodMirror);
  Uri uri = methodMirror.location.sourceUri;
  Expect.isTrue(
      uri.toString().endsWith(uriSuffix), "Expected suffix $uriSuffix in $uri");
  Expect.equals(line, methodMirror.location.line, "line");
  Expect.equals(column, methodMirror.location.column, "column");
}

class ClassInMainFile {
  ClassInMainFile();

  method() {}
}

void topLevelInMainFile() {}
spaceIdentedInMainFile() {}
tabIdentedInMainFile() {}

class HasImplicitConstructor {}

typedef bool Predicate(num n);

main() {
  localFunction(x) {
    return x;
  }

  String mainSuffix = 'method_mirror_location_test.dart';
  String otherSuffix = 'method_mirror_location_other.dart';

  // This file.
  expectLocation(reflectClass(ClassInMainFile).declarations[#ClassInMainFile],
      mainSuffix, 31, 3);
  expectLocation(
      reflectClass(ClassInMainFile).declarations[#method], mainSuffix, 33, 3);
  expectLocation(reflect(topLevelInMainFile), mainSuffix, 36, 1);
  expectLocation(reflect(spaceIdentedInMainFile), mainSuffix, 37, 3);
  expectLocation(reflect(tabIdentedInMainFile), mainSuffix, 38, 2);
  expectLocation(reflect(localFunction), mainSuffix, 45, 3);

  // Another part.
  expectLocation(reflectClass(ClassInOtherFile).declarations[#ClassInOtherFile],
      otherSuffix, 9, 3);
  expectLocation(
      reflectClass(ClassInOtherFile).declarations[#method], otherSuffix, 11, 3);
  expectLocation(reflect(topLevelInOtherFile), otherSuffix, 14, 1);
  expectLocation(reflect(spaceIdentedInOtherFile), otherSuffix, 16, 3);
  expectLocation(reflect(tabIdentedInOtherFile), otherSuffix, 18, 2);

  // Synthetic methods.
  Expect.isNull(reflectClass(HasImplicitConstructor)
      .declarations[#HasImplicitConstructor]
      .location);
  Expect.isNull(
      (reflectType(Predicate) as TypedefMirror).referent.callMethod.location);
}
