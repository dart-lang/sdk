// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): we need to find a way to avoid conflicts with other
// generated "typeName" fields. Ideally we wouldn't be patching 'Object' here.
Object.prototype.get$typeName = Object.prototype.$typeNameOf;
