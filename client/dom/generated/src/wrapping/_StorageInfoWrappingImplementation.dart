// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StorageInfoWrappingImplementation extends DOMWrapperBase implements StorageInfo {
  _StorageInfoWrappingImplementation() : super() {}

  static create__StorageInfoWrappingImplementation() native {
    return new _StorageInfoWrappingImplementation();
  }

  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback = null, StorageInfoErrorCallback errorCallback = null]) {
    _queryUsageAndQuota(this, storageType, usageCallback, errorCallback);
    return;
  }
  static void _queryUsageAndQuota(receiver, storageType, usageCallback, errorCallback) native;

  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback = null, StorageInfoErrorCallback errorCallback = null]) {
    _requestQuota(this, storageType, newQuotaInBytes, quotaCallback, errorCallback);
    return;
  }
  static void _requestQuota(receiver, storageType, newQuotaInBytes, quotaCallback, errorCallback) native;

  String get typeName() { return "StorageInfo"; }
}
