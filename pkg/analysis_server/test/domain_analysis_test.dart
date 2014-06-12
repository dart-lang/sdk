// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis;

import 'dart:async';

import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';


main() {
  groupSep = ' | ';

  MockServerChannel serverChannel;
  AnalysisServer server;
  AnalysisDomainHandler handler;
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  setUp(() {
    serverChannel = new MockServerChannel();
    server = new AnalysisServer(serverChannel, resourceProvider);
    server.defaultSdk = new MockSdk();
    handler = new AnalysisDomainHandler(server);
  });

  group('notification.errors', testNotificationErrors);
  group('notification.highlights', testNotificationHighlights);
  group('notification.navigation', testNotificationNavigation);
  group('updateContent', testUpdateContent);
  group('setSubscriptions', test_setSubscriptions);

  group('AnalysisDomainHandler', () {
    test('getFixes', () {
      var request = new Request('0', METHOD_GET_FIXES);
      request.setParameter(ERRORS, []);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('getMinorRefactorings', () {
      var request = new Request('0', METHOD_GET_MINOR_REFACTORINGS);
      request.setParameter(FILE, 'test.dart');
      request.setParameter(OFFSET, 10);
      request.setParameter(LENGTH, 20);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    group('setAnalysisRoots', () {
      Request request;

      setUp(() {
        request = new Request('0', METHOD_SET_ANALYSIS_ROOTS);
        request.setParameter(INCLUDED, []);
        request.setParameter(EXCLUDED, []);
      });

      test('excluded', () {
        request.setParameter(EXCLUDED, ['foo']);
        // TODO(scheglov) implement
        var response = handler.handleRequest(request);
        expect(response, isResponseFailure('0'));
      });

      group('included', () {
        test('new folder', () {
          resourceProvider.newFolder('/project');
          resourceProvider.newFile('/project/pubspec.yaml', 'name: project');
          resourceProvider.newFile('/project/bin/test.dart', 'main() {}');
          request.setParameter(
              INCLUDED,
              ['/project']);
          var response = handler.handleRequest(request);
          var serverRef = server;
          expect(response, isResponseSuccess('0'));
          // verify that unit is resolved eventually
          return waitForServerOperationsPerformed(server).then((_) {
            var unit = serverRef.test_getResolvedCompilationUnit('/project/bin/test.dart');
            expect(unit, isNotNull);
          });
        });
      });
    });

    test('setPriorityFiles', () {
      var request = new Request('0', METHOD_SET_PRIORITY_FILES);
      request.setParameter(
          FILES,
          ['projectA/aa.dart', 'projectB/ba.dart']);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('updateOptions', () {
      var request = new Request('0', METHOD_UPDATE_OPTIONS);
      request.setParameter(
          OPTIONS,
          {
            'analyzeAngular' : true,
            'enableDeferredLoading': true,
            'enableEnums': false
          });
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('updateSdks', () {
      var request = new Request('0', METHOD_UPDATE_SDKS);
      request.setParameter(
          ADDED,
          ['/dart/sdk-1.3', '/dart/sdk-1.4']);
      request.setParameter(
          REMOVED,
          ['/dart/sdk-1.2']);
      request.setParameter(DEFAULT, '/dart/sdk-1.4');
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });
  });
}


class AnalysisError {
  final String file;
  final String errorCode;
  final int offset;
  final int length;
  final String message;
  final String correction;
  AnalysisError(this.file, this.errorCode, this.offset, this.length,
      this.message, this.correction);

  @override
  String toString() {
    return 'NotificationError(file=$file; errorCode=$errorCode; '
        'offset=$offset; length=$length; message=$message)';
  }
}


AnalysisError jsonToAnalysisError(Map<String, Object> json) {
  return new AnalysisError(
      json['file'],
      json['errorCode'],
      json['offset'],
      json['length'],
      json['message'],
      json['correction']);
}


/**
 * A helper to test 'analysis.*' requests.
 */
class AnalysisTestHelper {
  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  AnalysisServer server;
  AnalysisDomainHandler handler;

  Map<String, List<String>> analysisSubscriptions = {};

  Map<String, List<AnalysisError>> filesErrors = {};
  Map<String, List<Map<String, Object>>> filesHighlights = {};
  Map<String, List<Map<String, Object>>> filesNavigation = {};

  String testFile = '/project/bin/test.dart';
  String testCode;

  AnalysisTestHelper() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    server = new AnalysisServer(serverChannel, resourceProvider);
    server.defaultSdk = new MockSdk();
    handler = new AnalysisDomainHandler(server);
    // listen for notifications
    Stream<Notification> notificationStream = serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      if (notification.event == NOTIFICATION_ERRORS) {
        String file = notification.getParameter(FILE);
        List<Map<String, Object>> errorMaps = notification.getParameter(ERRORS);
        filesErrors[file] = errorMaps.map(jsonToAnalysisError).toList();
      }
      if (notification.event == NOTIFICATION_HIGHLIGHTS) {
        String file = notification.getParameter(FILE);
        filesHighlights[file] = notification.getParameter(REGIONS);
      }
      if (notification.event == NOTIFICATION_NAVIGATION) {
        String file = notification.getParameter(FILE);
        filesNavigation[file] = notification.getParameter(REGIONS);
      }
    });
  }

  void addAnalysisSubscriptionHighlights(String file) {
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
  }

  void addAnalysisSubscriptionNavigation(String file) {
    addAnalysisSubscription(AnalysisService.NAVIGATION, file);
  }

  void addAnalysisSubscription(AnalysisService service, String file) {
    // add file to subscription
    var files = analysisSubscriptions[service.name];
    if (files == null) {
      files = <String>[];
      analysisSubscriptions[service.name] = files;
    }
    files.add(file);
    // set subscriptions
    Request request = new Request('0', METHOD_SET_ANALYSIS_SUBSCRIPTIONS);
    request.setParameter(SUBSCRIPTIONS, analysisSubscriptions);
    handleSuccessfulRequest(request);
  }

  /**
   * Returns a [Future] that completes when this this helper finished all its
   * scheduled tasks.
   */
  Future waitForOperationsFinished() {
    return waitForServerOperationsPerformed(server);
  }

  /**
   * Returns the offset of [search] in [testCode].
   * Fails if not found.
   */
  int findOffset(String search) {
    int offset = testCode.indexOf(search);
    expect(offset, isNot(-1));
    return offset;
  }

  /**
   * Returns [AnalysisError]s recorded for the given [file].
   * May be empty, but not `null`.
   */
  List<AnalysisError> getErrors(String file) {
    List<AnalysisError> errors = filesErrors[file];
    if (errors != null) {
      return errors;
    }
    return <AnalysisError>[];
  }

  /**
   * Returns highlights recorded for the given [file].
   * May be empty, but not `null`.
   */
  List<Map<String, Object>> getHighlights(String file) {
    List<Map<String, Object>> highlights = filesHighlights[file];
    if (highlights != null) {
      return highlights;
    }
    return [];
  }

  /**
   * Returns navigation regions recorded for the given [file].
   * May be empty, but not `null`.
   */
  List<Map<String, Object>> getNavigation(String file) {
    List<Map<String, Object>> navigation = filesNavigation[file];
    if (navigation != null) {
      return navigation;
    }
    return [];
  }

  /**
   * Returns [AnalysisError]s recorded for the [testFile].
   * May be empty, but not `null`.
   */
  List<AnalysisError> getTestErrors() {
    return getErrors(testFile);
  }

  /**
   * Returns highlights recorded for the given [testFile].
   * May be empty, but not `null`.
   */
  List<Map<String, Object>> getTestHighlights() {
    return getHighlights(testFile);
  }

  /**
   * Returns navigation information recorded for the given [testFile].
   * May be empty, but not `null`.
   */
  List<Map<String, Object>> getTestNavigation() {
    return getNavigation(testFile);
  }

  /**
   * Creates an empty project `/project`.
   */
  void createEmptyProject() {
    resourceProvider.newFolder('/project');
    Request request = new Request('0', METHOD_SET_ANALYSIS_ROOTS);
    request.setParameter(INCLUDED, ['/project']);
    request.setParameter(EXCLUDED, []);
    handleSuccessfulRequest(request);
  }

  /**
   * Creates a project with a single Dart file `/project/bin/test.dart` with
   * the given [code].
   */
  void createSingleFileProject(code) {
    this.testCode = _getCodeString(code);
    resourceProvider.newFolder('/project');
    resourceProvider.newFile(testFile, testCode);
    Request request = new Request('0', METHOD_SET_ANALYSIS_ROOTS);
    request.setParameter(INCLUDED, ['/project']);
    request.setParameter(EXCLUDED, []);
    handleSuccessfulRequest(request);
  }

  String setFileContent(String path, String content) {
    resourceProvider.newFile(path, content);
    return path;
  }

  /**
   * Validates that the given [request] is handled successfully.
   */
  void handleSuccessfulRequest(Request request) {
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
  }

  /**
   * Stops the associated server.
   */
  void stopServer() {
    server.done();
  }

  static String _getCodeString(code) {
    if (code is List<String>) {
      code = code.join('\n');
    }
    return code as String;
  }
}


testNotificationErrors() {
  AnalysisTestHelper helper;

  setUp(() {
    helper = new AnalysisTestHelper();
  });

  test('ParserErrorCode', () {
    helper.createSingleFileProject('library lib');
    return helper.waitForOperationsFinished().then((_) {
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, hasLength(1));
      AnalysisError error = errors[0];
      expect(error.file, '/project/bin/test.dart');
      expect(error.errorCode, 'ParserErrorCode.EXPECTED_TOKEN');
      expect(error.offset, isPositive);
      expect(error.length, isNonNegative);
      expect(error.message, isNotNull);
    });
  });

  test('StaticWarningCode', () {
    helper.createSingleFileProject([
      'main() {',
      '  print(unknown);',
      '}']);
    return helper.waitForOperationsFinished().then((_) {
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, hasLength(1));
      AnalysisError error = errors[0];
      expect(error.errorCode, 'StaticWarningCode.UNDEFINED_IDENTIFIER');
    });
  });
}


class NotificationHighlightHelper extends AnalysisTestHelper {
  List<Map<String, Object>> regions;

  Future prepareRegions(then()) {
    addAnalysisSubscriptionHighlights(testFile);
    return waitForOperationsFinished().then((_) {
      regions = getTestHighlights();
      then();
    });
  }

  void assertHasRawRegion(HighlightType type, int offset, int length) {
    for (Map<String, Object> region in regions) {
      if (region['offset'] == offset && region['length'] == length
          && region['type'] == type.name) {
        return;
      }
    }
    fail('Expected to find (offset=$offset; length=$length; type=$type) in\n'
         '${regions.join('\n')}');
  }

  void assertNoRawRegion(HighlightType type, int offset, int length) {
    for (Map<String, Object> region in regions) {
      if (region['offset'] == offset && region['length'] == length
          && region['type'] == type.name) {
        fail('Not expected to find (offset=$offset; length=$length; type=$type) in\n'
             '${regions.join('\n')}');
      }
    }
  }

  void assertHasRegion(HighlightType type, String search, [int length = -1]) {
    int offset = testCode.indexOf(search);
    expect(offset, isNot(-1));
    length = findRegionLength(search, length);
    assertHasRawRegion(type, offset, length);
  }

  void assertNoRegion(HighlightType type, String search, [int length = -1]) {
    int offset = testCode.indexOf(search);
    expect(offset, isNot(-1));
    length = findRegionLength(search, length);
    assertNoRawRegion(type, offset, length);
  }

  int findRegionLength(String search, int length) {
    if (length == -1) {
      length = 0;
      while (length < search.length) {
        int c = search.codeUnitAt(length);
        if (length == 0 && c == '@'.codeUnitAt(0)) {
          length++;
          continue;
        }
        if (!(c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0) ||
              c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0) ||
              c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0))) {
          break;
        }
        length++;
      }
    }
    return length;
  }
}


