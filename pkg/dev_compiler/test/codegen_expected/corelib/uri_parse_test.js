dart_library.library('corelib/uri_parse_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_parse_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_parse_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfUri = () => (JSArrayOfUri = dart.constFn(_interceptors.JSArray$(core.Uri)))();
  let dynamicAnddynamicAnddynamic__Tovoid = () => (dynamicAnddynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  uri_parse_test.testUriCombi = function() {
    let schemes = JSArrayOfString().of(["", "file", "ws", "ftp"]);
    let fragments = JSArrayOfString().of(["", "#", "#f", "#fragment", "#l:?/"]);
    let queries = JSArrayOfString().of(["", "?", "?q", "?query", "?q:/"]);
    let paths = JSArrayOfString().of(["/", "/x", "/x/y", "/x/y/", "/x:y", "x", "x/y", "x/y/"]);
    let userInfos = JSArrayOfString().of(["", "x", "xxx", "x:4", "xxx:444", "x:4:x"]);
    let hosts = JSArrayOfString().of(["", "h", "hhh", "h:4", "hhh:444", "[::1.2.3.4]"]);
    function check(uriString, scheme, fragment, query, path, user, host) {
      for (let uri of JSArrayOfUri().of([core.Uri.parse(core.String._check(uriString)), core.Uri.parse(dart.str`>𐀀>${uriString}<𐀀<`, 4, core.int._check(dart.dsend(dart.dload(uriString, 'length'), '+', 4))), core.Uri.parse(dart.str`http://example.com/${uriString}#?:/[]"`, 19, core.int._check(dart.dsend(dart.dload(uriString, 'length'), '+', 19))), core.Uri.parse(core.String._check(dart.dsend(uriString, '*', 3)), core.int._check(dart.dload(uriString, 'length')), core.int._check(dart.dsend(dart.dload(uriString, 'length'), '*', 2)))])) {
        let name = dart.str`${uriString} -> ${uri}`;
        expect$.Expect.equals(scheme, uri.scheme, name);
        let uriFragment = uri.fragment;
        if (dart.test(dart.dsend(fragment, 'startsWith', '#'))) uriFragment = dart.str`#${uriFragment}`;
        expect$.Expect.equals(fragment, uriFragment, name);
        let uriQuery = uri.query;
        if (dart.test(dart.dsend(query, 'startsWith', '?'))) uriQuery = dart.str`?${uriQuery}`;
        expect$.Expect.equals(query, uriQuery, name);
        expect$.Expect.equals(path, uri.path, name);
        expect$.Expect.equals(user, uri.userInfo, name);
        let uriHost = uri.host;
        if (dart.test(dart.dsend(host, 'startsWith', "["))) uriHost = dart.str`[${uriHost}]`;
        if (uri.port != 0) {
          uriHost = dart.notNull(uriHost) + dart.str`:${uri.port}`;
        }
        expect$.Expect.equals(host, uriHost, name);
      }
    }
    dart.fn(check, dynamicAnddynamicAnddynamic__Tovoid());
    for (let scheme of schemes) {
      for (let fragment of fragments) {
        for (let query of queries) {
          for (let path of paths) {
            if (scheme == "file" && !dart.test(path[dartx.startsWith]('/'))) continue;
            for (let user of userInfos) {
              for (let host of hosts) {
                let auth = host;
                let s = scheme;
                if (dart.test(user[dartx.isNotEmpty])) auth = dart.str`${user}@${auth}`;
                if (dart.test(auth[dartx.isNotEmpty])) auth = dart.str`//${auth}`;
                if (dart.test(auth[dartx.isNotEmpty]) && !dart.test(path[dartx.startsWith]('/'))) continue;
                check(dart.str`${scheme}${dart.test(scheme[dartx.isEmpty]) ? "" : ":"}` + dart.str`${auth}${path}${query}${fragment}`, scheme, fragment, query, path, user, host);
              }
            }
          }
        }
      }
    }
  };
  dart.fn(uri_parse_test.testUriCombi, VoidTovoid());
  uri_parse_test.main = function() {
    uri_parse_test.testUriCombi();
  };
  dart.fn(uri_parse_test.main, VoidTovoid());
  // Exports:
  exports.uri_parse_test = uri_parse_test;
});
