// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension TestGeneratorStringExtension on String {
  String upperCaseFirst() => "${this[0].toUpperCase()}${this.substring(1)}";

  String lowerCaseFirst() => "${this[0].toLowerCase()}${this.substring(1)}";

  String makeCComment() => "// " + split("\n").join("\n// ");

  String makeDartDocComment() => "/// " + split("\n").join("\n/// ");

  String limitTo(int lenght) {
    if (this.length > lenght) {
      return substring(0, lenght);
    }
    return this;
  }

  String trimCouts() => replaceAll('" << "', '').replaceAll('"<< "', '');
}
