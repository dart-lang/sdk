// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_api;

import "package:expect/expect.dart";
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import 'analyze_helper.dart';

/**
 * Map of white-listed warnings and errors.
 *
 * Only add a white-listing together with a bug report to dartbug.com and add
 * the bug issue number as a comment on the white-listing.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of white-listings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys and message kinds as
// values.
const Map<String,List<String>> WHITE_LIST = const {
  'sdk/lib/_internal/compiler/implementation/constants.dart':
      const [
          'Hint: The class "PrimitiveConstant" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/dart_types.dart':
      const [
          'Hint: The class "MalformedType" overrides "operator==", '
          'but not "get hashCode".',
          'Hint: The class "InterfaceType" overrides "operator==", '
          'but not "get hashCode".',
          'Hint: The class "TypedefType" overrides "operator==", '
          'but not "get hashCode".',
      ],

  'sdk/lib/_internal/compiler/implementation/ssa/types.dart':
      const [
          'Hint: The class "HBoundedType" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/ssa/value_range_analyzer.dart':
      const [
          'Hint: The class "IntValue" overrides "operator==", '
          'but not "get hashCode".',
          'Hint: The class "InstructionValue" overrides "operator==", '
          'but not "get hashCode".',
          'Hint: The class "AddValue" overrides "operator==", '
          'but not "get hashCode".',
          'Hint: The class "SubtractValue" overrides "operator==", '
          'but not "get hashCode".',
          'Hint: The class "NegateValue" overrides "operator==", '
          'but not "get hashCode".',
          'Hint: The class "Range" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/tree/dartstring.dart':
      const [
          'Hint: The class "DartString" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/types/container_type_mask.dart':
      const [
          'Hint: The class "ContainerTypeMask" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/types/element_type_mask.dart':
      const [
          'Hint: The class "ElementTypeMask" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/types/simple_types_inferrer.dart':
      const [
          'Hint: The class "ArgumentsTypes" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/types/union_type_mask.dart':
      const [
          'Hint: The class "UnionTypeMask" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/universe/side_effects.dart':
      const [
          'Hint: The class "SideEffects" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/util/link.dart':
      const [
          'Hint: The class "Link" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/util/link_implementation.dart':
      const [
          'Hint: The class "LinkEntry" overrides "operator==", '
          'but not "get hashCode".',
      ],
  'sdk/lib/_internal/compiler/implementation/warnings.dart':
      const [
          'Hint: The class "Message" overrides "operator==", '
          'but not "get hashCode".',
      ],
};

void main() {
  var uri = currentDirectory.resolve(
      'sdk/lib/_internal/compiler/implementation/dart2js.dart');
  analyze([uri], WHITE_LIST);
}
