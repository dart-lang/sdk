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
    if (usageCallback === null) {
      if (errorCallback === null) {
        _queryUsageAndQuota(this, storageType);
        return;
      }
    } else {
      if (errorCallback === null) {
        _queryUsageAndQuota_2(this, storageType, usageCallback);
        return;
      } else {
        _queryUsageAndQuota_3(this, storageType, usageCallback, errorCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _queryUsageAndQuota(receiver, storageType) native;
  static void _queryUsageAndQuota_2(receiver, storageType, usageCallback) native;
  static void _queryUsageAndQuota_3(receiver, storageType, usageCallback, errorCallback) native;

  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback = null, StorageInfoErrorCallback errorCallback = null]) {
    if (quotaCallback === null) {
      if (errorCallback === null) {
        _requestQuota(this, storageType, newQuotaInBytes);
        return;
      }
    } else {
      if (errorCallback === null) {
        _requestQuota_2(this, storageType, newQuotaInBytes, quotaCallback);
        return;
      } else {
        _requestQuota_3(this, storageType, newQuotaInBytes, quotaCallback, errorCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _requestQuota(receiver, storageType, newQuotaInBytes) native;
  static void _requestQuota_2(receiver, storageType, newQuotaInBytes, quotaCallback) native;
  static void _requestQuota_3(receiver, storageType, newQuotaInBytes, quotaCallback, errorCallback) native;

  String get typeName() { return "StorageInfo"; }
}
