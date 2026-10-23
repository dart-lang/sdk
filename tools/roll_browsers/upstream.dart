// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' show max;
import 'package:http/http.dart' as http;
import 'version.dart';

/// A browser or JS engine release that is available upstream.
final class Release {
  /// The version as pinned in DEPS and tagged in CIPD (`version:<version>`).
  final Version version;

  /// The version string passed to the CIPD packaging builder.
  ///
  /// This differs from [version] for Firefox, whose builder also needs the
  /// release candidate build number (e.g. `128.0+2`).
  final String builderVersion;

  Release(this.version, {String? builderVersion})
      : builderVersion = builderVersion ?? version.text;

  @override
  String toString() => builderVersion;
}

/// Looks up the latest upstream releases of the browsers and JS engines.
///
/// See go/dart-engprod/browsers.md for where each version comes from.
final class Upstream {
  static final _chromeVersions = Uri.https(
    'googlechromelabs.github.io',
    'chrome-for-testing/last-known-good-versions.json',
  );
  static final _firefoxVersions = Uri.https(
    'product-details.mozilla.org',
    '1.0/firefox_versions.json',
  );
  static final _jscLatest = Uri.https(
    'webkitgtk.org',
    'jsc-built-products/x86_64/release/LAST-IS',
  );

  /// The `chromium-v8` archive names of the platforms packaged for d8.
  ///
  /// Must match the d8 platforms in the dart.googlesource.com/deps builder.
  static const _d8ArchivePlatforms = [
    'linux64',
    'linux-arm64',
    'mac64',
    'mac-arm64',
    'win64',
  ];

  final http.Client _client;

  Upstream(this._client);

  /// The latest Chrome for Testing build on the beta channel.
  Future<Release> latestChromeBeta() async {
    final json = await _getJson(_chromeVersions) as Map<String, dynamic>;
    final channels = json['channels'] as Map<String, dynamic>;
    final beta = channels['Beta'] as Map<String, dynamic>;
    return Release(Version.parse(beta['version'] as String));
  }

  /// The latest stable Firefox release and its release candidate build.
  Future<Release> latestFirefox() async {
    final json = await _getJson(_firefoxVersions) as Map<String, dynamic>;
    final version = Version.parse(json['LATEST_FIREFOX_VERSION'] as String);
    final build = await _latestFirefoxCandidateBuild(version);
    return Release(version, builderVersion: '$version+$build');
  }

  /// The latest JavaScriptCore build published by WebKitGTK.
  Future<Release> latestJsc() async {
    // The file contains the archive name, e.g. `323183@main.zip`.
    final latest = (await _getText(_jscLatest)).trim();
    final revision = RegExp(r'^(\d+)@').firstMatch(latest)?[1];
    if (revision == null) {
      throw FormatException('Unexpected jsc LAST-IS contents', latest);
    }
    return Release(Version.parse(revision));
  }

  /// The latest V8 canary that is available for every packaged platform.
  ///
  /// Only the current and next major versions are listed to keep the number
  /// of GCS requests small.
  Future<Release> latestD8(Version current) async {
    final majors = [current.major, current.major + 1];
    final perPlatform = await Future.wait([
      for (final platform in _d8ArchivePlatforms)
        _d8CanaryVersions(platform, majors),
    ]);
    final common = perPlatform.reduce((a, b) => a.intersection(b));
    final latest = maxVersion(common.map(Version.parse));
    if (latest == null) {
      throw StateError('No d8 canary found for all platforms in $majors.');
    }
    return Release(latest);
  }

  /// Finds the highest `buildN` directory of a Firefox release candidate.
  Future<int> _latestFirefoxCandidateBuild(Version version) async {
    final listing = await _getText(Uri.https(
      'archive.mozilla.org',
      'pub/firefox/candidates/$version-candidates/',
    ));
    final builds = RegExp(r'build(\d+)/')
        .allMatches(listing)
        .map((match) => int.parse(match[1]!));
    if (builds.isEmpty) {
      throw StateError('No release candidate builds for Firefox $version.');
    }
    return builds.reduce(max);
  }

  /// Lists the canary versions of d8 for [platform] with the given [majors].
  Future<Set<String>> _d8CanaryVersions(
    String platform,
    List<int> majors,
  ) async {
    final prefix = 'official/canary/v8-$platform-rel-';
    final names = [
      for (final major in majors)
        ...await _listGcsObjects('chromium-v8', '$prefix$major.'),
    ];
    return {
      for (final name in names)
        if (name.endsWith('.zip'))
          name.substring(prefix.length, name.length - '.zip'.length),
    };
  }

  /// Lists the names of all objects in the public GCS [bucket] that start
  /// with [prefix], following pagination.
  Future<List<String>> _listGcsObjects(String bucket, String prefix) async {
    final names = <String>[];
    String? pageToken;
    do {
      final uri =
          Uri.https('storage.googleapis.com', 'storage/v1/b/$bucket/o', {
        'prefix': prefix,
        'fields': 'items(name),nextPageToken',
        'maxResults': '1000',
        if (pageToken != null) 'pageToken': pageToken,
      });
      final page = await _getJson(uri) as Map<String, dynamic>;
      for (final item in (page['items'] as List?) ?? const []) {
        names.add((item as Map<String, dynamic>)['name'] as String);
      }
      pageToken = page['nextPageToken'] as String?;
    } while (pageToken != null);
    return names;
  }

  Future<Object?> _getJson(Uri uri) async => jsonDecode(await _getText(uri));

  Future<String> _getText(Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        uri,
      );
    }
    return response.body;
  }
}
