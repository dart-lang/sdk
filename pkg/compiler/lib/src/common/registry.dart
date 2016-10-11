// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.registry;

import '../elements/elements.dart' show Element;

// TODO(johnniwinther): Remove this.
/// Interface for registration of element dependencies.
abstract class Registry {
  void registerDependency(Element element) {}
}
