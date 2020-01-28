// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FantasyRepoSettingsTest);
  });
}

@reflectiveTest
class FantasyRepoSettingsTest {
  test_fromNameDefaultCase() {
    FantasyRepoSettings settings = FantasyRepoSettings.fromName('defaultCase');

    expect(settings.name, equals('defaultCase'));
    expect(settings.clone, equals('git@github.com:dart-lang/defaultCase.git'));
    expect(settings.branch, equals('master'));
    expect(settings.revision, equals('master'));
  }

  test_fromNameDotDartCase() {
    FantasyRepoSettings settings =
        FantasyRepoSettings.fromName('somethingImportant.dart');

    expect(settings.name, equals('somethingImportant.dart'));
    expect(settings.clone,
        equals('git@github.com:google/somethingImportant.dart.git'));
    expect(settings.branch, equals('master'));
    expect(settings.revision, equals('master'));
  }

  test_fromNameTableCase() {
    FantasyRepoSettings settings = FantasyRepoSettings.fromName('git');

    expect(settings.name, equals('git'));
    expect(settings.clone, equals('git@github.com:kevmoo/git.git'));
    expect(settings.branch, equals('master'));
    expect(settings.revision, equals('master'));
  }

  test_equality() {
    var test1 = FantasyRepoSettings('one', 'two', 'three', 'four');
    var test2 = FantasyRepoSettings('one', 'two', 'three', 'four');
    var test3 = FantasyRepoSettings('one', 'two', 'three', 'five');
    var test4 = FantasyRepoSettings('one', 'two');

    expect(test1, equals(test2));
    expect(test1, isNot(equals(test3)));
    expect(test1, isNot(equals(test4)));
  }
}
