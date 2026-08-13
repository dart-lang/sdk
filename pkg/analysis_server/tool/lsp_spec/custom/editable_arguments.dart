// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support the Editable Arguments / Edit Argument features used by
/// the Property Editor.
final editableArgumentsClasses = <LspEntity>[
  interface('EditableArguments', [
    field('textDocument', type: 'TextDocumentIdentifier'),
    field('name', type: 'string', canBeUndefined: true),
    field('documentation', type: 'string', canBeUndefined: true),
    // TODO(dantup): field('refactors', ...),
    field('arguments', type: 'EditableArgument', array: true),
    field('range', type: 'Range', comment: 'The range of the invocation.'),
  ]),
  interface('EditableArgument', [
    field(
      'name',
      type: 'string',
      comment: 'The name of the corresponding parameter.',
    ),
    field('documentation', type: 'string', canBeUndefined: true),
    field(
      'type',
      type: 'string',
      comment:
          'The kind of parameter.\n\nThis is not necessarily the Dart type, '
          'it is from a defined set of values that clients may understand '
          'how to edit.',
    ),
    Field(
      name: 'value',
      type: TypeReference.lspAny,
      allowsNull: false,
      allowsUndefined: true,
      comment:
          'The current value for this argument (provided only if '
          'hasArgument=true).\n\nThis is only included if an explicit value '
          'is given in the code and is a valid literal for the kind of '
          'parameter. For expressions or named constants, this will not be '
          'included and displayValue can be shown as the current value '
          'instead.\n\nA value of `null` when hasArgument=true means the '
          'argument has an explicit null value and not that defaultValue is '
          'being used.',
    ),
    field(
      'hasArgument',
      type: 'boolean',
      comment:
          'Whether an explicit argument exists for this parameter in the '
          'code.\n\nThis will be true even if the explicit argument is the '
          'same value as the parameter default or null.',
    ),
    Field(
      name: 'defaultValue',
      type: TypeReference.lspAny,
      allowsNull: false,
      allowsUndefined: true,
      comment:
          'The default value for this parameter if no argument is supplied.'
          '\n\nSetting the argument to this value does not remove it from '
          'the argument list.',
    ),
    field(
      'displayValue',
      type: 'string',
      canBeUndefined: true,
      comment:
          'A string that can be displayed to indicate the value for this '
          'argument.\n\nThis will be populated in cases where the source '
          'code is not literally the same as the value field, for example an '
          'expression or named constant.',
    ),
    field(
      'isRequired',
      type: 'boolean',
      comment: 'Whether an argument is required for this parameter.',
    ),
    field(
      'isNullable',
      type: 'boolean',
      comment:
          'Whether this argument can be `null`.\n\nIt is possible for an '
          'argument to be required, but still allow an explicit `null`.',
    ),
    field(
      'isDeprecated',
      type: 'boolean',
      comment: 'Whether the parameter is deprecated.',
    ),
    field(
      'isEditable',
      type: 'boolean',
      comment:
          'Whether this argument can be add/edited.\n\nIf not, '
          'notEditableReason will contain an explanation for why.',
    ),
    field(
      'notEditableReason',
      type: 'String',
      canBeUndefined: true,
      comment:
          'If isEditable is false, contains a human-readable '
          'description of why.',
    ),
    field(
      'options',
      type: 'string',
      array: true,
      canBeUndefined: true,
      comment:
          'The set of values allowed for this argument if it is an enum.\n\n'
          'Values are qualified in the form `EnumName.valueName`.',
    ),
    // TODO(dantup): field('properties', ...),
  ]),
  interface('EditArgumentParams', [
    field('textDocument', type: 'TextDocumentIdentifier'),
    field('position', type: 'Position'),
    field('edit', type: 'ArgumentEdit'),
  ]),
  interface('ArgumentEdit', [
    field('name', type: 'string'),
    Field(
      name: 'newValue',
      type: TypeReference.lspAny,
      allowsNull: true,
      allowsUndefined: false,
    ),
  ]),
];
