// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

class Asset {
  final String name;
  final Uint8List data;

  Asset(this.name, this.data);

  String get mimeType {
    final extensionStart = name.lastIndexOf('.');
    final extension = name.substring(extensionStart + 1);
    switch (extension) {
      case 'html':
        return 'text/html; charset=UTF-8';
      case 'dart':
        return 'application/dart; charset=UTF-8';
      case 'js':
        return 'application/javascript; charset=UTF-8';
      case 'css':
        return 'text/css; charset=UTF-8';
      case 'gif':
        return 'image/gif';
      case 'png':
        return 'image/png';
      case 'jpg':
        return 'image/jpeg';
      case 'jpeg':
        return 'image/jpeg';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'text/plain';
    }
  }

  static Map<String, Asset>? request() {
    Uint8List? tarBytes = _requestAssets();
    if (tarBytes == null) {
      return null;
    }
    final assetList = _decodeAssets(tarBytes);
    final assets = <String, Asset>{};
    for (int i = 0; i < assetList.length; i += 2) {
      final a = Asset(assetList[i] as String, assetList[i + 1] as Uint8List);
      assets[a.name] = a;
    }
    return assets;
  }

  String toString() => '$name ($mimeType)';
}

@pragma("vm:external-name", "VMService_DecodeAssets")
external List<dynamic> _decodeAssets(Uint8List data);

Map<String, Asset>? _assets;
Map<String, Asset>? get assets {
  if (_assets == null) {
    try {
      _assets = Asset.request();
    } catch (e) {
      print('Could not load Observatory assets: $e');
    }
  }
  return _assets;
}
