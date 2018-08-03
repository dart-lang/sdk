// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.workspace;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Abstract superclass of classes that provide information about the workspace
 * in which analysis is being performed.
 */
abstract class Workspace {
  /**
   * Return `true` if this workspace defines a single "project"
   * and that "project" depends upon flutter,
   */
  bool get hasFlutterDependency => false;

  /**
   * Return a map of package sources.
   */
  Map<String, List<Folder>> get packageMap;

  /**
   * The [UriResolver] that can resolve `package` URIs.
   */
  UriResolver get packageUriResolver;

  /**
   * Create the [SourceFactory] for resolving Uris to [Source]s.
   * The [sdk] may be `null`.
   */
  SourceFactory createSourceFactory(DartSdk sdk);
}
