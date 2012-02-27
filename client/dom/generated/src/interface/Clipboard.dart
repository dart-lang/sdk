// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Clipboard {

  String dropEffect;

  String effectAllowed;

  final FileList files;

  final DataTransferItemList items;

  final List<String> types;

  void clearData([String type]);

  void getData(String type);

  bool setData(String type, String data);

  void setDragImage(HTMLImageElement image, int x, int y);
}
