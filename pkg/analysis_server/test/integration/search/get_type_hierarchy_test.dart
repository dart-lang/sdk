// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetTypeHierarchyTest);
  });
}

@reflectiveTest
class GetTypeHierarchyTest extends AbstractAnalysisServerIntegrationTest {
  /// Pathname of the main file to run tests in.
  late String pathname;

  Future<void> getTypeHierarchy_badTarget() async {
    var text = r'''
void f() {
  if /* target */ (true) {
    print('Hello');
  }
}
''';
    var results = await typeHierarchyTestNullable(text);
    expect(results, isNull);
  }

  Future<void> getTypeHierarchy_classElement() {
    var text = r'''
class Base {}
class Pivot /* target */ extends Base {}
class Derived extends Pivot {}
''';
    return typeHierarchyTest(text).then((HierarchyResults results) {
      expect(results.items, hasLength(4));
      expect(results.nameToIndex['Pivot'], equals(0));
      void checkElement(String name) {
        // We don't check the full element data structure; just enough to make
        // sure that we're pointing to the correct element.
        // var element = results.items[results.nameToIndex[name]].classElement;
        var element = results.getItem(name).classElement;
        expect(element.kind, equals(ElementKind.CLASS));
        expect(element.name, equals(name));
        if (name != 'Object') {
          expect(element.location!.offset,
              equals(text.indexOf('class $name') + 'class '.length));
        }
      }

      checkElement('Object');
      checkElement('Base');
      checkElement('Pivot');
      checkElement('Derived');
    });
  }

  Future<void> getTypeHierarchy_displayName() {
    var text = r'''
class Base<T> {}
class Pivot /* target */ extends Base<int> {}
''';
    return typeHierarchyTest(text).then((HierarchyResults results) {
      expect(results.items, hasLength(3));
      expect(results.getItem('Object').displayName, isNull);
      expect(results.getItem('Base').displayName, equals('Base<int>'));
      expect(results.getItem('Pivot').displayName, isNull);
    });
  }

  Future<void> getTypeHierarchy_functionTarget() async {
    var text = r'''
main /* target */ () {
}
''';
    var results = await typeHierarchyTestNullable(text);
    expect(results, isNull);
  }

  Future<void> getTypeHierarchy_interfaces() {
    var text = r'''
class Interface1 {}
class Interface2 {}
class Pivot /* target */ implements Interface1, Interface2 {}
''';
    return typeHierarchyTest(text).then((HierarchyResults results) {
      expect(results.items, hasLength(4));
      expect(results.pivot.interfaces, hasLength(2));
      expect(results.pivot.interfaces,
          contains(results.nameToIndex['Interface1']));
      expect(results.pivot.interfaces,
          contains(results.nameToIndex['Interface2']));
      expect(results.getItem('Object').interfaces, isEmpty);
      expect(results.getItem('Interface1').interfaces, isEmpty);
      expect(results.getItem('Interface2').interfaces, isEmpty);
    });
  }

  Future<void> getTypeHierarchy_memberElement() {
    var text = r'''
class Base1 {
  void foo /* base1 */ ();
}
class Base2 extends Base1 {}
class Pivot extends Base2 {
  void foo /* target */ ();
}
class Derived1 extends Pivot {}
class Derived2 extends Derived1 {
  void foo /* derived2 */ ();
}''';
    return typeHierarchyTest(text).then((HierarchyResults results) {
      expect(results.items, hasLength(6));
      expect(results.getItem('Object').memberElement, isNull);
      expect(results.getItem('Base1').memberElement!.location!.offset,
          equals(text.indexOf('foo /* base1 */')));
      expect(results.getItem('Base2').memberElement, isNull);
      expect(results.getItem('Pivot').memberElement!.location!.offset,
          equals(text.indexOf('foo /* target */')));
      expect(results.getItem('Derived1').memberElement, isNull);
      expect(results.getItem('Derived2').memberElement!.location!.offset,
          equals(text.indexOf('foo /* derived2 */')));
    });
  }

