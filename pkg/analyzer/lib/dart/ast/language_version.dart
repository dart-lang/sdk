// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The language version override specified for a compilation unit.
@Deprecated("Use unit.languageVersionToken instead")
class LanguageVersion {
  final int major;
  final int minor;

  LanguageVersion(this.major, this.minor);

  @override
  int get hashCode => major.hashCode * 13 + minor.hashCode * 17;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    return other is LanguageVersion &&
        other.major == major &&
        other.minor == minor;
  }

  @override
  String toString() {
    return 'LanguageVersion(major=$major,minor=$minor)';
  }
}
