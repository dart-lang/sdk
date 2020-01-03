// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_generation.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:expect/expect.dart';

const List<String> markers = ['a', 'b', 'c'];
final Uri mainUri = Uri.parse('memory:main.dart');

main() {
  testString('/*test*/');
  testString('''
some code/*test*/some more code
''');
  testString('/*a.test*/');
  testString('''
some code/*a.test*/some more code
''');
  testString('/*a|b.test*/');
  testString('''
some code/*a|b.test*/some more code
''');
  testString('/*a|b|c.test*/', expectedResult: '/*test*/');
  testString('''
some code/*a|b|c.test*/some more code
''', expectedResult: '''
some code/*test*/some more code
''');
  testString('/*a.test1*//*b.test2*//*c.test3*/');
  testString('/*b.test2*//*a.test1*//*c.test3*/',
      expectedResult: '/*a.test1*//*b.test2*//*c.test3*/');
  testString('/*a.test1*//*c.test3*//*b.test2*/',
      expectedResult: '/*a.test1*//*b.test2*//*c.test3*/');

  testString('some code',
      actualData: {
        'a': {
          new NodeId(0, IdKind.node): 'test',
        },
        'b': {
          new NodeId(0, IdKind.node): 'test',
        },
        'c': {
          new NodeId(0, IdKind.node): 'test',
        },
      },
      expectedResult: '/*test*/some code');

  testString('some code',
      actualData: {
        'a': {
          new NodeId(4, IdKind.node): 'test',
        },
        'b': {
          new NodeId(4, IdKind.node): 'test',
        },
        'c': {
          new NodeId(4, IdKind.node): 'test',
        },
      },
      expectedResult: 'some/*test*/ code');

  testString('some code',
      actualData: {
        'a': {
          new NodeId(0, IdKind.node): 'test',
        },
        'b': {
          new NodeId(0, IdKind.node): 'test',
        },
      },
      expectedResult: '/*a|b.test*/some code');

  testString('some code',
      actualData: {
        'a': {
          new NodeId(0, IdKind.node): 'test',
        },
      },
      expectedResult: '/*a.test*/some code');

  testString('',
      actualData: {
        'a': {
          new NodeId(0, IdKind.node): 'test1',
        },
        'b': {
          new NodeId(0, IdKind.node): 'test2',
        },
        'c': {
          new NodeId(0, IdKind.node): 'test3',
        },
      },
      expectedResult: '/*a.test1*//*b.test2*//*c.test3*/');
  testString('some code/*test*/some more code',
      actualData: {
        'a': {
          new NodeId(9, IdKind.node): 'test1',
        },
      },
      expectedResult: 'some code/*a.test1*//*b|c.test*/some more code');

  testString('some codesome more code',
      actualData: {
        'a': {
          new NodeId(9, IdKind.node): '',
        },
        'b': {
          new NodeId(9, IdKind.node): '',
        },
        'c': {
          new NodeId(9, IdKind.node): '',
        },
      },
      expectedResult: 'some codesome more code');

  testString('some codesome more code',
      actualData: {
        'a': {
          new NodeId(9, IdKind.node): '',
        },
        'b': {
          new NodeId(9, IdKind.node): '',
        },
      },
      expectedResult: 'some codesome more code');

  testString('some codesome more code',
      actualData: {
        'a': {
          new NodeId(9, IdKind.node): '',
        },
      },
      expectedResult: 'some codesome more code');

  testString('''
some code
/*member: memberName:test*/
some more code
''');

  testString('''
some code
/*member: memberName:test*/
some more code
''', actualData: {
    'a': {
      new MemberId('memberName'): 'test1',
    }
  }, expectedResult: '''
some code
/*a.member: memberName:test1*/
/*b|c.member: memberName:test*/
some more code
''');

  testString('''some code
/*a.member: memberName:test1*/
/*b|c.member: memberName:test*/
some more code
''', actualData: {
    'b': {
      new MemberId('memberName'): 'test1',
    }
  }, expectedResult: '''
some code
/*a|b.member: memberName:test1*/
/*c.member: memberName:test*/
some more code
''');

  testString('''
some code
/*a|b.member: memberName:test1*/
/*c.member: memberName:test*/
some more code
''', actualData: {
    'c': {
      new MemberId('memberName'): 'test1',
    }
  }, expectedResult: '''
some code
/*member: memberName:test1*/
some more code
''');

  testString('/*test*/',
      actualData: {
        'a': {
          new NodeId(0, IdKind.node): 'test1',
        }
      },
      expectedResult: '/*a.test1*//*b|c.test*/');

  testString('/*a.test1*//*b|c.test*/',
      actualData: {
        'b': {
          new NodeId(0, IdKind.node): 'test1',
        }
      },
      expectedResult: '/*a|b.test1*//*c.test*/');

  testString('/*a|b.test1*//*c.test*/',
      actualData: {
        'c': {
          new NodeId(0, IdKind.node): 'test1',
        }
      },
      expectedResult: '/*test1*/');

  testString('/*test*/', actualData: {'c': {}}, expectedResult: '/*a|b.test*/');

  testString('/*a|b.test*/',
      actualData: {'b': {}}, expectedResult: '/*a.test*/');

  testString('/*a.test*/', actualData: {'a': {}}, expectedResult: '');

  testFeatures('''
some code
/*member: memberName:
 test1=a,
 test2=[
  b,
  c],
 test3=d
*/
some more code
''');
  testFeatures('''
some code
/*member: memberName:
 test1=a,
 test2=[
  b,
  c],
 test3=d
*/
some more code
''', actualData: {
    'a': {
      new MemberId('memberName'): 'test1=b,test2=[c,d],test3=e',
    }
  }, expectedResult: '''
some code
/*a.member: memberName:test1=b,test2=[c,d],test3=e*/
/*b|c.member: memberName:
 test1=a,
 test2=[
  b,
  c],
 test3=d
*/
some more code
''');
  testFeatures('''
some code
/*a.member: memberName:test1=b,test2=[c,d],test3=e*/
/*b|c.member: memberName:
 test1=a,
 test2=[
  b,
  c],
 test3=d
*/
some more code
''', actualData: {
    'b': {
      new MemberId('memberName'): 'test1=b,test2=[c,d],test3=e',
    }
  }, expectedResult: '''
some code
/*a|b.member: memberName:test1=b,test2=[c,d],test3=e*/
/*c.member: memberName:
 test1=a,
 test2=[
  b,
  c],
 test3=d
*/
some more code
''');
  testFeatures('''
some code
/*a|b.member: memberName:test1=b,test2=[c,d],test3=e*/
/*c.member: memberName:
 test1=a,
 test2=[
  b,
  c],
 test3=d
*/
some more code
''', actualData: {
    'c': {
      new MemberId('memberName'): 'test1=b,test2=[c,d],test3=e',
    }
  }, expectedResult: '''
some code
/*member: memberName:test1=b,test2=[c,d],test3=e*/
some more code
''');
}

