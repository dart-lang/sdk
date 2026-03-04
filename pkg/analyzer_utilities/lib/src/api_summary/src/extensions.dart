// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

extension ElementExtension on Element {
  /// Returns the appropriate name for describing the element in `api.txt`.
  ///
  /// The name is the same as [name], but with `=` appended for setters.
  String get apiName {
    var apiName = name!;
    if (this is SetterElement) {
      apiName += '=';
    }
    return apiName;
  }
}

extension FormalParameterElementExtension on FormalParameterElement {
  bool get isDeprecated {
    // TODO(paulberry): add this to the analyzer public API
    return metadata.hasDeprecated;
  }
}

extension IterableIterableExtension on Iterable<Iterable<Object?>> {
  /// Forms a list containing [prefix], followed by the elements of `this`
  /// (separated by [separator]), followed by [suffix].
  ///
  /// Each element of `this` is also an iterable; these elements are added to
  /// the resulting list using `.addAll`, so one level of iterable nesting is
  /// removed.
  List<Object?> separatedBy({
    String separator = ', ',
    String prefix = '',
    String suffix = '',
  }) {
    var result = <Object?>[prefix];
    var first = true;
    for (var item in this) {
      if (first) {
        first = false;
      } else {
        result.add(separator);
      }
      result.addAll(item);
    }
    result.add(suffix);
    return result;
  }
}

extension StringExtension on String {
  bool get isPublic => !startsWith('_');
}

extension UriExtension on Uri {
  bool isIn(String packageName) =>
      scheme == 'package' &&
      pathSegments.isNotEmpty &&
      pathSegments[0] == packageName;

  bool isInPublicLibOf(String packageName) =>
      scheme == 'package' &&
      pathSegments.length > 1 &&
      pathSegments[0] == packageName &&
      pathSegments[1] != 'src';
}
