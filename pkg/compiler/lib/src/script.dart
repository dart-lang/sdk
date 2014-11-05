// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

class Script {
  final SourceFile file;

  /**
   * The readable URI from which this script was loaded.
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  final Uri readableUri;


  /**
   * The resource URI from which this script was loaded.
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  final Uri resourceUri;

  Script(this.readableUri, this.resourceUri, this.file);

  String get text => (file == null) ? null : file.slowText();
  String get name => (file == null) ? null : file.filename;
}
