dart_library.library('lib/html/js_function_getter_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__js_function_getter_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const js_function_getter_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  js_function_getter_test._injectJs = function() {
    html.document[dartx.body][dartx.append]((() => {
      let _ = html.ScriptElement.new();
      _[dartx.type] = 'text/javascript';
      _[dartx.innerHtml] = "  var bar = { };\n\n  bar.instanceMember = function() {\n    if (this !== bar) {\n      throw 'Unexpected this!';\n    }\n    return arguments.length;\n  };\n\n  bar.staticMember = function() {\n    return arguments.length * 2;\n  };\n\n  bar.dynamicStatic = function() {\n    return arguments.length;\n  };\n\n  bar.add = function(a, b) {\n    return a + b;\n  };\n\n  var foo = { 'bar' : bar };\n";
      return _;
    })());
  };
  dart.fn(js_function_getter_test._injectJs, VoidTodynamic());
  js_function_getter_test.AddFn = dart.typedef('AddFn', () => dart.functionType(core.int, [core.int, core.int]));
  js_function_getter_test.main = function() {
    js_function_getter_test._injectJs();
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('call getter as function', dart.fn(() => {
      unittest$.test('member function', dart.fn(() => {
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'instanceMember'), src__matcher__core_matchers.equals(0));
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'instanceMember', 0), src__matcher__core_matchers.equals(1));
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'instanceMember', 0, 0), src__matcher__core_matchers.equals(2));
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'instanceMember', 0, 0, 0, 0, 0, 0), src__matcher__core_matchers.equals(6));
        let instanceMember = dart.global.foo.bar.instanceMember;
        src__matcher__expect.expect(dart.fn(() => dart.dcall(instanceMember), VoidTodynamic()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => dart.dcall(instanceMember, 0), VoidTodynamic()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => dart.dcall(instanceMember, 0, 0), VoidTodynamic()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => dart.dcall(instanceMember, 0, 0, 0, 0, 0, 0), VoidTodynamic()), src__matcher__throws_matcher.throws);
      }, VoidTodynamic()));
      unittest$.test('static function', dart.fn(() => {
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'staticMember'), src__matcher__core_matchers.equals(0));
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'staticMember', 0), src__matcher__core_matchers.equals(2));
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'staticMember', 0, 0), src__matcher__core_matchers.equals(4));
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'staticMember', 0, 0, 0, 0, 0, 0), src__matcher__core_matchers.equals(12));
        let staticMember = dart.global.foo.bar.staticMember;
        src__matcher__expect.expect(dart.dcall(staticMember), src__matcher__core_matchers.equals(0));
        src__matcher__expect.expect(dart.dcall(staticMember, 0), src__matcher__core_matchers.equals(2));
        src__matcher__expect.expect(dart.dcall(staticMember, 0, 0), src__matcher__core_matchers.equals(4));
        src__matcher__expect.expect(dart.dcall(staticMember, 0, 0, 0, 0, 0, 0), src__matcher__core_matchers.equals(12));
      }, VoidTodynamic()));
      unittest$.test('static dynamicStatic', dart.fn(() => {
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'dynamicStatic'), src__matcher__core_matchers.equals(0));
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'dynamicStatic', 0), src__matcher__core_matchers.equals(1));
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'dynamicStatic', 0, 0), src__matcher__core_matchers.equals(2));
        src__matcher__expect.expect(dart.dsend(dart.global.foo.bar, 'dynamicStatic', 0, 0, 0, 0, 0, 0), src__matcher__core_matchers.equals(6));
        let dynamicStatic = dart.global.foo.bar.dynamicStatic;
        src__matcher__expect.expect(dart.dcall(dynamicStatic), src__matcher__core_matchers.equals(0));
        src__matcher__expect.expect(dart.dcall(dynamicStatic, 0), src__matcher__core_matchers.equals(1));
        src__matcher__expect.expect(dart.dcall(dynamicStatic, 0, 0), src__matcher__core_matchers.equals(2));
        src__matcher__expect.expect(dart.dcall(dynamicStatic, 0, 0, 0, 0, 0, 0), src__matcher__core_matchers.equals(6));
      }, VoidTodynamic()));
      unittest$.test('typedef function', dart.fn(() => {
        src__matcher__expect.expect(dart.global.foo.bar.add(4, 5), src__matcher__core_matchers.equals(9));
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(js_function_getter_test.main, VoidTodynamic());
  // Exports:
  exports.js_function_getter_test = js_function_getter_test;
});
