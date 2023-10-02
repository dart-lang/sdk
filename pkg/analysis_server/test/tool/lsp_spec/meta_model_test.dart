// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/lsp_spec/codegen_dart.dart';
import '../../../tool/lsp_spec/generate_all.dart';
import '../../../tool/lsp_spec/meta_model.dart';
import 'matchers.dart';

void main() {
  group('meta model reader', () {
    setUpAll(() {
      // Ensure any custom types like LSPAny are registered so that they can
      // be resolved.
      recordTypes(getCustomClasses());
    });
    test('reads an interface', () {
      final input = {
        'structures': [
          {
            'name': 'SomeOptions',
            'properties': [
              {
                'name': 'options',
                'type': {
                  'kind': 'array',
                  'element': {'kind': 'reference', 'name': 'string'}
                },
                'optional': true,
                'documentation': 'Options used by something.',
              }
            ],
            'documentation': 'Some options.'
          },
        ],
      };
      final output = readModel(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final interface = output[0] as Interface;
      expect(interface.name, equals('SomeOptions'));
      expect(interface.comment, equals('Some options.'));
      expect(interface.baseTypes, hasLength(0));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      final field = interface.members[0] as Field;
      expect(field.name, equals('options'));
      expect(field.comment, equals('''Options used by something.'''));
      expect(field.allowsNull, isFalse);
      expect(field.allowsUndefined, isTrue);
      expect(field.type, isArrayOf(isSimpleType('string')));
    });

    test('reads an interface with a field with an inline/unnamed type', () {
      final input = {
        'structures': [
          {
            'name': 'Capabilities',
            'properties': [
              {
                'name': 'textDoc',
                'type': {
                  'kind': 'literal',
                  'value': {
                    'properties': [
                      {
                        'name': 'deprecated',
                        'type': {'kind': 'base', 'name': 'bool'},
                        'optional': true,
                      }
                    ]
                  }
                },
                'optional': true,
              }
            ],
            'documentation': 'Some options.'
          },
        ],
      };
      final output = readModel(input);
      // Length is two because we'll fabricate the type of textDoc.
      expect(output, hasLength(2));

      // Check there was a full fabricated interface for this type.
      expect(output[0], const TypeMatcher<Interface>());
      var interface = output[0] as Interface;
      expect(interface.name, equals('CapabilitiesTextDoc'));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      var field = interface.members[0] as Field;
      expect(field.name, equals('deprecated'));
      expect(field.allowsNull, isFalse);
      expect(field.allowsUndefined, isTrue);
      expect(field.type, isSimpleType('bool'));
      expect(field.allowsUndefined, isTrue);

      expect(output[1], const TypeMatcher<Interface>());
      interface = output[1] as Interface;
      expect(interface.name, equals('Capabilities'));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      field = interface.members[0] as Field;
      expect(field.name, equals('textDoc'));
      expect(field.allowsNull, isFalse);
      expect(field.type, isSimpleType('CapabilitiesTextDoc'));
    });

    test('reads an interface with multiple fields', () {
      final input = {
        'structures': [
          {
            'name': 'SomeOptions',
            'properties': [
              {
                'name': 'options0',
                'type': {'kind': 'reference', 'name': 'LSPAny'},
                'documentation': 'Options0 used by something.',
              },
              {
                'name': 'options1',
                'type': {'kind': 'reference', 'name': 'LSPAny'},
                'documentation': 'Options1 used by something.',
              }
            ],
          },
        ],
      };
      final output = readModel(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final interface = output[0] as Interface;
      expect(interface.members, hasLength(2));
      for (var i in [0, 1]) {
        expect(interface.members[i], const TypeMatcher<Field>());
        final field = interface.members[i] as Field;
        expect(field.name, equals('options$i'));
        expect(field.comment, equals('''Options$i used by something.'''));
      }
    });

    test('reads an interface with a map into a MapType', () {
      final input = {
        'structures': [
          {
            'name': 'WorkspaceEdit',
            'properties': [
              {
                'name': 'changes',
                'type': {
                  'kind': 'map',
                  'key': {'kind': 'base', 'name': 'string'},
                  'value': {
                    'kind': 'array',
                    'element': {'kind': 'reference', 'name': 'TextEdit'}
                  },
                },
              }
            ],
          },
        ],
      };
      final output = readModel(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final interface = output[0] as Interface;
      expect(interface.members, hasLength(1));
      final field = interface.members.first as Field;
      expect(field, const TypeMatcher<Field>());
      expect(field.name, equals('changes'));
      expect(field.type,
          isMapOf(isSimpleType('string'), isArrayOf(isSimpleType('TextEdit'))));
    });

    test('flags nullable undefined values', () {
      final input = {
        'structures': [
          {
            'name': 'A',
            'properties': [
              {
                'name': 'canBeBoth',
                'type': {
                  'kind': 'or',
                  'items': [
                    {'kind': 'base', 'name': 'string'},
                    {'kind': 'base', 'name': 'null'}
                  ]
                },
                'optional': true,
              },
              {
                'name': 'canBeNeither',
                'type': {'kind': 'base', 'name': 'string'},
              },
              {
                'name': 'canBeNull',
                'type': {
                  'kind': 'or',
                  'items': [
                    {'kind': 'base', 'name': 'string'},
                    {'kind': 'base', 'name': 'null'}
                  ]
                },
              },
              {
                'name': 'canBeUndefined',
                'type': {'kind': 'base', 'name': 'string'},
                'optional': true,
              },
            ],
          },
        ],
      };
      final output = readModel(input);
      final interface = output[0] as Interface;
      expect(interface.members, hasLength(4));
      for (var m in interface.members) {
        expect(m, const TypeMatcher<Field>());
      }
      final canBeBoth = interface.members[0] as Field,
          canBeNeither = interface.members[1] as Field,
          canBeNull = interface.members[2] as Field,
          canBeUndefined = interface.members[3] as Field;
      expect(canBeNeither.allowsNull, isFalse);
      expect(canBeNeither.allowsUndefined, isFalse);
      expect(canBeNull.allowsNull, isTrue);
      expect(canBeNull.allowsUndefined, isFalse);
      expect(canBeUndefined.allowsNull, isFalse);
      expect(canBeUndefined.allowsUndefined, isTrue);
      expect(canBeBoth.allowsNull, isTrue);
      expect(canBeBoth.allowsUndefined, isTrue);
    });

    test('formats comments correctly', () {
      final input = {
        'structures': [
          {
            'name': 'A',
            'properties': [],
            'documentation': r"""
Describes the what this class in lots of words that wrap onto multiple lines that will need re-wrapping to format nicely when converted into Dart.

Blank lines should remain in-tact, as should:
  - Indented
  - Things

Some docs have:
- List items that are not indented

Sometimes after a blank line we'll have a note.

*Note* that something.""",
          },
        ],
      };
      final output = readModel(input);
      final interface = output[0] as Interface;
      expect(interface.comment, equals('''
Describes the what this class in lots of words that wrap onto multiple lines that will need re-wrapping to format nicely when converted into Dart.

Blank lines should remain in-tact, as should:
  - Indented
  - Things

Some docs have:
- List items that are not indented

Sometimes after a blank line we'll have a note.

*Note* that something.'''));
    });

    test('reads a type alias', () {
      final input = {
        'typeAliases': [
          {
            'name': 'DocumentSelector',
            'type': {
              'kind': 'array',
              'element': {'kind': 'reference', 'name': 'DocumentFilter'}
            },
          },
        ],
      };
      final output = readModel(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<TypeAlias>());
      final typeAlias = output[0] as TypeAlias;
      expect(typeAlias.name, equals('DocumentSelector'));
      expect(typeAlias.baseType, isArrayOf(isSimpleType('DocumentFilter')));
    });

    test('reads a type alias that is a union of unnamed types', () {
      final input = {
        'typeAliases': [
          {
            'name': 'NameOrLength',
            'type': {
              'kind': 'or',
              'items': [
                {
                  'kind': 'literal',
                  'value': {
                    'properties': [
                      {
                        'name': 'name',
                        'type': {'kind': 'base', 'name': 'string'}
                      },
                    ]
                  },
                },
                {
                  'kind': 'literal',
                  'value': {
                    'properties': [
                      {
                        'name': 'length',
                        'type': {'kind': 'base', 'name': 'number'}
                      },
                    ]
                  },
                },
              ]
            },
          },
        ],
      };
      final output = readModel(input);
      expect(output, hasLength(3));

      // Results should be the two inline interfaces followed by the type alias.

      expect(output[0], const TypeMatcher<Interface>());
      final interface1 = output[0] as Interface;
      expect(interface1.name, equals('NameOrLength1'));
      expect(interface1.members, hasLength(1));
      expect(interface1.members[0].name, equals('name'));

      expect(output[1], const TypeMatcher<Interface>());
      final interface2 = output[1] as Interface;
      expect(interface2.name, equals('NameOrLength2'));
      expect(interface2.members, hasLength(1));
      expect(interface2.members[0].name, equals('length'));

      expect(output[2], const TypeMatcher<TypeAlias>());
      final typeAlias = output[2] as TypeAlias;
      expect(typeAlias.name, equals('NameOrLength'));
      expect(typeAlias.baseType, const TypeMatcher<UnionType>());

      // The type alias should be a union of the two types above.
      final union = typeAlias.baseType as UnionType;
      expect(union.types, hasLength(2));
      expect(union.types[0], isSimpleType(interface1.name));
      expect(union.types[1], isSimpleType(interface2.name));
    });

    test('reads a namespace of constants', () {
      final input = {
        'enumerations': [
          {
            'name': 'ResourceOperationKind',
            'type': {'kind': 'base', 'name': 'string'},
            'values': [
              {
                'name': 'Create',
                'value': 'create',
                'documentation': 'Supports creating new files and folders.',
              },
              {
                'name': 'Delete',
                'value': 'delete',
                'documentation':
                    'Supports deleting existing files and folders.',
              },
              {
                'name': 'Rename',
                'value': 'rename',
                'documentation':
                    'Supports renaming existing files and folders.',
              },
            ],
          },
        ]
      };
      final output = readModel(input);
      expect(output, hasLength(1));

      expect(output[0], const TypeMatcher<LspEnum>());
      final namespace = output[0] as LspEnum;
      expect(namespace.members, hasLength(3));
      for (var m in namespace.members) {
        expect(m, const TypeMatcher<Constant>());
      }
      final create = namespace.members[0] as Constant,
          delete = namespace.members[1] as Constant,
          rename = namespace.members[2] as Constant;
      expect(create.name, equals('Create'));
      expect(create.type, isSimpleType('ResourceOperationKind'));
      expect(
          create.comment, equals('Supports creating new files and folders.'));
      expect(rename.name, equals('Rename'));
      expect(rename.type, isSimpleType('ResourceOperationKind'));
      expect(rename.comment,
          equals('Supports renaming existing files and folders.'));
      expect(delete.name, equals('Delete'));
      expect(delete.type, isSimpleType('ResourceOperationKind'));
      expect(delete.comment,
          equals('Supports deleting existing files and folders.'));
    });

    test('reads a tuple in an array', () {
      final input = {
        'structures': [
          {
            'name': 'SomeInformation',
            'properties': [
              {
                'name': 'label',
                'type': {
                  'kind': 'or',
                  'items': [
                    {'kind': 'base', 'name': 'string'},
                    {
                      'kind': 'tuple',
                      'items': [
                        {'kind': 'base', 'name': 'number'},
                        {'kind': 'base', 'name': 'number'}
                      ]
                    }
                  ]
                },
              },
            ],
          },
        ],
      };
      final output = readModel(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final interface = output[0] as Interface;
      expect(interface.members, hasLength(1));
      final field = interface.members.first as Field;
      expect(field, const TypeMatcher<Field>());
      expect(field.name, equals('label'));
      expect(field.type, const TypeMatcher<UnionType>());
      final union = field.type as UnionType;
      expect(union.types, hasLength(2));
      expect(union.types[0], isArrayOf(isSimpleType('number')));
      expect(union.types[1], isSimpleType('string'));
    });

    test('reads an union including LSPAny into a single type', () {
      final input = {
        'structures': [
          {
            'name': 'SomeInformation',
            'properties': [
              {
                'name': 'label',
                'type': {
                  'kind': 'or',
                  'items': [
                    {'kind': 'base', 'name': 'string'},
                    {'kind': 'base', 'name': 'LSPAny'},
                  ]
                },
              },
            ],
          },
        ],
      };
      final output = readModel(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final interface = output[0] as Interface;
      expect(interface.members, hasLength(1));
      final field = interface.members.first as Field;
      expect(field, const TypeMatcher<Field>());
      expect(field.name, equals('label'));
      expect(field.type, isSimpleType('LSPAny'));
    });

    test('reads literal string values', () {
      final input = {
        'structures': [
          {
            'name': 'MyType',
            'properties': [
              {
                'name': 'kind',
                'type': {'kind': 'stringLiteral', 'value': 'one'},
              },
            ],
          },
        ],
      };
      final output = readModel(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final interface = output[0] as Interface;
      expect(interface.name, equals('MyType'));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      final field = interface.members[0] as Field;
      expect(field.name, equals('kind'));
      expect(field.allowsNull, isFalse);
      expect(field.allowsUndefined, isFalse);
      expect(field.type, isLiteralOf(isSimpleType('string'), "'one'"));
    });

    test('reads literal union values', () {
      final input = {
        'structures': [
          {
            'name': 'MyType',
            'properties': [
              {
                'name': 'kind',
                'type': {
                  'kind': 'or',
                  'items': [
                    {'kind': 'stringLiteral', 'value': 'one'},
                    {'kind': 'stringLiteral', 'value': 'two'},
                  ]
                },
              },
            ],
          },
        ],
      };
      final output = readModel(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final interface = output[0] as Interface;
      expect(interface.name, equals('MyType'));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      final field = interface.members[0] as Field;
      expect(field.name, equals('kind'));
      expect(field.allowsNull, isFalse);
      expect(field.allowsUndefined, isFalse);
      expect(field.type, const TypeMatcher<LiteralUnionType>());
      final union = field.type as LiteralUnionType;
      expect(union.types, hasLength(2));
      expect(union.types[0], isLiteralOf(isSimpleType('string'), "'one'"));
      expect(union.types[1], isLiteralOf(isSimpleType('string'), "'two'"));
    });
  });
}

List<LspEntity> readModel(Map<String, dynamic> model) =>
    LspMetaModelCleaner().cleanTypes(LspMetaModelReader().readMap(model).types);
