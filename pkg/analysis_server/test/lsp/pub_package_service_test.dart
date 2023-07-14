// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/services/pub/pub_api.dart';
import 'package:analysis_server/src/services/pub/pub_command.dart';
import 'package:analysis_server/src/services/pub/pub_package_service.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../mocks.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubApiTest);
    defineReflectiveTests(PubCommandTest);
    defineReflectiveTests(PubPackageServiceTest);
  });
}

@reflectiveTest
class PubApiTest {
  static const pubDefaultUrl = 'https://pub.dartlang.org';

  Uri? lastCalledUrl;
  late MockHttpClient httpClient;

  Future<void> check_pubHostedUrl(String? envValue, String expectedBase) async {
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
class PubCommandTest with ResourceProviderMixin {
  late MockProcessRunner processRunner;
  late PubCommand pubCommand;
  late String pubspecPath, pubspec2Path;

  void setUp() {
    pubspecPath = convertPath('/home/project/pubspec.yaml');
    pubspec2Path = convertPath('/home/project2/pubspec.yaml');
    processRunner = MockProcessRunner();
    pubCommand = PubCommand(InstrumentationService.NULL_SERVICE,
        resourceProvider.pathContext, processRunner);
  }

  Future<void> test_doesNotRunConcurrently() async {
    var isRunning = false;
    processRunner.startHandler = (executable, args, {dir, env}) async {
      expect(isRunning, isFalse,
          reason: 'pub commands should not run concurrently');
      isRunning = true;
      await pumpEventQueue(times: 500);
      isRunning = false;
      return MockProcess(0, 0, 'a', 'a');
    };
    await Future.wait([
      pubCommand.outdatedVersions(pubspecPath),
      pubCommand.outdatedVersions(pubspecPath),
    ]);
  }

  Future<void> test_killsCommandOnShutdown() async {
    // Create a process that won't complete (unless it's killed, where
    // the MockProcess will complete it with a non-zero exit code).
    final process = MockProcess(0, Completer<int>().future, '', '');
    processRunner.startHandler = (executable, args, {dir, env}) => process;

    // Start running the (endless) command.
    final commandFuture = pubCommand.outdatedVersions(pubspecPath);
    await pumpEventQueue(times: 500);

    // Trigger shutdown, which should kill any in-process commands.
    pubCommand.shutdown();

    // Expect the process we created above terminates with non-zero exit code.
    expect(await process.exitCode, equals(MockProcess.killedExitCode));
    expect(commandFuture, completes);
  }

  Future<void> test_outdated_args() async {
    processRunner.startHandler = (executable, args, {dir, env}) {
      expect(executable, Platform.resolvedExecutable);
      expect(
          args,
          equals([
            'pub',
            'outdated',
            '--show-all',
            '--json',
          ]));
      expect(dir, equals(convertPath('/home/project')));
      expect(
          env!['PUB_ENVIRONMENT'],
          anyOf(equals('analysis_server.pub_api'),
              endsWith(':analysis_server.pub_api')));
      return MockProcess(0, 0, '', '');
    };
    await pubCommand.outdatedVersions(pubspecPath);
  }

  Future<void> test_outdated_invalidJson() async {
    processRunner.startHandler = (String executable, List<String> args,
            {dir, env}) =>
        MockProcess(1, 0, 'NOT VALID JSON', '');
    final result = await pubCommand.outdatedVersions(pubspecPath);
    expect(result, isEmpty);
  }

  Future<void> test_outdated_missingFields() async {
    final validJson = r'''
    {
      "packages": [
        {
          "package":    "foo",
          "current":    { "version": "1.0.0" },
          "upgradable": { "version": "2.0.0" },
          "resolvable": { }
        }
      ]
    }
    ''';
    processRunner.startHandler =
        (executable, args, {dir, env}) => MockProcess(1, 0, validJson, '');
    final result = await pubCommand.outdatedVersions(pubspecPath);
    expect(result, hasLength(1));
    final package = result.first;
    expect(package.packageName, equals('foo'));
    expect(package.currentVersion, equals('1.0.0'));
    expect(package.upgradableVersion, equals('2.0.0'));
    expect(package.resolvableVersion, isNull);
    expect(package.latestVersion, isNull);
  }

  Future<void> test_outdated_multiplePubspecs() async {
    final pubspecJson1 = r'''
    {
      "packages": [
        {
          "package":    "foo",
          "resolvable": { "version": "1.1.1" }
        }
      ]
    }
    ''';
    final pubspecJson2 = r'''
    {
      "packages": [
        {
          "package":    "foo",
          "resolvable": { "version": "2.2.2" }
        }
      ]
    }
    ''';

    processRunner.startHandler = (executable, args, {dir, env}) {
      // Return different json based on the directory we were invoked in.
      final json = dir == resourceProvider.pathContext.dirname(pubspecPath)
          ? pubspecJson1
          : pubspecJson2;
      return MockProcess(1, 0, json, '');
    };
    final result1 = await pubCommand.outdatedVersions(pubspecPath);
    final result2 = await pubCommand.outdatedVersions(pubspec2Path);
    expect(result1.first.resolvableVersion, equals('1.1.1'));
    expect(result2.first.resolvableVersion, equals('2.2.2'));
  }

  Future<void> test_outdated_nonZeroExitCode() async {
    processRunner.startHandler =
        (executable, args, {dir, env}) => MockProcess(1, 123, '{}', '');
    final result = await pubCommand.outdatedVersions(pubspecPath);
    expect(result, isEmpty);
  }

  Future<void> test_validJson() async {
    final validJson = r'''
    {
      "packages": [
        {
          "package":    "foo",
          "current":    { "version": "1.0.0" },
          "upgradable": { "version": "2.0.0" },
          "resolvable": { "version": "3.0.0" },
          "latest":     { "version": "4.0.0" }
        },
        {
          "package":    "bar",
          "current":    { "version": "1.0.0" },
          "upgradable": { "version": "2.0.0" },
          "resolvable": { "version": "3.0.0" },
          "latest":     { "version": "4.0.0" }
        }
      ]
    }
    ''';
    processRunner.startHandler =
        (executable, args, {dir, env}) => MockProcess(1, 0, validJson, '');
    final result = await pubCommand.outdatedVersions(pubspecPath);
    expect(result, hasLength(2));
    for (final (index, package) in result.indexed) {
      expect(package.packageName, equals(index == 0 ? 'foo' : 'bar'));
      expect(package.currentVersion, equals('1.0.0'));
      expect(package.upgradableVersion, equals('2.0.0'));
      expect(package.resolvableVersion, equals('3.0.0'));
      expect(package.latestVersion, equals('4.0.0'));
    }
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

    expect(server.pubPackageService.isPackageNamesTimerRunning, isFalse);
    expect(server.pubPackageService.packageCache, isNull);
    expectPackages([]);
    await openFile(pubspecFileUri, '');
    await pumpEventQueue();

    expect(server.pubPackageService.isPackageNamesTimerRunning, isTrue);
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

    final cache = server.pubPackageService.readDiskCache()!;
    final packages = cache.packages.values.toList();

    expect(packages.map((p) => p.packageName), equals(['one', 'two', 'three']));
  }
}
