// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Bumps the SDK language version of one or more packages under `pkg/`, and
/// applies the fixes that the new language version makes possible.
///
/// Run with `--help` for the available options, or with `--dry-run` to see
/// what a run would do without touching anything.
///
/// ## Why this is harder than "bump the version and run `dart fix`"
///
/// The formatter's behavior depends on the language version, so bumping the
/// version reformats the package. Done naively, the result is a diff in which
/// a handful of interesting changes are buried under thousands of lines of
/// reformatting, which is not reviewable.
///
/// The formatting can't simply be skipped either: `dart fix` writes
/// unformatted code, so leaving things unformatted only trades one kind of
/// noise for another.
///
/// ## The revert/read-tree choreography
///
/// So the tool deliberately makes the mess and then takes it back out again,
/// on a scratch branch, letting git's merge machinery work out how. It builds
/// up five commits:
///
/// 1. `Format` — format at the *old* language version. Any pre-existing
///    formatting drift is absorbed here rather than showing up in the result.
/// 2. `Bump language version`.
/// 3. `Re-format` — format again, now at the new language version.
/// 4. `Migrate` — enable the lints, run `dart fix`, and format once more.
/// 5. `Revert formatting` — `git revert -n` of commits 3 and 1. What survives
///    is the migration, without the reformatting.
///
/// Reverting, rather than never formatting in the first place, is what lets
/// `dart fix` see (and produce) well formatted code, and it makes git decide
/// hunk by hunk which lines were formatting and which were migration.
///
/// Those five commits are then collapsed back onto the commit the run started
/// from: `git reset --hard` moves `HEAD` back to it, and `git read-tree -m -u`
/// points the index and working tree at the tree of commit 5. Everything the
/// migration did is then a single uncommitted change, ready to be committed as
/// one `Migrate` commit. (`git checkout <sha> -- .` wouldn't do: it would
/// leave behind any file that the migration deleted.)
///
/// ## Files where formatting and migration collide
///
/// Reverting the formatting conflicts wherever `dart fix` touched a line that
/// reformatting had also touched. Those files can't be given a noise-free
/// diff, so they get an honest one instead: a `Pre-format` commit reformats
/// them and does nothing else, and the `Migrate` commit then carries their
/// migrated content. Every other file still gets a clean, formatting-free
/// diff.
///
/// A successful run therefore leaves either one commit (`Migrate`) or two
/// (`Pre-format`, then `Migrate`) on the scratch branch.
///
/// The run also regenerates `.dart_tool/package_config.json`, which then
/// records the migrated packages' new language versions. If the run is
/// abandoned, or some packages are dropped, the tool regenerates it again to
/// match. But after a successful run, it's right only for the scratch branch,
/// and stale for any other revision. After checking out another revision, run
/// `python3 tools/generate_package_config.py` before running anything that
/// depends on language versions (such as the analyzer, the formatter, or code
/// generators).
///
/// ## Exit status
///
/// 0 if the migration was committed, even if some packages had to be dropped
/// along the way; 1 if the run was thrown away; and 2 if even cleaning up
/// after that failed, leaving the repository part way through the run.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:analyzer_utilities/tool/sdk_packages.dart';
import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  var options = Options.parse(args);
  if (options.help) {
    showUsageAndExit(exitCode: 0);
  }
  var filteredPackages = packages;
  if (options.filterIsPublished case var filter?) {
    filteredPackages = filteredPackages
        .where((p) => p.isPublished == filter)
        .toList();
  }
  if (options.showOwners) {
    var header = [
      'Owner sets',
      if (options.filterIsPublished case var filterIsPublished?)
        'owning packages that ${filterIsPublished ? 'are' : 'are not'} '
            'published to pub',
    ].join(' ');
    print('$header:');
    for (var MapEntry(key: ownerSet, value: packages)
        in filteredPackages.groupListsBy((p) => p.ownerSet).entries) {
      var ownersArg = ownerSet.isEmpty ? 'none' : ownerSet.join(',');
      var packageList = packages.map((p) => p.name).join(', ');
      print('--owners $ownersArg ($packageList)');
    }
    return;
  }
  if (options.showLintSets) {
    printAvailableLintSets();
    return;
  }
  var lints = <String>{...options.lints};
  var lintSetName = options.lintSet;
  if (lintSetName == null && lints.isEmpty) {
    // Neither `--lint` nor `--lint-set` was given, so fall back to the
    // default lint set. Note that this deliberately doesn't happen when
    // `--lint` is given on its own, since silently migrating to a whole
    // extra lint set would be surprising.
    lintSetName = lintSets.keys.first;
  }
  if (lintSetName != null) {
    if (lintSets[lintSetName] case var setLints?) {
      lints.addAll(setLints);
    } else {
      print('Lint set ${json.encode(lintSetName)} not found.');
      printAvailableLintSets();
      exit(1);
    }
  }
  var lintSet = lints.toList();
  var followUpCodes = followUpFixCodes[lintSetName] ?? const <String>[];
  Version targetVersion;
  if (options.targetVersion case var rawTargetVersion?) {
    try {
      targetVersion = Version.parse(rawTargetVersion);
    } on FormatException catch (e) {
      print(
        'Could not parse --target-version '
        '${json.encode(rawTargetVersion)}: ${e.message}',
      );
      print('Expected a full semantic version, e.g. `3.14.0-0`.');
      exit(1);
    }
  } else {
    print('--target-version is required.');
    print('');
    showUsageAndExit();
  }
  if (checkTargetVersion(
        targetVersion,
        versionFileContents: File(join(repoRoot, 'tools', 'VERSION'))
            .readAsStringSync(),
      )
      case var problem?) {
    print(problem);
    exit(1);
  }
  if (options.filterOwnerSets case var filter?) {
    filteredPackages = filteredPackages
        .where((p) => filter.contains(p.ownerSet))
        .toList();
  }
  if (options.filterPackages case var filter?) {
    filteredPackages = filteredPackages
        .where((p) => filter.contains(p.name))
        .toList();
  }
  if (filteredPackages.isEmpty) {
    print('No packages selected.');
    exit(1);
  }
  var state = State(
    packageStates: {
      for (var packageInfo in filteredPackages)
        packageInfo.name: PackageState(packageInfo),
    },
    targetVersion: targetVersion,
    dryRun: options.dryRun,
  );

  // Before the `--dry-run` branch, since it's just as useful to learn you're
  // on the wrong SDK while planning as while running.
  state.warnIfPrebuiltSdk();

  if (options.dryRun) {
    // Deliberately before `checkGitClean`: a dry run neither reads nor writes
    // git state, so it's useful even on a dirty tree.
    try {
      state.checkCurrentLanguageVersion();
      state.describePlan(
        lintSet: lintSet,
        followUpCodes: followUpCodes,
        experiments: options.experiments,
        skipPreAnalysis: options.skipPreAnalysis,
        skipPostAnalysis: options.skipPostAnalysis,
      );
    } on Skip catch (e) {
      print('Nothing to do: ${e.message}');
    }
    return;
  }

  try {
    state.checkGitClean();
  } on Exception catch (e) {
    print('$e');
    exit(1);
  }
  state.initialSha = state.gitGetSha();
  state.warnIfColocatedWithJj();
  // `null` means `HEAD` was already detached. That's the normal case in a
  // repository colocated with `jj`, since `jj` exports its working-copy
  // commit's parent as a detached `HEAD`.
  var originalRef = state.gitGetCurrentBranch();
  var scratchBranch =
      'upgrade-sdk-language-version-'
      '${DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-')}';
  state.gitCreateBranch(scratchBranch);
  try {
    state.checkCurrentLanguageVersion();
    if (!options.skipPreAnalysis) {
      state.generatePackageConfig();
      state.checkForAnalysisErrors();
    }
    // Phase one: build up the five scratch commits described in the library
    // doc comment, deliberately reformatting along the way.
    state.format();
    state.gitCommit('Format');
    var initialFormatSha = state.gitGetSha();
    state.bumpLanguageVersion();
    state.gitCommit('Bump language version');
    state.generatePackageConfig();
    state.format();
    state.gitCommit('Re-format');
    var reformatSha = state.gitGetSha();
    state.enableLints(lintSet: lintSet, experiments: options.experiments);
    state.dartMigrate(lints: lintSet, followUpCodes: followUpCodes);
    state.format();
    state.gitCommit('Migrate');
    var migrateSha = state.gitGetSha();
    state.collapseScratchCommits(
      initialFormatSha: initialFormatSha,
      reformatSha: reformatSha,
      migrateSha: migrateSha,
    );
    print('Done.');
    // Any packages dropped after the version bump have been restored to their
    // old language version, which the package config doesn't know about yet.
    if (state.droppedPackagePaths.isNotEmpty) state.restorePackageConfig();
    if (!options.skipPostAnalysis) state.reportRemainingDiagnostics();
    printExperimentWarning(options.experiments);
    print('');
    print('The migration is on branch $scratchBranch, which is now checked');
    print('out. To go back without keeping it:');
    print('  git checkout ${originalRef ?? state.initialSha}');
    print('  git branch -D $scratchBranch');
    print('');
    print('.dart_tool/package_config.json now matches the migrated packages.');
    print('After checking out any other revision, regenerate it with:');
    print('  python3 tools/generate_package_config.py');
  } on Skip catch (e) {
    print('Skipping further steps: ${e.message}');
    exitCode = _exitCodeAfterAbandoning(
      state,
      scratchBranch: scratchBranch,
      originalRef: originalRef,
    );
  } catch (e) {
    print('Aborting due to error: $e');
    exitCode = _exitCodeAfterAbandoning(
      state,
      scratchBranch: scratchBranch,
      originalRef: originalRef,
    );
  }
}

