// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/lsp_spec/typescript_parser.dart';
import 'matchers.dart';

void main() {
  group('typescript parser', () {
    test('parses an interface', () {
      final input = '''
/**
 * Some options.
 */
export interface SomeOptions {
	/**
	 * Options used by something.
	 */
	options?: OptionKind[];
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.name, equals('SomeOptions'));
      expect(interface.commentText, equals('Some options.'));
      expect(interface.baseTypes, hasLength(0));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      final Field field = interface.members[0];
      expect(field.name, equals('options'));
      expect(field.commentText, equals('''Options used by something.'''));
      expect(field.allowsNull, isFalse);
      expect(field.allowsUndefined, isTrue);
      expect(field.type, isArrayOf(isSimpleType('OptionKind')));
    });

    test('parses an interface with a field with an inline/unnamed type', () {
      final input = '''
export interface Capabilities {
	textDoc?: {
    deprecated?: bool;
  };
}
    ''';
      final output = parseString(input);
      // Length is two because we'll fabricate the type of textDoc.
      expect(output, hasLength(2));

      // Check there was a full fabricarted interface for this type.
      expect(output[0], const TypeMatcher<Interface>());
      Interface interface = output[0];
      expect(interface.name, equals('CapabilitiesTextDoc'));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      Field field = interface.members[0];
      expect(field.name, equals('deprecated'));
      expect(field.allowsNull, isFalse);
      expect(field.allowsUndefined, isTrue);
      expect(field.type, isSimpleType('bool'));
      expect(field.allowsUndefined, isTrue);

      expect(output[1], const TypeMatcher<Interface>());
      interface = output[1];
      expect(interface.name, equals('Capabilities'));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      field = interface.members[0];
      expect(field.name, equals('textDoc'));
      expect(field.allowsNull, isFalse);
      expect(field.type, isSimpleType('CapabilitiesTextDoc'));
    });

    test('parses an interface with multiple fields', () {
      final input = '''
export interface SomeOptions {
	/**
	 * Options0 used by something.
	 */
	options0: any;
	/**
	 * Options1 used by something.
	 */
	options1: any;
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.members, hasLength(2));
      [0, 1].forEach((i) {
        expect(interface.members[i], const TypeMatcher<Field>());
        final Field field = interface.members[i];
        expect(field.name, equals('options$i'));
        expect(field.commentText, equals('''Options$i used by something.'''));
      });
    });

    test('parses an interface with type args', () {
      final input = '''
interface MyInterface<D> {
	data?: D;
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.members, hasLength(1));
      final Field field = interface.members.first;
      expect(field, const TypeMatcher<Field>());
      expect(field.name, equals('data'));
      expect(field.allowsUndefined, isTrue);
      expect(field.allowsNull, isFalse);
      expect(field.type, isSimpleType('D'));
    });

    test('parses an interface with Arrays in Array<T> format', () {
      final input = '''
export interface MyMessage {
	/**
	 * The method's params.
	 */
	params?: Array<any> | string;
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.members, hasLength(1));
      final Field field = interface.members.first;
      expect(field, const TypeMatcher<Field>());
      expect(field.name, equals('params'));
      expect(field.commentText, equals('''The method's params.'''));
      expect(field.allowsUndefined, isTrue);
      expect(field.allowsNull, isFalse);
      expect(field.type, const TypeMatcher<UnionType>());
      UnionType union = field.type;
      expect(union.types, hasLength(2));
      expect(union.types[0], isArrayOf(isSimpleType('any')));
      expect(union.types[1], isSimpleType('string'));
    });

    test('parses an interface with a map into a MapType', () {
      final input = '''
export interface WorkspaceEdit {
	changes: { [uri: string]: TextEdit[]; };
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.members, hasLength(1));
      final Field field = interface.members.first;
      expect(field, const TypeMatcher<Field>());
      expect(field.name, equals('changes'));
      expect(field.type,
          isMapOf(isSimpleType('string'), isArrayOf(isSimpleType('TextEdit'))));
    });

    test('flags nullable undefined values', () {
      final input = '''
export interface A {
  canBeBoth?: string | null;
  canBeNeither: string;
	canBeNull: string | null;
  canBeUndefined?: string;
}
    ''';
      final output = parseString(input);
      final Interface interface = output[0];
      expect(interface.members, hasLength(4));
      interface.members.forEach((m) => expect(m, const TypeMatcher<Field>()));
      final Field canBeBoth = interface.members[0],
          canBeNeither = interface.members[1],
          canBeNull = interface.members[2],
          canBeUndefined = interface.members[3];
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
      final input = '''
/**
 * Describes the what this class in lots of words that wrap onto
 * multiple lines that will need re-wrapping to format nicely when
 * converted into Dart.
 *
 * Blank lines should remain in-tact, as should:
 *   - Indented
 *   - Things
 *
 * Some docs have:
 * - List items that are not indented
 *
 * Sometimes after a blank line we'll have a note.
 *
 * *Note* that something.
 */
export interface A {
  a: a;
}
    ''';
      final output = parseString(input);
      final Interface interface = output[0];
      expect(interface.commentText, equals('''
Describes the what this class in lots of words that wrap onto multiple lines that will need re-wrapping to format nicely when converted into Dart.

Blank lines should remain in-tact, as should:
  - Indented
  - Things

Some docs have:
- List items that are not indented

Sometimes after a blank line we'll have a note.

*Note* that something.'''));
    });

    test('parses a type alias', () {
      final input = '''
export type DocumentSelector = DocumentFilter[];
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<TypeAlias>());
      final TypeAlias typeAlias = output[0];
      expect(typeAlias.name, equals('DocumentSelector'));
      expect(typeAlias.baseType, isArrayOf(isSimpleType('DocumentFilter')));
    });

    test('parses a type alias that is a union of unnamed types', () {
      final input = '''
export type NameOrLength = { name: string } | { length: number };
    ''';
      final output = parseString(input);
      expect(output, hasLength(3));

      // Results should be the two inline interfaces followed by the type alias.

      expect(output[0], const TypeMatcher<InlineInterface>());
      final InlineInterface interface1 = output[0];
      expect(interface1.name, equals('NameOrLength1'));
      expect(interface1.members, hasLength(1));
      expect(interface1.members[0].name, equals('name'));

      expect(output[1], const TypeMatcher<InlineInterface>());
      final InlineInterface interface2 = output[1];
      expect(interface2.name, equals('NameOrLength2'));
      expect(interface2.members, hasLength(1));
      expect(interface2.members[0].name, equals('length'));

      expect(output[2], const TypeMatcher<TypeAlias>());
      final TypeAlias typeAlias = output[2];
      expect(typeAlias.name, equals('NameOrLength'));
      expect(typeAlias.baseType, const TypeMatcher<UnionType>());

      // The type alias should be a union of the two types above.
      UnionType union = typeAlias.baseType;
      expect(union.types, hasLength(2));
      expect(union.types[0], isSimpleType(interface1.name));
      expect(union.types[1], isSimpleType(interface2.name));
    });

    test('parses a namespace of constants', () {
      final input = '''
export namespace ResourceOperationKind {
	/**
	 * Supports creating new files and folders.
	 */
	export const Create: ResourceOperationKind = 'create';

	/**
	 * Supports deleting existing files and folders.
	 */
	export const Delete: ResourceOperationKind = 'delete';

	/**
	 * Supports renaming existing files and folders.
	 */
	export const Rename: ResourceOperationKind = 'rename';
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Namespace>());
      final Namespace namespace = output[0];
      expect(namespace.members, hasLength(3));
      namespace.members.forEach((m) => expect(m, const TypeMatcher<Const>()));
      final Const create = namespace.members[0],
          delete = namespace.members[1],
          rename = namespace.members[2];
      expect(create.name, equals('Create'));
      expect(create.type, isSimpleType('ResourceOperationKind'));
      expect(create.commentText,
          equals('Supports creating new files and folders.'));
      expect(rename.name, equals('Rename'));
      expect(rename.type, isSimpleType('ResourceOperationKind'));
      expect(rename.commentText,
          equals('Supports renaming existing files and folders.'));
      expect(delete.name, equals('Delete'));
      expect(delete.type, isSimpleType('ResourceOperationKind'));
      expect(delete.commentText,
          equals('Supports deleting existing files and folders.'));
    });

    test('parses an enum using keywords as identifiers', () {
      final input = '''
enum Foo {
  namespace = 'namespace',
  class = 'class',
  enum = 'enum',
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output.first, const TypeMatcher<Namespace>());
      final enum_ = output.first as Namespace;
      expect(enum_.members, hasLength(3));
      expect(enum_.members[0].name, equals('namespace'));
      expect(enum_.members[1].name, equals('class'));
      expect(enum_.members[2].name, equals('enum'));
    });

    test('parses a tuple in an array', () {
      final input = '''
interface SomeInformation {
	label: string | [number, number];
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.members, hasLength(1));
      final Field field = interface.members.first;
      expect(field, const TypeMatcher<Field>());
      expect(field.name, equals('label'));
      expect(field.type, const TypeMatcher<UnionType>());
      UnionType union = field.type;
      expect(union.types, hasLength(2));
      expect(union.types[0], isSimpleType('string'));
      expect(union.types[1], isArrayOf(isSimpleType('number')));
    });

    test('parses an union including Object into a single type', () {
      final input = '''
interface SomeInformation {
	label: string | object;
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.members, hasLength(1));
      final Field field = interface.members.first;
      expect(field, const TypeMatcher<Field>());
      expect(field.name, equals('label'));
      expect(field.type, isSimpleType('object'));
    });

    test('parses multiple single-line comments into a single token', () {
      final input = '''
// This is line 1
// This is line 2
interface SomeInformation {
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0].commentNode.token.lexeme, equals('''// This is line 1
// This is line 2'''));
    });

    test('parses literal string values', () {
      final input = '''
export interface MyType {
	kind: 'one';
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.name, equals('MyType'));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      final Field field = interface.members[0];
      expect(field.name, equals('kind'));
      expect(field.allowsNull, isFalse);
      expect(field.allowsUndefined, isFalse);
      expect(field.type, isLiteralOf(isSimpleType('string'), "'one'"));
    });

    test('parses literal union values', () {
      final input = '''
export interface MyType {
	kind: 'one' | 'two';
}
    ''';
      final output = parseString(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.name, equals('MyType'));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      final Field field = interface.members[0];
      expect(field.name, equals('kind'));
      expect(field.allowsNull, isFalse);
      expect(field.allowsUndefined, isFalse);
      expect(field.type, const TypeMatcher<LiteralUnionType>());
      LiteralUnionType union = field.type;
      expect(union.types, hasLength(2));
      expect(union.types[0], isLiteralOf(isSimpleType('string'), "'one'"));
      expect(union.types[1], isLiteralOf(isSimpleType('string'), "'two'"));
    });
  });
}
