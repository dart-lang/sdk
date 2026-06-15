// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support for Interactive Forms.
final interactiveFormClasses = <LspEntity>[
  // TODO(dantup): Generate this from a JSON metadata file if one is made in the
  //  same format as the LSP metaModel file.
  interface('InteractiveParams', [
    field(
      'formFields',
      array: true,
      type: 'FormField',
      canBeUndefined: true,
      comment:
          'The questions and validation errors in previous '
          'answers to the same questions.\n\n'
          'This is a server-to-client field. The language server defines '
          'these, and the client uses them to render the form.\n\n'
          'The interactive phase is considered complete when the server '
          'returns a response where this slice is omitted.',
    ),
    field(
      'formAnswers',
      type: 'FormAnswer',
      array: true,
      canBeUndefined: true,
      comment:
          'The answers for the form questions.\n\n'
          'When sent by the language server, this field is optional and '
          'contains the current or default answers to the questions to support '
          'editing previous values.\n\n'
          "When sent by the language client, this field contains the user's "
          'answers.\n\n'
          "Answers are linked to their respective questions using the field's "
          'unique `id` rather than their array index. The list must not '
          "contain duplicate IDs, and each answer's ID must correspond to a "
          'field ID defined in `formFields`.\n\n'
          'The client must include answers for all required fields (where '
          '`required` is true). Answers for optional fields (where `required` '
          'is false) may be omitted if no answer was provided, or included if '
          'an answer is available.',
    ),
    field(
      'data',
      type: 'LSPAny',
      canBeUndefined: true,
      comment:
          'Additional data that the client preserves for the server. This '
          'data is for server use only and the client should not inspect it.',
    ),
  ]),
  interface(
    'InteractiveExecuteCommandParams',
    baseTypes: ['InteractiveParams', 'ExecuteCommandParams'],
    [
      field(
        'command',
        type: 'String',
        comment: 'The identifier of the actual command handler.',
      ),
      field(
        'arguments',
        type: 'LSPAny',
        array: true,
        canBeUndefined: true,
        comment: 'Arguments that the command should be invoked with.',
      ),
    ],
    comment:
        'InteractiveExecuteCommandParams extends the standard LSP '
        'ExecuteCommandParams with the experimental fields for interactive '
        'forms.',
  ),

  interface('FormField', [
    field(
      'id',
      type: 'String',
      comment:
          'A unique identifier for this field. This key is used as the '
          "property name in FormAnswers to map the user's input back to this "
          'specific field.',
    ),
    field(
      'description',
      type: 'String',
      comment:
          'The text content of the question (the prompt) presented to the '
          'user.',
    ),
    field(
      'type',
      type: 'FormFieldType',
      comment: 'The data type and validation constraints for the answer.',
    ),
    field(
      'required',
      type: 'boolean',
      comment: 'Whether an answer is absolutely required for this field.',
    ),
    field(
      'default',
      type: 'LSPAny',
      canBeUndefined: true,
      comment:
          'An optional initial value for the answer. If [type] is '
          "'enum', this value must be present in the enum's "
          'values array.',
    ),
    field(
      'error',
      type: 'String',
      canBeUndefined: true,
      comment:
          'A validation message from the language server. If empty or '
          'null, the current answer is considered valid.',
    ),
  ], comment: 'A single question in a form and its validation state.'),
  interface('FormAnswer', [
    field(
      'id',
      type: 'String',
      comment: 'The ID of the FormField being answered.',
    ),
    field('value', type: 'LSPAny', comment: "The user's answer value."),
  ], comment: 'A single answer to a FormField, identified by its unique ID.'),

  // Field kinds
  interface('FormFieldType', sealed: true, [field('kind', type: 'String')]),
  interface('FormFieldTypeString', baseType: 'FormFieldType', [
    field('kind', type: 'string', literal: true),
  ], comment: 'A text input.'),
  interface(
    'FormFieldTypeFile',
    baseType: 'FormFieldType',
    [
      field('kind', type: 'file', literal: true),
      field(
        'existence',
        type: 'FileExistence',
        canBeUndefined: true,
        comment: 'Existence constraint.',
      ),
      field(
        'type',
        type: 'FileType',
        canBeUndefined: true,
        comment:
            'Type specifies the set of allowed file types (regular file, '
            'directory, etc).\n\n'
            'Only applicable against existing file.',
      ),
      field(
        'filters',
        type: 'string',
        array: true,
        canBeUndefined: true,
        comment:
            'Filters specifies the allowed file extensions without the leading '
            'dot. A file is valid if it matches any of the extensions '
            '(OR logic). e.g. ["png", "jpg"].\n\n'
            'If omitted or empty, no extension filter is applied.',
      ),
    ],
    comment:
        'FormFieldTypeFile defines an input for a file or directory URI.\n\n'
        'The client determines the best mechanism to collect this information '
        'from the user (e.g., a graphical file picker, a text input with '
        'autocomplete, etc).\n\n'
        'The value returned by the client must be a valid "DocumentUri" as '
        'defined in the LSP specification: '
        'https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#documentUri',
  ),
  LspEnum(
    name: 'FileExistence',
    typeOfValues: TypeReference.int,
    flags: true,
    constants: [
      // Values should be powers of 2 to allow New|Existing.
      Constant(
        name: 'New',
        type: TypeReference.int,
        value: '1',
        comment: 'The file has not yet been created.',
      ),
      Constant(
        name: 'Existing',
        type: TypeReference.int,
        value: '2',
        comment: 'The file exists already.',
      ),
    ],
    comment:
        'FileExistence whether the file denoted by a DocumentURI exists.\n\n'
        'It is a bit set allowing combinations of existence states. For '
        'example, New|Existing allows either state.',
  ),
  LspEnum(
    name: 'FileType',
    typeOfValues: TypeReference.int,
    flags: true,
    constants: [
      // Values should be powers of 2 to allow Regular|Directory.
      Constant(
        name: 'Regular',
        type: TypeReference.int,
        value: '1',
        comment: 'The resource could be a regular file.',
      ),
      Constant(
        name: 'Directory',
        type: TypeReference.int,
        value: '2',
        comment: 'The resource could be a directory.',
      ),
    ],
    comment:
        'FileType represents the expected filesystem resource type.\n\n'
        'It is a bit set allowing combinations of file types. For example, '
        'Regular|Directory allows either types.',
  ),
  interface('FormFieldTypeBool', baseType: 'FormFieldType', [
    field('kind', type: 'bool', literal: true),
  ], comment: 'A boolean input.'),
  interface('FormFieldTypeNumber', baseType: 'FormFieldType', [
    field('kind', type: 'number', literal: true),
  ], comment: 'A numeric input.'),
  // TODO(dantup): Add these back when we have support for them.
  //  If we add them now, we'd need to implement validation (due to exhaustive
  //  checking on the switch()).
  // interface(
  //   'FormFieldTypeEnum',
  //   baseType: 'FormFieldType',
  //   [
  //     field('kind', type: 'enum', literal: true),
  //     field(
  //       'name',
  //       type: 'string',
  //       canBeUndefined: true,
  //       comment: 'An optional identifier for the enum type.',
  //     ),
  //     field(
  //       'entries',
  //       array: true,
  //       type: 'FormEnumEntry',
  //       comment: 'The list of allowable options.',
  //     ),
  //   ],
  //   comment:
  //       'FormFieldTypeEnum defines a selection from a set of values.\n\n'
  //       'Use this type when:\n'
  //       '- The number of options is small (e.g., < 20).\n'
  //       '- All options are known at the time the form is created.\n',
  // ),
  // interface('FormEnumEntry', [
  //   field(
  //     'value',
  //     type: 'string',
  //     comment:
  //         'The unique string identifier for this option.\n\n'
  //         'This is the value that will be sent back to the server in '
  //         '`FormAnswers` if the user selects this option.',
  //   ),
  //   field(
  //     'description',
  //     type: 'string',
  //     comment: 'The human-readable label presented to the user.',
  //   ),
  // ], comment: 'A single option in an enumeration.'),
  // interface('FormFieldTypeList', baseType: 'FormFieldType', [
  //   field('kind', type: 'list', literal: true),
  //   field(
  //     'elementType',
  //     type: 'FormFieldType',
  //     comment:
  //         'ElementType specifies the type of the items in the list. '
  //         'Recursive reference to the union type.',
  //   ),
  // ], comment: 'A homogenous list of items.'),
];
