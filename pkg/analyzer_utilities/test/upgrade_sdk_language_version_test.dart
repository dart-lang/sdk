// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_utilities/tool/sdk_packages.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
// `package:test` exports a `Skip` of its own, which isn't needed here and
// would collide with the tool's.
import 'package:test/test.dart' hide Skip;
import 'package:yaml/yaml.dart';

import '../tool/upgrade_sdk_language_version.dart';

void main() {
  group('addAnalysisOptionsEntries', () {
    group('linter: rules:', () {
      String? addLints(String? contents, List<String> lints) =>
          addAnalysisOptionsEntries(
            contents,
            outerKey: 'linter',
            innerKey: 'rules',
            entries: lints,
          );

      test('creates the file contents when there is no file', () {
        expect(addLints(null, ['foo']), '''
linter:
  rules:
    - foo
''');
      });

      test('creates both sections when neither is present', () {
        expect(
          addLints('include: package:lints/recommended.yaml\n', ['foo']),
          '''
linter:
  rules:
    - foo

include: package:lints/recommended.yaml
''',
        );
      });

      test('creates the new section below the license header', () {
        expect(
          addLints(
            '''
# Copyright (c) 2019, the Dart project authors.

include: package:lints/recommended.yaml
''',
            ['foo'],
          ),
          '''
# Copyright (c) 2019, the Dart project authors.

linter:
  rules:
    - foo

include: package:lints/recommended.yaml
''',
        );
      });

      test('creates the new section in a file of nothing but comments', () {
        expect(addLints('# Nothing to see here.\n', ['foo']), '''
# Nothing to see here.
linter:
  rules:
    - foo
''');
      });

      test('creates the new section after a final comment with no newline', () {
        expect(addLints('# Nothing to see here.', ['foo']), '''
# Nothing to see here.
linter:
  rules:
    - foo
''');
      });

      test('appends to a section at the end of a file with no newline', () {
        expect(
          addLints('linter:\n  rules:\n    - aaa', ['bbb']),
          'linter:\n  rules:\n    - aaa\n    - bbb\n',
        );
      });

      test('adds to an existing list-style section', () {
        expect(
          addLints(
            '''
linter:
  rules:
    - existing
''',
            ['foo'],
          ),
          '''
linter:
  rules:
    - existing
    - foo
''',
        );
      });

      test('adds to an existing map-style section', () {
        expect(
          addLints(
            '''
linter:
  rules:
    existing: true
''',
            ['foo'],
          ),
          '''
linter:
  rules:
    existing: true
    foo: true
''',
        );
      });

      test('nests a new rules section inside an existing linter section', () {
        // Regression test: the entry must go inside `linter:`, not become a
        // stray top-level `rules:` key.
        expect(
          addLints(
            '''
linter:
  # A comment.
  exclude:
    - foo.dart
''',
            ['foo'],
          ),
          '''
linter:
  rules:
    - foo
  # A comment.
  exclude:
    - foo.dart
''',
        );
      });

      test('returns null when every lint is already present', () {
        expect(
          addLints(
            '''
linter:
  rules:
    - foo
''',
            ['foo'],
          ),
          isNull,
        );
      });

      test('only adds the lints that are missing', () {
        expect(
          addLints(
            '''
linter:
  rules:
    - foo
''',
            ['foo', 'bar'],
          ),
          '''
linter:
  rules:
    - bar
    - foo
''',
        );
      });

      test('preserves comments and unrelated sections', () {
        expect(
          addLints(
            '''
# Leading comment.
analyzer:
  exclude:
    - generated.dart

linter:
  rules:
    # Why this one is enabled.
    - existing
''',
            ['foo'],
          ),
          '''
# Leading comment.
analyzer:
  exclude:
    - generated.dart

linter:
  rules:
    # Why this one is enabled.
    - existing
    - foo
''',
        );
      });

      test('keeps a comment attached to the entry it was written above', () {
        // The new lint sorts before `zebra`, so it has to go above `zebra`'s
        // comment, not between the comment and `zebra`.
        expect(
          addLints(
            '''
linter:
  rules:
    # Why this one is enabled.
    - zebra
''',
            ['foo'],
          ),
          '''
linter:
  rules:
    - foo
    # Why this one is enabled.
    - zebra
''',
        );
      });

      test('interleaves several new lints with the existing ones', () {
        expect(
          addLints(
            '''
linter:
  rules:
    - bbb
    - ddd
''',
            ['eee', 'aaa', 'ccc'],
          ),
          '''
linter:
  rules:
    - aaa
    - bbb
    - ccc
    - ddd
    - eee
''',
        );
      });

      test('sorts new lints that land in the same place', () {
        expect(
          addLints(
            '''
linter:
  rules:
    - bbb
''',
            ['abb', 'aaa'],
          ),
          '''
linter:
  rules:
    - aaa
    - abb
    - bbb
''',
        );
      });

      test('appends to a section that is not sorted to begin with', () {
        // There's no order to respect, so the end is the least surprising
        // place for the new lint.
        expect(
          addLints(
            '''
linter:
  rules:
    - zebra
    - apple
''',
            ['foo'],
          ),
          '''
linter:
  rules:
    - zebra
    - apple
    - foo
''',
        );
      });

      test('appends before a section that follows after a blank line', () {
        // Regression test: a block list's span runs on to the start of the
        // next key, so the new lint used to land inside `analyzer:`. This is
        // the shape used by `pkg/dtd_impl`.
        expect(
          addLints(
            '''
linter:
  rules:
    - zebra
    - apple

analyzer:
  language:
    strict-raw-types: true
''',
            ['foo'],
          ),
          '''
linter:
  rules:
    - zebra
    - apple
    - foo

analyzer:
  language:
    strict-raw-types: true
''',
        );
      });

      test('adds a last entry before a section that follows directly', () {
        expect(
          addLints(
            '''
linter:
  rules:
    - aaa
    - bbb # A trailing comment.
formatter:
  trailing_commas: preserve
''',
            ['ccc'],
          ),
          '''
linter:
  rules:
    - aaa
    - bbb # A trailing comment.
    - ccc
formatter:
  trailing_commas: preserve
''',
        );
      });

      test('adds a last map entry before a section that follows', () {
        expect(
          addLints(
            '''
linter:
  rules:
    aaa: true
    bbb: true

formatter:
  trailing_commas: preserve
''',
            ['ccc'],
          ),
          '''
linter:
  rules:
    aaa: true
    bbb: true
    ccc: true

formatter:
  trailing_commas: preserve
''',
        );
      });

      test('throws when a needed lint is explicitly disabled', () {
        expect(
          () => addLints(
            '''
linter:
  rules:
    foo: false
''',
            ['foo'],
          ),
          throwsUnimplementedError,
        );
      });

      test('ignores an unrelated disabled lint', () {
        expect(
          addLints(
            '''
linter:
  rules:
    bar: false
''',
            ['foo'],
          ),
          '''
linter:
  rules:
    bar: false
    foo: true
''',
        );
      });
    });

    group('analyzer: enable-experiment:', () {
      String? addExperiments(String? contents, List<String> experiments) =>
          addAnalysisOptionsEntries(
            contents,
            outerKey: 'analyzer',
            innerKey: 'enable-experiment',
            entries: experiments,
          );

      test('creates both sections when neither is present', () {
        expect(
          addExperiments(
            '''
linter:
  rules:
    - foo
''',
            ['this-promotion'],
          ),
          '''
analyzer:
  enable-experiment:
    - this-promotion

linter:
  rules:
    - foo
''',
        );
      });

      test('nests inside an existing analyzer section', () {
        // This is the shape used by `pkg/dwds`.
        expect(
          addExperiments(
            '''
analyzer:
  exclude:
    # Ignore generated files
    - "lib/src/generated.dart"
''',
            ['this-promotion'],
          ),
          '''
analyzer:
  enable-experiment:
    - this-promotion
  exclude:
    # Ignore generated files
    - "lib/src/generated.dart"
''',
        );
      });

      test('adds to an existing enable-experiment section', () {
        expect(
          addExperiments(
            '''
analyzer:
  enable-experiment:
    - existing-experiment
''',
            ['this-promotion'],
          ),
          '''
analyzer:
  enable-experiment:
    - existing-experiment
    - this-promotion
''',
        );
      });

      test('adds before another analyzer key that follows', () {
        expect(
          addExperiments(
            '''
analyzer:
  enable-experiment:
    - existing-experiment
  language:
    strict-raw-types: true
''',
            ['this-promotion'],
          ),
          '''
analyzer:
  enable-experiment:
    - existing-experiment
    - this-promotion
  language:
    strict-raw-types: true
''',
        );
      });

      test('returns null when the experiment is already enabled', () {
        expect(
          addExperiments(
            '''
analyzer:
  enable-experiment:
    - this-promotion
''',
            ['this-promotion'],
          ),
          isNull,
        );
      });
    });

    test('composes lints and experiments, as enableLints does', () {
      // The shape of `pkg/dwds`: map-style rules, an unrelated disabled lint,
      // and an `analyzer:` section that has no `enable-experiment:` entry.
      var contents = '''
include: package:dart_flutter_team_lints/analysis_options.yaml

analyzer:
  exclude:
    # Ignore generated files
    - "lib/src/handlers/injected_client_js.dart"

linter:
  rules:
    always_use_package_imports: true
    prefer_relative_imports: false
''';

      expect(
        addLintsAndExperiments(
          contents,
          lintSet: ['unnecessary_this_alias'],
          experiments: ['this-promotion'],
        ),
        '''
include: package:dart_flutter_team_lints/analysis_options.yaml

analyzer:
  enable-experiment:
    - this-promotion
  exclude:
    # Ignore generated files
    - "lib/src/handlers/injected_client_js.dart"

linter:
  rules:
    always_use_package_imports: true
    prefer_relative_imports: false
    unnecessary_this_alias: true
''',
      );
    });

    test('returns null when neither lints nor experiments need adding', () {
      var contents = '''
analyzer:
  enable-experiment:
    - this-promotion

linter:
  rules:
    - unnecessary_this_alias
''';
      expect(
        addLintsAndExperiments(
          contents,
          lintSet: ['unnecessary_this_alias'],
          experiments: ['this-promotion'],
        ),
        isNull,
      );
    });

    test('returns null when there is nothing at all to add', () {
      expect(
        addLintsAndExperiments(null, lintSet: [], experiments: []),
        isNull,
      );
    });

    group('include', () {
      test('starts a new file with an include of the inherited options', () {
        expect(
          addLintsAndExperiments(
            null,
            lintSet: ['foo'],
            experiments: [],
            include: '../analysis_options.yaml',
          ),
          'include: ../analysis_options.yaml\n\nlinter:\n  rules:\n    - foo\n',
        );
      });

      test('is not added to an existing file', () {
        expect(
          addLintsAndExperiments(
            'linter:\n  rules:\n    - bar\n',
            lintSet: ['foo'],
            experiments: [],
            include: '../analysis_options.yaml',
          ),
          'linter:\n  rules:\n    - bar\n    - foo\n',
        );
      });

      test('does not by itself call for a new file', () {
        expect(
          addLintsAndExperiments(
            null,
            lintSet: [],
            experiments: [],
            include: '../analysis_options.yaml',
          ),
          isNull,
        );
      });
    });

    test('rejects flow-style sections', () {
      expect(
        () => addAnalysisOptionsEntries(
          'linter: {rules: [foo]}\n',
          outerKey: 'linter',
          innerKey: 'rules',
          entries: ['bar'],
        ),
        throwsUnimplementedError,
      );
    });

    test('rejects a section that is neither a list nor a map', () {
      expect(
        () => addAnalysisOptionsEntries(
          'linter:\n  rules: foo\n',
          outerKey: 'linter',
          innerKey: 'rules',
          entries: ['bar'],
        ),
        throwsUnimplementedError,
      );
    });
  });

  group('bumpSdkConstraint', () {
    String bump(String pubspecText, {String target = '3.14.0-0'}) =>
        bumpSdkConstraint(
          pubspecText,
          sdkConstraintNode:
              ((loadYaml(pubspecText) as YamlMap)['environment'] as YamlMap)
                      .nodes['sdk']
                  as YamlScalar,
          targetVersion: Version.parse(target),
        );

    test('replaces a plain scalar, leaving the rest of the file alone', () {
      expect(
        bump('''
name: foo

environment:
  sdk: ^3.11.0

dependencies:
  bar: any
'''),
        '''
name: foo

environment:
  sdk: ^3.14.0-0

dependencies:
  bar: any
''',
      );
    });

    test('keeps the quotes of a single-quoted scalar', () {
      // The span of a quoted scalar covers the quotes, so replacing it
      // wholesale would strip them.
      expect(
        bump('''
environment:
  sdk: '^3.13.0-0'
'''),
        '''
environment:
  sdk: '^3.14.0-0'
''',
      );
    });

    test('refuses a constraint that is not a caret constraint', () {
      // The shape `pkg/status_file` used to have.
      expect(
        () => bump('''
environment:
  sdk: '>=3.13.0 <4.0.0'
'''),
        throwsUnimplementedError,
      );
    });

    test('refuses a scalar style it does not know how to requote', () {
      expect(
        () => bump('''
environment:
  sdk: "^3.13.0-0"
'''),
        throwsUnimplementedError,
      );
    });
  });

  group('checkTargetVersion', () {
    String versionFile({String channel = 'main'}) =>
        '''
# A comment, mentioning MAJOR 9.
CHANNEL $channel
MAJOR 3
MINOR 15
PATCH 0
PRERELEASE 0
PRERELEASE_PATCH 0
''';

    String? check(String target, {String channel = 'main'}) =>
        checkTargetVersion(
          Version.parse(target),
          versionFileContents: versionFile(channel: channel),
        );

    test('accepts an older release target', () {
      expect(check('3.13.0'), isNull);
    });

    test('accepts a prerelease target for the version in development', () {
      expect(check('3.15.0-0'), isNull);
    });

    test('rejects a target newer than the SDK', () {
      expect(check('3.16.0-0'), contains('newer than the SDK'));
      expect(check('4.0.0-0'), contains('newer than the SDK'));
    });

    test('rejects a release target for the version in development', () {
      expect(check('3.15.0'), contains('Use 3.15.0-0 instead'));
    });

    test('accepts a release target once the SDK is stable', () {
      expect(check('3.15.0', channel: 'stable'), isNull);
    });

    test('complains about a VERSION file it cannot read', () {
      expect(
        checkTargetVersion(
          Version.parse('3.15.0-0'),
          versionFileContents: 'MAJOR 3\n',
        ),
        contains('Could not find'),
      );
    });
  });

  group('classifySdkConstraint', () {
    ({Version minVersion, SdkConstraintVerdict verdict}) classify(
      String constraint, {
      String target = '3.14.0-0',
    }) =>
        classifySdkConstraint(constraint, targetVersion: Version.parse(target));

    test('one minor version behind needs an ordinary bump', () {
      expect(classify('^3.13.0-0'), (
        minVersion: Version.parse('3.13.0-0'),
        verdict: SdkConstraintVerdict.needsBump,
      ));
    });

    test('more than one minor version behind is flagged', () {
      expect(classify('^3.11.0'), (
        minVersion: Version.parse('3.11.0'),
        verdict: SdkConstraintVerdict.farBehind,
      ));
    });

    test('already at the target needs no bump', () {
      expect(classify('^3.14.0-0').verdict, SdkConstraintVerdict.upToDate);
    });

    test('past the target needs no bump', () {
      expect(classify('^3.15.0').verdict, SdkConstraintVerdict.upToDate);
    });

    test('an exact version is classified by itself', () {
      expect(classify('3.13.0'), (
        minVersion: Version.parse('3.13.0'),
        verdict: SdkConstraintVerdict.needsBump,
      ));
    });

    test('an inclusive range is classified by its lower bound', () {
      // Classification succeeds even though `bumpSdkConstraint` will later
      // refuse this shape; that's deliberate, so that the package is dropped
      // at the point of the bump rather than up front.
      expect(classify('>=3.13.0 <4.0.0'), (
        minVersion: Version.parse('3.13.0'),
        verdict: SdkConstraintVerdict.needsBump,
      ));
    });

    test('a major version difference skips the package', () {
      expect(() => classify('^2.19.0'), throwsA(isA<Skip>()));
    });

    test('an exclusive lower bound is rejected', () {
      expect(() => classify('>3.13.0 <4.0.0'), throwsException);
    });

    test('a constraint with no lower bound is rejected', () {
      expect(() => classify('any'), throwsException);
    });

    test('a prerelease of the target version needs no bump', () {
      // Only the major and minor versions matter: a release target mustn't
      // rewrite `^3.14.0-0` to `^3.14.0`, which a dev SDK wouldn't satisfy.
      expect(
        classify('^3.14.0-0', target: '3.14.0').verdict,
        SdkConstraintVerdict.upToDate,
      );
    });
  });

  group('execute', () {
    test('includes the end of stdout when the command fails', () {
      // A Dart script, rather than a shell command, so that this works on
      // every platform. The text is computed, so that it can't simply come
      // from the command line, which the error mentions too.
      var directory = Directory.systemTemp.createTempSync('execute_test');
      addTearDown(() => directory.deleteSync(recursive: true));
      var script = File(join(directory.path, 'fail.dart'))
        ..writeAsStringSync('''
import 'dart:io';
void main() {
  print('solver said \${6 * 7}');
  exit(255);
}
''');
      expect(
        () => execute(Platform.resolvedExecutable, [script.path]),
        throwsA(
          predicate((e) => '$e'.contains('solver said 42'), 'mentions stdout'),
        ),
      );
    });
  });

  group('findInheritedAnalysisOptions', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('find_inherited_options');
      Directory(join(root.path, 'pkg', 'foo')).createSync(recursive: true);
    });

    tearDown(() {
      root.deleteSync(recursive: true);
    });

    String? find() => findInheritedAnalysisOptions(
      join(root.path, 'pkg', 'foo'),
      root: root.path,
    );

    test('finds the nearest enclosing options file', () {
      File(join(root.path, 'analysis_options.yaml')).writeAsStringSync('');
      File(join(root.path, 'pkg', 'analysis_options.yaml'))
          .writeAsStringSync('');
      expect(find(), '../analysis_options.yaml');
    });

    test('looks as far up as the root', () {
      File(join(root.path, 'analysis_options.yaml')).writeAsStringSync('');
      expect(find(), '../../analysis_options.yaml');
    });

    test('ignores the package\'s own options file', () {
      File(join(root.path, 'pkg', 'foo', 'analysis_options.yaml'))
          .writeAsStringSync('');
      expect(find(), isNull);
    });

    test('looks no further up than the root', () {
      File(join(root.path, 'analysis_options.yaml')).writeAsStringSync('');
      expect(
        findInheritedAnalysisOptions(
          join(root.path, 'pkg', 'foo'),
          root: join(root.path, 'pkg'),
        ),
        isNull,
      );
    });
  });

  group('formatDiagnosticSummary', () {
    Map<String, Object?> diagnostic(String code, String file, int line) => {
      'code': code,
      'severity': 'INFO',
      'location': {
        'file': '/sdk/$file',
        'range': {
          'start': {'offset': 0, 'line': line, 'column': 3},
          'end': {'offset': 1, 'line': line, 'column': 4},
        },
      },
    };

    test('counts each code, most frequent first, then by name', () {
      expect(
        formatDiagnosticSummary([
          diagnostic('b_code', 'pkg/foo/a.dart', 1),
          diagnostic('c_code', 'pkg/foo/a.dart', 2),
          diagnostic('a_code', 'pkg/foo/b.dart', 3),
          diagnostic('c_code', 'pkg/foo/b.dart', 4),
        ], root: '/sdk'),
        [
          '2 c_code',
          '1 a_code',
          '1 b_code',
          'pkg/foo/a.dart:1:3: b_code',
          'pkg/foo/a.dart:2:3: c_code',
          'pkg/foo/b.dart:3:3: a_code',
          'pkg/foo/b.dart:4:3: c_code',
        ],
      );
    });

    test('lists only the first few locations', () {
      expect(
        formatDiagnosticSummary(
          [for (var i = 1; i <= 4; i++) diagnostic('x', 'pkg/foo/a.dart', i)],
          root: '/sdk',
          maxLocations: 2,
        ),
        [
          '4 x',
          'pkg/foo/a.dart:1:3: x',
          'pkg/foo/a.dart:2:3: x',
          '...and 2 more',
        ],
      );
    });
  });

  group('Options.parse --owner-set', () {
    Set<OwnerSet>? parseOwners(List<String> args) =>
        Options.parse(args).filterOwnerSets;

    test('is null when the option is absent', () {
      expect(parseOwners([]), isNull);
    });

    test('treats commas as separating owners within a single set', () {
      expect(parseOwners(['--owner-set', 'developer_experience,model']), {
        OwnerSet.fromStrings(['developer_experience', 'model']),
      });
    });

    test('treats each occurrence as a separate owner set', () {
      expect(
        parseOwners([
          '--owner-set',
          'model',
          '--owner-set',
          'developer_experience,model',
        ]),
        {
          OwnerSet.fromStrings(['model']),
          OwnerSet.fromStrings(['developer_experience', 'model']),
        },
      );
    });

    test('treats `none` as the empty owner set', () {
      expect(parseOwners(['--owner-set', 'none']), {OwnerSet.fromStrings([])});
    });

    test('combines `none` with other owner sets', () {
      expect(parseOwners(['--owner-set', 'none', '--owner-set', 'model']), {
        OwnerSet.fromStrings([]),
        OwnerSet.fromStrings(['model']),
      });
    });

    test('treats `all` as no filter, even alongside other values', () {
      expect(parseOwners(['--owner-set', 'all']), isNull);
      expect(
        parseOwners(['--owner-set', 'model', '--owner-set', 'all']),
        isNull,
      );
    });

    test('ignores case and surrounding whitespace', () {
      expect(parseOwners(['--owner-set', ' Developer_Experience, MODEL ']), {
        OwnerSet.fromStrings(['developer_experience', 'model']),
      });
      expect(parseOwners(['--owner-set', ' None ']), {
        OwnerSet.fromStrings([]),
      });
    });
  });

  group('parseFormatterBugReports', () {
    test('returns nothing for ordinary parse errors', () {
      expect(
        parseFormatterBugReports('''
Could not format because the source could not be parsed:

line 3, column 6 of pkg/foo/bad.dart: Expected an identifier.
'''),
        isEmpty,
      );
    });

    test('extracts the file from each bug report', () {
      expect(
        parseFormatterBugReports('''
Could not format because the source could not be parsed:

line 3, column 6 of pkg/foo/bad.dart: Expected an identifier.
Hit a bug in the formatter when formatting /sdk/pkg/foo/a.dart.
The formatter produced unexpected output. Input was:
var x = const .r;
Please report at github.com/dart-lang/dart_style/issues.
Hit a bug in the formatter when formatting /sdk/pkg/foo/b.dart.\r
Please report at github.com/dart-lang/dart_style/issues.
'''),
        ['/sdk/pkg/foo/a.dart', '/sdk/pkg/foo/b.dart'],
      );
    });
  });

  group('parseGitStatusConflicts', () {
    test('returns nothing for empty output', () {
      expect(parseGitStatusConflicts(''), isEmpty);
      expect(parseGitStatusConflicts('\n'), isEmpty);
    });

    test('recognizes every unmerged status code', () {
      for (var status in ['AA', 'AU', 'DD', 'DU', 'UA', 'UD', 'UU']) {
        expect(parseGitStatusConflicts('$status pkg/foo/lib/foo.dart\n'), [
          'pkg/foo/lib/foo.dart',
        ], reason: 'status $status should be treated as a conflict');
      }
    });

    test('ignores ordinary staged and unstaged statuses', () {
      // These all occur routinely part way through `git revert -n`: `M ` is a
      // staged modification, ` M` an unstaged one, `A ` a staged add (as
      // produced by `enableLints` creating an `analysis_options.yaml`), and
      // `R ` a rename.
      expect(
        parseGitStatusConflicts('''
M  pkg/foo/lib/foo.dart
 M pkg/foo/lib/bar.dart
A  pkg/foo/analysis_options.yaml
D  pkg/foo/lib/gone.dart
R  pkg/foo/lib/old.dart -> pkg/foo/lib/new.dart
'''),
        isEmpty,
      );
    });

    test('picks conflicts out of a mixture of statuses', () {
      expect(
        parseGitStatusConflicts('''
M  pkg/foo/lib/foo.dart
UU pkg/foo/lib/bar.dart
A  pkg/foo/analysis_options.yaml
AA pkg/foo/lib/baz.dart
'''),
        ['pkg/foo/lib/bar.dart', 'pkg/foo/lib/baz.dart'],
      );
    });

    test('reports the new name of a conflicted rename', () {
      expect(
        parseGitStatusConflicts(
          'UU pkg/foo/lib/old.dart -> '
          'pkg/foo/lib/new.dart\n',
        ),
        ['pkg/foo/lib/new.dart'],
      );
    });

    test('tolerates CRLF line endings', () {
      expect(parseGitStatusConflicts('UU pkg/foo/lib/foo.dart\r\n'), [
        'pkg/foo/lib/foo.dart',
      ]);
    });

    test('rejects a line that is too short to hold a path', () {
      expect(() => parseGitStatusConflicts('UU\n'), throwsException);
    });

    test('rejects a line without the separating space', () {
      expect(
        () => parseGitStatusConflicts('UUXpkg/foo/lib/foo.dart\n'),
        throwsException,
      );
    });

    test('rejects a quoted path rather than mangling it', () {
      expect(
        () => parseGitStatusConflicts('UU "pkg/foo/lib/w\\303\\244.dart"\n'),
        throwsException,
      );
    });
  });

  group('parseUnrestorableFiles', () {
    test('returns nothing for empty output', () {
      expect(parseUnrestorableFiles(''), isEmpty);
    });

    test('reports untracked files of any kind', () {
      expect(
        parseUnrestorableFiles(
          '?? pkg/foo/lib/wip.dart\n?? pkg/foo/analysis_options.yaml\n',
        ),
        ['pkg/foo/lib/wip.dart', 'pkg/foo/analysis_options.yaml'],
      );
    });

    test('reports only the ignored files that are Dart', () {
      expect(
        parseUnrestorableFiles(
          '!! pkg/foo/lib/generated.dart\n!! pkg/foo/data.json.gz\n',
        ),
        ['pkg/foo/lib/generated.dart'],
      );
    });

    test('ignores files in hidden directories, which dart format skips', () {
      expect(
        parseUnrestorableFiles(
          '!! pkg/foo/.dart_tool/x.dart\n?? pkg/foo/.idea/y.dart\n',
        ),
        isEmpty,
      );
    });

    test('ignores tracked files', () {
      expect(
        parseUnrestorableFiles(' M pkg/foo/lib/a.dart\nA  pkg/foo/b.dart\n'),
        isEmpty,
      );
    });
  });

  group('reportedFollowUpCodes', () {
    List<String> reported(List<String> codes) => reportedFollowUpCodes([
      for (var code in codes) {'code': code, 'severity': 'INFO'},
    ], followUpCodes: followUpFixCodes['this-promotion']!);

    test('is empty when nothing is reported', () {
      expect(reported([]), isEmpty);
    });

    test('ignores codes that are not follow-ups', () {
      expect(
        reported(['unused_import', 'lines_longer_than_80_chars']),
        isEmpty,
      );
    });

    test('lists each reported follow-up once, sorted', () {
      expect(
        reported([
          'unnecessary_this',
          'unused_import',
          'unnecessary_cast',
          'unnecessary_this',
        ]),
        ['unnecessary_cast', 'unnecessary_this'],
      );
    });

    test('uses the follow-ups of the given lint set', () {
      expect(
        reportedFollowUpCodes([
          {'code': 'prefer_initializing_formals', 'severity': 'INFO'},
          {'code': 'unnecessary_cast', 'severity': 'WARNING'},
        ], followUpCodes: followUpFixCodes['constructor-syntax']!),
        ['prefer_initializing_formals'],
      );
    });
  });

  group('State git choreography, in a throwaway repository', () {
    late Directory repo;
    late State state;

    String git(List<String> args) =>
        execute('git', args, workingDirectory: repo.path);

    String path(String relativePath) => join(repo.path, relativePath);

    String read(String relativePath) =>
        File(path(relativePath)).readAsStringSync();

    void write(String relativePath, String contents) {
      File(path(relativePath))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(contents);
    }

    String commit(String message) {
      git(['add', '-A']);
      git(['commit', '-q', '--no-verify', '--allow-empty', '-m', message]);
      return git(['rev-parse', 'HEAD']).trim();
    }

    List<String> subjectsSince(String sha) =>
        git(['log', '--format=%s', '$sha..HEAD']).trim().split('\n');

    setUp(() {
      repo = Directory.systemTemp.createTempSync(
        'upgrade_sdk_language_version',
      );
      git(['init', '-q']);
      git(['config', 'user.name', 'Test']);
      git(['config', 'user.email', 'test@example.com']);
      git(['config', 'commit.gpgsign', 'false']);
      state = State(
        packageStates: {},
        targetVersion: Version.parse('3.15.0-0'),
        dryRun: false,
        root: repo.path,
      );
    });

    tearDown(() {
      repo.deleteSync(recursive: true);
    });

    group('collapseScratchCommits', () {
      test('without conflicts, leaves just the migration', () {
        write('a.dart', 'a\nb\n');
        write('b.dart', 'x\n');
        write('c.dart', 'y\n');
        var initialSha = state.initialSha = commit('Initial');
        write('b.dart', 'x-formatted\n');
        var formatSha = commit('Format');
        write('pubspec.yaml', 'bumped\n');
        commit('Bump language version');
        write('c.dart', 'y-reformatted\n');
        var reformatSha = commit('Re-format');
        write('a.dart', 'a\nb-migrated\n');
        var migrateSha = commit('Migrate');

        state.collapseScratchCommits(
          initialFormatSha: formatSha,
          reformatSha: reformatSha,
          migrateSha: migrateSha,
        );

        expect(subjectsSince(initialSha), ['Migrate']);
        expect(git(['rev-parse', 'HEAD~1']).trim(), initialSha);
        expect(read('a.dart'), 'a\nb-migrated\n');
        expect(read('b.dart'), 'x\n');
        expect(read('c.dart'), 'y\n');
        expect(read('pubspec.yaml'), 'bumped\n');
        expect(git(['status', '--porcelain']), isEmpty);
      });

      test('with a conflict, still reverts both formatting commits', () {
        // Reverting `Re-format` conflicts on `a.dart`, because `Migrate`
        // touched the same line. `Format` (which touched only `b.dart`) must
        // still be reverted, and no revert may be left in progress.
        write('a.dart', 'a\nb\nc\n');
        write('b.dart', 'x\n');
        write('c.dart', 'p\nq\n');
        var initialSha = state.initialSha = commit('Initial');
        write('b.dart', 'x-formatted\n');
        var formatSha = commit('Format');
        write('pubspec.yaml', 'bumped\n');
        commit('Bump language version');
        write('a.dart', 'a\nb-reformatted\nc\n');
        var reformatSha = commit('Re-format');
        write('a.dart', 'a\nb-migrated\nc\n');
        write('c.dart', 'p\nq-migrated\n');
        var migrateSha = commit('Migrate');

        state.collapseScratchCommits(
          initialFormatSha: formatSha,
          reformatSha: reformatSha,
          migrateSha: migrateSha,
        );

        expect(subjectsSince(initialSha), ['Migrate', 'Pre-format']);
        expect(git(['rev-parse', 'HEAD~2']).trim(), initialSha);
        // `Pre-format` is the new-language-version formatting of the
        // conflicted file, and nothing else.
        expect(
          git(['diff', '--name-only', initialSha, 'HEAD~1']).trim(),
          'a.dart',
        );
        expect(git(['show', 'HEAD~1:a.dart']), 'a\nb-reformatted\nc\n');
        expect(read('a.dart'), 'a\nb-migrated\nc\n');
        expect(read('b.dart'), 'x\n');
        expect(read('c.dart'), 'p\nq-migrated\n');
        expect(read('pubspec.yaml'), 'bumped\n');
        expect(git(['status', '--porcelain']), isEmpty);
        expect(Directory(path('.git/sequencer')).existsSync(), isFalse);
        expect(File(path('.git/REVERT_HEAD')).existsSync(), isFalse);
      });

      test('leaves no trace of a dropped package', () {
        write('pkg/foo/foo.dart', 'f\n');
        write('pkg/bar/bar.dart', 'g\n');
        write('pkg/bar/baz.dart', 'h\n');
        var initialSha = state.initialSha = commit('Initial');
        write('pkg/foo/foo.dart', 'f-formatted\n');
        var formatSha = commit('Format');
        write('pkg/bar/baz.dart', 'h-reformatted\n');
        var reformatSha = commit('Re-format');
        write('pkg/foo/analysis_options.yaml', 'new\n');
        write('pkg/foo/foo.dart', 'f-migrated\n');
        write('pkg/bar/bar.dart', 'g-migrated\n');
        var migrateSha = commit('Migrate');
        state.droppedPackagePaths.add(path('pkg/foo'));

        state.collapseScratchCommits(
          initialFormatSha: formatSha,
          reformatSha: reformatSha,
          migrateSha: migrateSha,
        );

        expect(
          git(['diff', '--name-only', initialSha, 'HEAD']).trim(),
          'pkg/bar/bar.dart',
        );
        expect(read('pkg/foo/foo.dart'), 'f\n');
        expect(
          File(path('pkg/foo/analysis_options.yaml')).existsSync(),
          isFalse,
        );
        expect(
          git(['status', '--porcelain', '--untracked-files=all']),
          isEmpty,
        );
      });
    });

    test('gitDiscardChanges removes a newly staged file', () {
      write('pkg/foo/foo.dart', 'f\n');
      commit('Initial');
      write('pkg/foo/foo.dart', 'changed\n');
      write('pkg/foo/analysis_options.yaml', 'new\n');
      state.gitAdd([path('pkg/foo/analysis_options.yaml')]);

      state.gitDiscardChanges(path('pkg/foo'));

      expect(read('pkg/foo/foo.dart'), 'f\n');
      expect(File(path('pkg/foo/analysis_options.yaml')).existsSync(), isFalse);
      expect(git(['status', '--porcelain', '--untracked-files=all']), isEmpty);
    });

    test('abandonScratchBranch removes a newly staged file', () {
      write('pkg/foo/foo.dart', 'f\n');
      var initialSha = state.initialSha = commit('Initial');
      state.gitCreateBranch('scratch');
      write('pkg/foo/foo.dart', 'f-formatted\n');
      commit('Format');
      write('pkg/foo/analysis_options.yaml', 'new\n');
      state.gitAdd([path('pkg/foo/analysis_options.yaml')]);

      expect(
        state.abandonScratchBranch(scratchBranch: 'scratch', originalRef: null),
        isTrue,
      );

      expect(git(['rev-parse', 'HEAD']).trim(), initialSha);
      expect(git(['branch', '--list', 'scratch']), isEmpty);
      expect(read('pkg/foo/foo.dart'), 'f\n');
      expect(File(path('pkg/foo/analysis_options.yaml')).existsSync(), isFalse);
      expect(git(['status', '--porcelain', '--untracked-files=all']), isEmpty);
    });

    test('abandonScratchBranch reports a failed cleanup', () {
      commit('Initial');
      state.initialSha = '0' * 40;
      state.gitCreateBranch('scratch');

      expect(
        state.abandonScratchBranch(scratchBranch: 'scratch', originalRef: null),
        isFalse,
      );
    });

    group('checkGitClean', () {
      setUp(() {
        write('pkg/foo/pubspec.yaml', 'environment:\n  sdk: ^3.9.0\n');
        write('pkg/foo/lib/a.dart', 'void a() {}\n');
        write('.gitignore', 'generated.dart\n.dart_tool/\n');
        commit('Initial');
        state = State(
          packageStates: {
            'foo': PackageState(
              PackageInfo(
                path: path('pkg/foo'),
                name: 'foo',
                isPublished: false,
                ownerSet: OwnerSet.fromStrings([]),
                sdkConstraint: '^3.9.0',
                sdkConstraintNode: loadYamlNode('^3.9.0') as YamlScalar,
              ),
            ),
          },
          targetVersion: Version.parse('3.15.0-0'),
          dryRun: false,
          root: repo.path,
        );
      });

      test('accepts a clean package', () {
        state.checkGitClean();
      });

      test('rejects an untracked file in a selected package', () {
        write('pkg/foo/lib/wip.dart', 'void   wip( ) {   }\n');
        expect(state.checkGitClean, throwsException);
      });

      test('rejects an ignored Dart file in a selected package', () {
        write('pkg/foo/lib/generated.dart', 'void generated() {}\n');
        expect(state.checkGitClean, throwsException);
      });

      test('accepts files in hidden directories', () {
        write('pkg/foo/.dart_tool/cache.dart', 'void cache() {}\n');
        state.checkGitClean();
      });

      test('accepts an untracked file outside the selected packages', () {
        write('pkg/bar/lib/wip.dart', 'void wip() {}\n');
        state.checkGitClean();
      });
    });

    group('package config', () {
      // Stands in for the real script: like `pub get`, it records the
      // package's SDK constraint in the gitignored package config.
      const fakeGenerator = '''
import os, re
s = open('pkg/foo/pubspec.yaml').read()
os.makedirs('.dart_tool', exist_ok=True)
open('.dart_tool/package_config.json', 'w').write(
    re.search(r'sdk: (\\S+)', s).group(1))
''';

      String packageConfig() => read('.dart_tool/package_config.json');

      setUp(() {
        write('.gitignore', '.dart_tool/\n');
        write('tools/generate_package_config.py', fakeGenerator);
        write('pkg/foo/pubspec.yaml', 'environment:\n  sdk: ^3.9.0\n');
      });

      test('abandonScratchBranch restores it after a bump', () {
        state.initialSha = commit('Initial');
        state.generatePackageConfig();
        state.gitCreateBranch('scratch');
        state.versionsBumped = true;
        write('pkg/foo/pubspec.yaml', 'environment:\n  sdk: ^3.15.0-0\n');
        commit('Bump language version');
        state.generatePackageConfig();
        expect(packageConfig(), '^3.15.0-0');

        state.abandonScratchBranch(scratchBranch: 'scratch', originalRef: null);

        expect(packageConfig(), '^3.9.0');
      });

      test('abandonScratchBranch leaves it alone before a bump', () {
        state.initialSha = commit('Initial');
        state.gitCreateBranch('scratch');
        state.abandonScratchBranch(scratchBranch: 'scratch', originalRef: null);

        expect(
          File(path('.dart_tool/package_config.json')).existsSync(),
          isFalse,
        );
      });

      test('restorePackageConfig matches a dropped package again', () {
        state.initialSha = commit('Initial');
        state.versionsBumped = true;
        write('pkg/foo/pubspec.yaml', 'environment:\n  sdk: ^3.15.0-0\n');
        state.generatePackageConfig();
        // As `restoreDroppedPackages` would.
        git(['checkout', '--no-overlay', state.initialSha, '--', 'pkg/foo']);

        state.restorePackageConfig();

        expect(packageConfig(), '^3.9.0');
      });
    }, skip: _skipUnlessAvailable('python3'));
  }, skip: _skipUnlessAvailable('git'));
}

/// Returns a reason to skip tests that need [executable], or `null` if it's
/// available.
///
/// Some of the bots that run these tests don't have every tool installed. On
/// Windows, running a missing executable throws a [ProcessException]. On
/// macOS without the Xcode command line tools, `/usr/bin/git` is a stub that
/// fails, so the exit code needs checking too.
String? _skipUnlessAvailable(String executable) {
  try {
    if (Process.runSync(executable, ['--version']).exitCode == 0) return null;
  } on ProcessException {
    // Not installed; fall through.
  }
  return '`$executable` is not available on this machine';
}
