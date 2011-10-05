// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CharacterData extends Node {

  String get data();

  void set data(String value);

  int get length();

  void appendData(String data = null);

  void deleteData(int offset = null, int length = null);

  void insertData(int offset = null, String data = null);

  void replaceData(int offset = null, int length = null, String data = null);

  String substringData(int offset = null, int length = null);
}
