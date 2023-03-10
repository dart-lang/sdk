// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show ClassID, patch;

@patch
abstract class _TypedListBase {
  @patch
  bool _setRange(int startInBytes, int lengthInBytes, _TypedListBase from,
      int startFromInBytes, int toCid, int fromCid) {
    // The way [_setRange] is called, both `this` and [from] are [_TypedList].
    _TypedList thisList = this as _TypedList;
    _TypedList fromList = from as _TypedList;
    bool shouldClamp = (toCid == ClassID.cidUint8ClampedList ||
            toCid == ClassID.cid_Uint8ClampedList ||
            toCid == ClassID.cidUint8ClampedArrayView) &&
        (fromCid == ClassID.cidInt8List ||
            fromCid == ClassID.cid_Int8List ||
            fromCid == ClassID.cidInt8ArrayView);
    // TODO(joshualitt): There are conditions where we can avoid the copy even
    // when the buffer is the same, i.e. if the ranges do not overlap, or we
    // could if the ranges overlap but the destination index is higher than the
    // source.
    bool needsCopy = thisList.buffer == fromList.buffer;
    if (shouldClamp) {
      if (needsCopy) {
        List<int> temp = List<int>.generate(lengthInBytes,
            (index) => fromList._getInt8(index + startFromInBytes));
        for (int i = 0; i < lengthInBytes; i++) {
          thisList._setUint8(i + startInBytes, temp[i].clamp(0, 255));
        }
      } else {
        for (int i = 0; i < lengthInBytes; i++) {
          thisList._setUint8(i + startInBytes,
              fromList._getInt8(i + startFromInBytes).clamp(0, 255));
        }
      }
    } else if (needsCopy) {
      List<int> temp = List<int>.generate(lengthInBytes,
          (index) => fromList._getInt8(index + startFromInBytes));
      for (int i = 0; i < lengthInBytes; i++) {
        thisList._setUint8(i + startInBytes, temp[i]);
      }
    } else {
      for (int i = 0; i < lengthInBytes; i++) {
        thisList._setUint8(
            i + startInBytes, fromList._getInt8(i + startFromInBytes));
      }
    }
    return true;
  }
}

@patch
abstract class _TypedList extends _TypedListBase {
  Float32x4 _getFloat32x4(int offsetInBytes) {
    ByteData data = buffer.asByteData();
    return Float32x4(
        data.getFloat32(offsetInBytes + 0 * 4, Endian.host),
        data.getFloat32(offsetInBytes + 1 * 4, Endian.host),
        data.getFloat32(offsetInBytes + 2 * 4, Endian.host),
        data.getFloat32(offsetInBytes + 3 * 4, Endian.host));
  }

  void _setFloat32x4(int offsetInBytes, Float32x4 value) {
    ByteData data = buffer.asByteData();
    data.setFloat32(offsetInBytes + 0 * 4, value.x, Endian.host);
    data.setFloat32(offsetInBytes + 1 * 4, value.y, Endian.host);
    data.setFloat32(offsetInBytes + 2 * 4, value.z, Endian.host);
    data.setFloat32(offsetInBytes + 3 * 4, value.w, Endian.host);
  }

  Int32x4 _getInt32x4(int offsetInBytes) {
    ByteData data = buffer.asByteData();
    return Int32x4(
        data.getInt32(offsetInBytes + 0 * 4, Endian.host),
        data.getInt32(offsetInBytes + 1 * 4, Endian.host),
        data.getInt32(offsetInBytes + 2 * 4, Endian.host),
        data.getInt32(offsetInBytes + 3 * 4, Endian.host));
  }

  void _setInt32x4(int offsetInBytes, Int32x4 value) {
    ByteData data = buffer.asByteData();
    data.setInt32(offsetInBytes + 0 * 4, value.x, Endian.host);
    data.setInt32(offsetInBytes + 1 * 4, value.y, Endian.host);
    data.setInt32(offsetInBytes + 2 * 4, value.z, Endian.host);
    data.setInt32(offsetInBytes + 3 * 4, value.w, Endian.host);
  }

  Float64x2 _getFloat64x2(int offsetInBytes) {
    ByteData data = buffer.asByteData();
    return Float64x2(data.getFloat64(offsetInBytes + 0 * 8, Endian.host),
        data.getFloat64(offsetInBytes + 1 * 8, Endian.host));
  }

  void _setFloat64x2(int offsetInBytes, Float64x2 value) {
    ByteData data = buffer.asByteData();
    data.setFloat64(offsetInBytes + 0 * 8, value.x, Endian.host);
    data.setFloat64(offsetInBytes + 1 * 8, value.y, Endian.host);
  }
}
