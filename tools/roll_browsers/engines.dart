// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'process.dart';
import 'upstream.dart';
import 'version.dart';

const _cipdVersionPrefix = 'version:';

/// An in-memory view of the SDK's DEPS file.
final class DepsFile {
  final String contents;

  DepsFile(this.contents);

  /// Returns the string value of the DEPS variable [name].
  String readVar(String name) {
    final match = _varPattern(name).firstMatch(contents);
    if (match == null) throw StateError('DEPS has no "$name" variable.');
    return match[2]!;
  }

  /// Returns a copy of this file with variable [name] set to [value].
  DepsFile withVar(String name, String value) {
    readVar(name); // Fail loudly if the variable doesn't exist.
    return DepsFile(contents.replaceFirstMapped(
      _varPattern(name),
      (match) => '${match[1]}$value${match[3]}',
    ));
  }

  /// Matches `"name": "value"`, capturing the text around the value so it can
  /// be replaced without touching formatting or trailing comments.
  static RegExp _varPattern(String name) =>
      RegExp('("${RegExp.escape(name)}":\\s*")([^"]*)(")');
}

/// When an engine's DEPS pin should be rolled to a newer upstream release.
final class RollPolicy {
  /// How old the current pin must be before a minor or patch update rolls.
  final Duration minimumAge;

  /// Whether a new major version rolls immediately regardless of [minimumAge].
  final bool rollOnMajorVersion;

  const RollPolicy({
    required this.minimumAge,
    this.rollOnMajorVersion = false,
  });

  /// Returns why rolling from [current] (pinned [pinAge] ago) to [latest]
  /// should wait, or `null` if the roll should go ahead.
  String? holdReason(Version current, Version latest, Duration pinAge) {
    if (rollOnMajorVersion && latest.major > current.major) return null;
    if (pinAge >= minimumAge) return null;
    return [
      if (rollOnMajorVersion) 'same major version (${current.major})',
      'pinned ${pinAge.inDays} days ago '
          '(waiting for ${minimumAge.inDays} days)',
    ].join(', ');
  }
}

/// Where an [Engine]'s new versions come from.
sealed class VersionSource {
  const VersionSource();
}

/// Tracks upstream releases, rolling to them according to [policy].
final class UpstreamReleases extends VersionSource {
  /// When to roll to a newer upstream release.
  final RollPolicy policy;

  /// Looks up the latest upstream release given the current pinned version.
  final Future<Release> Function(Upstream upstream, Version current)
      fetchLatest;

  const UpstreamReleases({required this.policy, required this.fetchLatest});
}

/// Keeps the pin at the same version as [leader], rolling in the same CL
/// whenever [leader] rolls.
final class SameVersionAs extends VersionSource {
  final Engine leader;

  const SameVersionAs(this.leader);
}

/// A browser or JS engine pinned in DEPS and packaged in CIPD.
final class Engine {
  /// The name used by the tool proxy `browser` grant and by `--only`.
  final String name;

  /// The name used in commit messages and notifications.
  final String displayName;

  /// The DEPS variable holding the pinned version.
  final String depsVar;

  /// Whether the DEPS value includes the CIPD `version:` prefix.
  final bool depsValueHasCipdPrefix;

  /// The CIPD packages that must exist before the DEPS pin can be rolled.
  final List<String> cipdPackages;

  /// Try builders to add to roll CLs, beyond the default CQ set.
  final List<String> trybots;

  /// Where new versions come from and when to roll to them.
  final VersionSource source;

  const Engine({
    required this.name,
    required this.displayName,
    required this.depsVar,
    required this.depsValueHasCipdPrefix,
    required this.cipdPackages,
    required this.trybots,
    required this.source,
  });

  /// The engine whose version this engine tracks (itself unless [source] is
  /// [SameVersionAs]). Engines with the same [versionLeader] roll together.
  Engine get versionLeader => switch (source) {
        SameVersionAs(:final leader) => leader,
        UpstreamReleases() => this,
      };

  /// The version pinned in [deps].
  Version pinnedVersion(DepsFile deps) {
    final value = deps.readVar(depsVar);
    if (!depsValueHasCipdPrefix) return Version.parse(value);
    if (!value.startsWith(_cipdVersionPrefix)) {
      throw FormatException('Expected "$_cipdVersionPrefix" prefix', value);
    }
    return Version.parse(value.substring(_cipdVersionPrefix.length));
  }

  /// Returns a copy of [deps] with this engine pinned to [version].
  DepsFile withPinnedVersion(DepsFile deps, Version version) => deps.withVar(
        depsVar,
        depsValueHasCipdPrefix ? _cipdTag(version) : '$version',
      );

  /// Returns the [cipdPackages] that do not have an instance for [version].
  Future<List<String>> missingCipdPackages(Version version) async {
    final tag = _cipdTag(version);
    final results = await Future.wait([
      for (final package in cipdPackages)
        runProcess('cipd', ['resolve', package, '-version', tag]),
    ]);
    return [
      for (var i = 0; i < cipdPackages.length; i++)
        if (results[i].exitCode != 0) cipdPackages[i],
    ];
  }