testNotificationHighlights() {
  Future testRegions(String code, then(NotificationHighlightHelper helper)) {
    var helper = new NotificationHighlightHelper();
    helper.createSingleFileProject(code);
    return helper.prepareRegions(() {
      then(helper);
    });
  }

  group('ANNOTATION', () {
    test('no arguments', () {
      var code = '''
const AAA = 42;
@AAA main() {}
''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.ANNOTATION, '@AAA');
      });
    });

    test('has arguments', () {
      var code = '''
class AAA {
  const AAA(a, b, c);
}
@AAA(1, 2, 3) main() {}
''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.ANNOTATION, '@AAA(', '@AAA('.length);
        helper.assertHasRegion(HighlightType.ANNOTATION, ') main', ')'.length);
      });
    });
  });

  group('BUILT_IN', () {
    test('abstract', () {
      var code = '''
abstract class A {};
main() {
  var abstract = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'abstract class');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'abstract = 42');
      });
    });

    test('as', () {
      var code = '''
import 'dart:math' as math;
main() {
  p as int;
  var as = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'as math');
        helper.assertHasRegion(HighlightType.BUILT_IN, 'as int');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'as = 42');
      });
    });

    test('deferred', () {
      var code = '''
import 'dart:math' deferred as math;
main() {
  var deferred = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'deferred as math');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'deferred = 42');
      });
    });

    test('export', () {
      var code = '''
export "dart:math";
main() {
  var export = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'export "dart:');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'export = 42');
      });
    });

    test('external', () {
      var code = '''
class A {
  external A();
  external aaa();
}
external main() {
  var external = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'external A()');
        helper.assertHasRegion(HighlightType.BUILT_IN, 'external aaa()');
        helper.assertHasRegion(HighlightType.BUILT_IN, 'external main()');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'external = 42');
      });
    });

    test('factory', () {
      var code = '''
class A {
  factory A() => null;
}
main() {
  var factory = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'factory A()');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'factory = 42');
      });
    });

    test('get', () {
      var code = '''
get aaa => 1;
class A {
  get bbb => 2;
}
main() {
  var get = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'get aaa =>');
        helper.assertHasRegion(HighlightType.BUILT_IN, 'get bbb =>');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'get = 42');
      });
    });

    test('hide', () {
      var code = '''
import 'foo.dart' hide Foo;
main() {
  var hide = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'hide Foo');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'hide = 42');
      });
    });

    test('implements', () {
      var code = '''
class A {}
class B implements A {}
main() {
  var implements = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'implements A {}');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'implements = 42');
      });
    });

    test('import', () {
      var code = '''
import "foo.dart";
main() {
  var import = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'import "');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'import = 42');
      });
    });

    test('library', () {
      var code = '''
library lib;
main() {
  var library = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'library lib;');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'library = 42');
      });
    });

    test('native', () {
      var code = '''
class A native "A_native" {}
class B {
  bbb() native "bbb_native";
}
main() {
  var native = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'native "A_');
        helper.assertHasRegion(HighlightType.BUILT_IN, 'native "bbb_');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'native = 42');
      });
    });

    test('on', () {
      var code = '''
main() {
  try {
  } on int catch (e) {
  }
  var on = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'on int');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'on = 42');
      });
    });

    test('operator', () {
      var code = '''
class A {
  operator +(x) => null;
}
main() {
  var operator = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'operator +(');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'operator = 42');
      });
    });

    test('part', () {
      var helper = new NotificationHighlightHelper();
      var code = '''
part "my_part.dart";
main() {
  var part = 42;
}''';
      helper.createSingleFileProject(code);
      helper.setFileContent('/project/bin/my_part.dart', 'part of lib;');
      return helper.prepareRegions(() {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'part "my_');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'part = 42');
      });
    });

    test('part', () {
      var helper = new NotificationHighlightHelper();
      var code = '''
part of lib;
main() {
  var part = 1;
  var of = 2;
}''';
      helper.createSingleFileProject(code);
      helper.setFileContent('/project/bin/lib.dart', '''
library lib;
part 'test.dart';
''');
      return helper.prepareRegions(() {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'part of', 'part of'.length);
        helper.assertNoRegion(HighlightType.BUILT_IN, 'part = 1');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'of = 2');
      });
    });

    test('set', () {
      var code = '''
set aaa(x) {}
class A
  set bbb(x) {}
}
main() {
  var set = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'set aaa(');
        helper.assertHasRegion(HighlightType.BUILT_IN, 'set bbb(');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'set = 42');
      });
    });

    test('show', () {
      var code = '''
import 'foo.dart' show Foo;
main() {
  var show = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'show Foo');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'show = 42');
      });
    });

    test('static', () {
      var code = '''
class A {
  static aaa;
  static bbb() {}
}
main() {
  var static = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'static aaa;');
        helper.assertHasRegion(HighlightType.BUILT_IN, 'static bbb()');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'static = 42');
      });
    });

    test('typedef', () {
      var code = '''
typedef A();
main() {
  var typedef = 42;
}''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.BUILT_IN, 'typedef A();');
        helper.assertNoRegion(HighlightType.BUILT_IN, 'typedef = 42');
      });
    });
  });

  group('CLASS', () {
    test('CLASS', () {
      var code = '''
class AAA {}
AAA aaa;
''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertHasRegion(HighlightType.CLASS, 'AAA {}');
        helper.assertHasRegion(HighlightType.CLASS, 'AAA aaa');
      });
    });

    test('not dynamic', () {
      var code = '''
dynamic f() {}
''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertNoRegion(HighlightType.CLASS, 'dynamic f()');
      });
    });

    test('not void', () {
      var code = '''
void f() {}
''';
      return testRegions(code, (NotificationHighlightHelper helper) {
        helper.assertNoRegion(HighlightType.CLASS, 'void f()');
      });
    });
  });

  test('CONSTRUCTOR', () {
    var code = '''
class AAA {
  AAA() {}
  AAA.name(p) {}
}
main() {
  new AAA();
  new AAA.name(42);
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.CONSTRUCTOR, 'name(p)');
      helper.assertHasRegion(HighlightType.CONSTRUCTOR, 'name(42)');
      helper.assertNoRegion(HighlightType.CONSTRUCTOR, 'AAA() {}');
      helper.assertNoRegion(HighlightType.CONSTRUCTOR, 'AAA();');
    });
  });

  test('DYNAMIC_TYPE', () {
    var code = '''
f() {}
main(p) {
  print(p);
  var v1 = f();
  int v2;
  var v3 = v2;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.DYNAMIC_TYPE, 'p)');
      helper.assertHasRegion(HighlightType.DYNAMIC_TYPE, 'v1 =');
      helper.assertNoRegion(HighlightType.DYNAMIC_TYPE, 'v2;');
      helper.assertNoRegion(HighlightType.DYNAMIC_TYPE, 'v3 =');
    });
  });

  test('FIELD', () {
    var code = '''
class A {
  int aaa = 1;
  int bbb = 2;
  A([this.bbb = 3]);
}
main(A a) {
  a.aaa = 4;
  a.bbb = 5;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.FIELD, 'aaa = 1');
      helper.assertHasRegion(HighlightType.FIELD, 'bbb = 2');
      helper.assertHasRegion(HighlightType.FIELD, 'bbb = 3');
      helper.assertHasRegion(HighlightType.FIELD, 'aaa = 4');
      helper.assertHasRegion(HighlightType.FIELD, 'bbb = 5');
    });
  });

  test('FIELD_STATIC', () {
    var code = '''
class A {
  static aaa = 1;
  static get bbb => null;
  static set ccc(x) {}
}
main() {
  A.aaa = 2;
  A.bbb;
  A.ccc = 3;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.FIELD_STATIC, 'aaa = 1');
      helper.assertHasRegion(HighlightType.FIELD_STATIC, 'aaa = 2');
      helper.assertHasRegion(HighlightType.FIELD_STATIC, 'bbb;');
      helper.assertHasRegion(HighlightType.FIELD_STATIC, 'ccc = 3');
    });
  });

  test('FUNCTION', () {
    var code = '''
fff(p) {}
main() {
  fff(42);
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.FUNCTION_DECLARATION, 'fff(p) {}');
      helper.assertHasRegion(HighlightType.FUNCTION, 'fff(42)');
    });
  });

  test('FUNCTION_TYPE_ALIAS', () {
    var code = '''
typedef FFF(p);
main(FFF fff) {
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.FUNCTION_TYPE_ALIAS, 'FFF(p)');
      helper.assertHasRegion(HighlightType.FUNCTION_TYPE_ALIAS, 'FFF fff)');
    });
  });

  test('GETTER_DECLARATION', () {
    var code = '''
get aaa => null;
class A {
  get bbb => null;
}
main(A a) {
  aaa;
  a.bbb;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.GETTER_DECLARATION, 'aaa => null');
      helper.assertHasRegion(HighlightType.GETTER_DECLARATION, 'bbb => null');
      helper.assertHasRegion(HighlightType.FIELD_STATIC, 'aaa;');
      helper.assertHasRegion(HighlightType.FIELD, 'bbb;');
    });
  });

  test('IDENTIFIER_DEFAULT', () {
    var code = '''
main() {
  aaa = 42;
  bbb(84);
  CCC ccc;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.IDENTIFIER_DEFAULT, 'aaa = 42');
      helper.assertHasRegion(HighlightType.IDENTIFIER_DEFAULT, 'bbb(84)');
      helper.assertHasRegion(HighlightType.IDENTIFIER_DEFAULT, 'CCC ccc');
    });
  });

  test('IMPORT_PREFIX', () {
    var code = '''
import 'dart:math' as ma;
main() {
  ma.max(1, 2);
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.IMPORT_PREFIX, 'ma;');
      helper.assertHasRegion(HighlightType.IMPORT_PREFIX, 'ma.max');
    });
  });

  test('KEYWORD void', () {
    var code = '''
void main() {
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.KEYWORD, 'void main()');
    });
  });

  test('LITERAL_BOOLEAN', () {
    var code = 'var V = true;';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.LITERAL_BOOLEAN, 'true;');
    });
  });

  test('LITERAL_DOUBLE', () {
    var code = 'var V = 4.2;';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.LITERAL_DOUBLE, '4.2;', '4.2'.length);
    });
  });

  test('LITERAL_INTEGER', () {
    var code = 'var V = 42;';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.LITERAL_INTEGER, '42;');
    });
  });

  test('LITERAL_STRING', () {
    var code = 'var V = "abc";';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.LITERAL_STRING, '"abc";', '"abc"'.length);
    });
  });

  test('LOCAL_VARIABLE', () {
    var code = '''
main() {
  int vvv = 0;
  vvv;
  vvv = 1;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.LOCAL_VARIABLE_DECLARATION, 'vvv = 0');
      helper.assertHasRegion(HighlightType.LOCAL_VARIABLE, 'vvv;');
      helper.assertHasRegion(HighlightType.LOCAL_VARIABLE, 'vvv = 1;');
    });
  });

  test('METHOD', () {
    var code = '''
class A {
  aaa() {}
  static bbb() {}
}
main(A a) {
  a.aaa();
  a.aaa;
  A.bbb();
  A.bbb;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.METHOD_DECLARATION, 'aaa() {}');
      helper.assertHasRegion(HighlightType.METHOD_DECLARATION_STATIC, 'bbb() {}');
      helper.assertHasRegion(HighlightType.METHOD, 'aaa();');
      helper.assertHasRegion(HighlightType.METHOD, 'aaa;');
      helper.assertHasRegion(HighlightType.METHOD_STATIC, 'bbb();');
      helper.assertHasRegion(HighlightType.METHOD_STATIC, 'bbb;');
    });
  });

  test('METHOD best type', () {
    var code = '''
main(p) {
  if (p is List) {
    p.add(null);
  }
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.METHOD, 'add(null)');
    });
  });

  test('PARAMETER', () {
    var code = '''
main(int p) {
  p;
  p = 42;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.PARAMETER, 'p) {');
      helper.assertHasRegion(HighlightType.PARAMETER, 'p;');
      helper.assertHasRegion(HighlightType.PARAMETER, 'p = 42');
    });
  });

  test('SETTER_DECLARATION', () {
    var code = '''
set aaa(x) {}
class A {
  set bbb(x) {}
}
main(A a) {
  aaa = 1;
  a.bbb = 2;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.SETTER_DECLARATION, 'aaa(x)');
      helper.assertHasRegion(HighlightType.SETTER_DECLARATION, 'bbb(x)');
      helper.assertHasRegion(HighlightType.FIELD_STATIC, 'aaa = 1');
      helper.assertHasRegion(HighlightType.FIELD, 'bbb = 2');
    });
  });

  test('TOP_LEVEL_VARIABLE', () {
    var code = '''
var VVV = 0;
main() {
  print(VVV);
  VVV = 1;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.TOP_LEVEL_VARIABLE, 'VVV = 0');
      helper.assertHasRegion(HighlightType.FIELD_STATIC, 'VVV);');
      helper.assertHasRegion(HighlightType.FIELD_STATIC, 'VVV = 1');
    });
  });

  test('TYPE_NAME_DYNAMIC', () {
    var code = '''
dynamic main() {
  dynamic = 42;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.TYPE_NAME_DYNAMIC, 'dynamic main()');
      helper.assertNoRegion(HighlightType.IDENTIFIER_DEFAULT, 'dynamic main()');
      helper.assertNoRegion(HighlightType.TYPE_NAME_DYNAMIC, 'dynamic = 42');
    });
  });

  test('TYPE_PARAMETER', () {
    var code = '''
class A<T> {
  T fff;
  T mmm(T p) => null;
}
''';
    return testRegions(code, (NotificationHighlightHelper helper) {
      helper.assertHasRegion(HighlightType.TYPE_PARAMETER, 'T> {');
      helper.assertHasRegion(HighlightType.TYPE_PARAMETER, 'T fff;');
      helper.assertHasRegion(HighlightType.TYPE_PARAMETER, 'T mmm(');
      helper.assertHasRegion(HighlightType.TYPE_PARAMETER, 'T p)');
    });
  });
}




class NotificationNavigationHelper extends AnalysisTestHelper {
  List<Map<String, Object>> regions;

  Future prepareRegions(then()) {
    addAnalysisSubscriptionNavigation(testFile);
    return waitForOperationsFinished().then((_) {
      regions = getTestNavigation();
      then();
    });
  }

  void assertHasRegion(String regionSearch, String targetSearch) {
    var regionOffset = findOffset(regionSearch);
    int regionLength = findIdentifierLength(regionSearch);
    var targetOffset = findOffset(targetSearch);
    var targetLength = findIdentifierLength(targetSearch);
    asserHasRegionInts(regionOffset, regionLength, targetOffset, targetLength);
  }

  void asserHasOperatorRegion(String search, int regionLength, int targetLength) {
    var regionOffset = findOffset(search);
    var region = asserHasRegionInts(regionOffset, regionLength, -1, 0);
    if (targetLength != -1) {
      expect(region['targets'][0]['length'], targetLength);
    }
  }

  asserHasRegionInts(int regionOffset, int regionLength,
                          int targetOffset, int targetLength) {
    Map<String, Object> region = findRegion(regionOffset, regionLength);
    if (region != null) {
      List<Map<String, Object>> targets = region['targets'];
      if (targetOffset == -1) {
        return region;
      }
      var target = findTarget(targets, testFile, targetOffset, targetLength);
      if (target != null) {
        return target;
      }
    }
    fail('Expected to find (offset=$regionOffset; length=$regionLength) => '
         '(offset=$targetOffset; length=$targetLength) in\n'
         '${regions.join('\n')}');
  }

  Map<String, Object> findRegionString(String search, [bool notNull]) {
    int offset = findOffset(search);
    int length = search.length;
    return findRegion(offset, length, notNull);
  }

  Map<String, Object> findRegionAt(String search, [bool notNull]) {
    int offset = findOffset(search);
    for (Map<String, Object> region in regions) {
      if (region['offset'] == offset) {
        if (notNull == false) {
          fail('Not expected to find at offset=$offset in\n'
               '${regions.join('\n')}');
        }
        return region;
      }
    }
    if (notNull == true) {
      fail('Expected to find at offset=$offset in\n'
           '${regions.join('\n')}');
    }
    return null;
  }

  Map<String, Object> findRegionIdentifier(String search, [bool notNull]) {
    int offset = findOffset(search);
    int length = findIdentifierLength(search);
    return findRegion(offset, length, notNull);
  }

  Map<String, Object> findRegion(int offset, int length, [bool notNull]) {
    for (Map<String, Object> region in regions) {
      if (region['offset'] == offset && region['length'] == length) {
        if (notNull == false) {
          fail('Not expected to find (offset=$offset; length=$length) in\n'
               '${regions.join('\n')}');
        }
        return region;
      }
    }
    if (notNull == true) {
      fail('Expected to find (offset=$offset; length=$length) in\n'
           '${regions.join('\n')}');
    }
    return null;
  }

  Map<String, Object> findTarget(List<Map<String, Object>> targets,
                                 String file, int offset, int length) {
    for (Map<String, Object> target in targets) {
      if (target['file'] == file &&
          target['offset'] == offset &&
          target['length'] == length) {
        return target;
      }
    }
    return null;
  }

  void assertNoRegion(String regionSearch) {
    var regionOffset = findOffset(regionSearch);
    var regionLength = findIdentifierLength(regionSearch);
    for (Map<String, Object> region in regions) {
      if (region['offset'] == regionOffset && region['length'] == regionLength) {
        fail('Unexpected (offset=$regionOffset; length=$regionLength) in\n'
             '${regions.join('\n')}');
      }
    }
  }
}


int findIdentifierLength(String search) {
  int length = 0;
  while (length < search.length) {
    int c = search.codeUnitAt(length);
    if (!(c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0) ||
          c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0) ||
          c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0))) {
      break;
    }
    length++;
  }
  return length;
}


testNotificationNavigation() {
  Future testNavigation(String code, then(NotificationNavigationHelper helper)) {
    var helper = new NotificationNavigationHelper();
    helper.createSingleFileProject(code);
    return helper.prepareRegions(() {
      then(helper);
    });
  }

  group('constructor', () {
    test('named', () {
      var code = '''
class A {
  A.named(int p) {}
}
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        // has region for complete "A.named"
        helper.asserHasRegionInts(
            helper.findOffset('A.named'), 'A.named'.length,
            helper.findOffset('named(int'), 'named'.length);
        // no separate regions for "A" and "named"
        helper.assertNoRegion('A.named(');
        helper.assertNoRegion('named(');
        // validate that we don't forget to resolve parameters
        helper.asserHasRegionInts(
            helper.findOffset('int p'), 'int'.length,
            -1, 0);
      });
    });

    test('unnamed', () {
      var code = '''
class A {
  A(int p) {}
}
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        // has constructor region for "A()"
        helper.asserHasRegionInts(
            helper.findOffset('A(int p)'), 'A'.length,
            helper.findOffset('A(int p)'), 0);
        // validate that we don't forget to resolve parameters
        helper.asserHasRegionInts(
            helper.findOffset('int p'), 'int'.length,
            -1, 0);
      });
    });
  });

  group('identifier', () {
    test('resolved', () {
      var code = '''
class AAA {}
main() {
  AAA aaa = null;
  print(aaa);
}
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.assertHasRegion('AAA aaa', 'AAA {}');
        helper.assertHasRegion('aaa);', 'aaa = null');
        helper.assertHasRegion('main() {', 'main() {');
      });
    });

    test('unresolved', () {
      var code = '''
main() {
  print(noo);
}
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.assertNoRegion('noo);');
      });
    });
  });

  test('fieldFormalParameter', () {
    var code = '''
class A {
  int fff = 123;
  A(this.fff);
}
''';
    return testNavigation(code, (NotificationNavigationHelper helper) {
      helper.assertHasRegion('fff);', 'fff = 123');
    });
  });

  group('instanceCreation', () {
    test('implicit', () {
      var code = '''
class A {
}
main() {
  new A();
}
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.asserHasRegionInts(
            helper.findOffset('new A'), 'new A'.length,
            helper.findOffset('A {'), 'A'.length);
      });
    });

    test('named', () {
      var code = '''
class A {
  A.named() {}
}
main() {
  new A.named();
}
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.asserHasRegionInts(
            helper.findOffset('new A.named'), 'new A.named'.length,
            helper.findOffset('named()'), 'named'.length);
      });
    });

    test('unnamed', () {
      var code = '''
class A {
  A() {}
}
main() {
  new A();
}
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.asserHasRegionInts(
            helper.findOffset('new A'), 'new A'.length,
            helper.findOffset('A()'), ''.length);
      });
    });
  });

  group('operator', () {
    test('int', () {
      var code = '''
main() {
  var v = 0;
  v - 1;
  v + 2;
  -v; // unary
  --v;
  ++v;
  v--; // mm
  v++; // pp
  v -= 3;
  v += 4;
  v *= 5;
  v /= 6;
}
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.asserHasOperatorRegion('- 1;', 1, 1);
        helper.asserHasOperatorRegion('+ 2;', 1, 1);
        helper.asserHasOperatorRegion('-v; // unary', 1, -1);
        helper.asserHasOperatorRegion('--v;', 2, 1);
        helper.asserHasOperatorRegion('++v;', 2, 1);
        helper.asserHasOperatorRegion('--; // mm', 2, 1);
        helper.asserHasOperatorRegion('++; // pp', 2, 1);
        helper.asserHasOperatorRegion('-= 3;', 2, 1);
        helper.asserHasOperatorRegion('+= 4;', 2, 1);
        helper.asserHasOperatorRegion('*= 5;', 2, 1);
        helper.asserHasOperatorRegion('/= 6;', 2, 1);
      });
    });

    test('list', () {
      var code = '''
main() {
  List<int> v = [1, 2, 3];
  v[0]; // []
  v[1] = 1; // []=
  v[2] += 2;
}
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.asserHasOperatorRegion(']; // []', 1, 2);
        helper.asserHasOperatorRegion('] = 1', 1, 3);
        helper.asserHasOperatorRegion('] += 2', 1, 3);
        helper.asserHasOperatorRegion('+= 2', 2, 1);
      });
    });
  });

  test('partOf', () {
    var helper = new NotificationNavigationHelper();
    var code = '''
part of lib;
''';
    helper.createSingleFileProject(code);
    var libPath = helper.setFileContent('/project/bin/lib.dart', '''
library lib;
part 'test.dart';
''');
    return helper.prepareRegions(() {
      var region = helper.findRegionString('part of lib', true);
      var target = region['targets'][0];
      expect(target['file'], libPath);
    });
  });

  group('string', () {
    test('export', () {
      var code = '''
export "dart:math";
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.findRegionString('export "dart:math"', true);
      });
    });

    test('export unresolved URI', () {
      var code = '''
export 'no.dart';
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.findRegionAt('export ', false);
      });
    });

    test('import', () {
      var code = '''
import "dart:math" as m;
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.findRegionString('import "dart:math"', true);
      });
    });

    test('import no URI', () {
      var code = '''
import ;
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.findRegionAt('import ', false);
      });
    });

    test('import unresolved URI', () {
      var code = '''
import 'no.dart';
''';
      return testNavigation(code, (NotificationNavigationHelper helper) {
        helper.findRegionAt('import ', false);
      });
    });

    test('part', () {
      var helper = new NotificationNavigationHelper();
      var code = '''
library lib;
part "my_part.dart";
''';
      helper.createSingleFileProject(code);
      var unitPath = helper.setFileContent('/project/bin/my_part.dart', '''
part of lib;
''');
      return helper.prepareRegions(() {
        var region = helper.findRegionString('part "my_part.dart"', true);
        var target = region['targets'][0];
        expect(target['file'], unitPath);
      });
    });

    test('part unresolved URI', () {
      // TODO(scheglov) why do we throw MemoryResourceException here?
      // This Source/File does not exist.
//      var helper = new NotificationNavigationHelper();
//      var code = '''
//library lib;
//part "my_part.dart";
//''';
//      helper.createSingleFileProject(code);
//      return helper.prepareRegions(() {
//        helper.findRegionAt('part ', false);
//      });
    });
  });
}


