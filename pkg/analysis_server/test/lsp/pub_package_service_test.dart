// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/pub/pub_api.dart';
import 'package:analysis_server/src/services/pub/pub_package_service.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../mocks.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubApiTest);
    defineReflectiveTests(PubPackageServiceTest);
  });
}

@reflectiveTest
class PubApiTest {
  static const pubDefaultUrl = 'https://pub.dartlang.org';

  Uri lastCalledUrl;
  MockHttpClient httpClient;

  PubApi api;

  Future<void> check_pubHostedUrl(String envValue, String expectedBase) async {
    final api =
        PubApi(InstrumentationService.NULL_SERVICE, httpClient, envValue);
    await api.allPackages();
    expect(lastCalledUrl.toString(),
        equals('$expectedBase/api/package-name-completion-data'));
  }

  void setUp() {
    httpClient = MockHttpClient();
    lastCalledUrl = null;
    httpClient.sendHandler = (BaseRequest request) async {
      lastCalledUrl = request.url;
      return Response('{}', 200);
    };
  }

  Future<void> test_envPubHostedUrl_emptyString() =>
      check_pubHostedUrl('', pubDefaultUrl);

  Future<void> test_envPubHostedUrl_invalidUrl() =>
      check_pubHostedUrl('test', pubDefaultUrl);

  Future<void> test_envPubHostedUrl_missingScheme() =>
      // It's hard to tell that this is intended to be a valid URL minus the scheme
      // so it will fail validation and fall back to the default.
      check_pubHostedUrl('pub.example.org', pubDefaultUrl);

  Future<void> test_envPubHostedUrl_null() =>
      check_pubHostedUrl(null, pubDefaultUrl);

  Future<void> test_envPubHostedUrl_valid() =>
      check_pubHostedUrl('https://pub.example.org', 'https://pub.example.org');

  Future<void> test_envPubHostedUrl_validTrailingSlash() =>
      check_pubHostedUrl('https://pub.example.org/', 'https://pub.example.org');

  Future<void> test_httpClient_closesOwn() async {
    final api = PubApi(InstrumentationService.NULL_SERVICE, null, null);
    api.close();
    expect(() => api.httpClient.get(Uri.parse('https://www.google.co.uk/')),
        throwsA(anything));
  }

  Future<void> test_httpClient_doesNotCloseProvided() async {
    final api = PubApi(InstrumentationService.NULL_SERVICE, httpClient, null);
    api.close();
    expect(httpClient.wasClosed, isFalse);
  }
}

@reflectiveTest
class PubPackageServiceTest extends AbstractLspAnalysisServerTest {
  /// A sample API response for package names. This should match the JSON served
  /// at https://pub.dev/api/package-name-completion-data.
  static const samplePackageList = '''
  { "packages": ["one", "two", "three"] }
  ''';

  void expectPackages(List<String> packageNames) => expect(
      server.pubPackageService.cachedPackages.map((p) => p.packageName),
      equals(packageNames));

  void providePubApiPackageList(String jsonResponse) {
    httpClient.sendHandler = (BaseRequest request) async {
      if (request.url.toString().endsWith(PubApi.packageNameListPath)) {
        return Response(jsonResponse, 200);
      } else {
        throw UnimplementedError();
      }
    };
  }

  @override
  void setUp() {
    super.setUp();
    // Cause retries to run immediately.
    PubApi.failedRetryInitialDelaySeconds = 0;
  }

  Future<void> test_packageCache_diskCacheReplacedIfStale() async {
    // This test should mirror test_packageCache_diskCacheUsedIfFresh
    // besides the lastUpdated timestamp + expectations.
    providePubApiPackageList(samplePackageList);

    // Write a cache that should be considered stale.
    server.pubPackageService.writeDiskCache(
      PackageDetailsCache.fromApiResults([PubApiPackage('stalePackage1')])
        ..lastUpdatedUtc = DateTime.utc(1990),
    );

    await initialize();
    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    // Expect the sample list to have overwritten the stale cache.
    expectPackages(['one', 'two', 'three']);
  }

  Future<void> test_packageCache_diskCacheUsedIfFresh() async {
    // This test should mirror test_packageCache_diskCacheReplacedIfStale
    // besides the lastUpdated timestamp + expectations.
    providePubApiPackageList(samplePackageList);

    // Write a cache that is not stale.
    server.pubPackageService.writeDiskCache(
        PackageDetailsCache.fromApiResults([PubApiPackage('freshPackage1')]));

    await initialize();
    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    // Expect the fresh cache to still be used.
    expectPackages(['freshPackage1']);
  }

