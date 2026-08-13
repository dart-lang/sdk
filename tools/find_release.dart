// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A tool to find the lowest Dart and Flutter release containing a given
/// commit.
///
/// Usage:
///
/// `dart tools/find_release.dart --commit=<sha> --channel=<dev|beta|stable>`
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

final parser = ArgParser()
  ..addOption(
    'commit',
    abbr: 'c',
    help: 'The commit to search for',
    mandatory: true,
  )
  ..addOption(
    'channel',
    help: 'The channel to search for the commit in, dev only supports the dart '
        'sdk since flutter does not do dev releases.',
    allowed: ['dev', 'stable', 'beta'],
    mandatory: true,
  )
  ..addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Show usage information',
  );

void main(List<String> arguments) async {
  try {
    final parsedArgs = parser.parse(arguments);
    if (parsedArgs['help'] as bool) {
      print(parser.usage);
      exit(0);
    }
    final commit = parsedArgs['commit'] as String;
    final channel = parsedArgs['channel'] as String;
    print('Searching for commit $commit in channel $channel');

    final repo = await findRepoForCommit(commit);
    if (repo == null) {
      print('Commit not found in Dart or Flutter repositories.');
      exit(1);
    }
    print('Found commit in $repo');

    print('Fetching lowest release tag for $commit...');
    final tag = await fetchLowestVersionTag(repo, commit);
    if (tag == null) {
      print('No release tags found for commit $commit in $repo');
      exit(1);
    }
    print('Lowest release tag for $commit was: $tag');

    if (repo == flutterSdkRepo || (channel == 'beta' || channel == 'stable')) {
      print('Checking for lowest flutter release newer than $tag...');
      final flutterRelease = await fetchLowestFlutterRelease(
        repo,
        channel,
        tag,
      );
      if (flutterRelease == null) {
        print(
          'No Flutter releases found '
          '${repo == dartSdkRepo ? 'with a Dart sdk ' : ''}'
          'newer than $tag',
        );
      } else {
        print('Lowest Flutter release: $flutterRelease');
      }
    } else {
      print(
        'Skipping flutter version check for channel $channel, only `beta` and '
        '`stable` are supported for flutter version checks',
      );
    }

    if (repo == dartSdkRepo) {
      print('Checking for lowest Dart release newer than $tag...');
      final dartRelease = await fetchLowestDartReleaseFromGcs(
        'channels/$channel/release/',
        tag,
      );
      if (dartRelease == null) {
        print('No Dart releases found that were newer than $tag');
      } else {
        print('Lowest Dart release: $dartRelease');
      }
    } else {
      print('Skipping dart version check as this was a flutter commit');
    }
  } on FormatException catch (e) {
    print(e.message);
    print(parser.usage);
    exit(1);
  }
}

const dartSdkRepo = 'dart-lang/sdk';
const flutterSdkRepo = 'flutter/flutter';

/// Searches the Dart and Flutter repos for the given [sha], and returns the
/// org/repo string where it was found.
Future<String?> findRepoForCommit(String sha) async {
  if (await checkCommit(dartSdkRepo, sha)) return dartSdkRepo;
  if (await checkCommit(flutterSdkRepo, sha)) return flutterSdkRepo;
  return null;
}

/// Returns whether or not [sha] exists in [repo] (which should be an org/repo
/// string).
Future<bool> checkCommit(String repo, String sha) async {
  try {
    await makeGhApiRequest('repos/$repo/commits/$sha');
    return true;
  } on RequestException catch (_) {
    return false;
  }
}

/// Returns the lowest tag that parses as a semver version containing [commit].
Future<Version?> fetchLowestVersionTag(
  String repo,
  String commit,
) async {
  // Note that this is not an official endpoint, it was reverse engineered from
  // the commit page on github, and could break in the future.
  final response = await makeGhApiRequest(
    '$repo/branch_commits/$commit.json',
    isApiRequest: false,
  );
  final tags = (response['tags'] as List).cast<String>();
  Version? lowest;
  for (final tag in tags) {
    try {
      final version = Version.parse(tag);
      if (lowest == null || version < lowest) {
        lowest = version;
      }
    } on FormatException catch (_) {
      continue;
    }
  }
  return lowest;
}

