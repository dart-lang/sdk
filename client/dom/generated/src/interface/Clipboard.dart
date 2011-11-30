// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Clipboard {

  String get dropEffect();

  void set dropEffect(String value);

  String get effectAllowed();

  void set effectAllowed(String value);

  FileList get files();

  DataTransferItemList get items();

  List get types();

  void clearData([String type]);

  void getData(String type);

  bool setData(String type, String data);

  void setDragImage(HTMLImageElement image, int x, int y);
}
