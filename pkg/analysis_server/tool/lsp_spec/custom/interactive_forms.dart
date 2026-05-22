// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support for the new (Go-specified) interactive-refactors.
final interactiveFormClasses = <LspEntity>[
  // TODO(dantup): Try to generate this from the form.ts file once it has a
  //  stable location.
  //  https://github.com/golang/vscode-go/blob/fecc31339bc33de4b1db2a2242ba46ea552d0f39/extension/src/language/form.ts
  interface('InteractiveParams', [
    field(
      'formFields',
      array: true,
      type: 'FormField',
      canBeUndefined: true,
      comment:
          'FormFields defines the questions and validation errors in previous '
          'answers to the same questions.\n\n'
          'This is a server-to-client field. The language server defines '
          'these, and the client uses them to render the form.\n\n'
          'The interactive phase is considered complete when the server '
          'returns a response where this slice is omitted.',
    ),
    field(
      'formAnswers',
      array: true,
      type: 'LSPAny',
      canBeUndefined: true,
      comment:
          'FormAnswers contains the values for the form questions.\n\n'
          'When sent by the language server, this field is optional but '
          'recommended to support editing previous values.\n\n'
          'When sent by the language client as part of the ResolveXXX request, '
          'this field is required. The slice must have the same length as '
          'FormFields (one answer per question), where the answer at index i '
          'corresponds to the field at index i.',
    ),
    field(
      'data',
      type: 'LSPAny',
      canBeUndefined: true,
      comment: 'Context preserved for the server.',
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
        comment: 'Existence constraint.',
      ),
      field(
        'type',
        type: 'FileType',
        comment:
            'Type specifies the set of allowed file types (regular file, '
            'directory, etc).\n\n'
            'Only applicable against existing file.',
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
    members: [
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
    members: [
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
  interface(
    'FormFieldTypeEnum',
    baseType: 'FormFieldType',
    [
      field('kind', type: 'enum', literal: true),
      field(
        'name',
        type: 'string',
        canBeUndefined: true,
        comment: 'An optional identifier for the enum type.',
      ),
      field(
        'entries',
        array: true,
        type: 'FormEnumEntry',
        comment: 'The list of allowable options.',
      ),
    ],
    comment:
        'FormFieldTypeEnum defines a selection from a set of values.\n\n'
        'Use this type when:\n'
        '- The number of options is small (e.g., < 20).\n'
        '- All options are known at the time the form is created.\n',
  ),
  interface('FormEnumEntry', [
    field(
      'value',
      type: 'string',
      comment:
          'The unique string identifier for this option.\n\n'
          'This is the value that will be sent back to the server in '
          '`FormAnswers` if the user selects this option.',
    ),
    field(
      'description',
      type: 'string',
      comment: 'The human-readable label presented to the user.',
    ),
  ], comment: 'A single option in an enumeration.'),
  interface('FormFieldTypeList', baseType: 'FormFieldType', [
    field('kind', type: 'list', literal: true),
    field(
      'elementType',
      type: 'FormFieldType',
      comment:
          'ElementType specifies the type of the items in the list. '
          'Recursive reference to the union type.',
    ),
  ], comment: 'A homogenous list of items.'),
];