const lintSets = {
  'constructor-syntax': [
    'unnecessary_type_name_in_constructor',
    'unnecessary_const_in_enum_constructor',
  ],
  'primary-constructors-maximal': [
    'use_primary_constructors',
    'use_declaring_parameters',
    'unnecessary_type_name_in_constructor',
    'empty_container_bodies',
    'initialize_in_field_declaration',
  ],
  // `unnecessary_this_alias` only fires where `this-promotion` is enabled,
  // i.e. from language version 3.15 on. Targeting an earlier version needs
  // `--enable-experiment this-promotion` too.
  'this-promotion': ['unnecessary_this_alias'],
};

/// Further diagnostics for `dart fix` to fix when a lint set is applied,
/// without enabling anything for them in `analysis_options.yaml`.
///
/// These clean up the knock-on effects of a migration, and are only fixed in
/// a package if analyzing it shows that it reports them. That matters
/// because `dart fix --code=...` turns on any lint it's given, even in a
/// package that doesn't enable it; passing these codes unconditionally would
/// impose those lints on every package.
const followUpFixCodes = {
  'constructor-syntax': [
    // Crossing language version 3.12 (`private-named-parameters`) lets
    // initializing formals have private names, so constructors that assign a
    // named parameter to a private field become reportable.
    'prefer_initializing_formals',
  ],
  'this-promotion': [
    // A cast guarded by `this is T` becomes redundant once `this` promotes.
    'unnecessary_cast',
    // Removing such a cast can leave an explicit `this.` that's no longer
    // needed (`(this as Field).isFinal` becomes `this.isFinal`).
    'unnecessary_this',
    // Removing `var self = this;` can leave a block body containing nothing
    // but a `return`.
    'prefer_expression_function_bodies',
  ],
};

final argParser = ArgParser()
  ..addMultiOption(
    'owners',
    abbr: 'o',
    // Commas separate the owners *within* a single owner set, so `args` must
    // not split them; each occurrence of the option is a separate owner set.
    splitCommas: false,
    valueHelp: 'owner,owner,...',
    help:
        'Only consider packages with (one of) the given owner set(s). Repeat '
        'the option to accept more than one owner set. Note that a package '
        'matches only if its owners are exactly the ones listed.',
  )
  ..addMultiOption(
    'package',
    abbr: 'p',
    help: 'Only migrate the given package(s)',
  )
  ..addFlag(
    'published',
    help: "Only consider packages that are/aren't published to pub",
  )
  ..addFlag(
    'show-owners',
    negatable: false,
    help: 'Show all meaningful values that can be passed as --owners',
  )
  ..addFlag(
    'skip-pre-analysis',
    help:
        "Don't check for absence of analysis errors before starting version "
        'bump',
  )
  ..addFlag(
    'skip-post-analysis',
    help:
        "Don't analyze the migrated packages and report what's found after "
        'the migration is committed',
  )
  ..addMultiOption(
    'lint',
    help:
        'Enable the given lint(s) directly, rather than (or in addition to) '
        'a predefined lint set.',
    valueHelp: 'lint',
  )
  ..addOption(
    'lint-set',
    abbr: 'l',
    help:
        'Which lint set to enable. Defaults to '
        '${lintSets.keys.first} if --lint is not given.',
  )
  ..addMultiOption(
    'enable-experiment',
    help:
        'Analyzer experiment(s) to enable for the duration of the migration. '
        'Needed when the lints being applied are themselves gated on an '
        'experiment.',
    valueHelp: 'experiment',
  )
  ..addOption(
    'target-version',
    abbr: 't',
    help:
        'The SDK version to bump packages to, e.g. `3.14.0-0`. Required '
        'unless one of the `--show-*` flags is passed.',
    valueHelp: 'version',
  )
  ..addFlag(
    'dry-run',
    abbr: 'n',
    negatable: false,
    help:
        'Describe what would be done, without modifying the working tree or '
        'the git repository in any way.',
  )
  ..addFlag(
    'show-lint-sets',
    negatable: false,
    help: 'Show all available lint sets',
  )
  ..addFlag('help', abbr: 'h', help: 'Shows this help message');

final String dartExecutablePath = _computeDartExecutablePath();

/// The two-character status codes in `git status --porcelain` output that
/// denote an unmerged (conflicted) path.
///
/// See the "Short Format" section of `git status --help`. Note that `AA` and
/// `DD` are conflicts even though neither character is `U`.
const _gitConflictStatuses = {'AA', 'AU', 'DD', 'DU', 'UA', 'UD', 'UU'};

/// Adds [entries] to the `<outerKey>:` / `<innerKey>:` section of an
/// `analysis_options.yaml` file whose contents are [contents], or `null` if
/// the file doesn't exist yet. Either level is created if it's absent.
///
/// Returns the new contents of the file, or `null` if no change is needed
/// because every entry is already present.
///
/// The edit is done textually rather than by re-serializing the parsed YAML,
/// so that comments and formatting elsewhere in the file are preserved.
String? addAnalysisOptionsEntries(
  String? contents, {
  required String outerKey,
  required String innerKey,
  required List<String> entries,
}) {
  // Everything below inserts whole lines, so text inserted at the end of a
  // file whose last line has no newline would be glued onto that line.
  if (contents != null && contents.isNotEmpty && !contents.endsWith('\n')) {
    contents += '\n';
  }
  // The text to be inserted, keyed by the offset to insert it at. Keeping a
  // sorted section sorted can mean inserting in several different places, so
  // this is a map rather than a single buffer.
  var insertions = <int, StringBuffer>{};
  var indentation = 0;
  var useMapStyle = false;
  void lineToInsert(int insertionPoint, String line) {
    insertions
        .putIfAbsent(insertionPoint, StringBuffer.new)
        .writeln(' ' * indentation + line);
  }

  // The inner section may be written either as a list (`- foo`) or as a map
  // (`foo: true`). Both are valid, so new entries have to be written in
  // whichever style the file already uses.
  String entryLine(String entry) => useMapStyle ? '$entry: true' : '- $entry';

  // A node's span starts at the node itself, but entries are inserted at the
  // start of a line, so that the indentation can be written out too.
  int lineStartOf(YamlNode node) =>
      node.span.start.offset - node.span.start.column;

  var parsed = contents == null ? null : loadYaml(contents) as YamlMap?;
  var outerSection = switch (parsed?.nodes[outerKey]) {
    null => null,
    YamlMap(style: != CollectionStyle.BLOCK) => throw UnimplementedError(
      '$outerKey section is not in block style',
    ),
    YamlMap map => map,
    _ => throw UnimplementedError('$outerKey section is not a map'),
  };

  var innerSection = outerSection?.nodes[innerKey];
  if (innerSection != null) {
    List<YamlNode> existingNodes;
    switch (innerSection) {
      case YamlList(:var style, :var nodes):
        if (style != CollectionStyle.BLOCK) {
          throw UnimplementedError('$innerKey section is not in block style');
        }
        existingNodes = nodes;
      case YamlMap(:var style, :var nodes):
        if (style != CollectionStyle.BLOCK) {
          throw UnimplementedError('$innerKey section is not in block style');
        }
        useMapStyle = true;
        for (var MapEntry(:key, :value) in innerSection.entries) {
          if (value == false && entries.contains(key)) {
            // The package deliberately disables something this migration
            // needs. Silently overriding that would disregard a deliberate
            // decision, and silently leaving it would make the migration
            // mysteriously do nothing, so fail loudly instead.
            throw UnimplementedError(
              'analysis_options.yaml sets `$key: false`, but the migration '
              'needs it enabled',
            );
          }
        }
        // The keys of `nodes` are the key nodes themselves, so unlike `keys`
        // they carry the spans needed to work out where to insert.
        existingNodes = [for (var key in nodes.keys) key as YamlNode];
      default:
        throw UnimplementedError(
          '$innerKey section is neither a list nor a map',
        );
    }
    var existingEntries = [for (var node in existingNodes) '${node.value}'];
    var alreadyPresent = existingEntries.toSet();
    var newEntries = entries.where((e) => !alreadyPresent.contains(e)).toList()
      ..sort();
    if (newEntries.isEmpty) return null;
    indentation = innerSection.span.start.column;
    // Where an entry that sorts after all the existing ones goes: the start of
    // the line after the section's last entry. This has to be worked out from
    // the last entry itself, not from the section: a block collection's span
    // runs on over any blank lines after it, up to the start of whatever comes
    // next, so when another key follows the section, its span ends at the
    // start of that key's line.
    var lastEntry = switch (innerSection) {
      YamlList(:var nodes) => nodes.last,
      YamlMap(:var nodes) => nodes.values.last,
      _ => throw StateError('Unreachable'),
    };
    var newline = contents!.indexOf('\n', lastEntry.span.end.offset);
    var endOfSection = newline < 0 ? contents.length : newline + 1;
    // A section that is already sorted is kept sorted. One that isn't has no
    // order to respect, so its new entries simply go at the end, which is the
    // least surprising place for them.
    var sorted = existingEntries.isSorted();
    for (var entry in newEntries) {
      var index = sorted
          ? lowerBound(existingEntries, entry)
          : existingEntries.length;
      lineToInsert(
        index < existingEntries.length
            // A span starts at the entry itself, which is *after* any comment
            // written above it. Inserting there would leave the comment
            // sitting above the newly added entry, silently re-attributing it,
            // so back up over any such comment lines first.
            ? _skipBackOverComments(contents, lineStartOf(existingNodes[index]))
            : endOfSection,
        entryLine(entry),
      );
    }
  } else {
    int insertionPoint;
    if (outerSection case var outerSection?) {
      // The outer section exists but has no `$innerKey` entry of its own, so
      // the new entry has to be nested inside it rather than written at the
      // top of the file.
      indentation = outerSection.span.start.column;
      insertionPoint = _skipBackOverComments(
        contents!,
        lineStartOf(outerSection),
      );
    } else {
      // Neither level exists, so both are created. A brand new top level
      // section goes below the comment block at the top of the file, which is
      // usually the license header and needs to stay where it is.
      insertionPoint = contents == null ? 0 : _skipLeadingComments(contents);
      lineToInsert(insertionPoint, '$outerKey:');
      indentation += 2;
    }
    lineToInsert(insertionPoint, '$innerKey:');
    indentation += 2;
    for (var entry in [...entries]..sort()) {
      lineToInsert(insertionPoint, entryLine(entry));
    }
    if (outerSection == null &&
        contents != null &&
        insertionPoint < contents.length) {
      // Keep a blank line between the new section and whatever follows it.
      insertions[insertionPoint]!.writeln();
    }
  }

  var text = contents ?? '';
  var result = StringBuffer();
  var previousOffset = 0;
  for (var insertionPoint in insertions.keys.toList()..sort()) {
    result
      ..write(text.substring(previousOffset, insertionPoint))
      ..write(insertions[insertionPoint]);
    previousOffset = insertionPoint;
  }
  result.write(text.substring(previousOffset));
  return result.toString();
}

