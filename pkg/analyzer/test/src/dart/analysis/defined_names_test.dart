// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/src/dart/analysis/defined_names.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/feature_sets.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefinedNamesTest);
  });
}

@reflectiveTest
class DefinedNamesTest {
  test_classMemberNames_class() {
    DefinedNames names = _computeDefinedNames('''
class A {
  int a, b;
  A();
  A.c();
  d() {}
  get e => null;
  set f(_) {}
}
class B {
  g() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A', 'B']));
    expect(names.classMemberNames,
        unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']));
  }

  test_classMemberNames_extensionType() {
    DefinedNames names = _computeDefinedNames('''
extension type A.named(int it) {
  int a, b;
  A();
  A.other();
  void d() {}
  int get e => 0;
  set f(int _) {}
}
extension type B(int it) {
  void g() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A', 'B']));
    expect(names.classMemberNames,
        unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']));
  }

  test_classMemberNames_mixin() {
    DefinedNames names = _computeDefinedNames('''
mixin A {
  int a, b;
  d() {}
  get e => null;
  set f(_) {}
}
mixin B {
  g() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A', 'B']));
    expect(names.classMemberNames,
        unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']));
  }

  test_topLevelNames() {
    DefinedNames names = _computeDefinedNames('''
class A {}
class B = Object with A;
typedef C();
D() {}
get E => null;
set F(_) {}
var G, H;
mixin M {}
''');
    expect(names.topLevelNames,
        unorderedEquals(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'M']));
    expect(names.classMemberNames, isEmpty);
  }

  DefinedNames _computeDefinedNames(
    String code, {
    FeatureSet? featureSet,
  }) {
    var parseResult = parseString(
      content: code,
      featureSet: featureSet ?? FeatureSets.latestWithExperiments,
    );
    return computeDefinedNames(parseResult.unit);
  }
}
