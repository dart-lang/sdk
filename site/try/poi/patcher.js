// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

;(function(orig) {
  function patcher(main, args) {
    this.$dart_patch && this.$dart_unsafe_eval.patch($dart_patch);
    if (orig) {
      return orig(main, args);
    } else {
      return main(args);
    }
  }
  this.dartMainRunner = patcher;
})(this.dartMainRunner);