void testString(
  String text, {
  Map<String, Map<Id, String>> actualData: const {},
  String expectedResult,
}) {
  testGeneral(const StringDataInterpreter(), text,
      actualData: actualData, expectedResult: expectedResult);

  testFeatures(text, actualData: actualData, expectedResult: expectedResult);
}

void testFeatures(
  String text, {
  Map<String, Map<Id, String>> actualData: const {},
  String expectedResult,
}) {
  Map<String, Map<Id, Features>> actualFeatures = {};
  actualData.forEach((String marker, Map<Id, String> data) {
    Map<Id, Features> features = actualFeatures[marker] = {};
    data.forEach((Id id, String text) {
      features[id] = Features.fromText(text.trim());
    });
  });
  testGeneral(const FeaturesDataInterpreter(), text,
      actualData: actualFeatures, expectedResult: expectedResult);
}

void testGeneral<T>(DataInterpreter<T> dataInterpreter, String text,
    {Map<String, Map<Id, T>> actualData: const {}, String expectedResult}) {
  expectedResult ??= text;
  AnnotatedCode code =
      new AnnotatedCode.fromText(text, commentStart, commentEnd);
  Map<String, MemberAnnotations<IdValue>> expectedMaps = {};
  for (String marker in markers) {
    expectedMaps[marker] = new MemberAnnotations<IdValue>();
  }
  computeExpectedMap(mainUri, mainUri.path, code, expectedMaps);

  Map<String, Map<Uri, Map<Id, ActualData<T>>>> actualAnnotations = {};
  actualData.forEach((String marker, Map<Id, T> data) {
    Map<Uri, Map<Id, ActualData<T>>> map = actualAnnotations[marker] = {};
    Map<Id, ActualData<T>> actualData = map[mainUri] = {};
    data.forEach((Id id, T value) {
      int offset;
      if (id is NodeId) {
        offset = id.value;
      } else {
        offset = 0;
      }
      actualData[id] = new ActualData<T>(id, value, mainUri, offset, text);
    });
  });

  Map<Uri, List<Annotation>> annotations = computeAnnotationsPerUri<T>(
      expectedMaps, mainUri, actualAnnotations, dataInterpreter);
  AnnotatedCode generated = new AnnotatedCode(
      code.annotatedCode, code.sourceCode, annotations[mainUri]);
  String actualResult = generated.toText();
  if (expectedResult != actualResult) {
    print("Unexpected result for '$text'"
        "${actualData != null ? ' with actualData=$actualData' : ''}");
    print('---expected-------------------------------------------------------');
    print(expectedResult);
    print('---actual---------------------------------------------------------');
    print(actualResult);
    Expect.stringEquals(expectedResult, actualResult);
  }
}
