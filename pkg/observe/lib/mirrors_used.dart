// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An empty library that declares what needs to be retained with [MirrorsUsed]
/// if you were to use observables together with mirrors. By default this is not
/// included because frameworks using this package also use code generation to
/// avoid using mirrors at deploy time.
library observe.mirrors_used;

// Note: ObservableProperty is in this list only for the unusual use case of
// invoking dart2js without running this package's transformers. The
// transformer in `lib/transformer.dart` will replace @observable with the
// @reflectable annotation.
@MirrorsUsed(metaTargets: const [Reflectable, ObservableProperty],
    override: 'smoke.mirrors')
import 'dart:mirrors' show MirrorsUsed;
import 'package:observe/observe.dart' show Reflectable, ObservableProperty;
