// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StorageInfo {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  void queryUsageAndQuota(int storageType, StorageInfoUsageCallback usageCallback = null, StorageInfoErrorCallback errorCallback = null);

  void requestQuota(int storageType, int newQuotaInBytes, StorageInfoQuotaCallback quotaCallback = null, StorageInfoErrorCallback errorCallback = null);
}
