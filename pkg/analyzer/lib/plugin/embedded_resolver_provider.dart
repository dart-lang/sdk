// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library analyzer.plugin.embedded_resolver_provider;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/embedder.dart';

/**
 * A function that will return a [UriResolver] that can be used to resolve
 * URI's for embedded libraries within a given folder, or `null` if we should
 * fall back to the standard URI resolver.
 */
@deprecated
typedef EmbedderUriResolver EmbeddedResolverProvider(Folder folder);
