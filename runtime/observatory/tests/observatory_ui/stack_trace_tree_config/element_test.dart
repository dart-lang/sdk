// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/stack_trace_tree_config.dart';

main() {
  StackTraceTreeConfigElement.tag.ensureRegistration();

  group('instantiation', () {
    test('default', () {
      final e = new StackTraceTreeConfigElement();
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.showMode, isTrue);
      expect(e.showDirection, isTrue);
      expect(e.showFilter, isTrue);
      expect(e.filter, equals(''));
      expect(e.mode, equals(ProfileTreeMode.function));
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
    });
    test('showMode', () {
      final e = new StackTraceTreeConfigElement(showMode: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.showMode, isFalse);
      expect(e.showDirection, isTrue);
      expect(e.showFilter, isTrue);
      expect(e.filter, equals(''));
      expect(e.mode, equals(ProfileTreeMode.function));
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
    });
    test('showDirection', () {
      final e = new StackTraceTreeConfigElement(showDirection: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.showMode, isTrue);
      expect(e.showDirection, isFalse);
      expect(e.showFilter, isTrue);
      expect(e.filter, equals(''));
      expect(e.mode, equals(ProfileTreeMode.function));
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
    });
    test('showFilter', () {
      final e = new StackTraceTreeConfigElement(showFilter: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.showMode, isTrue);
      expect(e.showDirection, isTrue);
      expect(e.showFilter, isFalse);
      expect(e.filter, equals(''));
      expect(e.mode, equals(ProfileTreeMode.function));
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
    });
    test('filter', () {
      final filter = 'filter-string';
      final e = new StackTraceTreeConfigElement(filter: filter);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.showMode, isTrue);
      expect(e.showDirection, isTrue);
      expect(e.showFilter, isTrue);
      expect(e.filter, equals(filter));
      expect(e.mode, equals(ProfileTreeMode.function));
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
    });
    test('mode', () {
      final e = new StackTraceTreeConfigElement(mode: ProfileTreeMode.code);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.showMode, isTrue);
      expect(e.showDirection, isTrue);
      expect(e.showFilter, isTrue);
      expect(e.filter, equals(''));
      expect(e.mode, equals(ProfileTreeMode.code));
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
    });
    test('default', () {
      final e = new StackTraceTreeConfigElement(
          direction: M.ProfileTreeDirection.inclusive);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.showMode, isTrue);
      expect(e.showDirection, isTrue);
      expect(e.showFilter, isTrue);
      expect(e.filter, equals(''));
      expect(e.mode, equals(ProfileTreeMode.function));
      expect(e.direction, equals(M.ProfileTreeDirection.inclusive));
    });
  });
  group('elements', () {
    test('created after attachment', () async {
      final e = new StackTraceTreeConfigElement();
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('react to mode change', () async {
      final e = new StackTraceTreeConfigElement();
      document.body.append(e);
      await e.onRendered.first;
      expect(e.mode, equals(ProfileTreeMode.function));
      e.mode = ProfileTreeMode.code;
      await e.onRendered.first;
      expect(e.mode, equals(ProfileTreeMode.code));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('react to direction change', () async {
      final e = new StackTraceTreeConfigElement();
      document.body.append(e);
      await e.onRendered.first;
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
      e.direction = M.ProfileTreeDirection.inclusive;
      await e.onRendered.first;
      expect(e.direction, equals(M.ProfileTreeDirection.inclusive));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('react to filter change', () async {
      final filter = 'filter-string';
      final e = new StackTraceTreeConfigElement();
      document.body.append(e);
      await e.onRendered.first;
      expect(e.filter, equals(''));
      e.filter = filter;
      await e.onRendered.first;
      expect(e.filter, equals(filter));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
  group('events', () {
    test('onModeChange', () async {
      final e = new StackTraceTreeConfigElement();
      document.body.append(e);
      await e.onRendered.first;
      expect(e.mode, equals(ProfileTreeMode.function));
      e.onModeChange.listen(expectAsync((_) {
        expect(e.mode, equals(ProfileTreeMode.code));
      }, count: 1));
      final select = (e.querySelector('.mode-select') as SelectElement);
      select.selectedIndex = select.options.indexOf(
          (select.options.toSet()
            ..removeAll(select.selectedOptions)).toList().first
        );
      select.dispatchEvent(new Event("change"));
      e.remove();
      await e.onRendered.first;
    });
    test('onDirectionChange', () async {
      final e = new StackTraceTreeConfigElement();
      document.body.append(e);
      await e.onRendered.first;
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
      e.onDirectionChange.listen(expectAsync((_) {
        expect(e.direction, equals(M.ProfileTreeDirection.inclusive));
      }, count: 1));
      final select = (e.querySelector('.direction-select') as SelectElement);
      select.selectedIndex = select.options.indexOf(
          (select.options.toSet()
            ..removeAll(select.selectedOptions)).toList().first
        );
      select.dispatchEvent(new Event("change"));
      e.remove();
      await e.onRendered.first;
    });
    test('onFilterChange', () async {
      final e = new StackTraceTreeConfigElement();
      document.body.append(e);
      await e.onRendered.first;
      expect(e.direction, equals(M.ProfileTreeDirection.exclusive));
      e.onFilterChange.listen(expectAsync((_) {
        expect(e.filter, equals('value'));
      }, count: 1));
      var input = (e.querySelector('input') as TextInputElement);
      input.value = 'value';
      input.dispatchEvent(new Event("change"));
      e.remove();
      await e.onRendered.first;
    });
  });
}
