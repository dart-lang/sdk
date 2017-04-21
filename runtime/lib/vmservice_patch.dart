// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@patch
class Asset {
  /// Call to request assets from the embedder.
  @patch
  static HashMap<String, Asset> request() {
    Uint8List tarBytes = _requestAssets();
    if (tarBytes == null) {
      return null;
    }
    List assetList = _decodeAssets(tarBytes);
    HashMap<String, Asset> assets = new HashMap<String, Asset>();
    for (int i = 0; i < assetList.length; i += 2) {
      var a = new Asset(assetList[i], assetList[i + 1]);
      assets[a.name] = a;
    }
    return assets;
  }
}

List _decodeAssets(Uint8List data) native "VMService_DecodeAssets";

@patch
bool sendIsolateServiceMessage(SendPort sp, List m)
    native "VMService_SendIsolateServiceMessage";
@patch
void sendRootServiceMessage(List m) native "VMService_SendRootServiceMessage";
@patch
void sendObjectRootServiceMessage(List m)
    native "VMService_SendObjectRootServiceMessage";
@patch
void _onStart() native "VMService_OnStart";
@patch
void _onExit() native "VMService_OnExit";
@patch
void onServerAddressChange(String address)
    native "VMService_OnServerAddressChange";
@patch
bool _vmListenStream(String streamId) native "VMService_ListenStream";
@patch
void _vmCancelStream(String streamId) native "VMService_CancelStream";
@patch
Uint8List _requestAssets() native "VMService_RequestAssets";
@patch
void _spawnUriNotify(obj, String token) native "VMService_spawnUriNotify";
