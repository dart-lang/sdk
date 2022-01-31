// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/instrumentation/service.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// A class for interacting with the Pub API.
///
/// https://github.com/dart-lang/pub/blob/master/doc/repository-spec-v2.md
///
/// Failed requests will automatically be retried.
class PubApi {
  static const packageNameListPath = '/api/package-name-completion-data';
  static const packageInfoPath = '/api/packages';

  /// Maximum number of retries if requests fail.
  static const maxFailedRequests = 5;

  /// Initial wait period between retries. Doubled for each failure (but restarts
  /// from this value for each new request).
  static int _failedRetryInitialDelaySeconds = 1;

  @visibleForTesting
  static set failedRetryInitialDelaySeconds(int value) {
    _failedRetryInitialDelaySeconds = value;
  }

  final InstrumentationService instrumentationService;
  final http.Client httpClient;
  final String _pubHostedUrl;
  final _headers = {
    'Accept': 'application/vnd.pub.v2+json',
    'Accept-Encoding': 'gzip',
    'User-Agent': 'Dart Analysis Server/${Platform.version.split(' ').first}'
        ' (+https://github.com/dart-lang/sdk)',
  };

  PubApi(this.instrumentationService, http.Client? httpClient,
      String? envPubHostedUrl)
      : httpClient =
            httpClient != null ? _NoCloseHttpClient(httpClient) : http.Client(),
        _pubHostedUrl = _validPubHostedUrl(envPubHostedUrl);

  /// Fetches a list of package names from the Pub API.
  ///
  /// Failed requests will be retried a number of times. If no successful response
  /// is received, will return null.
  Future<List<PubApiPackage>?> allPackages() async {
    final json = await _getJson('$_pubHostedUrl$packageNameListPath');
    if (json == null) {
      return null;
    }

    final packageNames = json['packages'];
    return packageNames is List
        ? packageNames.map((name) => PubApiPackage(name as String)).toList()
        : null;
  }

  void close() {
    httpClient.close();
  }

  /// Fetches package details from the Pub API.
  ///
  /// Failed requests will be retried a number of times. If no successful response
  /// is received, will return null.
  Future<PubApiPackageDetails?> packageInfo(String packageName) async {
    final json = await _getJson('$_pubHostedUrl$packageInfoPath/$packageName');
    if (json == null) {
      return null;
    }

    final latest = json['latest'] as Map<String, Object?>?;
    if (latest == null) {
      return null;
    }

    final pubspec = latest['pubspec'] as Map<String, Object?>?;
    final description =
        pubspec != null ? pubspec['description'] as String? : null;
    final version = latest['version'] as String?;
    return PubApiPackageDetails(packageName, description, version);
  }

  /// Calls a pub API and decodes the resulting JSON.
  ///
  /// Automatically retries the request for specific types of failures after
  /// [_failedRetryInitialDelaySeconds] doubling each time. After [maxFailedRequests]
  /// requests or upon a 4XX response, will return `null` and not retry.
  Future<Map<String, Object?>?> _getJson(String url) async {
    var requestCount = 0;
    var retryAfterSeconds = _failedRetryInitialDelaySeconds;
    while (requestCount++ < maxFailedRequests) {
      try {
        final response =
            await httpClient.get(Uri.parse(url), headers: _headers);
        if (response.statusCode == 200) {
          instrumentationService.logInfo('Pub API request successful for $url');
          return jsonDecode(response.body) as Map<String, Object?>?;
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          // Do not retry 4xx responses.
          instrumentationService.logError(
              'Pub API returned ${response.statusCode} ${response.reasonPhrase} '
              'for $url. Not retrying.');
          return null;
        }
        instrumentationService.logError(
            'Pub API returned ${response.statusCode} ${response.reasonPhrase} '
            'for $url on attempt $requestCount');
      } catch (e) {
        if (e is! IOException && e is! FormatException) {
          instrumentationService
              .logError('Error calling pub API for $url. Not retrying. $e');
          return null;
        }
        instrumentationService.logError('Error calling pub API for $url: $e');
      }
      if (requestCount >= maxFailedRequests) {
        instrumentationService
            .logInfo('Pub API request failed after $requestCount requests');
      } else {
        // Sleep before the next try.
        await Future.delayed(Duration(seconds: retryAfterSeconds));
        retryAfterSeconds *= 2;
      }
    }
    return null;
  }

  /// Returns a valid Pub base URL from [envPubHostedUrl] if valid, otherwise using
  /// the default 'https://pub.dartlang.org'.
  static String _validPubHostedUrl(String? envPubHostedUrl) {
    final validUrl = envPubHostedUrl != null &&
            (Uri.tryParse(envPubHostedUrl)?.isAbsolute ?? false)
        ? envPubHostedUrl
        : 'https://pub.dartlang.org';

    // Discard any trailing slashes, as all API paths start with them.
    return validUrl.endsWith('/')
        ? validUrl.substring(0, validUrl.length - 1)
        : validUrl;
  }
}

class PubApiPackage {
  final String packageName;

  PubApiPackage(this.packageName);
}

class PubApiPackageDetails {
  final String packageName;
  final String? description;
  final String? latestVersion;

  PubApiPackageDetails(this.packageName, this.description, this.latestVersion);
}

/// A wrapper over a package:http Client that does not pass on calls to [close].
///
/// This is used to prevent the server closing a client that may be provided to
/// it (while still allowing it to close any client it creates itself).
class _NoCloseHttpClient extends http.BaseClient {
  final http.Client client;

  _NoCloseHttpClient(this.client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      client.send(request);
}