/// Computes what an `analysis_options.yaml` file whose contents are
/// [contents] (or `null`, if it doesn't exist yet) should look like with
/// [lintSet] and [experiments] enabled.
///
/// When the file doesn't exist yet, the new file starts with an `include:` of
/// [include], if given. The analyzer uses only the nearest
/// `analysis_options.yaml`, so without that, a new file would silently stop
/// the package from inheriting the options it was using until now.
///
/// Returns `null` if no change is needed.
String? addLintsAndExperiments(
  String? contents, {
  required List<String> lintSet,
  required List<String> experiments,
  String? include,
}) {
  var result = contents;
  for (var (outerKey, innerKey, entries) in [
    ('linter', 'rules', lintSet),
    ('analyzer', 'enable-experiment', experiments),
  ]) {
    if (entries.isEmpty) continue;
    // Each section is applied to the result of the previous one, so that the
    // offsets computed while parsing always refer to the text actually being
    // edited.
    if (addAnalysisOptionsEntries(
          result,
          outerKey: outerKey,
          innerKey: innerKey,
          entries: entries,
        )
        case var updated?) {
      result = updated;
    }
  }
  if (result == contents) return null;
  if (contents == null && include != null) {
    // `include:` conventionally comes first in the file. It can't simply be
    // put in the file before the loop above, because
    // `addAnalysisOptionsEntries` writes a brand new top-level section at the
    // very top of the file (below any leading comments), which would push the
    // `include:` down below it. So it's prepended now instead.
    return 'include: $include\n\n$result';
  }
  return result;
}

/// Returns [pubspecText] with its SDK constraint replaced by a caret
/// constraint on [targetVersion].
///
/// [sdkConstraintNode] must be the constraint's node as parsed from
/// [pubspecText], since its span says what to replace.
///
/// Throws [UnimplementedError] if the existing constraint isn't a caret
/// constraint, or is written in a scalar style whose quoting this doesn't know
/// how to preserve.
String bumpSdkConstraint(
  String pubspecText, {
  required YamlScalar sdkConstraintNode,
  required Version targetVersion,
}) {
  var rawSdkConstraint = sdkConstraintNode.value as String;
  if (!rawSdkConstraint.startsWith('^')) {
    throw UnimplementedError(
      "Don't know how to bump version string ${json.encode(rawSdkConstraint)}",
    );
  }
  var span = sdkConstraintNode.span;
  var replacementStart = span.start.offset;
  var replacementEnd = span.end.offset;
  switch (sdkConstraintNode.style) {
    case ScalarStyle.PLAIN:
      break;
    case ScalarStyle.SINGLE_QUOTED:
      // The span covers the quotes as well as the constraint, and the quotes
      // need to survive the replacement.
      replacementStart++;
      replacementEnd--;
    default:
      throw UnimplementedError(
        "Don't know how to replace scalar of style ${sdkConstraintNode.style}",
      );
  }
  return [
    pubspecText.substring(0, replacementStart),
    '^$targetVersion',
    pubspecText.substring(replacementEnd),
  ].join();
}

/// Checks [targetVersion] against the version of the SDK being built, as
/// described by [versionFileContents], the contents of `tools/VERSION`.
///
/// Returns a description of the problem, or `null` if there is none.
///
/// Only the major and minor versions are compared, since those are all that
/// a language version consists of. A target above the SDK's version would
/// make `pub get` (run by `tools/generate_package_config.py`) fail part way
/// through the run. And while the SDK's own version is still in development
/// (any channel other than `stable`), a target of the same major and minor
/// version must be a prerelease: the SDK's version is then a prerelease
/// itself, which a constraint such as `^3.15.0` doesn't allow.
String? checkTargetVersion(
  Version targetVersion, {
  required String versionFileContents,
}) {
  // Decode the SDK's current version from `tools/VERSION`, whose lines are
  // `KEY VALUE` pairs (e.g. `MINOR 15`), interspersed with `#` comments.
  var fields = {
    for (var line in const LineSplitter().convert(versionFileContents))
      if (!line.startsWith('#'))
        if (line.trim().split(RegExp(r'\s+')) case [var key, var value])
          key: value,
  };
  var channel = fields['CHANNEL'];
  var major = int.tryParse(fields['MAJOR'] ?? '');
  var minor = int.tryParse(fields['MINOR'] ?? '');
  if (channel == null || major == null || minor == null) {
    return 'Could not find CHANNEL, MAJOR and MINOR in tools/VERSION.';
  }
  var comparison = targetVersion.major != major
      ? targetVersion.major.compareTo(major)
      : targetVersion.minor.compareTo(minor);
  if (comparison > 0) {
    return 'Target version $targetVersion is newer than the SDK being built '
        '($major.$minor, according to tools/VERSION).';
  }
  if (comparison == 0 && channel != 'stable' && !targetVersion.isPreRelease) {
    return 'Target version $targetVersion is not a prerelease, but the SDK '
        'being built ($major.$minor, channel $channel, according to '
        'tools/VERSION) is still in development, and its prerelease versions '
        "wouldn't satisfy ^$targetVersion. Use $major.$minor.0-0 instead.";
  }
  return null;
}

