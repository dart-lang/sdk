// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SecurePubspecUrlsTest);
  });
}

@reflectiveTest
class SecurePubspecUrlsTest extends LintRuleTest {
  @override
  bool get dumpAstOnFailures => false;

  @override
  String get lintRule => 'secure_pubspec_urls';

  test_dependencyGit_insecure() async {
    await assertPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1

dependencies:
  kittens:
    git: http://github.com/munificent/kittens.git
''', [
      lint(81, 40),
    ]);
  }

  test_dependencyGitUrl_insecure() async {
    await assertPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1

dependencies:
  kittens2:
    git:
      url: http://github.com/munificent/kittens2.git
      ref: main
''', [
      lint(93, 41),
    ]);
  }

  test_dependencyHosted_insecure() async {
    await assertPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1

dependencies:
  transmogrify:
    hosted: http://some-package-server.com
''', [
      lint(89, 30),
    ]);
  }

  test_dependencyHostedUrl_insecure() async {
    await assertPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1

dependencies:
  transmogrify:
    hosted:
      name: transmogrify
      url: http://some-package-server.com
    version: ^1.0.0
''', [
      lint(125, 30),
    ]);
  }

  test_dependencyOverridesGit_insecure() async {
    await assertPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1

dependency_overrides:
  kittens:
    git: http://github.com/munificent/kittens.git
''', [
      lint(89, 40),
    ]);
  }

  test_devDependencyGit_insecure() async {
    await assertPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1

dev_dependencies:
  kittens:
    git: http://github.com/munificent/kittens.git
''', [
      lint(85, 40),
    ]);
  }

  test_homepage_insecure() async {
    await assertPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1
homepage: http://github.com/dart-lang/linter
''', [
      lint(56, 34),
    ]);
  }

  test_homepage_secure() async {
    await assertNoPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1
homepage: https://github.com/dart-lang/linter
''');
  }

  test_issueTracker_insecure() async {
    await assertPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1
issue_tracker: http://github.com/dart-lang/linter/issues
''', [
      lint(61, 41),
    ]);
  }

  test_repository_insecure() async {
    await assertPubspecDiagnostics(r'''
name: fancy
description: Text.
version: 1.1.1
repository: http://github.com/dart-lang/linter

environment:
  sdk: ">=2.15.2 <3.0.0"
''', [
      lint(58, 34),
    ]);
  }
}
