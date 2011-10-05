// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageInfoWrappingImplementation extends DOMWrapperBase implements StorageInfo {
  StorageInfoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void queryUsageAndQuota(int storageType, StorageInfoUsageCallback usageCallback, StorageInfoErrorCallback errorCallback) {
    _ptr.queryUsageAndQuota(storageType, LevelDom.unwrap(usageCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  void requestQuota(int storageType, int newQuotaInBytes, StorageInfoQuotaCallback quotaCallback, StorageInfoErrorCallback errorCallback) {
    _ptr.requestQuota(storageType, newQuotaInBytes, LevelDom.unwrap(quotaCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  String get typeName() { return "StorageInfo"; }
}
