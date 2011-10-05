// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DataView extends ArrayBufferView {

  num getFloat32(int byteOffset, bool littleEndian = null);

  num getFloat64(int byteOffset, bool littleEndian = null);

  int getInt16(int byteOffset, bool littleEndian = null);

  int getInt32(int byteOffset, bool littleEndian = null);

  Object getInt8();

  int getUint16(int byteOffset, bool littleEndian = null);

  int getUint32(int byteOffset, bool littleEndian = null);

  Object getUint8();

  void setFloat32(int byteOffset, num value, bool littleEndian = null);

  void setFloat64(int byteOffset, num value, bool littleEndian = null);

  void setInt16(int byteOffset, int value, bool littleEndian = null);

  void setInt32(int byteOffset, int value, bool littleEndian = null);

  void setInt8();

  void setUint16(int byteOffset, int value, bool littleEndian = null);

  void setUint32(int byteOffset, int value, bool littleEndian = null);

  void setUint8();
}
