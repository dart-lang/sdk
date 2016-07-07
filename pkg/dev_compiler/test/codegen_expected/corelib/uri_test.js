dart_library.library('corelib/uri_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfUri = () => (JSArrayOfUri = dart.constFn(_interceptors.JSArray$(core.Uri)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let StringAndboolTodynamic = () => (StringAndboolTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.bool])))();
  let StringAndStringTodynamic = () => (StringAndStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.String])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let StringAndStringAndString__Todynamic = () => (StringAndStringAndString__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.String, core.String, core.String])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndStringTovoid = () => (StringAndStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, core.String])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTovoid = () => (dynamicAnddynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidToUri = () => (VoidToUri = dart.constFn(dart.definiteFunctionType(core.Uri, [])))();
  let UriToString = () => (UriToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Uri])))();
  uri_test.testUri = function(uriText, isAbsolute) {
    let uri = core.Uri.parse(uriText);
    expect$.Expect.equals(isAbsolute, uri.isAbsolute);
    expect$.Expect.stringEquals(uriText, dart.toString(uri));
    let uri2 = core.Uri.parse(uriText);
    expect$.Expect.equals(uri, uri2);
    expect$.Expect.equals(dart.hashCode(uri), dart.hashCode(uri2));
    if (dart.test(uri.hasFragment)) {
      expect$.Expect.equals(core.Uri.parse(uriText[dartx.substring](0, uriText[dartx.indexOf]('#'))), uri.removeFragment());
    } else {
      expect$.Expect.equals(uri, core.Uri.parse(dart.notNull(uriText) + "#fragment").removeFragment());
    }
  };
  dart.fn(uri_test.testUri, StringAndboolTodynamic());
  uri_test.testEncodeDecode = function(orig, encoded) {
    let e = core.Uri.encodeFull(orig);
    expect$.Expect.stringEquals(encoded, e);
    let d = core.Uri.decodeFull(encoded);
    expect$.Expect.stringEquals(orig, d);
  };
  dart.fn(uri_test.testEncodeDecode, StringAndStringTodynamic());
  uri_test.testEncodeDecodeComponent = function(orig, encoded) {
    let e = core.Uri.encodeComponent(orig);
    expect$.Expect.stringEquals(encoded, e);
    let d = core.Uri.decodeComponent(encoded);
    expect$.Expect.stringEquals(orig, d);
  };
  dart.fn(uri_test.testEncodeDecodeComponent, StringAndStringTodynamic());
  uri_test.testEncodeDecodeQueryComponent = function(orig, encodedUTF8, encodedLatin1, encodedAscii) {
    let e = null, d = null;
    e = core.Uri.encodeQueryComponent(orig);
    expect$.Expect.stringEquals(encodedUTF8, core.String._check(e));
    d = core.Uri.decodeQueryComponent(encodedUTF8);
    expect$.Expect.stringEquals(orig, core.String._check(d));
    e = core.Uri.encodeQueryComponent(orig, {encoding: convert.UTF8});
    expect$.Expect.stringEquals(encodedUTF8, core.String._check(e));
    d = core.Uri.decodeQueryComponent(encodedUTF8, {encoding: convert.UTF8});
    expect$.Expect.stringEquals(orig, core.String._check(d));
    e = core.Uri.encodeQueryComponent(orig, {encoding: convert.LATIN1});
    expect$.Expect.stringEquals(encodedLatin1, core.String._check(e));
    d = core.Uri.decodeQueryComponent(encodedLatin1, {encoding: convert.LATIN1});
    expect$.Expect.stringEquals(orig, core.String._check(d));
    if (encodedAscii != null) {
      e = core.Uri.encodeQueryComponent(orig, {encoding: convert.ASCII});
      expect$.Expect.stringEquals(encodedAscii, core.String._check(e));
      d = core.Uri.decodeQueryComponent(encodedAscii, {encoding: convert.ASCII});
      expect$.Expect.stringEquals(orig, core.String._check(d));
    } else {
      expect$.Expect.throws(dart.fn(() => core.Uri.encodeQueryComponent(orig, {encoding: convert.ASCII}), VoidToString()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    }
  };
  dart.fn(uri_test.testEncodeDecodeQueryComponent, StringAndStringAndString__Todynamic());
  uri_test.testUriPerRFCs = function() {
    let urisSample = "http://a/b/c/d;p?q";
    let base = core.Uri.parse(urisSample);
    function testResolve(expect, relative) {
      expect$.Expect.stringEquals(core.String._check(expect), dart.toString(base.resolve(core.String._check(relative))));
    }
    dart.fn(testResolve, dynamicAnddynamicTodynamic());
    testResolve("g:h", "g:h");
    testResolve("http://a/b/c/g", "g");
    testResolve("http://a/b/c/g", "./g");
    testResolve("http://a/b/c/g/", "g/");
    testResolve("http://a/g", "/g");
    testResolve("http://g", "//g");
    testResolve("http://a/b/c/d;p?y", "?y");
    testResolve("http://a/b/c/g?y", "g?y");
    testResolve("http://a/b/c/d;p?q#s", "#s");
    testResolve("http://a/b/c/g#s", "g#s");
    testResolve("http://a/b/c/g?y#s", "g?y#s");
    testResolve("http://a/b/c/;x", ";x");
    testResolve("http://a/b/c/g;x", "g;x");
    testResolve("http://a/b/c/g;x?y#s", "g;x?y#s");
    testResolve("http://a/b/c/d;p?q", "");
    testResolve("http://a/b/c/", ".");
    testResolve("http://a/b/c/", "./");
    testResolve("http://a/b/", "..");
    testResolve("http://a/b/", "../");
    testResolve("http://a/b/g", "../g");
    testResolve("http://a/", "../..");
    testResolve("http://a/", "../../");
    testResolve("http://a/g", "../../g");
    testResolve("http://a/g", "../../../g");
    testResolve("http://a/g", "../../../../g");
    testResolve("http://a/g", "/./g");
    testResolve("http://a/g", "/../g");
    testResolve("http://a/b/c/g.", "g.");
    testResolve("http://a/b/c/.g", ".g");
    testResolve("http://a/b/c/g..", "g..");
    testResolve("http://a/b/c/..g", "..g");
    testResolve("http://a/b/g", "./../g");
    testResolve("http://a/b/c/g/", "./g/.");
    testResolve("http://a/b/c/g/h", "g/./h");
    testResolve("http://a/b/c/h", "g/../h");
    testResolve("http://a/b/c/g;x=1/y", "g;x=1/./y");
    testResolve("http://a/b/c/y", "g;x=1/../y");
    testResolve("http://a/b/c/g?y/./x", "g?y/./x");
    testResolve("http://a/b/c/g?y/../x", "g?y/../x");
    testResolve("http://a/b/c/g#s/./x", "g#s/./x");
    testResolve("http://a/b/c/g#s/../x", "g#s/../x");
    testResolve("http:g", "http:g");
    testResolve("http://a/b/g;p/h;s", "../g;p/h;s");
    base = core.Uri.parse("a/b/c?_#_");
    testResolve("a/b/g?q#f", "g?q#f");
    testResolve("../", "../../..");
    testResolve("a/b/", ".");
    testResolve("c", "../../c");
    base = core.Uri.parse("s:a/b");
    testResolve("s:/c", "../c");
  };
  dart.fn(uri_test.testUriPerRFCs, VoidTodynamic());
  uri_test.testResolvePath = function(expected, path) {
    expect$.Expect.equals(expected, core.Uri.new({path: '/'}).resolveUri(core.Uri.new({path: path})).path);
    expect$.Expect.equals(dart.str`http://localhost${expected}`, dart.toString(core.Uri.parse("http://localhost").resolveUri(core.Uri.new({path: path}))));
  };
  dart.fn(uri_test.testResolvePath, StringAndStringTovoid());
  uri_test.ALPHA = "abcdefghijklmnopqrstuvwxuzABCDEFGHIJKLMNOPQRSTUVWXUZ";
  uri_test.DIGIT = "0123456789";
  uri_test.PERCENT_ENCODED = "%00%ff";
  uri_test.SUBDELIM = "!$&'()*+,;=";
  uri_test.SCHEMECHAR = dart.str`${uri_test.ALPHA}${uri_test.DIGIT}+-.`;
  uri_test.UNRESERVED = dart.str`${uri_test.ALPHA}${uri_test.DIGIT}-._~`;
  uri_test.REGNAMECHAR = dart.str`${uri_test.UNRESERVED}${uri_test.SUBDELIM}${uri_test.PERCENT_ENCODED}`;
  uri_test.USERINFOCHAR = dart.str`${uri_test.REGNAMECHAR}:`;
  uri_test.PCHAR_NC = dart.str`${uri_test.UNRESERVED}${uri_test.SUBDELIM}${uri_test.PERCENT_ENCODED}@`;
  uri_test.PCHAR = dart.str`${uri_test.PCHAR_NC}:`;
  uri_test.QUERYCHAR = dart.str`${uri_test.PCHAR}/?`;
  uri_test.testValidCharacters = function() {
    for (let scheme of JSArrayOfString().of(["", dart.str`${uri_test.SCHEMECHAR}${uri_test.SCHEMECHAR}:`])) {
      for (let userinfo of JSArrayOfString().of(["", "@", dart.str`${uri_test.USERINFOCHAR}${uri_test.USERINFOCHAR}@`, dart.str`${uri_test.USERINFOCHAR}:${uri_test.DIGIT}@`])) {
        for (let host of JSArrayOfString().of(["", dart.str`${uri_test.REGNAMECHAR}${uri_test.REGNAMECHAR}`, "255.255.255.256", "[ffff::ffff:ffff]", "[ffff::255.255.255.255]"])) {
          for (let port of JSArrayOfString().of(["", ":", dart.str`:${uri_test.DIGIT}${uri_test.DIGIT}`])) {
            let auth = dart.str`${userinfo}${host}${port}`;
            if (dart.test(auth[dartx.isNotEmpty])) auth = dart.str`//${auth}`;
            let paths = JSArrayOfString().of(["", "/", dart.str`/${uri_test.PCHAR}`, dart.str`/${uri_test.PCHAR}/`]);
            if (dart.test(auth[dartx.isNotEmpty])) {
              paths[dartx.add](dart.str`//${uri_test.PCHAR}`);
            } else {
              if (dart.test(scheme[dartx.isEmpty])) {
                paths[dartx.add](uri_test.PCHAR_NC);
                paths[dartx.add](dart.str`${uri_test.PCHAR_NC}/${uri_test.PCHAR}`);
                paths[dartx.add](dart.str`${uri_test.PCHAR_NC}/${uri_test.PCHAR}/`);
              } else {
                paths[dartx.add](uri_test.PCHAR);
                paths[dartx.add](dart.str`${uri_test.PCHAR}/${uri_test.PCHAR}`);
                paths[dartx.add](dart.str`${uri_test.PCHAR}/${uri_test.PCHAR}/`);
              }
            }
            for (let path of paths) {
              for (let query of JSArrayOfString().of(["", "?", dart.str`?${uri_test.QUERYCHAR}`])) {
                for (let fragment of JSArrayOfString().of(["", "#", dart.str`#${uri_test.QUERYCHAR}`])) {
                  let uri = dart.str`${scheme}${auth}${path}${query}${fragment}`;
                  let result = core.Uri.parse(uri);
                }
              }
            }
          }
        }
      }
    }
  };
  dart.fn(uri_test.testValidCharacters, VoidTovoid());
  uri_test.testInvalidUrls = function() {
    function checkInvalid(uri) {
      try {
        let result = core.Uri.parse(core.String._check(uri));
        expect$.Expect.fail(dart.str`Invalid URI \`${uri}\` parsed to ${result}\n` + dart.notNull(uri_test.dump(result)));
      } catch (e) {
        if (core.FormatException.is(e)) {
        } else
          throw e;
      }

    }
    dart.fn(checkInvalid, dynamicTovoid());
    checkInvalid("s%41://x.x/");
    checkInvalid("1a://x.x/");
    checkInvalid(".a://x.x/");
    checkInvalid("_:");
    checkInvalid(":");
    function checkInvalidReplaced(uri, invalid, replacement) {
      let source = dart.dsend(uri, 'replaceAll', '{}', invalid);
      let expected = dart.dsend(uri, 'replaceAll', '{}', replacement);
      let result = core.Uri.parse(core.String._check(source));
      expect$.Expect.equals(expected, dart.str`${result}`, dart.str`Source: ${source}\n${uri_test.dump(result)}`);
    }
    dart.fn(checkInvalidReplaced, dynamicAnddynamicAnddynamicTovoid());
    checkInvalidReplaced("http://www.example.org/red%09ros{}#red)", "é", "%C3%A9");
    checkInvalidReplaced("http://r{}sum{}.example.org", "é", "%C3%A9");
    let invalidCharsAndReplacements = JSArrayOfString().of(["ç", "%C3%A7", " ", "%20", '"', "%22", "<>", "%3C%3E", "", "%7F", "ß", "%C3%9F", "İ", "%C4%B0", "%ﬃ", "%25%EF%AC%83", "K", "%E2%84%AA", "%1g", "%251g", "𐀀", "%F0%90%80%80"]);
    for (let i = 0; i < dart.notNull(invalidCharsAndReplacements[dartx.length]); i = i + 2) {
      let invalid = invalidCharsAndReplacements[dartx.get](i);
      let valid = invalidCharsAndReplacements[dartx.get](i + 1);
      checkInvalid("A{}b:///"[dartx.replaceAll]('{}', invalid));
      checkInvalid("{}b:///"[dartx.replaceAll]('{}', invalid));
      checkInvalidReplaced("s://user{}info@x.x/", invalid, valid);
      checkInvalidReplaced("s://reg{}name/", invalid, valid);
      checkInvalid("s://regname:12{}45/"[dartx.replaceAll]("{}", invalid));
      checkInvalidReplaced("s://regname/p{}ath/", invalid, valid);
      checkInvalidReplaced("/p{}ath/", invalid, valid);
      checkInvalidReplaced("p{}ath/", invalid, valid);
      checkInvalidReplaced("s://regname/path/?x{}x", invalid, valid);
      checkInvalidReplaced("s://regname/path/#x{}x", invalid, valid);
      checkInvalidReplaced("s://regname/path/??#x{}x", invalid, valid);
    }
    checkInvalid("s://x@x@x.x/");
    checkInvalid("s://x@x:x/");
    checkInvalid("s://x@x:9:9/");
    checkInvalid("s://x/x#foo#bar");
    checkInvalid("s@://x:9/x?x#x");
    checkInvalid("s://xx]/");
    checkInvalid("s://xx/]");
    checkInvalid("s://xx/?]");
    checkInvalid("s://xx/#]");
    checkInvalid("s:/]");
    checkInvalid("s:/?]");
    checkInvalid("s:/#]");
    checkInvalid("s://ffff::ffff:1234/");
  };
  dart.fn(uri_test.testInvalidUrls, VoidTovoid());
  uri_test.testNormalization = function() {
    let uri = null;
    uri = core.Uri.parse("A:");
    expect$.Expect.equals("a", dart.dload(uri, 'scheme'));
    uri = core.Uri.parse("Z:");
    expect$.Expect.equals("z", dart.dload(uri, 'scheme'));
    uri = core.Uri.parse(dart.str`${uri_test.SCHEMECHAR}:`);
    expect$.Expect.equals(uri_test.SCHEMECHAR[dartx.toLowerCase](), dart.dload(uri, 'scheme'));
    for (let i = 0; i < dart.notNull(uri_test.UNRESERVED[dartx.length]); i++) {
      let char = uri_test.UNRESERVED[dartx.get](i);
      let escape = "%" + dart.notNull(char[dartx.codeUnitAt](0)[dartx.toRadixString](16));
      uri = core.Uri.parse(dart.str`s://xX${escape}xX@yY${escape}yY/zZ${escape}zZ` + dart.str`?vV${escape}vV#wW${escape}wW`);
      expect$.Expect.equals(dart.str`xX${char}xX`, dart.dload(uri, 'userInfo'));
      expect$.Expect.equals(dart.str`yY${char}yY`[dartx.toLowerCase](), dart.dload(uri, 'host'));
      expect$.Expect.equals(dart.str`/zZ${char}zZ`, dart.dload(uri, 'path'));
      expect$.Expect.equals(dart.str`vV${char}vV`, dart.dload(uri, 'query'));
      expect$.Expect.equals(dart.str`wW${char}wW`, dart.dload(uri, 'fragment'));
    }
    for (let escape of JSArrayOfString().of(["%00", "%1f", "%7F", "%fF"])) {
      uri = core.Uri.parse(dart.str`s://xX${escape}xX@yY${escape}yY/zZ${escape}zZ` + dart.str`?vV${escape}vV#wW${escape}wW`);
      let normalizedEscape = escape[dartx.toUpperCase]();
      expect$.Expect.equals(dart.str`xX${normalizedEscape}xX`, dart.dload(uri, 'userInfo'));
      expect$.Expect.equals(dart.str`yy${normalizedEscape}yy`, dart.dload(uri, 'host'));
      expect$.Expect.equals(dart.str`/zZ${normalizedEscape}zZ`, dart.dload(uri, 'path'));
      expect$.Expect.equals(dart.str`vV${normalizedEscape}vV`, dart.dload(uri, 'query'));
      expect$.Expect.equals(dart.str`wW${normalizedEscape}wW`, dart.dload(uri, 'fragment'));
    }
    uri = core.Uri.parse("x://x%61X%41x%41X%61x/");
    expect$.Expect.equals("xaxaxaxax", dart.dload(uri, 'host'));
    uri = core.Uri.parse("x://Xxxxxxxx/");
    expect$.Expect.equals("xxxxxxxx", dart.dload(uri, 'host'));
    uri = core.Uri.parse("x://xxxxxxxX/");
    expect$.Expect.equals("xxxxxxxx", dart.dload(uri, 'host'));
    uri = core.Uri.parse("x://xxxxxxxx%61/");
    expect$.Expect.equals("xxxxxxxxa", dart.dload(uri, 'host'));
    uri = core.Uri.parse("x://%61xxxxxxxx/");
    expect$.Expect.equals("axxxxxxxx", dart.dload(uri, 'host'));
    uri = core.Uri.parse("x://X/");
    expect$.Expect.equals("x", dart.dload(uri, 'host'));
    uri = core.Uri.parse("x://%61/");
    expect$.Expect.equals("a", dart.dload(uri, 'host'));
    uri = core.Uri.new({scheme: "x", path: "//y"});
    expect$.Expect.equals("//y", dart.dload(uri, 'path'));
    expect$.Expect.equals("x:////y", dart.toString(uri));
    uri = core.Uri.new({scheme: "file", path: "//y"});
    expect$.Expect.equals("//y", dart.dload(uri, 'path'));
    expect$.Expect.equals("file:////y", dart.toString(uri));
    uri = core.Uri.new({scheme: "file", path: "/y"});
    expect$.Expect.equals("file:///y", dart.toString(uri));
    uri = core.Uri.new({scheme: "file", path: "y"});
    expect$.Expect.equals("file:///y", dart.toString(uri));
    expect$.Expect.equals("scheme:/", dart.toString(core.Uri.parse("scheme:/")));
    expect$.Expect.equals("scheme:/", core.Uri.new({scheme: "scheme", path: "/"}).toString());
    expect$.Expect.equals("scheme:///?#", dart.toString(core.Uri.parse("scheme:///?#")));
    expect$.Expect.equals("scheme:///#", core.Uri.new({scheme: "scheme", host: "", path: "/", query: "", fragment: ""}).toString());
  };
  dart.fn(uri_test.testNormalization, VoidTovoid());
  uri_test.testReplace = function() {
    let uris = JSArrayOfUri().of([core.Uri.parse(""), core.Uri.parse("a://@:/?#"), core.Uri.parse("a://b@c:4/e/f?g#h"), core.Uri.parse(dart.str`${uri_test.SCHEMECHAR}://${uri_test.USERINFOCHAR}@${uri_test.REGNAMECHAR}:${uri_test.DIGIT}/${uri_test.PCHAR}/${uri_test.PCHAR}` + dart.str`?${uri_test.QUERYCHAR}#${uri_test.QUERYCHAR}`)]);
    for (let uri1 of uris) {
      for (let uri2 of uris) {
        if (core.identical(uri1, uri2)) continue;
        let scheme = uri1.scheme;
        let userInfo = dart.test(uri1.hasAuthority) ? uri1.userInfo : "";
        let host = dart.test(uri1.hasAuthority) ? uri1.host : null;
        let port = dart.test(uri1.hasAuthority) ? uri1.port : 0;
        let path = uri1.path;
        let query = dart.test(uri1.hasQuery) ? uri1.query : null;
        let fragment = dart.test(uri1.hasFragment) ? uri1.fragment : null;
        let tmp1 = uri1;
        function test() {
          let tmp2 = core.Uri.new({scheme: scheme, userInfo: userInfo, host: host, port: port, path: path, query: query == "" ? null : query, queryParameters: query == "" ? dart.map() : null, fragment: fragment});
          expect$.Expect.equals(tmp1, tmp2);
        }
        dart.fn(test, VoidTovoid());
        test();
        scheme = uri2.scheme;
        tmp1 = tmp1.replace({scheme: scheme});
        test();
        if (dart.test(uri2.hasAuthority)) {
          userInfo = uri2.userInfo;
          host = uri2.host;
          port = uri2.port;
          tmp1 = tmp1.replace({userInfo: userInfo, host: host, port: port});
          test();
        }
        path = uri2.path;
        tmp1 = tmp1.replace({path: path});
        test();
        if (dart.test(uri2.hasQuery)) {
          query = uri2.query;
          tmp1 = tmp1.replace({query: query});
          test();
        }
        if (dart.test(uri2.hasFragment)) {
          fragment = uri2.fragment;
          tmp1 = tmp1.replace({fragment: fragment});
          test();
        }
      }
    }
    let uri = core.Uri.parse("/no-authorty/");
    uri = uri.replace({fragment: "fragment"});
    expect$.Expect.isFalse(uri.hasAuthority);
    uri = core.Uri.new({scheme: "foo", path: "bar"});
    uri = uri.replace({queryParameters: dart.map({x: JSArrayOfString().of(["42", "37"]), y: JSArrayOfString().of(["43", "38"])})});
    let params = uri.queryParametersAll;
    expect$.Expect.equals(2, params[dartx.length]);
    expect$.Expect.listEquals(JSArrayOfString().of(["42", "37"]), params[dartx.get]("x"));
    expect$.Expect.listEquals(JSArrayOfString().of(["43", "38"]), params[dartx.get]("y"));
  };
  dart.fn(uri_test.testReplace, VoidTovoid());
  uri_test.main = function() {
    uri_test.testUri("http:", true);
    uri_test.testUri("file:///", true);
    uri_test.testUri("file", false);
    uri_test.testUri("http://user@example.com:8080/fisk?query=89&hest=silas", true);
    uri_test.testUri("http://user@example.com:8080/fisk?query=89&hest=silas#fragment", false);
    expect$.Expect.stringEquals("http://user@example.com/a/b/c?query#fragment", core.Uri.new({scheme: "http", userInfo: "user", host: "example.com", port: 80, path: "/a/b/c", query: "query", fragment: "fragment"}).toString());
    expect$.Expect.stringEquals("/a/b/c/", core.Uri.new({scheme: null, userInfo: null, host: null, port: 0, path: "/a/b/c/", query: null, fragment: null}).toString());
    expect$.Expect.stringEquals("file:///", dart.toString(core.Uri.parse("file:")));
    uri_test.testResolvePath("/a/g", "/a/b/c/./../../g");
    uri_test.testResolvePath("/a/g", "/a/b/c/./../../g");
    uri_test.testResolvePath("/mid/6", "mid/content=5/../6");
    uri_test.testResolvePath("/a/b/e", "a/b/c/d/../../e");
    uri_test.testResolvePath("/a/b/e", "../a/b/c/d/../../e");
    uri_test.testResolvePath("/a/b/e", "./a/b/c/d/../../e");
    uri_test.testResolvePath("/a/b/e", "../a/b/./c/d/../../e");
    uri_test.testResolvePath("/a/b/e", "./a/b/./c/d/../../e");
    uri_test.testResolvePath("/a/b/e/", "./a/b/./c/d/../../e/.");
    uri_test.testResolvePath("/a/b/e/", "./a/b/./c/d/../../e/./.");
    uri_test.testResolvePath("/a/b/e/", "./a/b/./c/d/../../e/././.");
    uri_test.testUriPerRFCs();
    expect$.Expect.stringEquals("http://example.com", core.Uri.parse("http://example.com/a/b/c").origin);
    expect$.Expect.stringEquals("https://example.com", core.Uri.parse("https://example.com/a/b/c").origin);
    expect$.Expect.stringEquals("http://example.com:1234", core.Uri.parse("http://example.com:1234/a/b/c").origin);
    expect$.Expect.stringEquals("https://example.com:1234", core.Uri.parse("https://example.com:1234/a/b/c").origin);
    expect$.Expect.throws(dart.fn(() => core.Uri.parse("http:").origin, VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()), "origin for uri with empty host should fail");
    expect$.Expect.throws(dart.fn(() => core.Uri.new({scheme: "http", userInfo: null, host: "", port: 80, path: "/a/b/c", query: "query", fragment: "fragment"}).origin, VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()), "origin for uri with empty host should fail");
    expect$.Expect.throws(dart.fn(() => core.Uri.new({scheme: null, userInfo: null, host: "", port: 80, path: "/a/b/c", query: "query", fragment: "fragment"}).origin, VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()), "origin for uri with empty scheme should fail");
    expect$.Expect.throws(dart.fn(() => core.Uri.new({scheme: "http", userInfo: null, host: null, port: 80, path: "/a/b/c", query: "query", fragment: "fragment"}).origin, VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()), "origin for uri with empty host should fail");
    expect$.Expect.throws(dart.fn(() => core.Uri.parse("http://:80").origin, VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()), "origin for uri with empty host should fail");
    expect$.Expect.throws(dart.fn(() => core.Uri.parse("file://localhost/test.txt").origin, VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()), "origin for non-http/https uri should fail");
    let s = convert.UTF8.decode(JSArrayOfint().of([240, 144, 128, 128]));
    expect$.Expect.stringEquals("𐀀", s);
    uri_test.testEncodeDecode("A + B", "A%20+%20B");
    uri_test.testEncodeDecode("￾", "%EF%BF%BE");
    uri_test.testEncodeDecode("￿", "%EF%BF%BF");
    uri_test.testEncodeDecode("￾", "%EF%BF%BE");
    uri_test.testEncodeDecode("￿", "%EF%BF%BF");
    uri_test.testEncodeDecode("", "%7F");
    uri_test.testEncodeDecode("", "%C2%80");
    uri_test.testEncodeDecode("ࠀ", "%E0%A0%80");
    let unescapedFull = "abcdefghijklmnopqrstuvwxyz" + "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "0123456789!#$&'()*+,-./:;=?@_~";
    let escapedFull = " \b\t\n\v\f\r" + "" + ' "%<>[\\]^`{|}' + "";
    let escapedTo = "%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F" + "%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F" + "%20%22%25%3C%3E%5B%5C%5D%5E%60%7B%7C%7D%7F";
    uri_test.testEncodeDecode(unescapedFull, unescapedFull);
    uri_test.testEncodeDecode(escapedFull, escapedTo);
    let nonAscii = "-ÿ-Ā-߿-ࠀ-￿-𐀀-􏿿";
    let nonAsciiEncoding = "%C2%80-%C3%BF-%C4%80-%DF%BF-%E0%A0%80-%EF%BF%BF-" + "%F0%90%80%80-%F4%8F%BF%BF";
    uri_test.testEncodeDecode(nonAscii, nonAsciiEncoding);
    uri_test.testEncodeDecode(s, "%F0%90%80%80");
    uri_test.testEncodeDecodeComponent("A + B", "A%20%2B%20B");
    uri_test.testEncodeDecodeComponent("￾", "%EF%BF%BE");
    uri_test.testEncodeDecodeComponent("￿", "%EF%BF%BF");
    uri_test.testEncodeDecodeComponent("￾", "%EF%BF%BE");
    uri_test.testEncodeDecodeComponent("￿", "%EF%BF%BF");
    uri_test.testEncodeDecodeComponent("", "%7F");
    uri_test.testEncodeDecodeComponent("", "%C2%80");
    uri_test.testEncodeDecodeComponent("ࠀ", "%E0%A0%80");
    uri_test.testEncodeDecodeComponent(":/@',;?&=+$", "%3A%2F%40'%2C%3B%3F%26%3D%2B%24");
    uri_test.testEncodeDecodeComponent(s, "%F0%90%80%80");
    uri_test.testEncodeDecodeQueryComponent("A + B", "A+%2B+B", "A+%2B+B", "A+%2B+B");
    uri_test.testEncodeDecodeQueryComponent("æ ø å", "%C3%A6+%C3%B8+%C3%A5", "%E6+%F8+%E5", null);
    uri_test.testEncodeDecodeComponent(nonAscii, nonAsciiEncoding);
    expect$.Expect.throws(dart.fn(() => core.Uri.parse("file://user@password:host/path"), VoidToUri()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
    uri_test.testValidCharacters();
    uri_test.testInvalidUrls();
    uri_test.testNormalization();
    uri_test.testReplace();
  };
  dart.fn(uri_test.main, VoidTodynamic());
  uri_test.dump = function(uri) {
    return dart.str`URI: ${uri}\n` + dart.str`  Scheme:    ${uri.scheme} #${uri.scheme[dartx.length]}\n` + dart.str`  User-info: ${uri.userInfo} #${uri.userInfo[dartx.length]}\n` + dart.str`  Host:      ${uri.host} #${uri.host[dartx.length]}\n` + dart.str`  Port:      ${uri.port}\n` + dart.str`  Path:      ${uri.path} #${uri.path[dartx.length]}\n` + dart.str`  Query:     ${uri.query} #${uri.query[dartx.length]}\n` + dart.str`  Fragment:  ${uri.fragment} #${uri.fragment[dartx.length]}\n`;
  };
  dart.fn(uri_test.dump, UriToString());
  // Exports:
  exports.uri_test = uri_test;
});
