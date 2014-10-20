library storage_quota_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

import 'dart:async';
import 'dart:isolate';
import 'dart:html';

main() {
  useHtmlConfiguration();

  expectSaneStorageInfo(StorageInfo storageInfo) {
     expect(storageInfo.usage, isNotNull);
     expect(storageInfo.quota, isNotNull);
     expect(storageInfo.usage >= 0, isTrue);
     expect(storageInfo.quota >= storageInfo.usage, isNotNull);
  };

  test('storage quota - temporary', () {
    Future f = window.navigator.storageQuota.queryInfo('temporary');
    expect(f.then(expectSaneStorageInfo), completes);
  });

  test('storage quota - persistent', () {
    Future f = window.navigator.storageQuota.queryInfo('persistent');
    expect(f.then(expectSaneStorageInfo), completes);
  });

  test('storage quota - unknown', () {
    // Throwing synchronously is bogus upstream behavior; should result in a
    // smashed promise.
    expect(() => window.navigator.storageQuota.queryInfo("foo"), throws);  /// missingenumcheck: ok
    var wrongType = 3;
    expect(() => window.navigator.storageQuota.queryInfo(wrongType), throws);
    expect(() => window.navigator.storageQuota.queryInfo(null), throws);
  });
}
