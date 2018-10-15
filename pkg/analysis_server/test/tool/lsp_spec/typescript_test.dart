// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/lsp_spec/typescript.dart';

main() {
  group('typescript parser', () {
    test('parses an interface', () {
      final String input = '''
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
      final List<ApiItem> output = extractTypes(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.name, equals('SomeOptions'));
      expect(interface.comment, equals('Some options.'));
      expect(interface.baseTypes, hasLength(0));
      expect(interface.members, hasLength(1));
      expect(interface.members[0], const TypeMatcher<Field>());
      final Field field = interface.members[0];
      expect(field.name, equals('options'));
      expect(field.comment, equals('''Options used by something.'''));
      expect(field.allowsNull, isFalse);
      expect(field.allowsUndefined, isTrue);
      expect(field.types, hasLength(1));
      expect(field.types[0], equals('OptionKind[]'));
    });

    test('parses an interface with multiple fields', () {
      final String input = '''
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
      final List<ApiItem> output = extractTypes(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Interface>());
      final Interface interface = output[0];
      expect(interface.members, hasLength(2));
      [0, 1].forEach((i) {
        expect(interface.members[i], const TypeMatcher<Field>());
        final Field field = interface.members[i];
        expect(field.name, equals('options$i'));
        expect(field.comment, equals('''Options$i used by something.'''));
      });
    });

    test('flags nullable undefined values', () {
      final String input = '''
export interface A {
  canBeBoth?: string | null;
  canBeNeither: string;
	canBeNull: string | null;
  canBeUndefined?: string;
}
    ''';
      final List<ApiItem> output = extractTypes(input);
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
      final String input = '''
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
      final List<ApiItem> output = extractTypes(input);
      final Interface interface = output[0];
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

    test('parses a type alias', () {
      final String input = '''
export type DocumentSelector = DocumentFilter[];
    ''';
      final List<ApiItem> output = extractTypes(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<TypeAlias>());
      final TypeAlias typeAlias = output[0];
      expect(typeAlias.name, equals('DocumentSelector'));
      expect(typeAlias.baseType, equals('DocumentFilter[]'));
    });

    test('parses a namespace of constants', () {
      final String input = '''
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
      final List<ApiItem> output = extractTypes(input);
      expect(output, hasLength(1));
      expect(output[0], const TypeMatcher<Namespace>());
      final Namespace namespace = output[0];
      expect(namespace.members, hasLength(3));
      namespace.members.forEach((m) => expect(m, const TypeMatcher<Const>()));
      final Const create = namespace.members[0],
          delete = namespace.members[1],
          rename = namespace.members[2];
      expect(create.name, equals('Create'));
      expect(create.type, equals('ResourceOperationKind'));
      expect(
          create.comment, equals('Supports creating new files and folders.'));
      expect(rename.name, equals('Rename'));
      expect(rename.type, equals('ResourceOperationKind'));
      expect(rename.comment,
          equals('Supports renaming existing files and folders.'));
      expect(delete.name, equals('Delete'));
      expect(delete.type, equals('ResourceOperationKind'));
      expect(delete.comment,
          equals('Supports deleting existing files and folders.'));
    });

    test('sorts types and members', () {
      final String input = '''
export interface b {
	b: string;
  a: string;
}
export interface a {
	b: string;
  a: string;
}
    ''';
      final List<ApiItem> output = extractTypes(input);
      expect(output, hasLength(2));
      output.forEach((m) => expect(m, const TypeMatcher<Interface>()));
      output.cast<Interface>().forEach((interface) {
        interface.members.forEach((m) => expect(m, const TypeMatcher<Field>()));
        final fields = interface.members.cast<Field>();
        expect(fields[0].name, equals('a'));
        expect(fields[1].name, equals('b'));
      });
    });
  });
}
