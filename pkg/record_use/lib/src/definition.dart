// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'identifier.dart' show Identifier;

/// A defintion is an [identifier] with its [loadingUnit].
class Definition {
  final Identifier identifier;
  final String? loadingUnit;

  const Definition({required this.identifier, this.loadingUnit});

  static const _identifierKey = 'identifier';
  static const _loadingUnitKey = 'loading_unit';

  factory Definition.fromJson(Map<String, Object?> json) {
    return Definition(
      identifier: Identifier.fromJson(
        json[_identifierKey] as Map<String, Object?>,
      ),
      loadingUnit: json[_loadingUnitKey] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    _identifierKey: identifier.toJson(),
    if (loadingUnit != null) _loadingUnitKey: loadingUnit,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Definition &&
        other.identifier == identifier &&
        other.loadingUnit == loadingUnit;
  }

  @override
  int get hashCode => Object.hash(identifier, loadingUnit);
}
