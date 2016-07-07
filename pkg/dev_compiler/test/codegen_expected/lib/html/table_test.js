dart_library.library('lib/html/table_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__table_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const table_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  table_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('createTBody', dart.fn(() => {
      let table = html.TableElement.new();
      let head = table[dartx.createTHead]();
      src__matcher__expect.expect(table[dartx.tHead], head);
      let headerRow = head[dartx.addRow]();
      let headerCell = headerRow[dartx.addCell]();
      headerCell[dartx.text] = 'Header Cell';
      let caption = table[dartx.createCaption]();
      src__matcher__expect.expect(table[dartx.caption], caption);
      let body = table[dartx.createTBody]();
      src__matcher__expect.expect(table[dartx.tBodies][dartx.length], 1);
      src__matcher__expect.expect(table[dartx.tBodies][dartx.get](0), body);
      let bodyRow = body[dartx.addRow]();
      src__matcher__expect.expect(body[dartx.rows][dartx.length], 1);
      src__matcher__expect.expect(body[dartx.rows][dartx.get](0), bodyRow);
      let bodyCell = bodyRow[dartx.addCell]();
      bodyCell[dartx.text] = 'Body Cell';
      src__matcher__expect.expect(bodyRow[dartx.cells][dartx.length], 1);
      src__matcher__expect.expect(bodyRow[dartx.cells][dartx.get](0), bodyCell);
      let foot = table[dartx.createTFoot]();
      src__matcher__expect.expect(table[dartx.tFoot], foot);
      let footerRow = foot[dartx.addRow]();
      src__matcher__expect.expect(foot[dartx.rows][dartx.length], 1);
      src__matcher__expect.expect(foot[dartx.rows][dartx.get](0), footerRow);
      let footerCell = footerRow[dartx.addCell]();
      footerCell[dartx.text] = 'Footer Cell';
      src__matcher__expect.expect(footerRow[dartx.cells][dartx.length], 1);
      src__matcher__expect.expect(footerRow[dartx.cells][dartx.get](0), footerCell);
      let body2 = table[dartx.createTBody]();
      let bodyRow2 = body2[dartx.addRow]();
      let bodyCell2 = bodyRow2[dartx.addCell]();
      bodyCell2[dartx.text] = 'Body Cell2';
      src__matcher__expect.expect(body2[dartx.rows][dartx.length], 1);
      src__matcher__expect.expect(table[dartx.tBodies][dartx.length], 2);
      src__matcher__expect.expect(table[dartx.tBodies][dartx.get](1), body2);
    }, VoidTodynamic()));
  };
  dart.fn(table_test.main, VoidTodynamic());
  // Exports:
  exports.table_test = table_test;
});