  Future<void> getTypeHierarchy_mixins() {
    var text = r'''
class Base {}
class Mixin1 {}
class Mixin2 {}
class Pivot /* target */ extends Base with Mixin1, Mixin2 {}
''';
    return typeHierarchyTest(text).then((HierarchyResults results) {
      expect(results.items, hasLength(5));
      expect(results.pivot.mixins, hasLength(2));
      expect(results.pivot.mixins, contains(results.nameToIndex['Mixin1']));
      expect(results.pivot.mixins, contains(results.nameToIndex['Mixin2']));
      expect(results.getItem('Object').mixins, isEmpty);
      expect(results.getItem('Base').mixins, isEmpty);
      expect(results.getItem('Mixin1').mixins, isEmpty);
      expect(results.getItem('Mixin2').mixins, isEmpty);
    });
  }

  Future<void> getTypeHierarchy_subclasses() {
    var text = r'''
class Base {}
class Pivot /* target */ extends Base {}
class Sub1 extends Pivot {}
class Sub2 extends Pivot {}
class Sub2a extends Sub2 {}
''';
    return typeHierarchyTest(text).then((HierarchyResults results) {
      expect(results.items, hasLength(6));
      expect(results.pivot.subclasses, hasLength(2));
      expect(results.pivot.subclasses, contains(results.nameToIndex['Sub1']));
      expect(results.pivot.subclasses, contains(results.nameToIndex['Sub2']));
      expect(results.getItem('Object').subclasses, isEmpty);
      expect(results.getItem('Base').subclasses, isEmpty);
      expect(results.getItem('Sub1').subclasses, isEmpty);
      expect(results.getItem('Sub2').subclasses,
          equals([results.nameToIndex['Sub2a']]));
      expect(results.getItem('Sub2a').subclasses, isEmpty);
    });
  }

  Future<void> getTypeHierarchy_superclass() {
    var text = r'''
class Base1 {}
class Base2 extends Base1 {}
class Pivot /* target */ extends Base2 {}
''';
    return typeHierarchyTest(text).then((HierarchyResults results) {
      expect(results.items, hasLength(4));
      expect(results.getItem('Object').superclass, isNull);
      expect(results.getItem('Base1').superclass,
          equals(results.nameToIndex['Object']));
      expect(results.getItem('Base2').superclass,
          equals(results.nameToIndex['Base1']));
      expect(results.getItem('Pivot').superclass,
          equals(results.nameToIndex['Base2']));
    });
  }

  Future<void> test_getTypeHierarchy() async {
    pathname = sourcePath('test.dart');
    // Write a dummy file which will be overridden by tests using
    // [sendAnalysisUpdateContent].
    writeFile(pathname, '// dummy');
    await standardAnalysisSetup();

    // Run all the getTypeHierarchy tests at once so that the server can take
    // advantage of incremental analysis and the test doesn't time out.
    await getTypeHierarchy_classElement();
    await getTypeHierarchy_displayName();
    await getTypeHierarchy_memberElement();
    await getTypeHierarchy_superclass();
    await getTypeHierarchy_interfaces();
    await getTypeHierarchy_mixins();
    await getTypeHierarchy_subclasses();
    await getTypeHierarchy_badTarget();
    await getTypeHierarchy_functionTarget();
  }

  Future<HierarchyResults> typeHierarchyTest(String text) async {
    var results = (await typeHierarchyTestNullable(text))!;
    return results;
  }

  Future<HierarchyResults?> typeHierarchyTestNullable(String text) async {
    var offset = text.indexOf(' /* target */') - 1;
    await sendAnalysisUpdateContent({pathname: AddContentOverlay(text)});
    await analysisFinished;
    var result = await sendSearchGetTypeHierarchy(pathname, offset);

    var hierarchyItems = result.hierarchyItems;
    if (hierarchyItems == null) {
      return null;
    }

    return HierarchyResults(hierarchyItems);
  }
}

/// Results of a getTypeHierarchy request, processed for easier testing.
class HierarchyResults {
  /// The list of hierarchy items from the result.
  List<TypeHierarchyItem> items;

  /// The first hierarchy item from the result, which represents the pivot
  /// class.
  final TypeHierarchyItem pivot;

  /// A map from element name to item index.
  final Map<String, int> nameToIndex = {};

  /// Create a [HierarchyResults] object based on the result from a
  /// getTypeHierarchy request.
  HierarchyResults(this.items) : pivot = items[0] {
    for (var i = 0; i < items.length; i++) {
      nameToIndex[items[i].classElement.name] = i;
    }
  }

  /// Get an item by class name.
  TypeHierarchyItem getItem(String name) {
    var index = nameToIndex[name];
    if (index != null) {
      return items[index];
    } else {
      fail('Class $name not found in hierarchy results');
    }
  }
}
