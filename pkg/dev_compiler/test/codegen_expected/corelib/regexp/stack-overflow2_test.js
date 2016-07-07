dart_library.library('corelib/regexp/stack-overflow2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__stack$45overflow2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const stack$45overflow2_test = Object.create(null);
  const v8_regexp_utils = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamic__Tovoid = () => (dynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String])))();
  let dynamic__Tovoid = () => (dynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String])))();
  let dynamic__Tovoid$ = () => (dynamic__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.num])))();
  let dynamicAnddynamicAndnumTovoid = () => (dynamicAnddynamicAndnumTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, core.num])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let StringAndRegExpToMatch = () => (StringAndRegExpToMatch = dart.constFn(dart.definiteFunctionType(core.Match, [core.String, core.RegExp])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let StringAndRegExpToListOfString = () => (StringAndRegExpToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [core.String, core.RegExp])))();
  stack$45overflow2_test.main = function() {
    let res149 = core.RegExp.new("(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\d+(?:\\s|$))(\\w+)\\s+(\\270)", {caseSensitive: false});
    v8_regexp_utils.assertToStringEquals("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256 257 258 259 260 261 262 263 264 265 266 267 268 269 ABC ABC,1 ,2 ,3 ,4 ,5 ,6 ,7 ,8 ,9 ,10 ,11 ,12 ,13 ,14 ,15 ,16 ,17 ,18 ,19 ,20 ,21 ,22 ,23 ,24 ,25 ,26 ,27 ,28 ,29 ,30 ,31 ,32 ,33 ,34 ,35 ,36 ,37 ,38 ,39 ,40 ,41 ,42 ,43 ,44 ,45 ,46 ,47 ,48 ,49 ,50 ,51 ,52 ,53 ,54 ,55 ,56 ,57 ,58 ,59 ,60 ,61 ,62 ,63 ,64 ,65 ,66 ,67 ,68 ,69 ,70 ,71 ,72 ,73 ,74 ,75 ,76 ,77 ,78 ,79 ,80 ,81 ,82 ,83 ,84 ,85 ,86 ,87 ,88 ,89 ,90 ,91 ,92 ,93 ,94 ,95 ,96 ,97 ,98 ,99 ,100 ,101 ,102 ,103 ,104 ,105 ,106 ,107 ,108 ,109 ,110 ,111 ,112 ,113 ,114 ,115 ,116 ,117 ,118 ,119 ,120 ,121 ,122 ,123 ,124 ,125 ,126 ,127 ,128 ,129 ,130 ,131 ,132 ,133 ,134 ,135 ,136 ,137 ,138 ,139 ,140 ,141 ,142 ,143 ,144 ,145 ,146 ,147 ,148 ,149 ,150 ,151 ,152 ,153 ,154 ,155 ,156 ,157 ,158 ,159 ,160 ,161 ,162 ,163 ,164 ,165 ,166 ,167 ,168 ,169 ,170 ,171 ,172 ,173 ,174 ,175 ,176 ,177 ,178 ,179 ,180 ,181 ,182 ,183 ,184 ,185 ,186 ,187 ,188 ,189 ,190 ,191 ,192 ,193 ,194 ,195 ,196 ,197 ,198 ,199 ,200 ,201 ,202 ,203 ,204 ,205 ,206 ,207 ,208 ,209 ,210 ,211 ,212 ,213 ,214 ,215 ,216 ,217 ,218 ,219 ,220 ,221 ,222 ,223 ,224 ,225 ,226 ,227 ,228 ,229 ,230 ,231 ,232 ,233 ,234 ,235 ,236 ,237 ,238 ,239 ,240 ,241 ,242 ,243 ,244 ,245 ,246 ,247 ,248 ,249 ,250 ,251 ,252 ,253 ,254 ,255 ,256 ,257 ,258 ,259 ,260 ,261 ,262 ,263 ,264 ,265 ,266 ,267 ,268 ,269 ,ABC,ABC", res149.firstMatch("O900 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256 257 258 259 260 261 262 263 264 265 266 267 268 269 ABC ABC"), 242);
  };
  dart.fn(stack$45overflow2_test.main, VoidTovoid$());
  v8_regexp_utils.assertEquals = function(actual, expected, message) {
    if (message === void 0) message = null;
    expect$.Expect.equals(actual, expected, message);
  };
  dart.fn(v8_regexp_utils.assertEquals, dynamicAnddynamic__Tovoid());
  v8_regexp_utils.assertTrue = function(actual, message) {
    if (message === void 0) message = null;
    expect$.Expect.isTrue(actual, message);
  };
  dart.fn(v8_regexp_utils.assertTrue, dynamic__Tovoid());
  v8_regexp_utils.assertFalse = function(actual, message) {
    if (message === void 0) message = null;
    expect$.Expect.isFalse(actual, message);
  };
  dart.fn(v8_regexp_utils.assertFalse, dynamic__Tovoid());
  v8_regexp_utils.assertThrows = function(fn, testid) {
    if (testid === void 0) testid = null;
    expect$.Expect.throws(VoidTovoid()._check(fn), null, dart.str`Test ${testid}`);
  };
  dart.fn(v8_regexp_utils.assertThrows, dynamic__Tovoid$());
  v8_regexp_utils.assertNull = function(actual, testid) {
    if (testid === void 0) testid = null;
    expect$.Expect.isNull(actual, dart.str`Test ${testid}`);
  };
  dart.fn(v8_regexp_utils.assertNull, dynamic__Tovoid$());
  v8_regexp_utils.assertToStringEquals = function(str, match, testid) {
    let actual = [];
    for (let i = 0; i <= dart.notNull(core.num._check(dart.dload(match, 'groupCount'))); i++) {
      let g = dart.dsend(match, 'group', i);
      actual[dartx.add](g == null ? "" : g);
    }
    expect$.Expect.equals(str, actual[dartx.join](","), dart.str`Test ${testid}`);
  };
  dart.fn(v8_regexp_utils.assertToStringEquals, dynamicAnddynamicAndnumTovoid());
  v8_regexp_utils.shouldBeTrue = function(actual) {
    expect$.Expect.isTrue(actual);
  };
  dart.fn(v8_regexp_utils.shouldBeTrue, dynamicTovoid());
  v8_regexp_utils.shouldBeFalse = function(actual) {
    expect$.Expect.isFalse(actual);
  };
  dart.fn(v8_regexp_utils.shouldBeFalse, dynamicTovoid());
  v8_regexp_utils.shouldBeNull = function(actual) {
    expect$.Expect.isNull(actual);
  };
  dart.fn(v8_regexp_utils.shouldBeNull, dynamicTovoid());
  v8_regexp_utils.shouldBe = function(actual, expected, message) {
    if (message === void 0) message = null;
    if (expected == null) {
      expect$.Expect.isNull(actual, message);
    } else {
      expect$.Expect.equals(dart.dload(expected, 'length'), dart.dsend(dart.dload(actual, 'groupCount'), '+', 1));
      for (let i = 0; i <= dart.notNull(core.num._check(dart.dload(actual, 'groupCount'))); i++) {
        expect$.Expect.equals(dart.dindex(expected, i), dart.dsend(actual, 'group', i), message);
      }
    }
  };
  dart.fn(v8_regexp_utils.shouldBe, dynamicAnddynamic__Tovoid());
  v8_regexp_utils.firstMatch = function(str, pattern) {
    return pattern.firstMatch(str);
  };
  dart.fn(v8_regexp_utils.firstMatch, StringAndRegExpToMatch());
  v8_regexp_utils.allStringMatches = function(str, pattern) {
    return pattern.allMatches(str)[dartx.map](core.String)(dart.fn(m => m.group(0), MatchToString()))[dartx.toList]();
  };
  dart.fn(v8_regexp_utils.allStringMatches, StringAndRegExpToListOfString());
  v8_regexp_utils.description = function(str) {
  };
  dart.fn(v8_regexp_utils.description, dynamicTovoid());
  // Exports:
  exports.stack$45overflow2_test = stack$45overflow2_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
