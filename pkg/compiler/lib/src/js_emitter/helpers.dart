// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

ClassElement computeMixinClass(MixinApplicationElement mixinApplication) {
  ClassElement mixin = mixinApplication.mixin;
  while (mixin.isMixinApplication) {
    mixinApplication = mixin;
    mixin = mixinApplication.mixin;
  }
  return mixin;
}
