// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.configuration;

class Configuration {
  final int charOffset;
  final String dottedName;
  final String condition;
  final String importUri;
  Configuration(
      this.charOffset, this.dottedName, this.condition, this.importUri);
}