/// Makes a request to [path] against the github API.
///
/// If [isApiRequest] is false, treats this as a regular github request instead
/// of an official API request.
///
/// Throws a [RequestException] if the request fails.
Future<Map<String, Object?>> makeGhApiRequest(
  String path, {
  bool isApiRequest = true,
}) async {
  var uri = Uri.https(
    isApiRequest ? 'api.github.com' : 'github.com',
    '/$path',
  );
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw RequestException(response, uri);
  }
  return jsonDecode(response.body) as Map<String, Object?>;
}

/// Returns the lowest Dart release version in the GCS storage bucket starting
/// with [prefix] and greater than or equal to [minVersion].
///
/// Throws a [RequestException] if the request fails.
Future<Version?> fetchLowestDartReleaseFromGcs(
  String prefix,
  Version minVersion,
) async {
  final uri = Uri.https(
    'storage.googleapis.com',
    '/storage/v1/b/dart-archive/o',
    {
      'delimiter': '/',
      'prefix': prefix,
      'alt': 'json',
    },
  );
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw RequestException(response, uri);
  }
  Version? lowest;
  try {
    final releases = ((jsonDecode(response.body)
            as Map<String, Object?>)['prefixes'] as List)
        .cast<String>();
    for (var release in releases) {
      final versionPart = release.split('/')[3];
      try {
        final version = Version.parse(versionPart);
        if (version >= minVersion && (lowest == null || version < lowest)) {
          lowest = version;
        }
      } on FormatException catch (_) {
        continue;
      }
    }
  } catch (e) {
    throw RequestException(response, uri);
  }
  return lowest;
}

/// Returns the lowest Flutter version greater than or equal to [minVersion].
///
/// The [minVersion] is either a Dart or Flutter version, depending on [repo].
///
/// If [repo] is [flutterSdkRepo], then it will only return a version from
/// [channel], otherwise it may contain a release from any channel. This is
/// because the release channels do not always correspond to each other.
///
/// Throws a [RequestException] if the request fails.
Future<Version?> fetchLowestFlutterRelease(
  String repo, // The repo that `minVersion` corresponds to.
  String channel,
  Version minVersion,
) async {
  final uri = Uri.https(
    'storage.googleapis.com',
    '/flutter_infra_release/releases/releases_linux.json',
  );
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw RequestException(response, uri);
  }
  Version? lowest;
  try {
    final releases = ((jsonDecode(response.body)
            as Map<String, Object?>)['releases'] as List)
        .cast<Map<String, Object?>>();
    for (var release in releases) {
      // We do search for dart releases in any flutter channel because sometimes
      // stable flutter releases contain dart sdk releases from beta channels.
      if (repo == flutterSdkRepo && release['channel'] != channel) continue;

      var versionStr = switch (repo) {
        dartSdkRepo => release['dart_sdk_version'] as String?,
        flutterSdkRepo => release['version'] as String,
        _ => throw FormatException('Unknown repository $repo'),
      };
      if (versionStr == null) continue;
      // Some versions look like `3.11.0 (build 3.11.0-93.1.beta)`
      if (versionStr.contains('(build')) {
        versionStr = versionStr.split('(build ').last;
        versionStr = versionStr.substring(0, versionStr.length - 1);
      }

      try {
        final version = Version.parse(versionStr);
        if (version >= minVersion) {
          // This is a potential candidate, now check if the flutter version
          // is the lowest we have seen.
          final flutterVersion = switch (repo) {
            flutterSdkRepo => version,
            dartSdkRepo => Version.parse(release['version'] as String),
            _ => throw StateError('Unexpected repo string $repo'),
          };
          if (lowest == null || flutterVersion < lowest) {
            lowest = flutterVersion;
          }
        }
      } on FormatException catch (_) {
        continue;
      }
    }
  } catch (e) {
    throw RequestException(response, uri, e);
  }
  return lowest;
}

class RequestException implements Exception {
  final http.Response response;
  final Uri uri;
  final Object? error;

  RequestException(this.response, this.uri, [this.error]);

  @override
  String toString() => '''
uri: $uri
statusCode:  ${response.statusCode}
body: ${response.body}
error: $error
''';
}