  Future<void> test_packageCache_doesNotRetryOn400() async {
    var requestNum = 1;
    httpClient.sendHandler = (BaseRequest request) async {
      if (request.url.toString().endsWith(PubApi.packageNameListPath)) {
        return requestNum++ == 1
            ? Response('ERROR', 400)
            : Response(samplePackageList, 200);
      } else {
        throw UnimplementedError();
      }
    };

    await initialize();
    expectPackages([]);

    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    expectPackages([]);
    expect(httpClient.sendHandlerCalls, equals(1));
  }

  Future<void> test_packageCache_doesNotRetryUnknownException() async {
    httpClient.sendHandler =
        (BaseRequest request) async => throw UnimplementedError();

    await initialize();
    expectPackages([]);

    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    expectPackages([]);
    expect(httpClient.sendHandlerCalls, equals(1));
  }

  Future<void> test_packageCache_fetchesFromServer() async {
    // Provide the sample packages in the web request.
    providePubApiPackageList(samplePackageList);

    await initialize();
    expectPackages([]);

    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    expectPackages(['one', 'two', 'three']);
  }

  Future<void> test_packageCache_initializesOnPubspecOpen() async {
    await initialize();

    expect(server.pubPackageService.isRunning, isFalse);
    expect(server.pubPackageService.packageCache, isNull);
    expectPackages([]);
    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    expect(server.pubPackageService.isRunning, isTrue);
    expect(server.pubPackageService.packageCache, isNotNull);
    expectPackages([]);
  }

  Future<void> test_packageCache_readsDiskCache() async {
    server.pubPackageService.writeDiskCache(
        PackageDetailsCache.fromApiResults([PubApiPackage('package1')]));

    await initialize();
    expectPackages([]);

    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    expectPackages(['package1']);
  }

  Future<void> test_packageCache_retriesOn500() async {
    var requestNum = 1;
    httpClient.sendHandler = (BaseRequest request) async {
      if (request.url.toString().endsWith(PubApi.packageNameListPath)) {
        return requestNum++ == 1
            ? Response('ERROR', 500)
            : Response(samplePackageList, 200);
      } else {
        throw UnimplementedError();
      }
    };

    await initialize();
    expectPackages([]);

    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    expectPackages(['one', 'two', 'three']);
    expect(httpClient.sendHandlerCalls, equals(2));
  }

  Future<void> test_packageCache_retriesOnInvalidJson() async {
    var requestNum = 1;
    httpClient.sendHandler = (BaseRequest request) async {
      if (request.url.toString().endsWith(PubApi.packageNameListPath)) {
        return requestNum++ == 1
            ? Response('$samplePackageList{{{{{{{', 200)
            : Response(samplePackageList, 200);
      } else {
        throw UnimplementedError();
      }
    };

    await initialize();
    expectPackages([]);

    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    expectPackages(['one', 'two', 'three']);
    expect(httpClient.sendHandlerCalls, equals(2));
  }

  Future<void> test_packageCache_timeRemaining() async {
    void expectHoursRemaining(DateTime cacheTime, int expectedHoursRemaining) {
      final cache = PackageDetailsCache.empty();
      cache.lastUpdatedUtc = cacheTime.toUtc();

      final remainingHours = cache.cacheTimeRemaining.inHours;
      expect(remainingHours, isNonNegative);
      expect(remainingHours, closeTo(expectedHoursRemaining, 1));
    }

    final maxHours = PackageDetailsCache.maxCacheAge.inHours;

    // Very old cache should have no time remaining.
    expectHoursRemaining(DateTime(2020, 12, 1), 0);

    // Cache from 1 hour ago should max-1 hours remaining.
    expectHoursRemaining(DateTime.now().add(Duration(hours: -1)), maxHours - 1);

    // Cache from 10 hours ago should max-10 hours remaining.
    expectHoursRemaining(
        DateTime.now().add(Duration(hours: -10)), maxHours - 10);

    // Cache from maxAge ago should have no hours remaining.
    expectHoursRemaining(
        DateTime.now().add(-PackageDetailsCache.maxCacheAge), 0);
  }

  Future<void> test_packageCache_writesDiskCache() async {
    // Provide the sample packages in the web request.
    providePubApiPackageList(samplePackageList);

    await initialize();
    expect(server.pubPackageService.readDiskCache(), isNull);

    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    final cache = server.pubPackageService.readDiskCache();
    final packages = cache.packages.values.toList();

    expect(packages.map((p) => p.packageName), equals(['one', 'two', 'three']));
  }
}