testUpdateContent() {
  test('full content', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('// empty');
    return helper.waitForOperationsFinished().then((_) {
      // no errors initially
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, isEmpty);
      // update code
      {
        Request request = new Request('0', METHOD_UPDATE_CONTENT);
        request.setParameter('files',
            {
              helper.testFile : {
                CONTENT : 'library lib'
              }
            });
        helper.handleSuccessfulRequest(request);
      }
      // wait, there is an error
      return helper.waitForOperationsFinished().then((_) {
        List<AnalysisError> errors = helper.getTestErrors();
        expect(errors, hasLength(1));
      });
    });
  });

  test('incremental', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    return helper.waitForOperationsFinished().then((_) {
      // no errors initially
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, isEmpty);
      // update code
      {
        Request request = new Request('0', METHOD_UPDATE_CONTENT);
        request.setParameter('files',
            {
              helper.testFile : {
                CONTENT : 'library lib',
                OFFSET : 'library '.length,
                OLD_LENGTH : 'A;'.length,
                NEW_LENGTH : 'lib'.length,
              }
            });
        helper.handleSuccessfulRequest(request);
      }
      // wait, there is an error
      return helper.waitForOperationsFinished().then((_) {
        List<AnalysisError> errors = helper.getTestErrors();
        expect(errors, hasLength(1));
      });
    });
  });
}


void test_setSubscriptions() {
  test('before analysis', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    // subscribe
    helper.addAnalysisSubscriptionHighlights(helper.testFile);
    // create project
    helper.createSingleFileProject('int V = 42;');
    // wait, there are highlight regions
    helper.waitForOperationsFinished().then((_) {
      var highlights = helper.getHighlights(helper.testFile);
      expect(highlights, isNot(isEmpty));
    });
  });

  test('after analysis', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    // create project
    helper.createSingleFileProject('int V = 42;');
    // wait, no regions initially
    return helper.waitForOperationsFinished().then((_) {
      var highlights = helper.getHighlights(helper.testFile);
      expect(highlights, isEmpty);
      // subscribe
      helper.addAnalysisSubscriptionHighlights(helper.testFile);
      // wait, has regions
      return helper.waitForOperationsFinished().then((_) {
        var highlights = helper.getHighlights(helper.testFile);
        expect(highlights, isNot(isEmpty));
      });
    });
  });
}