  String _cipdTag(Version version) => '$_cipdVersionPrefix$version';
}

/// The pinned and latest versions of an engine and whether to roll it.
final class EngineStatus {
  final Engine engine;
  final Version current;
  final Release latest;

  /// Why the engine shouldn't be rolled, or `null` if it should.
  final String? holdReason;

  EngineStatus({
    required this.engine,
    required this.current,
    required this.latest,
    required this.holdReason,
  });

  bool get shouldRoll => holdReason == null;

  /// The new DEPS pin when rolling.
  Version get target => latest.version;

  /// E.g. "Firefox 127.0 -> 128.0".
  String get rollSummary => '${engine.displayName} $current -> $target';

  /// The engine and builder version, e.g. "Firefox 128.0+2".
  String get buildName => '${engine.displayName} ${latest.builderVersion}';

  /// Returns the CIPD packages for [target] that have not been published yet.
  Future<List<String>> missingCipdPackages() =>
      engine.missingCipdPackages(target);
}

/// Returns the CIPD package names for [prefix] on each of [platforms].
List<String> _packages(String prefix, List<String> platforms) =>
    [for (final platform in platforms) '$prefix/$platform'];

// The platform lists mirror what the packaging builders upload; see
// https://dart.googlesource.com/deps/+/refs/heads/main/bin/update_browsers.dart
const _chromePlatforms = [
  'linux-amd64',
  'mac-amd64',
  'mac-arm64',
  'windows-amd64',
];
const _d8Platforms = [
  'linux-amd64',
  'linux-arm64',
  'mac-amd64',
  'mac-arm64',
  'windows-amd64',
];
const _firefoxPlatforms = [
  'linux-amd64',
  'linux-arm64',
  'windows-amd64',
  'windows-arm64',
];
const _jsshellPlatforms = [
  'linux-amd64',
  'linux-arm64',
  'mac-amd64',
  'windows-amd64',
  'windows-arm64',
];

/// Chrome and Firefox roll on a new major version, and otherwise every two
/// weeks.
const _majorOrBiweekly = RollPolicy(
  minimumAge: Duration(days: 14),
  rollOnMajorVersion: true,
);

/// d8 and jsc are rolled monthly.
const _monthly = RollPolicy(minimumAge: Duration(days: 30));

/// We follow Chrome beta to catch issues before they reach stable.
final chrome = Engine(
  name: 'chrome',
  displayName: 'Chrome',
  depsVar: 'chrome_tag',
  depsValueHasCipdPrefix: false,
  cipdPackages: [
    ..._packages('dart/browsers/chrome', _chromePlatforms),
    ..._packages('dart/third_party/chromedriver', _chromePlatforms),
  ],
  trybots: const [
    'dart2js-linux-chrome-try',
    'ddc-linux-chrome-try',
    'dart2wasm-linux-chrome-try',
  ],
  source: UpstreamReleases(
    policy: _majorOrBiweekly,
    fetchLatest: (upstream, _) => upstream.latestChromeBeta(),
  ),
);

/// We follow Firefox stable.
final firefox = Engine(
  name: 'firefox',
  displayName: 'Firefox',
  depsVar: 'firefox_tag',
  depsValueHasCipdPrefix: false,
  cipdPackages: _packages('dart/browsers/firefox', _firefoxPlatforms),
  trybots: const [
    'dart2js-linux-firefox-try',
    'ddc-linux-firefox-try',
    'dart2wasm-linux-firefox-try',
  ],
  source: UpstreamReleases(
    policy: _majorOrBiweekly,
    fetchLatest: (upstream, _) => upstream.latestFirefox(),
  ),
);

final d8 = Engine(
  name: 'd8',
  displayName: 'd8',
  depsVar: 'd8_tag',
  depsValueHasCipdPrefix: true,
  cipdPackages: _packages('dart/third_party/d8', _d8Platforms),
  trybots: const [
    'dart2js-minified-linux-d8-try',
    'ddc-hostasserts-linux-d8-try',
    'dart2wasm-linux-d8-try',
  ],
  source: UpstreamReleases(
    policy: _monthly,
    fetchLatest: (upstream, current) => upstream.latestD8(current),
  ),
);

/// jsshell is built from the same release as Firefox, so it is kept at the
/// Firefox version and rolled in the same CL.
final jsshell = Engine(
  name: 'jsshell',
  displayName: 'jsshell',
  depsVar: 'jsshell_tag',
  depsValueHasCipdPrefix: true,
  cipdPackages: _packages('dart/third_party/jsshell', _jsshellPlatforms),
  trybots: const [],
  source: SameVersionAs(firefox),
);

final jsc = Engine(
  name: 'jsc',
  displayName: 'jsc',
  depsVar: 'jsc_tag',
  depsValueHasCipdPrefix: true,
  cipdPackages: const ['dart/third_party/jsc/linux-amd64'],
  trybots: const ['dart2wasm-linux-optimized-jsc-try'],
  source: UpstreamReleases(
    policy: _monthly,
    fetchLatest: (upstream, _) => upstream.latestJsc(),
  ),
);

/// All engines managed by the roller, in the order they are reported.
final allEngines = [chrome, firefox, d8, jsshell, jsc];
