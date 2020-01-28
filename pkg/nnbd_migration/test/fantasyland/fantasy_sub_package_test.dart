// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FantasySubPackageSettingsTest);
  });
}

@reflectiveTest
class FantasySubPackageSettingsTest {
  test_settingsFromTable() {
    var subPackageSettings = FantasySubPackageSettings.fromName('vm_service');
    expect(subPackageSettings.name, equals('vm_service'));
    expect(subPackageSettings.repoSettings.name, equals('sdk'));
    expect(subPackageSettings.subDir, equals('pkg/vm_service'));
  }

  test_settingsFromTableDefault() {
    var subPackageSettings =
        FantasySubPackageSettings.fromName('completely_unknown_package');
    expect(subPackageSettings.name, equals('completely_unknown_package'));
    expect(subPackageSettings.repoSettings.name,
        equals('completely_unknown_package'));
    expect(subPackageSettings.subDir, equals('.'));
  }

  test_settingsEqual() {
    var repo1 = FantasyRepoSettings.fromName('some_repo_somewhere');
    var repo2 = FantasyRepoSettings.fromName('another_repo_somewhere_else');
    var test1 = FantasySubPackageSettings('foo', repo1, '.');
    var test2 = FantasySubPackageSettings('foo', repo2, '.');
    var test3 = FantasySubPackageSettings('foo', repo1, 'pkg/something');
    var test4 = FantasySubPackageSettings('foobie', repo1, '.');
    var test5 = FantasySubPackageSettings('foo', repo1, '.');

    expect(test1, equals(test1));
    expect(test1, isNot(equals(test2)));
    expect(test1, isNot(equals(test3)));
    expect(test1, isNot(equals(test4)));
    expect(test1, equals(test5));
  }
}
