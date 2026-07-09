// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class ImageStreamCompleter {
  void addListener();
}

class _LiveImage {
  factory _LiveImage(ImageStreamCompleter a) => throw UnimplementedError();
}

abstract class Foo {
  dynamic get _pendingImages;

  ImageStreamCompleter? putIfAbsent(Object key, ImageStreamCompleter loader()) {
    assert(key != null);
    assert(loader != null);
    ImageStreamCompleter? result = _pendingImages[key]?.completer;
    if (result != null) {
      return result;
    }
    try {
      result = loader();
      _LiveImage(result);
    } catch (error) {
      return null;
    }

    result.addListener();

    return result;
  }
}

main() {}
