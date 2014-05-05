// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transformer.lazy_transformer;

import 'declaring_transformer.dart';

/// An interface for [Transformer]s that indicates that the transformer's
/// outputs shouldn't be generated until requested.
///
/// The [declareOutputs] method is used to figure out which assets should be
/// treated as "lazy." Lazy assets will only be forced to be generated if
/// they're requested by the user or if they're used by a non-declaring
/// transformer.
abstract class LazyTransformer extends DeclaringTransformer {}
