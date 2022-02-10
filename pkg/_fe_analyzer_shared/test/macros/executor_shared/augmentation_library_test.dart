// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/augmentation_library.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/response_impls.dart';

import '../util.dart';

void main() {
  group('AugmentationLibraryBuilder', () {
    test('can combine multiple execution results', () {
      var results = [
        for (var i = 0; i < 2; i++)
          MacroExecutionResultImpl(augmentations: [
            for (var j = 0; j < 3; j++)
              DeclarationCode.fromParts([
                'augment class Foo$i$j {\n',
                DeclarationCode.fromParts([
                  'int get i => $i;\n',
                  'int get j => $j;\n',
                ]),
                '}',
              ]),
          ], newTypeNames: [
            'Foo${i}0',
            'Foo${i}1',
            'Foo${i}2',
          ]),
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          results, (Identifier i) => (i as TestIdentifier).resolved);
      expect(library, equalsIgnoringWhitespace('''
        augment class Foo00 {
          int get i => 0;
          int get j => 0;
        }
        augment class Foo01 {
          int get i => 0;
          int get j => 1;
        }
        augment class Foo02 {
          int get i => 0;
          int get j => 2;
        }
        augment class Foo10 {
          int get i => 1;
          int get j => 0;
        }
        augment class Foo11 {
          int get i => 1;
          int get j => 1;
        }
        augment class Foo12 {
          int get i => 1;
          int get j => 2;
        }
      '''));
    });

    test('can add imports for identifiers', () {
      var fooIdentifier = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'Foo',
          kind: IdentifierKind.topLevelMember,
          staticScope: null,
          uri: Uri.parse('package:foo/foo.dart'));
      var barIdentifier = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'Bar',
          kind: IdentifierKind.topLevelMember,
          staticScope: null,
          uri: Uri.parse('package:bar/bar.dart'));
      var builderIdentifier = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'Builder',
          kind: IdentifierKind.topLevelMember,
          staticScope: null,
          uri: Uri.parse('package:builder/builder.dart'));
      var barInstanceMember = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'baz',
          kind: IdentifierKind.instanceMember,
          staticScope: null,
          uri: Uri.parse('package:bar/bar.dart'));
      var barStaticMember = TestIdentifier(
          id: RemoteInstance.uniqueId,
          name: 'zap',
          kind: IdentifierKind.staticInstanceMember,
          staticScope: 'Bar',
          uri: Uri.parse('package:bar/bar.dart'));
      var results = [
        MacroExecutionResultImpl(augmentations: [
          DeclarationCode.fromParts([
            'class FooBuilder<T extends ',
            fooIdentifier,
            '> implements ',
            builderIdentifier,
            '<',
            barIdentifier,
            '<T>> {\n',
            'late int ${barInstanceMember.name};\n',
            barIdentifier,
            '<T> build() => new ',
            barIdentifier,
            '()..',
            barInstanceMember,
            ' = ',
            barStaticMember,
            ';',
            '\n}',
          ]),
        ], newTypeNames: [
          'FooBuilder',
        ])
      ];
      var library = _TestExecutor().buildAugmentationLibrary(
          results, (Identifier i) => (i as TestIdentifier).resolved);
      expect(library, equalsIgnoringWhitespace('''
        import 'package:foo/foo.dart' as i0;
        import 'package:builder/builder.dart' as i1;
        import 'package:bar/bar.dart' as i2;

        class FooBuilder<T extends i0.Foo> implements i1.Builder<i2.Bar<T>> {
          late int baz;

          i2.Bar<T> build() => new i2.Bar()..baz = i2.Bar.zap;
        }
      '''));
    });
  });
}

class _TestExecutor extends MacroExecutor
    with AugmentationLibraryBuilder, Fake {}
