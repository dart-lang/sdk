// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:barback/barback.dart';
import 'package:observe/transform.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useCompactVMConfiguration();

  group('replaces Observable for ChangeNotifier', () {
    _testClause('extends ObservableBase', 'extends ChangeNotifierBase');
    _testClause('extends Base with ObservableMixin',
        'extends Base with ChangeNotifierMixin');
    _testClause('extends Base<T> with ObservableMixin',
        'extends Base<T> with ChangeNotifierMixin');
    _testClause('extends Base with Mixin, ObservableMixin',
        'extends Base with Mixin, ChangeNotifierMixin');
    _testClause('extends Base with ObservableMixin, Mixin',
        'extends Base with ChangeNotifierMixin, Mixin');
    _testClause('extends Base with Mixin<T>, ObservableMixin',
        'extends Base with Mixin<T>, ChangeNotifierMixin');
    _testClause('extends Base with Mixin, ObservableMixin, Mixin2',
        'extends Base with Mixin, ChangeNotifierMixin, Mixin2');
    _testClause('extends ObservableBase implements Interface',
        'extends ChangeNotifierBase implements Interface');
    _testClause('extends ObservableBase implements Interface<T>',
        'extends ChangeNotifierBase implements Interface<T>');
    _testClause('extends Base with ObservableMixin implements Interface',
        'extends Base with ChangeNotifierMixin implements Interface');
    _testClause(
        'extends Base with Mixin, ObservableMixin implements I1, I2',
        'extends Base with Mixin, ChangeNotifierMixin implements I1, I2');
  });

  group('fixes contructor calls ', () {
    _testInitializers('this.a', '(a) : __\$a = a');
    _testInitializers('{this.a}', '({a}) : __\$a = a');
    _testInitializers('[this.a]', '([a]) : __\$a = a');
    _testInitializers('this.a, this.b', '(a, b) : __\$a = a, __\$b = b');
    _testInitializers('{this.a, this.b}', '({a, b}) : __\$a = a, __\$b = b');
    _testInitializers('[this.a, this.b]', '([a, b]) : __\$a = a, __\$b = b');
    _testInitializers('this.a, [this.b]', '(a, [b]) : __\$a = a, __\$b = b');
    _testInitializers('this.a, {this.b}', '(a, {b}) : __\$a = a, __\$b = b');
  });

  for (var annotation in ['observable', 'published']) {
    group('@$annotation full text', () {
      test('with changes', () {
        return _transform(_sampleObservable(annotation)).then(
            (out) => expect(out, _sampleObservableOutput(annotation)));
      });

      test('complex with changes', () {
        return _transform(_complexObservable(annotation)).then(
            (out) => expect(out, _complexObservableOutput(annotation)));
      });

      test('no changes', () {
        var input = 'class A {/*@$annotation annotation to trigger transform */;}';
        return _transform(input).then((output) => expect(output, input));
      });
    });
  }
}

_testClause(String clauses, String expected) {
  test(clauses, () {
    var className = 'MyClass';
    if (clauses.contains('<T>')) className += '<T>';
    var code = '''
      class $className $clauses {
        @observable var field;
      }''';

    return _transform(code).then((output) {
      var classPos = output.indexOf(className) + className.length;
      var actualClauses = output.substring(classPos,
        output.indexOf('{')).trim().replaceAll('  ', ' ');
      expect(actualClauses, expected);
    });
  });
}

_testInitializers(String args, String expected) {
  test(args, () {
    var constructor = 'MyClass(';
    var code = '''
        class MyClass {
          @observable var a;
          @observable var b;
          MyClass($args);
        }''';

    return _transform(code).then((output) {
      var begin = output.indexOf(constructor) + constructor.length - 1;
      var end = output.indexOf(';', begin);
      if (end == -1) end = output.length;
      var init = output.substring(begin, end).trim().replaceAll('  ', ' ');
      expect(init, expected);
    });
  });
}

/** Helper that applies the transform by creating mock assets. */
Future<String> _transform(String code) {
  var id = new AssetId('foo', 'a/b/c.dart');
  var asset = new Asset.fromString(id, code);
  var transformer = new ObservableTransformer();
  return transformer.isPrimary(asset).then((isPrimary) {
    expect(isPrimary, isTrue);
    var transform = new _MockTransform(asset);
    return transformer.apply(transform).then((_) {
      expect(transform.outs, hasLength(1));
      expect(transform.outs[0].id, id);
      return transform.outs.first.readAsString();
    });
  });
}

class _MockTransform implements Transform {
  List<Asset> outs = [];
  Asset _asset;
  TransformLogger logger = new TransformLogger(_mockLogFn);
  Asset get primaryInput => _asset;

  _MockTransform(this._asset);
  Future<Asset> getInput(AssetId id) {
    if (id == primaryInput.id) return new Future.value(primaryInput);
    fail('_MockTransform fail');
  }

  void addOutput(Asset output) {
    outs.add(output);
  }

  readInput(id) => throw new UnimplementedError();
  readInputAsString(id, {encoding}) => throw new UnimplementedError();

  static void _mockLogFn(AssetId asset, LogLevel level, String message,
                         Span span) {
    // Do nothing.
  }
}

String _sampleObservable(String annotation) => '''
library A_foo;
import 'package:observe/observe.dart';

class A extends ObservableBase {
  @$annotation int foo;
  A(this.foo);
}
''';

String _sampleObservableOutput(String annotation) =>
    "library A_foo;\n"
    "import 'package:observe/observe.dart';\n\n"
    "class A extends ChangeNotifierBase {\n"
    "  @reflectable @$annotation int get foo => __\$foo; int __\$foo; "
      "${_makeSetter('int', 'foo')}\n"
    "  A(foo) : __\$foo = foo;\n"
    "}\n";

_makeSetter(type, name) => '@reflectable set $name($type value) { '
    '__\$$name = notifyPropertyChange(#$name, __\$$name, value); }';

String _complexObservable(String annotation) => '''
class Foo extends ObservableBase {
  @$annotation
  @otherMetadata
      Foo
          foo/*D*/= 1, bar =/*A*/2/*B*/,
          quux/*C*/;

  @$annotation var baz;
}
''';

String _complexObservableOutput(String meta) =>
    "class Foo extends ChangeNotifierBase {\n"
    "  @reflectable @$meta\n"
    "  @otherMetadata\n"
    "      Foo\n"
    "          get foo => __\$foo; Foo __\$foo/*D*/= 1; "
        "${_makeSetter('Foo', 'foo')} "
        "@reflectable @$meta @otherMetadata Foo get bar => __\$bar; "
        "Foo __\$bar =/*A*/2/*B*/; ${_makeSetter('Foo', 'bar')}\n"
    "          @reflectable @$meta @otherMetadata Foo get quux => __\$quux; "
        "Foo __\$quux/*C*/; ${_makeSetter('Foo', 'quux')}\n\n"
    "  @reflectable @$meta dynamic get baz => __\$baz; dynamic __\$baz; "
        "${_makeSetter('dynamic', 'baz')}\n"
    "}\n";
