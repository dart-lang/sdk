// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

typedef DebugPrintCallback = void Function(String? message, {int? wrapWidth});

DebugPrintCallback debugPrint = (String? message, {int? wrapWidth}) {};
