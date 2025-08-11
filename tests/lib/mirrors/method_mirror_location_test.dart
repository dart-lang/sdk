// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Don't let the formatter change the location of things.
// dart format off

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
  final location = methodMirror.location!;
  final uri = location.sourceUri;
  Expect.isTrue(
    uri.toString().endsWith(uriSuffix),
    "Expected suffix $uriSuffix in $uri",
  );
  Expect.equals(line, location.line, "line");
  Expect.equals(column, location.column, "column");
}

class ClassInMainFile {
  ClassInMainFile();

  method() {}
}

void topLevelInMainFile() {}
  spaceIndentedInMainFile() {}
	tabIndentedInMainFile() {}

class HasImplicitConstructor {}

typedef bool Predicate(num n);

main() {
  localFunction(x) {
    return x;
  }

  String mainSuffix = 'method_mirror_location_test.dart';
  String otherSuffix = 'method_mirror_location_other.dart';

  // This file.
  expectLocation(
    reflectClass(ClassInMainFile).declarations[#ClassInMainFile]!,
    mainSuffix,
    36,
    3,
  );
  expectLocation(
    reflectClass(ClassInMainFile).declarations[#method]!,
    mainSuffix,
    38,
    3,
  );
  expectLocation(reflect(topLevelInMainFile), mainSuffix, 41, 1);
  expectLocation(reflect(spaceIndentedInMainFile), mainSuffix, 42, 3);
  expectLocation(reflect(tabIndentedInMainFile), mainSuffix, 43, 2);
  expectLocation(reflect(localFunction), mainSuffix, 50, 3);

  // Another part.
  expectLocation(
    reflectClass(ClassInOtherFile).declarations[#ClassInOtherFile]!,
    otherSuffix,
    11,
    3,
  );
  expectLocation(
    reflectClass(ClassInOtherFile).declarations[#method]!,
    otherSuffix,
    13,
    3,
  );
  expectLocation(reflect(topLevelInOtherFile), otherSuffix, 16, 1);
  expectLocation(reflect(spaceIndentedInOtherFile), otherSuffix, 18, 3);
  expectLocation(reflect(tabIndentedInOtherFile), otherSuffix, 20, 2);

  // Synthetic methods.
  Expect.isNull(
    reflectClass(
      HasImplicitConstructor,
    ).declarations[#HasImplicitConstructor]!.location,
  );
  Expect.isNull(
    (reflectType(Predicate) as TypedefMirror).referent.callMethod.location,
  );
}
