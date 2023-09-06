// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/field_promotability.dart';
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';

main() {
  test('final private field is promotable', () {
    var f = Field('_f', isFinal: true);
    var c = Class(fields: [f]);
    check(_TestFieldPromotability().run([c])).unorderedEquals({});
    check(f.isPossiblyPromotable).isTrue();
  });

  test('final public field is not promotable', () {
    var f = Field('f', isFinal: true);
    var c = Class(fields: [f]);
    // Note that the set returned by `_TestFieldPromotability.run` is just the
    // set of *private* field names that are unpromotable, so even though `f`
    // is not promotable, the returned set is empty.
    check(_TestFieldPromotability().run([c])).unorderedEquals({});
    check(f.isPossiblyPromotable).isFalse();
  });

  test('non-final private field is not promotable', () {
    var f = Field('_f');
    var c = Class(fields: [f]);
    check(_TestFieldPromotability().run([c])).unorderedEquals({'_f'});
    check(f.isPossiblyPromotable).isFalse();
  });

  test('external private final field is not promotable', () {
    var f = Field('_f', isFinal: true, isExternal: true);
    var c = Class(fields: [f]);
    check(_TestFieldPromotability().run([c])).unorderedEquals({'_f'});
    check(f.isPossiblyPromotable).isFalse();
  });

  group('concrete getter renders a private field non-promotable:', () {
    test('in a concrete class', () {
      var c = Class(fields: [Field('_f', isFinal: true)]);
      var d = Class(getters: [Getter('_f')]);
      check(_TestFieldPromotability().run([c, d])).unorderedEquals({'_f'});
    });

    test('in an abstract class', () {
      var c = Class(fields: [Field('_f', isFinal: true)]);
      var d = Class(isAbstract: true, getters: [Getter('_f')]);
      check(_TestFieldPromotability().run([c, d])).unorderedEquals({'_f'});
    });
  });

  test('abstract getter does not render a private field non-promotable', () {
    var f = Field('_f', isFinal: true);
    var c = Class(fields: [f]);
    var d = Class(isAbstract: true, getters: [Getter('_f', isAbstract: true)]);
    check(_TestFieldPromotability().run([c, d])).unorderedEquals({});
    check(f.isPossiblyPromotable).isTrue();
  });

  test('public concrete getter is ignored', () {
    // Since public fields are never promotable, there's no need for the
    // algorithm to keep track of public concrete getters.
    var f = Field('f', isFinal: true);
    var c = Class(fields: [f]);
    var d = Class(getters: [Getter('f')]);
    // Therefore the set returned by `_TestFieldPromotability.run` is empty.
    check(_TestFieldPromotability().run([c, d])).unorderedEquals({});
    check(f.isPossiblyPromotable).isFalse();
  });

  group('unimplemented getter renders a field non-promotable:', () {
    test('induced by getter', () {
      var f = Field('_f', isFinal: true);
      var c = Class(fields: [f]);
      var d =
          Class(isAbstract: true, getters: [Getter('_f', isAbstract: true)]);
      var e = Class(implements: [d]);
      check(_TestFieldPromotability().run([c, d, e])).unorderedEquals({'_f'});
    });

    test('induced by field', () {
      var f = Field('_f', isFinal: true);
      var c = Class(fields: [f]);
      var d = Class(isAbstract: true, fields: [Field('_f', isFinal: true)]);
      var e = Class(implements: [d]);
      check(_TestFieldPromotability().run([c, d, e])).unorderedEquals({'_f'});
    });
  });

  test('unimplemented getter in an abstract class is ok', () {
    var f = Field('_f', isFinal: true);
    var c = Class(fields: [f]);
    var d = Class(isAbstract: true, getters: [Getter('_f', isAbstract: true)]);
    var e = Class(isAbstract: true, implements: [d]);
    check(_TestFieldPromotability().run([c, d, e])).unorderedEquals({});
    check(f.isPossiblyPromotable).isTrue();
  });

  test('unimplemented abstract field renders a field non-promotable:', () {
    var f = Field('_f', isFinal: true);
    var c = Class(fields: [f]);
    var d = Class(
        isAbstract: true,
        fields: [Field('_f', isAbstract: true, isFinal: true)]);
    var e = Class(extendsOrMixesIn: [d]);
    check(_TestFieldPromotability().run([c, d, e])).unorderedEquals({'_f'});
  });

  test('implementations are inherited transitively', () {
    // `e` inherits `f` from `c` via `d`, so no `noSuchMethod` forwarder is
    // needed, and therefore promotion is allowed.
    var f = Field('_f', isFinal: true);
    var c = Class(fields: [f]);
    var d = Class(extendsOrMixesIn: [c]);
    var e = Class(extendsOrMixesIn: [d], implements: [c]);
    check(_TestFieldPromotability().run([c, d, e])).unorderedEquals({});
    check(f.isPossiblyPromotable).isTrue();
  });

  test('interfaces are inherited transitively', () {
    // `e` inherits the interface for `f` from `c` via `d`, so a `noSuchMethod`
    // forwarder is needed, and therefore promotion is not allowed.
    var f = Field('_f', isFinal: true);
    var c = Class(fields: [f]);
    var d = Class(isAbstract: true, implements: [c]);
    var e = Class(implements: [d]);
    check(_TestFieldPromotability().run([c, d, e])).unorderedEquals({'_f'});
  });

  test('class hierarchy circularities are handled', () {
    // Since it's a compile error to have a circularity in the class hierarchy,
    // all we need to check is that the algorithm terminates; we don't check the
    // result.
    var c = Class(extendsOrMixesIn: []);
    var d = Class(extendsOrMixesIn: [c]);
    c.extendsOrMixesIn.add(d);
    var e = Class(extendsOrMixesIn: [d]);
    _TestFieldPromotability().run([c, d, e]);
  });
}

class Class {
  final List<Class> extendsOrMixesIn;
  final List<Class> implements;
  final bool isAbstract;
  final List<Field> fields;
  final List<Getter> getters;

  Class(
      {this.extendsOrMixesIn = const [],
      this.implements = const [],
      this.isAbstract = false,
      this.fields = const [],
      this.getters = const []});
}

class Field {
  final String name;
  final bool isFinal;
  final bool isAbstract;
  final bool isExternal;
  late final bool isPossiblyPromotable;

  Field(this.name,
      {this.isFinal = false, this.isAbstract = false, this.isExternal = false});
}

class Getter {
  final String name;
  final bool isAbstract;

  Getter(this.name, {this.isAbstract = false});
}

class _TestFieldPromotability extends FieldPromotability<Class> {
  @override
  Iterable<Class> getSuperclasses(Class class_,
      {required bool ignoreImplements}) {
    if (ignoreImplements) {
      return class_.extendsOrMixesIn;
    } else {
      return [...class_.extendsOrMixesIn, ...class_.implements];
    }
  }

  Set<String> run(Iterable<Class> classes) {
    // Iterate through all the classes, enums, and mixins in the library,
    // recording the non-synthetic instance fields and getters of each.
    for (var class_ in classes) {
      var classInfo = addClass(class_, isAbstract: class_.isAbstract);
      for (var field in class_.fields) {
        field.isPossiblyPromotable = addField(classInfo, field.name,
            isFinal: field.isFinal,
            isAbstract: field.isAbstract,
            isExternal: field.isExternal);
      }
      for (var getter in class_.getters) {
        addGetter(classInfo, getter.name, isAbstract: getter.isAbstract);
      }
    }

    // Compute the set of field names that are not promotable.
    return computeUnpromotablePrivateFieldNames();
  }
}
