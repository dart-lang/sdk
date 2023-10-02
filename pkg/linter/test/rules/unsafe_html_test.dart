// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnsafeHtmlTest);
  });
}

@reflectiveTest
class UnsafeHtmlTest extends LintRuleTest {
  @override
  String get lintRule => 'unsafe_html';

  test_anchorHref_cascade() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f() {
  AnchorElement()..href = 'foo';
}
''', [
      lint(49, 14),
    ]);
  }

  test_declaration() async {
    await assertNoDiagnostics(r'''
void f() {
  var src = 'foo.js';
}
''');
  }

  test_documentFragmentHtml() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f() {
  DocumentFragment.html('<script>');
}
''', [
      lint(34, 33),
    ]);
  }

  test_dynamicCreateFragment() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  p.createFragment('<script>');
}
''', [
      lint(22, 28),
    ]);
  }

  test_dynamicHrefSetter() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  p.href = 'foo.js';
}
''', [
      lint(22, 17),
    ]);
  }

  test_dynamicOpen() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  p.open('url', 'name');
}
''', [
      lint(22, 21),
    ]);
  }

  test_dynamicSetInnerHtml() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  p.setInnerHtml('<script>');
}
''', [
      lint(22, 26),
    ]);
  }

  test_dynamicSrcdocSetter() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  p.srcdoc = 'foo.js';
}
''', [
      lint(22, 19),
    ]);
  }

  test_dynamicSrcSetter() async {
    await assertDiagnostics(r'''
void f(dynamic p) {
  p.src = 'foo.js';
}
''', [
      lint(22, 16),
    ]);
  }

  test_elementHtml() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f() {
  Element.html('<script>');
}
''', [
      lint(34, 24),
    ]);
  }

  test_embedSrc_assignment() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f(EmbedElement embed) {
  embed.src = 'foo';
}
''', [
      lint(52, 17),
    ]);
  }

  test_headingCreateFragment() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f(HeadingElement heading) {
  heading.createFragment('<script>');
}
''', [
      lint(56, 34),
    ]);
  }

  test_headingCreateFragment_cascade() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f(HeadingElement heading) {
  heading..createFragment('<script>');
}
''', [
      lint(63, 28),
    ]);
  }

  test_headingSetInnerHtml() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f(HeadingElement heading) {
  heading.setInnerHtml('<script>');
}
''', [
      lint(56, 32),
    ]);
  }

  test_iframeSrc_cascade() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f() {
  IFrameElement()..src = 'foo';
}
''', [
      lint(49, 13),
    ]);
  }

  test_iframeSrcdoc_cascade() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f() {
  IFrameElement()..srcdoc = 'foo';
}
''', [
      lint(49, 16),
    ]);
  }

  test_scriptCreateFragment_fromExtension() async {
    await assertDiagnostics(r'''
import 'dart:html';

extension E on ScriptElement {
  void m(String html) => createFragment(html);
}
''', [
      lint(77, 20),
    ]);
  }

  test_scriptSetInnerHtml_fromExtension() async {
    await assertDiagnostics(r'''
import 'dart:html';

extension E on ScriptElement {
  void m(String html) => setInnerHtml(html);
}
''', [
      lint(77, 18),
    ]);
  }

  test_scriptSrc_assignment() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f(ScriptElement script) {
  script.src = 'foo.js';
}
''', [
      lint(54, 21),
    ]);
  }

  test_scriptSrc_cascade() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f(ScriptElement script) {
  script
    ..src = 'foo.js'
    ..type = 'application/javascript';
}
''', [
      lint(65, 16),
    ]);
  }

  test_scriptSrc_cascade_subsequent() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f(ScriptElement script) {
  script
    ..type = 'application/javascript'
    ..src = 'foo.js';
}
''', [
      lint(103, 16),
    ]);
  }

  test_scriptSrc_nullAware() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f(ScriptElement? script) {
  script?.src = 'foo.js';
}
''', [
      lint(55, 22),
    ]);
  }

  test_scriptSrcSetter_fromExtension() async {
    await assertDiagnostics(r'''
import 'dart:html';

extension E on ScriptElement {
  void m(String url) => src = url;
}
''', [
      lint(76, 9),
    ]);
  }

  test_unrelatedCreateFragment() async {
    await assertNoDiagnostics(r'''
class C {
  void createFragment(String s) {}
}
void f(C c) {
  c.createFragment('<script>');
}
''');
  }

  test_unrelatedCreateFragment_fromExtension() async {
    await assertNoDiagnostics(r'''
class C {
  void createFragment(String html) {}
}
extension E on C {
  void m(String html) => createFragment(html);
}
''');
  }

  test_unrelatedHtml() async {
    await assertNoDiagnostics(r'''
class C {
  void html(String s) {}
}
void f(C c) {
  c.html('<script>');
}
''');
  }

  test_unrelatedOpen() async {
    await assertNoDiagnostics(r'''
class C {
  void open(String s, String s2) {}
}
void f(C c) {
  c.open('url', 'name');
}
''');
  }

  test_unrelatedOpen_fromExtension() async {
    await assertNoDiagnostics(r'''
class C {
  void open(String url, String name) {}
}
extension E on C {
  void m(String url, String name) => open(url, name);
}
''');
  }

  test_unrelatedOpen_fromExtensionWithExplicitThis() async {
    await assertNoDiagnostics(r'''
class C {
  void open(String url, String name) {}
}
extension E on C {
  void m(String url, String name) => this.open(url, name);
}
''');
  }

  test_unrelatedSetInnerHtml() async {
    await assertNoDiagnostics(r'''
class C {
  void setInnerHtml(String s) {}
}
void f(C c) {
  c.setInnerHtml('<script>');
}
''');
  }

  test_unrelatedSetInnerHtml_fromExtension() async {
    await assertNoDiagnostics(r'''
class C {
  void setInnerHtml(String html) {}
}
extension E on C {
  void m(String html) => setInnerHtml(html);
}
''');
  }

  test_unrelatedSrcdocSetter() async {
    await assertNoDiagnostics(r'''
class C {
  set srcdoc(String s) {}
}
void f(C c) {
  c.srcdoc = 'foo.js';
}
''');
  }

  test_unrelatedSrcSetter() async {
    await assertNoDiagnostics(r'''
class C {
  set src(String url) {}
}
void f(C c) {
  c.src = 'foo.js';
}
''');
  }

  test_unrelatedSrcSetter_fromExtension() async {
    await assertNoDiagnostics(r'''
class C {
  set src(String url) {}
}
extension E on C {
  void m(String url) => src = url;
}
''');
  }

  test_unrelatedSrcSetter_nullAware() async {
    await assertNoDiagnostics(r'''
class C {
  set src(String s) {}
}
void f(C? c) {
  c?.src = 'foo.js';
}
''');
  }

  test_windowOpen() async {
    await assertDiagnostics(r'''
import 'dart:html';

void f() {
  Window().open('url', 'name');
}
''', [
      lint(34, 28),
    ]);
  }

  test_windowOpen_fromExtension() async {
    await assertDiagnostics(r'''
import 'dart:html';

extension E on Window {
  void m(String url, String name) => open(url, name);
}
''', [
      lint(82, 15),
    ]);
  }
}
