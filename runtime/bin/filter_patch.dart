// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _FilterImpl extends NativeFieldWrapperClass1 implements _Filter {
  void process(List<int> data) native "Filter_Process";

  List<int> processed({bool flush: true}) native "Filter_Processed";

  void end() native "Filter_End";
}

class _ZLibInflateFilter extends _FilterImpl {
  _ZLibInflateFilter() {
    _init();
  }
  void _init() native "Filter_CreateZLibInflate";
}

class _ZLibDeflateFilter extends _FilterImpl {
  _ZLibDeflateFilter(bool gzip, int level) {
    _init(gzip, level);
  }
  void _init(bool gzip, int level) native "Filter_CreateZLibDeflate";
}

patch class _Filter {
  /* patch */ static _Filter newZLibDeflateFilter(bool gzip, int level)
      => new _ZLibDeflateFilter(gzip, level);
  /* patch */ static _Filter newZLibInflateFilter() => new _ZLibInflateFilter();
}

