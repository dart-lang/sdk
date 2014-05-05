// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exists so that pub can retain backwards-compatibility with
/// versions of barback prior to 0.13.1.
///
/// In 0.13.1, `lib/src/internal_asset.dart` was moved to
/// `lib/src/asset/internal_asset.dart. Pub needs to support all versions of
/// barback back through 0.13.0, though. In order for this to work, it needs to
/// be able to import "package:barback/src/internal_asset.dart" on all available
/// barback versions, hence the existence of this library.
library barback.internal_asset;

export 'asset/internal_asset.dart';
