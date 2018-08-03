// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

class _FilterImpl extends NativeFieldWrapperClass1 implements RawZLibFilter {
  void process(List<int> data, int start, int end) native "Filter_Process";

  List<int> processed({bool flush: true, bool end: false})
      native "Filter_Processed";
}

class _ZLibInflateFilter extends _FilterImpl {
  _ZLibInflateFilter(int windowBits, List<int> dictionary, bool raw) {
    _init(windowBits, dictionary, raw);
  }
  void _init(int windowBits, List<int> dictionary, bool raw)
      native "Filter_CreateZLibInflate";
}

class _ZLibDeflateFilter extends _FilterImpl {
  _ZLibDeflateFilter(bool gzip, int level, int windowBits, int memLevel,
      int strategy, List<int> dictionary, bool raw) {
    _init(gzip, level, windowBits, memLevel, strategy, dictionary, raw);
  }
  void _init(bool gzip, int level, int windowBits, int memLevel, int strategy,
      List<int> dictionary, bool raw) native "Filter_CreateZLibDeflate";
}

@patch
class RawZLibFilter {
  @patch
  static RawZLibFilter _makeZLibDeflateFilter(
          bool gzip,
          int level,
          int windowBits,
          int memLevel,
          int strategy,
          List<int> dictionary,
          bool raw) =>
      new _ZLibDeflateFilter(
          gzip, level, windowBits, memLevel, strategy, dictionary, raw);
  @patch
  static RawZLibFilter _makeZLibInflateFilter(
          int windowBits, List<int> dictionary, bool raw) =>
      new _ZLibInflateFilter(windowBits, dictionary, raw);
}
