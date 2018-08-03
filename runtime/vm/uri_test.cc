// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/uri.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(ParseUri_WithScheme_NoQueryNoUser) {
  ParsedUri uri;
  EXPECT(ParseUri("foo://example.com:8042/over/there", &uri));
  EXPECT_STREQ("foo", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT_STREQ("example.com", uri.host);
  EXPECT_STREQ("8042", uri.port);
  EXPECT_STREQ("/over/there", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_WithScheme_WithQuery) {
  ParsedUri uri;
  EXPECT(ParseUri("foo://example.com:8042/over/there?name=ferret", &uri));
  EXPECT_STREQ("foo", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT_STREQ("example.com", uri.host);
  EXPECT_STREQ("8042", uri.port);
  EXPECT_STREQ("/over/there", uri.path);
  EXPECT_STREQ("name=ferret", uri.query);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_WithScheme_WithFragment) {
  ParsedUri uri;
  EXPECT(ParseUri("foo://example.com:8042/over/there#fragment", &uri));
  EXPECT_STREQ("foo", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT_STREQ("example.com", uri.host);
  EXPECT_STREQ("8042", uri.port);
  EXPECT_STREQ("/over/there", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT_STREQ("fragment", uri.fragment);
}

TEST_CASE(ParseUri_WithScheme_WithQueryWithFragment) {
  ParsedUri uri;
  EXPECT(
      ParseUri("foo://example.com:8042/over/there?name=ferret#fragment", &uri));
  EXPECT_STREQ("foo", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT_STREQ("example.com", uri.host);
  EXPECT_STREQ("8042", uri.port);
  EXPECT_STREQ("/over/there", uri.path);
  EXPECT_STREQ("name=ferret", uri.query);
  EXPECT_STREQ("fragment", uri.fragment);
}

TEST_CASE(ParseUri_WithScheme_WithUser) {
  ParsedUri uri;
  EXPECT(ParseUri("foo://user@example.com:8042/over/there", &uri));
  EXPECT_STREQ("foo", uri.scheme);
  EXPECT_STREQ("user", uri.userinfo);
  EXPECT_STREQ("example.com", uri.host);
  EXPECT_STREQ("8042", uri.port);
  EXPECT_STREQ("/over/there", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_WithScheme_ShortPath) {
  ParsedUri uri;
  EXPECT(ParseUri("foo://example.com:8042/", &uri));
  EXPECT_STREQ("foo", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT_STREQ("example.com", uri.host);
  EXPECT_STREQ("8042", uri.port);
  EXPECT_STREQ("/", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_WithScheme_EmptyPath) {
  ParsedUri uri;
  EXPECT(ParseUri("foo://example.com:8042", &uri));
  EXPECT_STREQ("foo", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT_STREQ("example.com", uri.host);
  EXPECT_STREQ("8042", uri.port);
  EXPECT_STREQ("", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_WithScheme_Rootless1) {
  ParsedUri uri;
  EXPECT(ParseUri("foo:here", &uri));
  EXPECT_STREQ("foo", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("here", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_WithScheme_Rootless2) {
  ParsedUri uri;
  EXPECT(ParseUri("foo:or/here", &uri));
  EXPECT_STREQ("foo", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("or/here", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_NoScheme_AbsPath_WithAuthority) {
  ParsedUri uri;
  EXPECT(ParseUri("//example.com:8042/over/there", &uri));
  EXPECT(uri.scheme == NULL);
  EXPECT(uri.userinfo == NULL);
  EXPECT_STREQ("example.com", uri.host);
  EXPECT_STREQ("8042", uri.port);
  EXPECT_STREQ("/over/there", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_NoScheme_AbsPath_NoAuthority) {
  ParsedUri uri;
  EXPECT(ParseUri("/over/there", &uri));
  EXPECT(uri.scheme == NULL);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("/over/there", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

// Colons are permitted in path segments, in many cases.
TEST_CASE(ParseUri_NoScheme_AbsPath_StrayColon) {
  ParsedUri uri;
  EXPECT(ParseUri("/ov:er/there", &uri));
  EXPECT(uri.scheme == NULL);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("/ov:er/there", uri.path);
  EXPECT(uri.query == NULL);
}

TEST_CASE(ParseUri_NoScheme_Rootless1) {
  ParsedUri uri;
  EXPECT(ParseUri("here", &uri));
  EXPECT(uri.scheme == NULL);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("here", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_NoScheme_Rootless2) {
  ParsedUri uri;
  EXPECT(ParseUri("or/here", &uri));
  EXPECT(uri.scheme == NULL);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("or/here", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_NoScheme_Empty) {
  ParsedUri uri;
  EXPECT(ParseUri("", &uri));
  EXPECT(uri.scheme == NULL);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_NoScheme_QueryOnly) {
  ParsedUri uri;
  EXPECT(ParseUri("?name=ferret", &uri));
  EXPECT(uri.scheme == NULL);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("", uri.path);
  EXPECT_STREQ("name=ferret", uri.query);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_NoScheme_FragmentOnly) {
  ParsedUri uri;
  EXPECT(ParseUri("#fragment", &uri));
  EXPECT(uri.scheme == NULL);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT_STREQ("fragment", uri.fragment);
}

TEST_CASE(ParseUri_LowerCaseScheme) {
  ParsedUri uri;
  EXPECT(ParseUri("ScHeMe:path", &uri));
  EXPECT_STREQ("scheme", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("path", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_NormalizeEscapes_PathQueryFragment) {
  ParsedUri uri;
  EXPECT(ParseUri("scheme:/This%09Is A P%61th?This%09Is A Qu%65ry#A Fr%61gment",
                  &uri));
  EXPECT_STREQ("scheme", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("/This%09Is%20A%20Path", uri.path);
  EXPECT_STREQ("This%09Is%20A%20Query", uri.query);
  EXPECT_STREQ("A%20Fragment", uri.fragment);
}

TEST_CASE(ParseUri_NormalizeEscapes_UppercaseEscapesPreferred) {
  ParsedUri uri;
  EXPECT(ParseUri("scheme:/%1b%1B", &uri));
  EXPECT_STREQ("scheme", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("/%1B%1B", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_NormalizeEscapes_Authority) {
  ParsedUri uri;
  EXPECT(ParseUri("scheme://UsEr N%61%4de@h%4FsT.c%6fm:80/", &uri));
  EXPECT_STREQ("scheme", uri.scheme);
  EXPECT_STREQ("UsEr%20NaMe", uri.userinfo);  // Normalized, case preserved.
  EXPECT_STREQ("host.com", uri.host);         // Normalized, lower-cased.
  EXPECT_STREQ("80", uri.port);
  EXPECT_STREQ("/", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_NormalizeEscapes_UppercaseEscapeInHost) {
  ParsedUri uri;
  EXPECT(ParseUri("scheme://tEst%1b/", &uri));
  EXPECT_STREQ("scheme", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT_STREQ("test%1B", uri.host);  // Notice that %1B is upper-cased.
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("/", uri.path);
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ParseUri_BrokenEscapeSequence) {
  ParsedUri uri;
  EXPECT(ParseUri("scheme:/%1g", &uri));
  EXPECT_STREQ("scheme", uri.scheme);
  EXPECT(uri.userinfo == NULL);
  EXPECT(uri.host == NULL);
  EXPECT(uri.port == NULL);
  EXPECT_STREQ("/%1g", uri.path);  // Broken sequence is unchanged.
  EXPECT(uri.query == NULL);
  EXPECT(uri.fragment == NULL);
}

TEST_CASE(ResolveUri_WithScheme_NoAuthorityNoQuery) {
  const char* target_uri;
  EXPECT(ResolveUri("rscheme:/ref/path",
                    "bscheme://buser@bhost:11/base/path?baseQuery",
                    &target_uri));
  EXPECT_STREQ("rscheme:/ref/path", target_uri);
}

TEST_CASE(ResolveUri_WithScheme_WithAuthorityWithQuery) {
  const char* target_uri;
  EXPECT(ResolveUri("rscheme://ruser@rhost:22/ref/path?refQuery",
                    "bscheme://buser@bhost:11/base/path?baseQuery",
                    &target_uri));
  EXPECT_STREQ("rscheme://ruser@rhost:22/ref/path?refQuery", target_uri);
}

TEST_CASE(ResolveUri_NoScheme_WithAuthority) {
  const char* target_uri;
  EXPECT(ResolveUri("//ruser@rhost:22/ref/path",
                    "bscheme://buser@bhost:11/base/path?baseQuery",
                    &target_uri));
  EXPECT_STREQ("bscheme://ruser@rhost:22/ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_AbsolutePath) {
  const char* target_uri;
  EXPECT(ResolveUri("/ref/path", "bscheme://buser@bhost:11/base/path?baseQuery",
                    &target_uri));
  EXPECT_STREQ("bscheme://buser@bhost:11/ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_RelativePath) {
  const char* target_uri;
  EXPECT(ResolveUri("ref/path", "bscheme://buser@bhost:11/base/path?baseQuery",
                    &target_uri));
  EXPECT_STREQ("bscheme://buser@bhost:11/base/ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_RelativePathEmptyBasePath) {
  const char* target_uri;
  EXPECT(ResolveUri("ref/path", "bscheme://buser@bhost:11", &target_uri));
  EXPECT_STREQ("bscheme://buser@bhost:11/ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_RelativePathWeirdBasePath) {
  const char* target_uri;
  EXPECT(ResolveUri("ref/path", "bscheme:base", &target_uri));
  EXPECT_STREQ("bscheme:ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_EmptyPath) {
  const char* target_uri;
  EXPECT(ResolveUri("",
                    "bscheme://buser@bhost:11/base/path?baseQuery#bfragment",
                    &target_uri));
  // Note that we drop the base fragment from the resolved uri.
  EXPECT_STREQ("bscheme://buser@bhost:11/base/path?baseQuery", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_EmptyPathWithQuery) {
  const char* target_uri;
  EXPECT(ResolveUri("?refQuery",
                    "bscheme://buser@bhost:11/base/path?baseQuery#bfragment",
                    &target_uri));
  EXPECT_STREQ("bscheme://buser@bhost:11/base/path?refQuery", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_EmptyPathWithFragment) {
  const char* target_uri;
  EXPECT(ResolveUri("#rfragment",
                    "bscheme://buser@bhost:11/base/path?baseQuery#bfragment",
                    &target_uri));
  EXPECT_STREQ("bscheme://buser@bhost:11/base/path?baseQuery#rfragment",
               target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveOneDotSegment) {
  const char* target_uri;
  EXPECT(ResolveUri("./refpath", "scheme://auth/a/b/c/d", &target_uri));
  EXPECT_STREQ("scheme://auth/a/b/c/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveTwoDotSegments) {
  const char* target_uri;
  EXPECT(ResolveUri("././refpath", "scheme://auth/a/b/c/d", &target_uri));
  EXPECT_STREQ("scheme://auth/a/b/c/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveOneDotDotSegment) {
  const char* target_uri;
  EXPECT(ResolveUri("../refpath", "scheme://auth/a/b/c/d", &target_uri));
  EXPECT_STREQ("scheme://auth/a/b/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveTwoDotDotSegments) {
  const char* target_uri;
  EXPECT(ResolveUri("../../refpath", "scheme://auth/a/b/c/d", &target_uri));
  EXPECT_STREQ("scheme://auth/a/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveTooManyDotDotSegments) {
  const char* target_uri;
  EXPECT(ResolveUri("../../../../../../../../../refpath",
                    "scheme://auth/a/b/c/d", &target_uri));
  EXPECT_STREQ("scheme://auth/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveDotSegmentsNothingLeft1) {
  const char* target_uri;
  EXPECT(ResolveUri("../../../../..", "scheme://auth/a/b/c/d", &target_uri));
  EXPECT_STREQ("scheme://auth/", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveDotSegmentsNothingLeft2) {
  const char* target_uri;
  EXPECT(ResolveUri(".", "scheme://auth/", &target_uri));
  EXPECT_STREQ("scheme://auth/", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveDotSegmentsInitialPrefix) {
  const char* target_uri;
  EXPECT(ResolveUri("../../../../refpath", "scheme://auth", &target_uri));
  EXPECT_STREQ("scheme://auth/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveDotSegmentsMixed) {
  const char* target_uri;
  EXPECT(ResolveUri("../../1/./2/../3/4/../5/././6/../7",
                    "scheme://auth/a/b/c/d/e", &target_uri));
  EXPECT_STREQ("scheme://auth/a/b/1/3/5/7", target_uri);
}

TEST_CASE(ResolveUri_NormalizeEscapes_PathQueryFragment) {
  const char* target_uri;
  EXPECT(ResolveUri("#A Fr%61gment",
                    "scheme:/This%09Is A P%61th?This%09Is A Qu%65ry",
                    &target_uri));
  EXPECT_STREQ(
      "scheme:/This%09Is%20A%20Path?This%09Is%20A%20Query#A%20Fragment",
      target_uri);
}

TEST_CASE(ResolveUri_NormalizeEscapes_UppercaseHexPreferred) {
  const char* target_uri;
  EXPECT(ResolveUri("", "scheme:/%1b%1B", &target_uri));
  EXPECT_STREQ("scheme:/%1B%1B", target_uri);
}

TEST_CASE(ResolveUri_NormalizeEscapes_Authority) {
  const char* target_uri;
  EXPECT(
      ResolveUri("", "scheme://UsEr N%61%4de@h%4FsT.c%6fm:80/", &target_uri));
  // userinfo is normalized and case is preserved.  host is normalized
  // and lower-cased.
  EXPECT_STREQ("scheme://UsEr%20NaMe@host.com:80/", target_uri);
}

TEST_CASE(ResolveUri_NormalizeEscapes_BrokenEscapeSequence) {
  const char* target_uri;
  EXPECT(ResolveUri("", "scheme:/%1g", &target_uri));
  // We don't change broken escape sequences.
  EXPECT_STREQ("scheme:/%1g", target_uri);
}

TEST_CASE(ResolveUri_DataUri) {
  const char* data_uri =
      "data:application/"
      "dart;charset=utf-8,%20%20%20%20%20%20%20%20import%20%22dart:isolate%22;%"
      "0A%0A%20%20%20%20%20%20%20%20import%20%22package:stream_channel/"
      "stream_channel.dart%22;%0A%0A%20%20%20%20%20%20%20%20import%20%"
      "22package:test/src/runner/plugin/"
      "remote_platform_helpers.dart%22;%0A%20%20%20%20%20%20%20%20import%20%"
      "22package:test/src/runner/vm/"
      "catch_isolate_errors.dart%22;%0A%0A%20%20%20%20%20%20%20%20import%20%"
      "22file:///home/sra/xxxx/dev_compiler/test/"
      "all_tests.dart%22%20as%20test;%0A%0A%20%20%20%20%20%20%20%20void%20main("
      "_,%20SendPort%20message)%20%7B%0A%20%20%20%20%20%20%20%20%20%20var%"
      "20channel%20=%20serializeSuite(()%20%7B%0A%20%20%20%20%20%20%20%20%20%"
      "20%20%20catchIsolateErrors();%0A%20%20%20%20%20%20%20%20%20%20%20%"
      "20return%20test.main;%0A%20%20%20%20%20%20%20%20%20%20%7D);%0A%20%20%20%"
      "20%20%20%20%20%20%20new%20IsolateChannel.connectSend(message).pipe("
      "channel);%0A%20%20%20%20%20%20%20%20%7D%0A%20%20%20%20%20%20";

  const char* target_uri;
  EXPECT(ResolveUri(data_uri,
                    "bscheme://buser@bhost:11/base/path?baseQuery#bfragment",
                    &target_uri));
  EXPECT_STREQ(data_uri, target_uri);
}

// dart:core Uri allows for the base url to be relative (no scheme, no
// authory, relative path) but this behavior is not in RFC 3986.  We
// do not implement this.
TEST_CASE(ResolveUri_RelativeBase_NotImplemented) {
  const char* target_uri;
  EXPECT(!ResolveUri("../r1", "b1/b2", &target_uri));
  EXPECT(target_uri == NULL);

  EXPECT(!ResolveUri("..", "b1/b2", &target_uri));
  EXPECT(target_uri == NULL);

  EXPECT(!ResolveUri("../..", "b1/b2", &target_uri));
  EXPECT(target_uri == NULL);

  EXPECT(!ResolveUri("../../..", "b1/b2", &target_uri));
  EXPECT(target_uri == NULL);

  EXPECT(!ResolveUri("../../../r1", "b1/b2", &target_uri));
  EXPECT(target_uri == NULL);

  EXPECT(!ResolveUri("../r1", "../../b1/b2/b3", &target_uri));
  EXPECT(target_uri == NULL);

  EXPECT(!ResolveUri("../../../r1", "../../b1/b2/b3", &target_uri));
  EXPECT(target_uri == NULL);
}

static const char* TestResolve(const char* base_uri, const char* uri) {
  const char* target_uri;
  EXPECT(ResolveUri(uri, base_uri, &target_uri));
  return target_uri;
}

// This test is ported from sdk/tests/corelib/uri_test.dart (testUriPerRFCs).
TEST_CASE(ResolveUri_TestUriPerRFCs) {
  const char* base = "http://a/b/c/d;p?q";

  // From RFC 3986
  EXPECT_STREQ("g:h", TestResolve(base, "g:h"));
  EXPECT_STREQ("http://a/b/c/g", TestResolve(base, "g"));
  EXPECT_STREQ("http://a/b/c/g", TestResolve(base, "./g"));
  EXPECT_STREQ("http://a/b/c/g/", TestResolve(base, "g/"));
  EXPECT_STREQ("http://a/g", TestResolve(base, "/g"));
  EXPECT_STREQ("http://g", TestResolve(base, "//g"));
  EXPECT_STREQ("http://a/b/c/d;p?y", TestResolve(base, "?y"));
  EXPECT_STREQ("http://a/b/c/g?y", TestResolve(base, "g?y"));
  EXPECT_STREQ("http://a/b/c/d;p?q#s", TestResolve(base, "#s"));
  EXPECT_STREQ("http://a/b/c/g#s", TestResolve(base, "g#s"));
  EXPECT_STREQ("http://a/b/c/g?y#s", TestResolve(base, "g?y#s"));
  EXPECT_STREQ("http://a/b/c/;x", TestResolve(base, ";x"));
  EXPECT_STREQ("http://a/b/c/g;x", TestResolve(base, "g;x"));
  EXPECT_STREQ("http://a/b/c/g;x?y#s", TestResolve(base, "g;x?y#s"));
  EXPECT_STREQ("http://a/b/c/d;p?q", TestResolve(base, ""));
  EXPECT_STREQ("http://a/b/c/", TestResolve(base, "."));
  EXPECT_STREQ("http://a/b/c/", TestResolve(base, "./"));
  EXPECT_STREQ("http://a/b/", TestResolve(base, ".."));
  EXPECT_STREQ("http://a/b/", TestResolve(base, "../"));
  EXPECT_STREQ("http://a/b/g", TestResolve(base, "../g"));
  EXPECT_STREQ("http://a/", TestResolve(base, "../.."));
  EXPECT_STREQ("http://a/", TestResolve(base, "../../"));
  EXPECT_STREQ("http://a/g", TestResolve(base, "../../g"));
  EXPECT_STREQ("http://a/g", TestResolve(base, "../../../g"));
  EXPECT_STREQ("http://a/g", TestResolve(base, "../../../../g"));
  EXPECT_STREQ("http://a/g", TestResolve(base, "/./g"));
  EXPECT_STREQ("http://a/g", TestResolve(base, "/../g"));
  EXPECT_STREQ("http://a/b/c/g.", TestResolve(base, "g."));
  EXPECT_STREQ("http://a/b/c/.g", TestResolve(base, ".g"));
  EXPECT_STREQ("http://a/b/c/g..", TestResolve(base, "g.."));
  EXPECT_STREQ("http://a/b/c/..g", TestResolve(base, "..g"));
  EXPECT_STREQ("http://a/b/g", TestResolve(base, "./../g"));
  EXPECT_STREQ("http://a/b/c/g/", TestResolve(base, "./g/."));
  EXPECT_STREQ("http://a/b/c/g/h", TestResolve(base, "g/./h"));
  EXPECT_STREQ("http://a/b/c/h", TestResolve(base, "g/../h"));
  EXPECT_STREQ("http://a/b/c/g;x=1/y", TestResolve(base, "g;x=1/./y"));
  EXPECT_STREQ("http://a/b/c/y", TestResolve(base, "g;x=1/../y"));
  EXPECT_STREQ("http://a/b/c/g?y/./x", TestResolve(base, "g?y/./x"));
  EXPECT_STREQ("http://a/b/c/g?y/../x", TestResolve(base, "g?y/../x"));
  EXPECT_STREQ("http://a/b/c/g#s/./x", TestResolve(base, "g#s/./x"));
  EXPECT_STREQ("http://a/b/c/g#s/../x", TestResolve(base, "g#s/../x"));
  EXPECT_STREQ("http:g", TestResolve(base, "http:g"));

  // Additional tests (not from RFC 3986).
  EXPECT_STREQ("http://a/b/g;p/h;s", TestResolve(base, "../g;p/h;s"));

  base = "s:a/b";
  EXPECT_STREQ("s:/c", TestResolve(base, "../c"));
}

// This test is ported from sdk/tests/corelib/uri_test.dart (testResolvePath).
TEST_CASE(ResolveUri_MoreDotSegmentTests) {
  const char* base = "/";
  EXPECT_STREQ("/a/g", TestResolve(base, "/a/b/c/./../../g"));
  EXPECT_STREQ("/a/g", TestResolve(base, "/a/b/c/./../../g"));
  EXPECT_STREQ("/mid/6", TestResolve(base, "mid/content=5/../6"));
  EXPECT_STREQ("/a/b/e", TestResolve(base, "a/b/c/d/../../e"));
  EXPECT_STREQ("/a/b/e", TestResolve(base, "../a/b/c/d/../../e"));
  EXPECT_STREQ("/a/b/e", TestResolve(base, "./a/b/c/d/../../e"));
  EXPECT_STREQ("/a/b/e", TestResolve(base, "../a/b/./c/d/../../e"));
  EXPECT_STREQ("/a/b/e", TestResolve(base, "./a/b/./c/d/../../e"));
  EXPECT_STREQ("/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/."));
  EXPECT_STREQ("/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/./."));
  EXPECT_STREQ("/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/././."));

#define LH "http://localhost"
  base = LH;
  EXPECT_STREQ(LH "/a/g", TestResolve(base, "/a/b/c/./../../g"));
  EXPECT_STREQ(LH "/a/g", TestResolve(base, "/a/b/c/./../../g"));
  EXPECT_STREQ(LH "/mid/6", TestResolve(base, "mid/content=5/../6"));
  EXPECT_STREQ(LH "/a/b/e", TestResolve(base, "a/b/c/d/../../e"));
  EXPECT_STREQ(LH "/a/b/e", TestResolve(base, "../a/b/c/d/../../e"));
  EXPECT_STREQ(LH "/a/b/e", TestResolve(base, "./a/b/c/d/../../e"));
  EXPECT_STREQ(LH "/a/b/e", TestResolve(base, "../a/b/./c/d/../../e"));
  EXPECT_STREQ(LH "/a/b/e", TestResolve(base, "./a/b/./c/d/../../e"));
  EXPECT_STREQ(LH "/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/."));
  EXPECT_STREQ(LH "/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/./."));
  EXPECT_STREQ(LH "/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/././."));
#undef LH
}

}  // namespace dart
