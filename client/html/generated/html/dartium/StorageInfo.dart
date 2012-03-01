
class _StorageInfoImpl extends _DOMTypeBase implements StorageInfo {
  _StorageInfoImpl._wrap(ptr) : super._wrap(ptr);

  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback = null, StorageInfoErrorCallback errorCallback = null]) {
    if (usageCallback === null) {
      if (errorCallback === null) {
        _ptr.queryUsageAndQuota(_unwrap(storageType));
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.queryUsageAndQuota(_unwrap(storageType), _unwrap(usageCallback));
        return;
      } else {
        _ptr.queryUsageAndQuota(_unwrap(storageType), _unwrap(usageCallback), _unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback = null, StorageInfoErrorCallback errorCallback = null]) {
    if (quotaCallback === null) {
      if (errorCallback === null) {
        _ptr.requestQuota(_unwrap(storageType), _unwrap(newQuotaInBytes));
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.requestQuota(_unwrap(storageType), _unwrap(newQuotaInBytes), _unwrap(quotaCallback));
        return;
      } else {
        _ptr.requestQuota(_unwrap(storageType), _unwrap(newQuotaInBytes), _unwrap(quotaCallback), _unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
