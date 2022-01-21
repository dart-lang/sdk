// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../executor.dart';
import '../api.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';

/// Implementation of [MacroClassIdentifier].
class MacroClassIdentifierImpl implements MacroClassIdentifier {
  final String id;

  MacroClassIdentifierImpl(Uri library, String name) : id = '$library#$name';

  MacroClassIdentifierImpl.deserialize(Deserializer deserializer)
      : id = (deserializer..moveNext()).expectString();

  void serialize(Serializer serializer) => serializer.addString(id);

  operator ==(other) => other is MacroClassIdentifierImpl && id == other.id;

  int get hashCode => id.hashCode;
}

/// Implementation of [MacroInstanceIdentifier].
class MacroInstanceIdentifierImpl implements MacroInstanceIdentifier {
  static int _next = 0;

  final int id;

  MacroInstanceIdentifierImpl() : id = _next++;

  MacroInstanceIdentifierImpl.deserialize(Deserializer deserializer)
      : id = (deserializer..moveNext()).expectNum();

  void serialize(Serializer serializer) => serializer.addNum(id);

  operator ==(other) => other is MacroInstanceIdentifierImpl && id == other.id;

  int get hashCode => id;
}

/// Implementation of [MacroExecutionResult].
class MacroExecutionResultImpl implements MacroExecutionResult {
  @override
  final List<DeclarationCode> augmentations;

  @override
  final List<DeclarationCode> imports;

  MacroExecutionResultImpl({
    required this.augmentations,
    required this.imports,
  });

  factory MacroExecutionResultImpl.deserialize(Deserializer deserializer) {
    deserializer.moveNext();
    deserializer.expectList();
    List<DeclarationCode> augmentations = [
      for (bool hasNext = deserializer.moveNext();
          hasNext;
          hasNext = deserializer.moveNext())
        deserializer.expectCode()
    ];
    deserializer.moveNext();
    deserializer.expectList();
    List<DeclarationCode> imports = [
      for (bool hasNext = deserializer.moveNext();
          hasNext;
          hasNext = deserializer.moveNext())
        deserializer.expectCode()
    ];

    return new MacroExecutionResultImpl(
      augmentations: augmentations,
      imports: imports,
    );
  }

  void serialize(Serializer serializer) {
    serializer.startList();
    for (DeclarationCode augmentation in augmentations) {
      augmentation.serialize(serializer);
    }
    serializer.endList();
    serializer.startList();
    for (DeclarationCode import in imports) {
      import.serialize(serializer);
    }
    serializer.endList();
  }
}