/// Decides what a package whose SDK constraint is [rawSdkConstraint] needs,
/// given that the migration targets [targetVersion], and returns that verdict
/// along with the lowest SDK version the constraint allows.
///
/// Throws [Skip] if the package has to be left out of the migration
/// altogether, or [Exception] if the constraint is in a shape this tool can't
/// reason about.
({Version minVersion, SdkConstraintVerdict verdict}) classifySdkConstraint(
  String rawSdkConstraint, {
  required Version targetVersion,
}) {
  Version minVersion;
  switch (VersionConstraint.parse(rawSdkConstraint)) {
    case Version v:
      minVersion = v;
    case VersionRange(:var min, :var includeMin):
      minVersion = min ?? (throw Exception('No minimum version'));
      if (!includeMin) {
        // Note: we could support this if needed; just being lazy since this
        // script won't be run very often.
        throw Exception('Low end of range not inclusive');
      }
    default:
      // Note: we could support this if needed; just being lazy since this
      // script won't be run very often.
      throw Exception('Complex version constraint');
  }

  // Only the major and minor versions matter, since that's all a language
  // version is. In particular, a package at `^3.14.0-0` is already up to date
  // for a target of `3.14.0`.
  if (minVersion.major > targetVersion.major ||
      (minVersion.major == targetVersion.major &&
          minVersion.minor >= targetVersion.minor)) {
    // Already at or beyond the target version, so there is nothing to bump.
    // The package is still migrated, in case it hasn't yet had this lint set
    // applied to it.
    return (minVersion: minVersion, verdict: SdkConstraintVerdict.upToDate);
  }
  if (minVersion.major != targetVersion.major) {
    // A major version bump implies breaking changes that this script has no
    // way to reason about.
    throw Skip(
      'SDK version $minVersion differs from target $targetVersion by a major '
      'version',
    );
  }
  return (
    minVersion: minVersion,
    verdict: targetVersion.minor - minVersion.minor > 1
        ? SdkConstraintVerdict.farBehind
        : SdkConstraintVerdict.needsBump,
  );
}

/// Runs [executable] with [args] from [workingDirectory], which defaults to
/// the root of the SDK repository, and returns its stdout.
///
/// Everything this tool shells out to — `git`, `dart`, and
/// `tools/generate_package_config.py` — assumes it is being run from the repo
/// root, so the working directory is pinned rather than inherited. That makes
/// the tool independent of the directory the user happened to invoke it from.
String execute(
  String executable,
  List<String> args, {
  bool Function(ProcessResult)? checkOk,
  String? workingDirectory,
}) {
  return withErrorContext(
    context: () => 'command: ${[executable, ...args].join(' ')}',
    () {
      var processResult = Process.runSync(
        executable,
        args,
        workingDirectory: workingDirectory ?? repoRoot,
      );
      var isOk = checkOk?.call(processResult) ?? processResult.exitCode == 0;
      if (!isOk) {
        // Some commands report failure on stdout rather than stderr, notably
        // `tools/generate_package_config.py`, which prints `pub get`'s
        // complaints. So include the end of stdout too.
        var stdoutLines = const LineSplitter().convert(
          processResult.stdout as String,
        );
        var stdoutTail = stdoutLines
            .skip(max(0, stdoutLines.length - 20))
            .join('\n');
        throw Exception(
          'Subprocess exited with code ${processResult.exitCode}\n'
          'stdout (last ${min(20, stdoutLines.length)} lines):\n'
          '$stdoutTail\n'
          'stderr:\n'
          '${processResult.stderr as String}',
        );
      }
      return processResult.stdout as String;
    },
  );
}

/// Returns the path, relative to [packagePath], of the `analysis_options.yaml`
/// that the package at [packagePath] inherits when it has none of its own.
///
/// That's the nearest one in an enclosing directory, looking no further up
/// than [root]. Returns `null` if there isn't one.
String? findInheritedAnalysisOptions(
  String packagePath, {
  required String root,
}) {
  var packageDirectory = absolute(packagePath);
  var directory = packageDirectory;
  var stop = absolute(root);
  while (directory != stop && isWithin(stop, directory)) {
    directory = dirname(directory);
    var candidate = join(directory, 'analysis_options.yaml');
    if (File(candidate).existsSync()) {
      return posix.joinAll(split(relative(candidate, from: packageDirectory)));
    }
  }
  return null;
}

