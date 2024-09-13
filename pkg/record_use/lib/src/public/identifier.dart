// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Identifier {
  final String importUri;
  final String? parent; // Optional since not all elements have parents
  final String name;

  const Identifier({
    required this.importUri,
    this.parent,
    required this.name,
  });

  factory Identifier.fromJson(Map<String, dynamic> json, List<String> uris) =>
      Identifier(
        importUri: uris[json['uri'] as int],
        parent: json['parent'] as String?,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson(Map<String, int> uris) => {
        'uri': uris[importUri]!,
        if (parent != null) 'parent': parent,
        'name': name,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Identifier &&
        other.importUri == importUri &&
        other.parent == parent &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(importUri, parent, name);
}
