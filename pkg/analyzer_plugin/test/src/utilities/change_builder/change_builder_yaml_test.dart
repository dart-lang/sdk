// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_yaml.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'change_builder_core_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeBuilderImplTest);
    defineReflectiveTests(YamlEditBuilderImplTest);
    defineReflectiveTests(YamlFileEditBuilderImplTest);
    defineReflectiveTests(YamlLinkedEditBuilderImplTest);
  });
}

class AbstractYamlChangeBuilderTest extends AbstractChangeBuilderTest {
  String get testFilePath {
    return resourceProvider.convertPath('/home/my/pubspec.yaml');
  }

  void createPubspec(String content) {
    resourceProvider.newFile(testFilePath, content);
  }
}

@reflectiveTest
class ChangeBuilderImplTest extends AbstractYamlChangeBuilderTest {
  Future<void> test_addYamlFileEdit() async {
    createPubspec('''
name: my
''');
    await builder.addYamlFileEdit(testFilePath, (builder) {
      expect(builder, isA<YamlFileEditBuilderImpl>());
    });
  }
}

@reflectiveTest
class YamlEditBuilderImplTest extends AbstractYamlChangeBuilderTest {
  Future<void> test_addLinkedEdit() async {
    createPubspec('''
name: my
''');
    await builder.addYamlFileEdit(testFilePath, (builder) {
      builder.addReplacement(range.startOffsetEndOffset(6, 8), (builder) {
        expect(builder, isA<YamlEditBuilderImpl>());
        builder.addLinkedEdit('group', (builder) {
          expect(builder, isA<YamlLinkedEditBuilderImpl>());
          builder.write('test');
        });
      });
    });
    var sourceChange = builder.sourceChange;
    expect(sourceChange, isNotNull);
    var groups = sourceChange.linkedEditGroups;
    expect(groups, hasLength(1));
    var group = groups[0];
    expect(group, isNotNull);
    expect(group.length, 4);
    var positions = group.positions;
    expect(positions, hasLength(1));
    expect(positions[0].offset, 6);
  }
}

@reflectiveTest
class YamlFileEditBuilderImplTest extends AbstractYamlChangeBuilderTest {
  Future<void> test_addDeletion() async {
    createPubspec('''
name: my test
''');
    await builder.addGenericFileEdit(testFilePath, (builder) {
      builder.addDeletion(SourceRange(6, 3));
    });
    var edits = builder.sourceChange.edits[0].edits;
    expect(edits, hasLength(1));
    expect(edits[0].offset, 6);
    expect(edits[0].length, 3);
    expect(edits[0].replacement, isEmpty);
  }
}

@reflectiveTest
class YamlLinkedEditBuilderImplTest extends AbstractYamlChangeBuilderTest {
  Future<void> test_addSuggestion() async {
    createPubspec('''
name: my
''');
    var groupName = 'group';
    await builder.addYamlFileEdit(testFilePath, (builder) {
      builder.addReplacement(range.startOffsetEndOffset(6, 8), (builder) {
        builder.addLinkedEdit(groupName, (builder) {
          builder.write('test');
          builder.addSuggestion(
              LinkedEditSuggestionKind.VARIABLE, 'suggestion');
        });
      });
    });
    var group = builder.getLinkedEditGroup(groupName);
    expect(group.suggestions, hasLength(1));
  }
}
