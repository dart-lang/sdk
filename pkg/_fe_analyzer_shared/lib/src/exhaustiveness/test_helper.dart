// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_template_buffer.dart';
import 'exhaustive.dart';
import 'key.dart';
import 'shape.dart';
import 'space.dart';
import 'witness.dart';

/// Tags used for id-testing of exhaustiveness.
class Tags {
  static const String error = 'error';
  static const String reduced = 'reduced';
  static const String scrutineeType = 'type';
  static const String scrutineeFields = 'fields';
  static const String space = 'space';
  static const String subtypes = 'subtypes';
  static const String expandedSubtypes = 'expandedSubtypes';
  static const String checkingOrder = 'checkingOrder';
}

/// Returns a textual representation for [space] used for testing.
String spacesToText(Space space) {
  String text = space.toString();
  if (text.startsWith('[') && (text.endsWith(']') || text.endsWith(']?'))) {
    // Avoid list-like syntax which collides with the [Features] encoding.
    return '<$text>';
  }
  return text;
}

/// Returns a textual representation for [propertiesOfInterest] used for
/// testing.
String propertiesToText(
  Shape shape,
  ObjectPropertyLookup objectPropertyLookup,
  Set<Key> propertiesOfInterest,
) {
  List<Key> sortedNames = propertiesOfInterest.toList()..sort();
  StringBuffer sb = new StringBuffer();
  String comma = '';
  sb.write('{');
  for (Key key in sortedNames) {
    sb.write(comma);
    if (key is ExtensionKey) {
      sb.write(key.receiverShape);
      sb.write('.');
      sb.write(key.name);
      sb.write(':');
      sb.write(shapeToText(key.shape));
    } else {
      Shape? propertyShape = shape.getPropertyShape(objectPropertyLookup, key);
      sb.write(key.name);
      sb.write(':');
      if (propertyShape != null) {
        sb.write(shapeToText(propertyShape));
      } else {
        sb.write("-");
      }
    }
    comma = ',';
  }
  sb.write('}');
  return sb.toString();
}

/// Returns a textual representation for [shape] used for testing.
String shapeToText(Shape shape) => shape.toString();

/// Returns a textual representation of [shapes] used for testing.
String? shapesToText(Iterable<Shape> shapes) {
  if (shapes.isEmpty) return null;
  // TODO(johnniwinther): Sort shapes.
  StringBuffer sb = new StringBuffer();
  String comma = '';
  sb.write('{');
  for (Shape shape in shapes) {
    sb.write(comma);
    sb.write(shapeToText(shape));
    comma = ',';
  }
  sb.write('}');
  return sb.toString();
}

/// Returns a textual representation of the witnesses in [nonExhaustiveness].
String nonExhaustivenessToText(NonExhaustiveness nonExhaustiveness) {
  StringBuffer sb = new StringBuffer();
  sb.write('non-exhaustive:');
  String delimiter = '';
  for (Witness witness in nonExhaustiveness.witnesses) {
    sb.write(delimiter);
    String witnessText = witness.asWitness;
    String correctionText = witness.asCorrection;
    if (witnessText != correctionText) {
      sb.write('$witnessText/$correctionText');
    } else {
      sb.write(witnessText);
    }
    delimiter = ';';
  }
  return sb.toString();
}

/// Returns a textual representation of the reduced witnesses of
/// [nonExhaustiveness].
///
/// This is deliberately identical to [nonExhaustivenessToText] if the reduction
/// didn't produce different witnesses, such that tests only need to include
/// the reduced test expectation when it is different.
Future<String> reducedNonExhaustivenessToText(
  NonExhaustiveness nonExhaustiveness,
) async {
  StringBuffer sb = new StringBuffer();
  sb.write('non-exhaustive:');
  String delimiter = '';
  ReducedWitnesses reducedWitnesses =
      await ReducedWitnesses.computeReducedWitnesses(
        nonExhaustiveness.cases,
        nonExhaustiveness.witnesses,
        const DartAccessibilityForTesting(),
      );
  for (Witness witness in reducedWitnesses.nonTrivialWitnesses) {
    sb.write(delimiter);
    String witnessText = witness.asWitness;
    String correctionText = witness.asCorrection;
    if (witnessText != correctionText) {
      sb.write('$witnessText/$correctionText');
    } else {
      sb.write(witnessText);
    }
    delimiter = ';';
  }
  if (reducedWitnesses.needsDefault) {
    sb.write(delimiter);
    sb.write('needsDefault');
  }
  return sb.toString();
}

/// [DartAccessibility] used for testing.
///
/// This considers all enum values and types whose name start with `_` as
/// inaccessible.
class const DartAccessibilityForTesting() implements DartAccessibility {
  @override
  Future<bool> isEnumValueAccessible(Object value, String name) {
    return new Future.value(!name.startsWith('_'));
  }

  @override
  Future<bool> isTypeAccessible(Object type, String name) {
    return new Future.value(!name.startsWith('_'));
  }
}