/// Summarizes [diagnostics], the `diagnostics` list from the JSON output of
/// `dart analyze`, as lines to print: how many there are of each code, most
/// frequent first, followed by the locations of the first [maxLocations].
///
/// Paths are shown relative to [root].
List<String> formatDiagnosticSummary(
  List<Object?> diagnostics, {
  required String root,
  int maxLocations = 5,
}) {
  var counts = <String, int>{};
  for (var diagnostic in diagnostics) {
    var code = (diagnostic as Map)['code'] as String;
    counts[code] = (counts[code] ?? 0) + 1;
  }
  var codes = counts.keys.toList()
    ..sort((a, b) {
      var byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return [
    for (var code in codes) '${counts[code]} $code',
    for (var diagnostic in diagnostics.take(maxLocations))
      if ((diagnostic as Map)['location'] case {
        'file': String file,
        'range': {'start': {'line': int line, 'column': int column}},
      })
        '${relative(file, from: root)}:$line:$column: ${diagnostic['code']}',
    if (diagnostics.length > maxLocations)
      '...and ${diagnostics.length - maxLocations} more',
  ];
}

/// Extracts, from the [stderr] of `dart format`, the paths of any files it
/// reported hitting an internal bug on.
///
/// `dart format` exits with code 70 when this happens, but only after
/// formatting every other file; the files it reports are simply left as they
/// were, just like files it couldn't parse. So an exit code of 70 is
/// acceptable as long as this returns something, which shows that's what the
/// 70 was for.
List<String> parseFormatterBugReports(String stderr) => [
  for (var match in RegExp(
    r'^Hit a bug in the formatter when formatting (.*)\.\r?$',
    multiLine: true,
  ).allMatches(stderr))
    match[1]!,
];

/// Extracts the paths of unmerged (conflicted) files from the [output] of
/// `git status --porcelain`.
///
/// Statuses that aren't conflicts are ignored rather than rejected; part way
/// through a deliberately uncommitted `git revert -n` the index is expected to
/// hold all kinds of ordinary staged and unstaged changes.
List<String> parseGitStatusConflicts(String output) {
  var mergeConflicts = <String>[];
  for (var line in output.split('\n')) {
    // Deliberately not trimmed: the first two characters are the status codes
    // for the index and the work tree respectively, so a leading space is
    // significant (` M` means "modified, but not staged").
    if (line.endsWith('\r')) {
      line = line.substring(0, line.length - 1);
    }
    if (line.isEmpty) continue;
    if (line.length < 4 || line[2] != ' ') {
      throw Exception(
        'Unrecognized line in git status output: ${json.encode(line)}',
      );
    }
    var status = line.substring(0, 2);
    var path = line.substring(3);
    if (path.startsWith('"')) {
      // Porcelain v1 C-quotes paths containing unusual characters. No path in
      // the SDK needs this, and unquoting correctly is fiddly, so refuse
      // rather than silently mangling the name.
      throw Exception(
        'Cannot handle quoted path in git status output: ${json.encode(line)}',
      );
    }
    if (!_gitConflictStatuses.contains(status)) continue;
    // A rename is reported as `ORIG -> PATH`; the new name is the one that
    // needs restoring. Renames can't themselves be conflicts, but a conflicted
    // path can still be reported this way after `git revert -n` follows a
    // rename, so handle it here rather than assuming it can't happen.
    if (path.indexOf(' -> ') case var arrow when arrow >= 0) {
      path = path.substring(arrow + 4);
    }
    mergeConflicts.add(path);
  }
  return mergeConflicts;
}

/// Extracts, from the [output] of `git status --porcelain
/// --untracked-files=all --ignored=traditional`, the paths of files that the
/// tool might rewrite but git can't restore: untracked files, and ignored
/// `.dart` files.
///
/// `dart format` and `dart fix` rewrite every `.dart` file under a package
/// regardless of git status, except in hidden directories such as
/// `.dart_tool`, which they skip. Files that git doesn't track survive every
/// way the tool has of undoing its changes, so a work-in-progress file would
/// end up formatted at the new language version and migrated, even when the
/// run is abandoned.
///
/// Untracked files count whatever their type, since a stray
/// `analysis_options.yaml`, for instance, would also be edited.
List<String> parseUnrestorableFiles(String output) => [
  for (var line in const LineSplitter().convert(output))
    if (line.length > 3 && line[2] == ' ')
      if (line.substring(3) case var path
          when !posix.split(path).any((segment) => segment.startsWith('.')))
        if (line.startsWith('??') ||
            (line.startsWith('!!') && path.endsWith('.dart')))
          path,
];

void printAvailableLintSets() {
  print('Available lint sets');
  for (var MapEntry(:key, :value) in lintSets.entries) {
    var lints = value.join(', ');
    var followUps = followUpFixCodes[key];
    print(
      '--lint-set $key ($lints)'
      '${followUps == null ? '' : '; also fixes ${followUps.join(', ')} where reported'}',
    );
  }
}

/// Warns that code migrated with [experiments] enabled won't compile unless
/// those experiments are enabled on the command line too.
///
/// Prints nothing if [experiments] is empty.
///
/// This is easy to be caught out by, because `dart analyze` reads the
/// experiments out of `analysis_options.yaml` and so reports no problem at
/// all, while everything that goes through the CFE — running a test, building
/// the SDK — fails.
void printExperimentWarning(List<String> experiments) {
  if (experiments.isEmpty) return;
  print('');
  print(
    'NOTE: the migrated code uses ${experiments.join(', ')}, so it only '
    'compiles with',
  );
  print('  --enable-experiment=${experiments.join(',')}');
  print('`dart analyze` reads the experiments from analysis_options.yaml, so');
  print("it won't complain, but the CFE, the VM and the SDK build don't. The");
  print('migration therefore cannot land until the experiments are enabled by');
  print('default.');
}

/// Returns, sorted, those of [followUpCodes] that appear in [diagnostics],
/// the `diagnostics` list from the JSON output of `dart analyze`.
List<String> reportedFollowUpCodes(
  List<Object?> diagnostics, {
  required List<String> followUpCodes,
}) => {
  for (var diagnostic in diagnostics)
    if ((diagnostic as Map)['code'] case String code
        when followUpCodes.contains(code))
      code,
}.toList()..sort();

Never showUsageAndExit({int exitCode = 1}) {
  print('Usage:');
  print(argParser.usage);
  exit(exitCode);
}

T withErrorContext<T>(
  T Function() operation, {
  required String Function() context,
}) {
  try {
    return operation();
  } on Skip {
    rethrow;
  } catch (e, st) {
    Error.throwWithStackTrace(
      ErrorWithContext(innerError: e, context: context()),
      st,
    );
  }
}

String _computeDartExecutablePath() {
  // `resolvedExecutable` rather than `executable`, so that the result is
  // absolute regardless of how this script was invoked. That matters now that
  // subprocesses run from `repoRoot` rather than the caller's directory.
  var path = Platform.resolvedExecutable;
  // A basename comparison rather than `endsWith('dart')`, which also accepts
  // nonsense like `.../mydart`. `withoutExtension` tolerates `dart.exe`.
  if (basenameWithoutExtension(path) == 'dart') {
    return path;
  } else {
    print(
      'Unexpected dart executable ${json.encode(path)}. Did you compile using AOT?',
    );
    exit(1);
  }
}

/// Throws away the run, and returns the exit code that reflects how that went.
///
/// Either way the migration has been thrown away, which is a failure (1). If
/// even cleaning up failed, the repository is left part way through the run,
/// which is worse (2).
int _exitCodeAfterAbandoning(
  State state, {
  required String scratchBranch,
  required String? originalRef,
}) =>
    state.abandonScratchBranch(
      scratchBranch: scratchBranch,
      originalRef: originalRef,
    )
    ? 1
    : 2;

/// Whether the SDK repository is colocated with a `jj` repository.
bool get _isColocatedWithJj => Directory(join(repoRoot, '.jj')).existsSync();

/// Whether this script is running on the prebuilt SDK checked in under
/// `tools/sdks`, rather than one freshly built into `out/`.
bool get _isPrebuiltSdk =>
    isWithin(join(repoRoot, 'tools', 'sdks'), dartExecutablePath);

/// Moves [insertionPoint], which must be at the start of a line of [contents],
/// backwards over any immediately preceding comment lines.
///
/// This keeps a comment attached to the entry it was written above, rather
/// than to an entry subsequently inserted at that point.
int _skipBackOverComments(String contents, int insertionPoint) {
  while (insertionPoint >= 2) {
    // `insertionPoint` is at the start of a line, so the character just before
    // it is the newline that ends the previous line.
    var previousLineStart = contents.lastIndexOf('\n', insertionPoint - 2) + 1;
    var previousLine = contents.substring(
      previousLineStart,
      insertionPoint - 1,
    );
    if (!previousLine.trimLeft().startsWith('#')) break;
    insertionPoint = previousLineStart;
  }
  return insertionPoint;
}

/// Returns the offset of the first line of [contents] that is neither blank
/// nor a comment, or the end of [contents] if there is no such line.
///
/// A brand new top level section is inserted there, so that the comment block
/// at the top of the file — usually the license header — stays at the top.
int _skipLeadingComments(String contents) {
  var offset = 0;
  while (offset < contents.length) {
    var newline = contents.indexOf('\n', offset);
    var lineEnd = newline < 0 ? contents.length : newline;
    var line = contents.substring(offset, lineEnd).trim();
    if (line.isNotEmpty && !line.startsWith('#')) break;
    offset = newline < 0 ? contents.length : newline + 1;
  }
  return offset;
}

class ErrorWithContext implements Exception {
  final Object innerError;
  final String context;

  new({required this.innerError, required this.context});

  @override
  String toString() => '$innerError ($context)';
}

class Options {
  /// If not `null`, only packages whose `ownerSet` matches one of the owner
  /// sets in this set will be migrated.
  final Set<OwnerSet>? filterOwnerSets;

  /// If not `null`, only packages whose `isPublished` boolean matches this
  /// value will be migrated.
  final bool? filterIsPublished;

  /// If not `null`, only packages whose names are in this set will be migrated.
  final Set<String>? filterPackages;

  /// If `true`, the list of possible values to pass for the `owner`
  /// command-line option should be printed.
  final bool showOwners;

  /// If `true`, the pre-analysis phase is skipped.
  final bool skipPreAnalysis;

  /// If `true`, the post-analysis phase is skipped.
  final bool skipPostAnalysis;

  /// Analyzer experiments passed via the `enable-experiment` command-line
  /// option.
  final List<String> experiments;

  /// Lint codes passed individually via the `lint` command-line option.
  final List<String> lints;

  /// The lint set that should be applied, or `null` if the `lint-set`
  /// command-line option wasn't supplied.
  final String? lintSet;

  /// If `true`, the list of possible values to pass for the `lint-set`
  /// command-line option should be printed.
  final bool showLintSets;

  /// The raw value passed to the `target-version` command-line option, or
  /// `null` if it wasn't supplied.
  ///
  /// This is left unparsed so that the `--show-*` flags, which don't need it,
  /// can be used without supplying it.
  final String? targetVersion;

  /// If `true`, the tool describes what it would do and then exits without
  /// modifying anything.
  final bool dryRun;

  /// If `true`, the usage should be printed.
  final bool help;

  factory parse(List<String> args) {
    var argResults = argParser.parse(args);
    if (argResults.rest case var rest when rest.isNotEmpty) {
      print('Unrecognized arguments: ${rest.join(' ')}');
      print('');
      showUsageAndExit();
    }
    return Options._(
      filterOwnerSets: switch (argResults.multiOption('owners')) {
        [] => null,
        var rawValues when rawValues.contains('all') => null,
        var rawValues => {
          for (var rawValue in rawValues)
            OwnerSet.fromStrings(
              rawValue == 'none' ? const [] : rawValue.split(','),
            ),
        },
      },
      filterIsPublished: argResults.wasParsed('published')
          ? argResults.flag('published')
          : null,
      filterPackages: switch (argResults.multiOption('package')) {
        [] => null,
        var strings => strings.toSet(),
      },
      showOwners: argResults.flag('show-owners'),
      skipPreAnalysis: argResults.flag('skip-pre-analysis'),
      skipPostAnalysis: argResults.flag('skip-post-analysis'),
      experiments: argResults.multiOption('enable-experiment'),
      lints: argResults.multiOption('lint'),
      lintSet: argResults.wasParsed('lint-set')
          ? argResults.option('lint-set')!
          : null,
      showLintSets: argResults.flag('show-lint-sets'),
      targetVersion: argResults.option('target-version'),
      dryRun: argResults.flag('dry-run'),
      help: argResults.flag('help'),
    );
  }

  new _({
    required this.filterOwnerSets,
    required this.filterIsPublished,
    required this.filterPackages,
    required this.showOwners,
    required this.skipPreAnalysis,
    required this.skipPostAnalysis,
    required this.experiments,
    required this.lints,
    required this.lintSet,
    required this.showLintSets,
    required this.targetVersion,
    required this.dryRun,
    required this.help,
  });
}

class PackageState {
  final PackageInfo packageInfo;
  late final bool needsVersionBump;

  new(this.packageInfo);
}

/// What [classifySdkConstraint] concluded about a package's SDK constraint.
enum SdkConstraintVerdict {
  /// The constraint already allows the target version, so there's nothing to
  /// bump. The package is still migrated, in case it hasn't yet had the lint
  /// set applied to it.
  upToDate,

  /// The constraint needs bumping to the target version.
  needsBump,

  /// The constraint needs bumping, and is more than one minor version behind
  /// the target. Not fatal, but worth warning about: `dart fix` will be
  /// migrating across more than one language version at once, so the diff may
  /// contain unrelated changes.
  farBehind,
}

class Skip {
  final String message;

  new(this.message);
}

class State {
  final Map<String, PackageState> packageStates;

  /// Whether this is a dry run, in which case nothing may be modified.
  final bool dryRun;

  /// The SDK version that packages should be bumped to.
  final Version targetVersion;

  /// The root of the repository to operate on, from which every command is
  /// run.
  ///
  /// Always the SDK repository, except in tests, which point it at a
  /// throwaway repository.
  final String root;

  /// The absolute paths of packages that were dropped part way through the
  /// run because some operation failed on them.
  final Set<String> droppedPackagePaths = {};

  /// Whether [bumpLanguageVersion] has run, after which the package config
  /// may record language versions that the working tree no longer has, once
  /// the bump has been undone for some or all packages.
  bool versionsBumped = false;

  /// The git sha that was checked out when the run started.
  ///
  /// Everything the tool does is undone by returning to this sha, so it's the
  /// anchor for both whole-run and per-package rollback.
  ///
  /// Not set during a dry run, which never reaches any code that needs it.
  late final String initialSha;

  new({
    required this.packageStates,
    required this.targetVersion,
    required this.dryRun,
    String? root,
  }) : root = root ?? repoRoot;

  /// Throws away the scratch branch and everything committed to it, returning
  /// to whatever was checked out when the run started.
  ///
  /// This is the last thing that runs on every failure path, so it must not
  /// itself fail silently. If it can't finish, it says exactly what to type to
  /// finish by hand, and returns `false`.
  bool abandonScratchBranch({
    required String scratchBranch,
    required String? originalRef,
  }) {
    try {
      gitRevertQuit();
      gitResetHard(initialSha);
      // `git branch -D` refuses to delete the branch we're standing on, so
      // move off it first. When `originalRef` is `null`, `HEAD` was already
      // detached, so detach it again at the same sha.
      gitCheckout(originalRef ?? initialSha);
      gitDeleteBranch(scratchBranch);
    } catch (e) {
      print('');
      print('ERROR: could not clean up after the failed migration: $e');
      print('');
      print('The repository has been left part way through the migration.');
      print('To finish cleaning up by hand:');
      print('  git revert --quit');
      print('  git reset --hard $initialSha');
      print('  git checkout ${originalRef ?? initialSha}');
      print('  git branch -D $scratchBranch');
      if (versionsBumped) {
        print('  python3 tools/generate_package_config.py');
      }
      if (_isColocatedWithJj) {
        print('');
        print('Or, since this repository is colocated with jj, undo the whole');
        print('run at once:');
        print('  jj op log             # find the op just before the run');
        print('  jj op restore <id>');
        if (versionsBumped) {
          print('  python3 tools/generate_package_config.py');
        }
      }
      print('');
      return false;
    }
    restorePackageConfig();
    return true;
  }

  void bumpLanguageVersion() {
    print('Bumping language version...');
    versionsBumped = true;
    byPackage((packageState) {
      if (!packageState.needsVersionBump) return;
      var sdkConstraintNode = packageState.packageInfo.sdkConstraintNode;
      var pubspecFile = File(sdkConstraintNode.span.sourceUrl!.toFilePath());
      pubspecFile.writeAsStringSync(
        bumpSdkConstraint(
          pubspecFile.readAsStringSync(),
          sdkConstraintNode: sdkConstraintNode,
          targetVersion: targetVersion,
        ),
      );
    });
  }

  Map<String, T> byPackage<T>(T Function(PackageState) operation) {
    var results = <String, T>{};
    for (var entry in packageStates.entries) {
      try {
        results[entry.key] = operation(entry.value);
      } on Skip catch (e) {
        print('Skipping ${entry.key}: ${e.message}');
      } catch (e) {
        print('${entry.key}: skipping due to error: $e');
      }
      if (results.containsKey(entry.key)) continue;
      // The operation may have failed part way through, leaving the package
      // half-edited. Nothing else will look at this package again, so those
      // edits would otherwise be swept up by the next `git commit -a`.
      //
      // This only undoes what is still uncommitted. Anything the package
      // already had committed on its behalf (formatting, the version bump) is
      // undone in one go by `restoreDroppedPackages`, which runs once the git
      // choreography in `main` is finished and it's safe to rewrite whole
      // packages.
      var path = entry.value.packageInfo.path;
      gitDiscardChanges(path);
      droppedPackagePaths.add(path);
    }
    packageStates.removeWhere((name, _) => !results.containsKey(name));
    if (packageStates.isEmpty) {
      throw Skip('No unskipped packages remain');
    }
    return results;
  }

  void checkCurrentLanguageVersion() {
    print('Checking current language version...');
    byPackage((packageState) {
      var sdkConstraint = packageState.packageInfo.sdkConstraint;
      withErrorContext(
        context: () => 'version=${json.encode(sdkConstraint)}',
        () {
          var (:minVersion, :verdict) = classifySdkConstraint(
            sdkConstraint,
            targetVersion: targetVersion,
          );
          if (verdict == SdkConstraintVerdict.farBehind) {
            print(
              '  Warning: ${packageState.packageInfo.name} is at $minVersion, '
              'which is more than one minor version behind $targetVersion. '
              'Review its diff with extra care.',
            );
          }
          packageState.needsVersionBump =
              verdict != SdkConstraintVerdict.upToDate;
          if (packageState.needsVersionBump) {
            // Try the bump now, without writing anything, so that a package
            // whose constraint can't be bumped is dropped here (and reported
            // by a dry run) rather than after formatting it.
            var sdkConstraintNode = packageState.packageInfo.sdkConstraintNode;
            bumpSdkConstraint(
              File(sdkConstraintNode.span.sourceUrl!.toFilePath())
                  .readAsStringSync(),
              sdkConstraintNode: sdkConstraintNode,
              targetVersion: targetVersion,
            );
          }
        },
      );
    });
  }

  void checkForAnalysisErrors() {
    print('Checking for analysis errors...');
    byPackage((packageState) {
      var name = packageState.packageInfo.name;
      var output = _execute(
        dartExecutablePath,
        ['analyze', 'pkg/$name', '--format=json'],
        // `dart analyze` uses its exit code to report the most severe
        // diagnostic it found: 1 for errors, 2 for warnings, 3 for infos. We
        // only care about errors, and we determine that from the JSON below,
        // so all of these are acceptable here.
        checkOk: (processResult) => processResult.exitCode <= 3,
      );
      var parsedJson = json.decode(output) as Map;
      if (parsedJson['version'] case var version when version != 1) {
        throw Exception('Unexpected analysis result version: $version');
      }
      // Only errors are disqualifying. Warnings and infos (lints, TODOs,
      // deprecation notices) are present in nearly every package, and
      // skipping on them would make this check useless.
      var errors = [
        for (var diagnostic in parsedJson['diagnostics'] as List)
          if ((diagnostic as Map)['severity'] == 'ERROR') diagnostic,
      ];
      if (errors.isNotEmpty) {
        for (var error in errors.take(5)) {
          print('  ${error['code']}: ${error['problemMessage']}');
        }
        if (errors.length > 5) {
          print('  ...and ${errors.length - 5} more');
        }
        throw Skip('${errors.length} analysis error(s)');
      }
    });
  }

  /// Throws unless the selected packages can be safely migrated and then
  /// restored: there must be no local modifications at all, and no files
  /// under the packages that git can't restore (see
  /// [parseUnrestorableFiles]).
  void checkGitClean() {
    print('Checking that there are no modified files...');
    var output = _execute('git', [
      'status', '--porcelain', // Machine-readable
      '-uno', // Ignore untracked files
    ]);
    if (output.isNotEmpty) {
      throw Exception(
        'There are local modifications. Commit or discard before running.',
      );
    }
    print('Checking for untracked files in the selected packages...');
    var unrestorableFiles = parseUnrestorableFiles(
      _execute('git', [
        'status',
        '--porcelain',
        '--untracked-files=all',
        '--ignored=traditional',
        '--',
        for (var packageState in packageStates.values)
          packageState.packageInfo.path,
      ]),
    );
    if (unrestorableFiles.isNotEmpty) {
      for (var file in unrestorableFiles.take(10)) {
        print('  $file');
      }
      if (unrestorableFiles.length > 10) {
        print('  ...and ${unrestorableFiles.length - 10} more');
      }
      throw Exception(
        'The selected packages contain files that git does not track, which '
        'the migration could rewrite but not restore. Commit, move or delete '
        'them before running.',
      );
    }
  }

  /// Reverts the formatting commits ([reformatSha] and [initialFormatSha]),
  /// then collapses the scratch commits into one `Migrate` commit, or a
  /// `Pre-format` commit followed by a `Migrate` commit, directly on top of
  /// [initialSha]. [migrateSha] is the scratch commit containing the
  /// migration itself, and must be checked out.
  ///
  /// See the library doc comment for why.
  void collapseScratchCommits({
    required String initialFormatSha,
    required String reformatSha,
    required String migrateSha,
  }) {
    // Files whose formatting couldn't be reverted, because the migration
    // touched the same lines. They're dealt with separately below.
    var conflicts = <String>{};
    // Newest first, as `git revert` itself would. Each revert is a separate
    // command because a multi-commit `git revert` stops at the first conflict.
    for (var sha in [reformatSha, initialFormatSha]) {
      gitRevert(sha);
      var newConflicts = gitGetMergeConflicts();
      // Settle these on the migrated version for now, since the next revert
      // can't start while any file is conflicted. They get their final
      // treatment in phase two anyway.
      if (newConflicts.isNotEmpty) gitRestore(migrateSha, newConflicts);
      conflicts.addAll(newConflicts);
    }
    gitCommit('Revert formatting');
    var revertSha = gitGetSha();
    // Phase two: throw the scratch commits away and rebuild the result as one
    // or two commits on top of the commit the run started from.
    gitResetHard(initialSha);
    var sortedConflicts = conflicts.toList()..sort();
    if (sortedConflicts.isNotEmpty) {
      // `reformatSha` has these files fully formatted at the new language
      // version, but not yet migrated, so this commit is pure formatting.
      gitRestore(reformatSha, sortedConflicts);
      gitCommit('Pre-format');
    }
    gitReadTree(revertSha);
    if (sortedConflicts.isNotEmpty) {
      // Take the migrated and formatted version of these. The `Pre-format`
      // commit above is what keeps that from reading as migration noise.
      gitRestore(migrateSha, sortedConflicts);
    }
    restoreDroppedPackages();
    gitCommit('Migrate');
  }

  /// Runs `dart fix` on each package to apply the [lints], and then to fix
  /// any of the [followUpCodes] that the result is reported to have.
  ///
  /// The follow-up fixes are repeated, a few times at most, since one can
  /// expose another: removing a cast can leave an unnecessary `this.`.
  void dartMigrate({
    required List<String> lints,
    required List<String> followUpCodes,
  }) {
    print('Running dart fix...');
    byPackage((packageState) {
      var name = packageState.packageInfo.name;
      _dartFix(name, lints);
      for (var pass = 0; followUpCodes.isNotEmpty && pass < 3; pass++) {
        // Analyzed with the package's own configuration, so that only lints
        // the package actually enables are reported; see `followUpFixCodes`.
        var output = _execute(dartExecutablePath, [
          'analyze',
          'pkg/$name',
          '--format=json',
        ], checkOk: (processResult) => processResult.exitCode <= 3);
        var reported = reportedFollowUpCodes(
          (json.decode(output) as Map)['diagnostics'] as List,
          followUpCodes: followUpCodes,
        );
        if (reported.isEmpty) break;
        print('  $name: also fixing ${reported.join(', ')}');
        _dartFix(name, reported);
      }
    });
  }

  /// Prints what a real run would do, having already worked out which
  /// packages need a version bump.
  ///
  /// Everything reported here is computed by the same code the real run uses,
  /// so a package reported as "would fail" here really will fail.
  void describePlan({
    required List<String> lintSet,
    required List<String> followUpCodes,
    required List<String> experiments,
    required bool skipPreAnalysis,
    required bool skipPostAnalysis,
  }) {
    print('');
    print('Dry run. Nothing has been modified.');
    print('');
    print('Target SDK version:    $targetVersion');
    print('Lints to enable:       ${_orNone(lintSet)}');
    print('Follow-up fixes:       ${_orNone(followUpCodes)}');
    print('Experiments to enable: ${_orNone(experiments)}');
    print('');
    print('Packages (${packageStates.length}):');
    for (var packageState in packageStates.values) {
      var packageInfo = packageState.packageInfo;
      print('  ${packageInfo.name}');
      print(
        '    sdk constraint:         ${packageInfo.sdkConstraint}'
        '${packageState.needsVersionBump ? ' -> ^$targetVersion' : ' (already at or past the target)'}',
      );
      print(
        '    analysis_options.yaml:  '
        '${_describeAnalysisOptionsChange(packageInfo, lintSet: lintSet, experiments: experiments)}',
      );
    }
    print('');
    print('Steps a real run would then take, on a scratch branch:');
    var step = 1;
    for (var description in [
      if (!skipPreAnalysis) 'check each package for pre-existing errors',
      'dart format each package                         -> commit',
      'bump the sdk constraint in each pubspec.yaml     -> commit',
      'regenerate the package config, format again      -> commit',
      'edit each analysis_options.yaml',
      'dart fix --code=${lintSet.join(',')} --apply',
      if (followUpCodes.isNotEmpty)
        'dart fix any follow-up diagnostics analysis reports',
      'dart format each package                         -> commit',
      'revert the formatting commits, replay migration  -> commit',
      if (!skipPostAnalysis) 'analyze each migrated package, report findings',
    ]) {
      print('  ${step++}. $description');
    }
    printExperimentWarning(experiments);
    print('');
  }

  /// Enables [lintSet] and [experiments] in each package's
  /// `analysis_options.yaml`, creating the file where it doesn't exist.
  ///
  /// A newly created file is staged straight away. That way, if the package
  /// is dropped later or the whole run is abandoned, the git commands that
  /// clean up see the file and remove it, rather than leaving it behind as an
  /// untracked file.
  void enableLints({
    required List<String> lintSet,
    required List<String> experiments,
  }) {
    print('Enabling lints...');
    byPackage((packageState) {
      var analysisOptionsPath = join(
        packageState.packageInfo.path,
        'analysis_options.yaml',
      );
      var analysisOptionsFile = File(analysisOptionsPath);
      String? originalAnalysisOptions;
      if (analysisOptionsFile.existsSync()) {
        originalAnalysisOptions = analysisOptionsFile.readAsStringSync();
      }
      if (addLintsAndExperiments(
            originalAnalysisOptions,
            lintSet: lintSet,
            experiments: experiments,
            include: findInheritedAnalysisOptions(
              packageState.packageInfo.path,
              root: root,
            ),
          )
          case var updated?) {
        analysisOptionsFile.writeAsStringSync(updated);
        if (originalAnalysisOptions == null) {
          gitAdd([analysisOptionsPath]);
        }
      }
    });
  }

  void format() {
    print('Formatting packages...');
    byPackage((packageState) {
      var formatterBugFiles = const <String>[];
      // Passing the directory rather than an enumerated list of files means
      // `dart format` applies its own traversal rules, which skip hidden
      // directories such as `.dart_tool`. It also keeps the command line
      // short; `pkg/analyzer` alone has thousands of files, which would risk
      // exceeding the system's argument length limit.
      _execute(
        dartExecutablePath,
        ['format', packageState.packageInfo.path],
        checkOk: (processResult) {
          if (processResult.exitCode == 70) {
            formatterBugFiles = parseFormatterBugReports(
              processResult.stderr as String,
            );
            return formatterBugFiles.isNotEmpty;
          }
          // Exit code 65 happens when a source file couldn't be parsed, or an
          // analysis_options.yaml file had problems. These errors don't stop
          // the formatter, just force it to skip one or more files. So for
          // our purposes they're ok.
          return processResult.exitCode == 0 || processResult.exitCode == 65;
        },
      );
      for (var file in formatterBugFiles) {
        print('  Warning: dart format hit a bug in $file, so left it as is.');
      }
    });
  }

  void generatePackageConfig() {
    print('Generating package config...');
    _execute('python3', ['tools/generate_package_config.py']);
  }

  void gitAdd(List<String> files) {
    if (files.isEmpty) return;
    print('Adding new files: ${json.encode(files)}...');
    _execute('git', ['add', ...files]);
  }

  void gitCheckout(String ref) {
    print('Checking out $ref...');
    _execute('git', ['checkout', ref]);
  }

  void gitCommit(String message) {
    print('Committing changes...');
    _execute('git', [
      'commit',
      '-a',
      '-m',
      message,
      '--no-verify',
      '--allow-empty',
    ]);
  }

  void gitCreateBranch(String name) {
    print('Creating and checking out scratch branch $name...');
    _execute('git', ['checkout', '-b', name]);
  }

  void gitDeleteBranch(String name) {
    print('Deleting scratch branch $name...');
    _execute('git', ['branch', '-D', name]);
  }

  /// Discards any uncommitted changes under [path], in both the index and the
  /// work tree, returning it to its state as of the most recent commit.
  ///
  /// That includes removing files that have been staged but don't exist in
  /// the most recent commit, such as an `analysis_options.yaml` created by
  /// [enableLints]. Untracked files are left alone, since git has no way to
  /// know they weren't there all along.
  void gitDiscardChanges(String path) {
    // `byPackage` can drop a package during a dry run's inspection phase, and
    // a dry run must not touch the repository.
    if (dryRun) return;
    print('Discarding uncommitted changes under $path...');
    _execute('git', ['checkout', '--no-overlay', 'HEAD', '--', path]);
  }

  /// Returns the name of the branch that is currently checked out, or `null`
  /// if `HEAD` is detached.
  String? gitGetCurrentBranch() {
    String? branch;
    var output = _execute(
      'git',
      ['symbolic-ref', '--quiet', '--short', 'HEAD'],
      // Exit code 1 simply means `HEAD` isn't a symbolic ref, i.e. it's
      // detached.
      checkOk: (processResult) =>
          processResult.exitCode == 0 || processResult.exitCode == 1,
    );
    if (output.trim() case var trimmed when trimmed.isNotEmpty) {
      branch = trimmed;
    }
    print('Currently checked out: ${branch ?? 'detached HEAD'}');
    return branch;
  }

  List<String> gitGetMergeConflicts() {
    print('Looking for merge conflicts...');
    var output = _execute('git', [
      'status', '--porcelain', // Machine-readable
      '-uno', // Ignore untracked files
    ]);
    return parseGitStatusConflicts(output);
  }

  String gitGetSha() {
    var sha = _execute('git', ['rev-parse', 'HEAD']).trim();
    print('Current git sha is $sha');
    return sha;
  }

  void gitReadTree(String sha) {
    print('Restoring index from $sha...');
    _execute('git', ['read-tree', '-m', '-u', sha]);
  }

  void gitResetHard(String sha) {
    print('Reset to $sha...');
    _execute('git', ['reset', '--hard', sha]);
  }

  /// Restores [files] from [sha], in both the index and the work tree.
  ///
  /// Updating the index too is what resolves a file left conflicted by
  /// [gitRevert].
  void gitRestore(String sha, List<String> files) {
    print('Restoring files from $sha...');
    _execute('git', [
      'restore',
      '--source=$sha',
      '--staged',
      '--worktree',
      '--',
      ...files,
    ]);
  }

  /// Applies the inverse of [sha] to the index and work tree, without
  /// committing it.
  ///
  /// Deliberately takes a single commit. Given several, `git revert` stops at
  /// the first one that conflicts, silently leaving the rest unreverted and
  /// the sequencer state behind.
  void gitRevert(String sha) {
    print('Reverting $sha...');
    _execute(
      'git',
      ['revert', '-n', sha],
      checkOk: (processResult) =>
          // Exit code of 1 just means there were conflicts.
          processResult.exitCode == 0 || processResult.exitCode == 1,
    );
  }

  /// Clears any in-progress `git revert` state.
  ///
  /// The tool's reverts are `-n`, so a failure between `gitRevert` and the
  /// commit that concludes it leaves `REVERT_HEAD` and the sequencer state
  /// behind. `git reset --hard` doesn't clear those, so without this the
  /// repository would still think a revert was in progress after cleanup.
  void gitRevertQuit() {
    print('Clearing any in-progress revert...');
    _execute(
      'git',
      ['revert', '--quit'],
      // Harmlessly does nothing when no revert is in progress, but older git
      // versions complain about it, and there's no point failing cleanup over
      // that.
      checkOk: (_) => true,
    );
  }

  /// Analyzes each migrated package, and summarizes whatever is reported, so
  /// that any fallout from the migration is noticed before review.
  ///
  /// Purely informational: the migration is already committed, and what to do
  /// about anything reported is up to the reviewer. Infos count as much as
  /// errors, since the SDK's bots analyze `pkg/` with `--fatal-infos`.
  ///
  /// Never throws, since it runs after the migration has been committed, and
  /// a failure here mustn't cause that to be thrown away.
  void reportRemainingDiagnostics() {
    print('');
    print('Analyzing the migrated packages...');
    var clean = 0;
    for (var packageState in packageStates.values) {
      var name = packageState.packageInfo.name;
      try {
        var output = _execute(
          dartExecutablePath,
          ['analyze', 'pkg/$name', '--format=json'],
          // As in `checkForAnalysisErrors`: the exit code only reflects the
          // most severe diagnostic, which the JSON reports anyway.
          checkOk: (processResult) => processResult.exitCode <= 3,
        );
        var diagnostics = (json.decode(output) as Map)['diagnostics'] as List;
        if (diagnostics.isEmpty) {
          clean++;
          continue;
        }
        print('  $name: ${diagnostics.length} diagnostic(s)');
        for (var line in formatDiagnosticSummary(diagnostics, root: root)) {
          print('    $line');
        }
      } catch (e) {
        print('  $name: could not analyze: $e');
      }
    }
    print(
      '$clean of ${packageStates.length} migrated package(s) have no '
      'diagnostics.',
    );
  }

  /// Returns every package that was dropped part way through the run to its
  /// pre-run state, so that a package the tool gave up on leaves no trace in
  /// the result.
  ///
  /// This has to happen after the revert/read-tree choreography rather than at
  /// the moment the package is dropped: that choreography reverts the
  /// formatting commits, and those reverts only apply cleanly if the package
  /// still looks the way the commit being reverted left it.
  void restoreDroppedPackages() {
    if (droppedPackagePaths.isEmpty) return;
    print('Restoring ${droppedPackagePaths.length} dropped package(s)...');
    // `--no-overlay` makes this an exact restore: as well as putting back the
    // files that existed at `initialSha`, it removes, from both the index and
    // the work tree, any file created since — notably an
    // `analysis_options.yaml` newly written by `enableLints`.
    _execute('git', [
      'checkout',
      '--no-overlay',
      initialSha,
      '--',
      ...droppedPackagePaths,
    ]);
  }

  /// Regenerates the package config, if [bumpLanguageVersion] has run, so
  /// that it matches the language versions in the working tree again.
  ///
  /// Called once the bump has been undone for some packages (because they
  /// were dropped) or for all of them (because the run was abandoned).
  ///
  /// Never throws, since it runs during cleanup. If it fails, it says what to
  /// type to finish by hand.
  void restorePackageConfig() {
    if (!versionsBumped) return;
    try {
      generatePackageConfig();
    } catch (e) {
      print('  Could not regenerate the package config: $e');
      print('  To regenerate it by hand:');
      print('    python3 tools/generate_package_config.py');
    }
  }

  /// Runs `dart fix` on the package named [name], fixing the diagnostics in
  /// [codes].
  void _dartFix(String name, List<String> codes) {
    _execute(dartExecutablePath, [
      'fix',
      'pkg/$name',
      '--code=${codes.join(',')}',
      '--apply',
    ]);
  }

  /// Runs [executable] with [args] from [root]; see [execute].
  String _execute(
    String executable,
    List<String> args, {
    bool Function(ProcessResult)? checkOk,
  }) => execute(executable, args, checkOk: checkOk, workingDirectory: root);

  /// Prints a warning if this repository is colocated with `jj`.
  ///
  /// Everything this tool does is raw git plumbing. `jj` snapshots the working
  /// copy on *every* `jj` command and imports git ref movements after the
  /// fact, so a `jj` command run part way through a migration can capture an
  /// intermediate state that was never meant to be seen.
  void warnIfColocatedWithJj() {
    if (!_isColocatedWithJj) return;
    print('');
    print('WARNING: this repository is colocated with jj.');
    print('  - Do not run any jj commands until this script finishes. jj');
    print('    snapshots the working copy on every command, and this script');
    print('    rewrites the working copy and HEAD many times.');
    print('  - Intermediate commits that this script creates and then throws');
    print('    away may still show up in `jj log` as abandoned commits.');
    print('  - If something goes wrong, `jj op log` followed by');
    print('    `jj op restore <id>` will return the repository to its state');
    print('    before the run.');
    print('');
  }

  /// Prints a warning if this script is running on the prebuilt SDK.
  ///
  /// In-development lints and experiments only exist in a freshly built SDK,
  /// so running under `tools/sdks` is the most likely explanation for a
  /// migration that appears to succeed while changing nothing.
  void warnIfPrebuiltSdk() {
    if (!_isPrebuiltSdk) return;
    print('');
    print('WARNING: running on the prebuilt SDK at');
    print('  $dartExecutablePath');
    print('Lints and experiments that are still in development only exist in');
    print('a freshly built SDK, so `dart fix` may silently find nothing to');
    print('do. Consider re-running with out/ReleaseX64/dart-sdk/bin/dart.');
    print('');
  }

  /// Describes, in a few words, what [enableLints] would do to the
  /// `analysis_options.yaml` of the package described by [packageInfo].
  String _describeAnalysisOptionsChange(
    PackageInfo packageInfo, {
    required List<String> lintSet,
    required List<String> experiments,
  }) {
    var file = File(join(packageInfo.path, 'analysis_options.yaml'));
    var exists = file.existsSync();
    var contents = exists ? file.readAsStringSync() : null;
    var include = exists
        ? null
        : findInheritedAnalysisOptions(packageInfo.path, root: root);
    try {
      if (addLintsAndExperiments(
            contents,
            lintSet: lintSet,
            experiments: experiments,
            include: include,
          ) ==
          null) {
        return 'already up to date';
      }
    } catch (e) {
      // Surfacing this here is the main reason `--dry-run` exists: a package
      // that explicitly disables a lint we're trying to enable would otherwise
      // only fail part way through a real run.
      return 'WOULD FAIL: $e';
    }
    if (exists) return 'would be updated';
    return include == null
        ? 'would be created, inheriting nothing'
        : 'would be created, including $include';
  }

  /// Renders [values] as a comma-separated list, or `(none)` if it's empty.
  String _orNone(List<String> values) =>
      values.isEmpty ? '(none)' : values.join(', ');
}
