// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unit_test.h"

#include "bin/uri.h"
#include "platform/utils.h"

namespace dart {

#define EXPECT_USTREQ(expected, actual) EXPECT_STREQ(expected, actual.get())

TEST_CASE(ParseUri_WithScheme_NoQueryNoUser) {
  auto uri = ParseUri("foo://example.com:8042/over/there");
  EXPECT(uri);
  EXPECT_USTREQ("foo", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT_USTREQ("example.com", uri->host);
  EXPECT_USTREQ("8042", uri->port);
  EXPECT_USTREQ("/over/there", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_WithScheme_WithQuery) {
  auto uri = ParseUri("foo://example.com:8042/over/there?name=ferret");
  EXPECT(uri);
  EXPECT_USTREQ("foo", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT_USTREQ("example.com", uri->host);
  EXPECT_USTREQ("8042", uri->port);
  EXPECT_USTREQ("/over/there", uri->path);
  EXPECT_USTREQ("name=ferret", uri->query);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_WithScheme_WithFragment) {
  auto uri = ParseUri("foo://example.com:8042/over/there#fragment");
  EXPECT(uri);
  EXPECT_USTREQ("foo", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT_USTREQ("example.com", uri->host);
  EXPECT_USTREQ("8042", uri->port);
  EXPECT_USTREQ("/over/there", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT_USTREQ("fragment", uri->fragment);
}

TEST_CASE(ParseUri_WithScheme_WithQueryWithFragment) {
  auto uri = ParseUri("foo://example.com:8042/over/there?name=ferret#fragment");
  EXPECT(uri);
  EXPECT_USTREQ("foo", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT_USTREQ("example.com", uri->host);
  EXPECT_USTREQ("8042", uri->port);
  EXPECT_USTREQ("/over/there", uri->path);
  EXPECT_USTREQ("name=ferret", uri->query);
  EXPECT_USTREQ("fragment", uri->fragment);
}

TEST_CASE(ParseUri_WithScheme_WithUser) {
  auto uri = ParseUri("foo://user@example.com:8042/over/there");
  EXPECT(uri);
  EXPECT_USTREQ("foo", uri->scheme);
  EXPECT_USTREQ("user", uri->userinfo);
  EXPECT_USTREQ("example.com", uri->host);
  EXPECT_USTREQ("8042", uri->port);
  EXPECT_USTREQ("/over/there", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_WithScheme_ShortPath) {
  auto uri = ParseUri("foo://example.com:8042/");
  EXPECT(uri);
  EXPECT_USTREQ("foo", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT_USTREQ("example.com", uri->host);
  EXPECT_USTREQ("8042", uri->port);
  EXPECT_USTREQ("/", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_WithScheme_EmptyPath) {
  auto uri = ParseUri("foo://example.com:8042");
  EXPECT(uri);
  EXPECT_USTREQ("foo", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT_USTREQ("example.com", uri->host);
  EXPECT_USTREQ("8042", uri->port);
  EXPECT_USTREQ("", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_WithScheme_Rootless1) {
  auto uri = ParseUri("foo:here");
  EXPECT(uri);
  EXPECT_USTREQ("foo", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("here", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_WithScheme_Rootless2) {
  auto uri = ParseUri("foo:or/here");
  EXPECT(uri);
  EXPECT_USTREQ("foo", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("or/here", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_NoScheme_AbsPath_WithAuthority) {
  auto uri = ParseUri("//example.com:8042/over/there");
  EXPECT(uri);
  EXPECT(uri->scheme == nullptr);
  EXPECT(uri->userinfo == nullptr);
  EXPECT_USTREQ("example.com", uri->host);
  EXPECT_USTREQ("8042", uri->port);
  EXPECT_USTREQ("/over/there", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_NoScheme_AbsPath_NoAuthority) {
  auto uri = ParseUri("/over/there");
  EXPECT(uri);
  EXPECT(uri->scheme == nullptr);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("/over/there", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

// Colons are permitted in path segments, in many cases.
TEST_CASE(ParseUri_NoScheme_AbsPath_StrayColon) {
  auto uri = ParseUri("/ov:er/there");
  EXPECT(uri);
  EXPECT(uri->scheme == nullptr);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("/ov:er/there", uri->path);
  EXPECT(uri->query == nullptr);
}

TEST_CASE(ParseUri_NoScheme_Rootless1) {
  auto uri = ParseUri("here");
  EXPECT(uri);
  EXPECT(uri->scheme == nullptr);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("here", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_NoScheme_Rootless2) {
  auto uri = ParseUri("or/here");
  EXPECT(uri);
  EXPECT(uri->scheme == nullptr);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("or/here", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_NoScheme_Empty) {
  auto uri = ParseUri("");
  EXPECT(uri);
  EXPECT(uri->scheme == nullptr);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_NoScheme_QueryOnly) {
  auto uri = ParseUri("?name=ferret");
  EXPECT(uri);
  EXPECT(uri->scheme == nullptr);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("", uri->path);
  EXPECT_USTREQ("name=ferret", uri->query);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_NoScheme_FragmentOnly) {
  auto uri = ParseUri("#fragment");
  EXPECT(uri);
  EXPECT(uri->scheme == nullptr);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT_USTREQ("fragment", uri->fragment);
}

TEST_CASE(ParseUri_LowerCaseScheme) {
  auto uri = ParseUri("ScHeMe:path");
  EXPECT(uri);
  EXPECT_USTREQ("scheme", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("path", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_NormalizeEscapes_PathQueryFragment) {
  auto uri =
      ParseUri("scheme:/This%09Is A P%61th?This%09Is A Qu%65ry#A Fr%61gment");
  EXPECT(uri);
  EXPECT_USTREQ("scheme", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("/This%09Is%20A%20Path", uri->path);
  EXPECT_USTREQ("This%09Is%20A%20Query", uri->query);
  EXPECT_USTREQ("A%20Fragment", uri->fragment);
}

TEST_CASE(ParseUri_NormalizeEscapes_UppercaseEscapesPreferred) {
  auto uri = ParseUri("scheme:/%1b%1B");
  EXPECT(uri);
  EXPECT_USTREQ("scheme", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("/%1B%1B", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_NormalizeEscapes_Authority) {
  auto uri = ParseUri("scheme://UsEr N%61%4de@h%4FsT.c%6fm:80/");
  EXPECT(uri);
  EXPECT_USTREQ("scheme", uri->scheme);
  EXPECT_USTREQ("UsEr%20NaMe", uri->userinfo);  // Normalized, case preserved.
  EXPECT_USTREQ("host.com", uri->host);         // Normalized, lower-cased.
  EXPECT_USTREQ("80", uri->port);
  EXPECT_USTREQ("/", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_NormalizeEscapes_UppercaseEscapeInHost) {
  auto uri = ParseUri("scheme://tEst%1b/");
  EXPECT(uri);
  EXPECT_USTREQ("scheme", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT_USTREQ("test%1B", uri->host);  // Notice that %1B is upper-cased.
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("/", uri->path);
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ParseUri_BrokenEscapeSequence) {
  auto uri = ParseUri("scheme:/%1g");
  EXPECT(uri);
  EXPECT_USTREQ("scheme", uri->scheme);
  EXPECT(uri->userinfo == nullptr);
  EXPECT(uri->host == nullptr);
  EXPECT(uri->port == nullptr);
  EXPECT_USTREQ("/%1g", uri->path);  // Broken sequence is unchanged.
  EXPECT(uri->query == nullptr);
  EXPECT(uri->fragment == nullptr);
}

TEST_CASE(ResolveUri_WithScheme_NoAuthorityNoQuery) {
  auto target_uri = ResolveUri("rscheme:/ref/path",
                               "bscheme://buser@bhost:11/base/path?baseQuery");
  EXPECT(target_uri);
  EXPECT_USTREQ("rscheme:/ref/path", target_uri);
}

TEST_CASE(ResolveUri_WithScheme_WithAuthorityWithQuery) {
  auto target_uri = ResolveUri("rscheme://ruser@rhost:22/ref/path?refQuery",
                               "bscheme://buser@bhost:11/base/path?baseQuery");
  EXPECT(target_uri);
  EXPECT_USTREQ("rscheme://ruser@rhost:22/ref/path?refQuery", target_uri);
}

TEST_CASE(ResolveUri_NoScheme_WithAuthority) {
  auto target_uri = ResolveUri("//ruser@rhost:22/ref/path",
                               "bscheme://buser@bhost:11/base/path?baseQuery");
  EXPECT(target_uri);
  EXPECT_USTREQ("bscheme://ruser@rhost:22/ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_AbsolutePath) {
  auto target_uri =
      ResolveUri("/ref/path", "bscheme://buser@bhost:11/base/path?baseQuery");
  EXPECT(target_uri);
  EXPECT_USTREQ("bscheme://buser@bhost:11/ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_RelativePath) {
  auto target_uri =
      ResolveUri("ref/path", "bscheme://buser@bhost:11/base/path?baseQuery");
  EXPECT(target_uri);
  EXPECT_USTREQ("bscheme://buser@bhost:11/base/ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_RelativePathEmptyBasePath) {
  auto target_uri = ResolveUri("ref/path", "bscheme://buser@bhost:11");
  EXPECT(target_uri);
  EXPECT_USTREQ("bscheme://buser@bhost:11/ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_RelativePathWeirdBasePath) {
  auto target_uri = ResolveUri("ref/path", "bscheme:base");
  EXPECT(target_uri);
  EXPECT_USTREQ("bscheme:ref/path", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_EmptyPath) {
  auto target_uri =
      ResolveUri("", "bscheme://buser@bhost:11/base/path?baseQuery#bfragment");
  EXPECT(target_uri);
  // Note that we drop the base fragment from the resolved uri->
  EXPECT_USTREQ("bscheme://buser@bhost:11/base/path?baseQuery", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_EmptyPathWithQuery) {
  auto target_uri = ResolveUri(
      "?refQuery", "bscheme://buser@bhost:11/base/path?baseQuery#bfragment");
  EXPECT(target_uri);
  EXPECT_USTREQ("bscheme://buser@bhost:11/base/path?refQuery", target_uri);
}

TEST_CASE(ResolveUri_NoSchemeNoAuthority_EmptyPathWithFragment) {
  auto target_uri = ResolveUri(
      "#rfragment", "bscheme://buser@bhost:11/base/path?baseQuery#bfragment");
  EXPECT(target_uri);
  EXPECT_USTREQ("bscheme://buser@bhost:11/base/path?baseQuery#rfragment",
                target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveOneDotSegment) {
  auto target_uri = ResolveUri("./refpath", "scheme://auth/a/b/c/d");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme://auth/a/b/c/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveTwoDotSegments) {
  auto target_uri = ResolveUri("././refpath", "scheme://auth/a/b/c/d");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme://auth/a/b/c/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveOneDotDotSegment) {
  auto target_uri = ResolveUri("../refpath", "scheme://auth/a/b/c/d");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme://auth/a/b/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveTwoDotDotSegments) {
  auto target_uri = ResolveUri("../../refpath", "scheme://auth/a/b/c/d");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme://auth/a/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveTooManyDotDotSegments) {
  auto target_uri =
      ResolveUri("../../../../../../../../../refpath", "scheme://auth/a/b/c/d");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme://auth/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveDotSegmentsNothingLeft1) {
  auto target_uri = ResolveUri("../../../../..", "scheme://auth/a/b/c/d");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme://auth/", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveDotSegmentsNothingLeft2) {
  auto target_uri = ResolveUri(".", "scheme://auth/");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme://auth/", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveDotSegmentsInitialPrefix) {
  auto target_uri = ResolveUri("../../../../refpath", "scheme://auth");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme://auth/refpath", target_uri);
}

TEST_CASE(ResolveUri_RemoveDots_RemoveDotSegmentsMixed) {
  auto target_uri = ResolveUri("../../1/./2/../3/4/../5/././6/../7",
                               "scheme://auth/a/b/c/d/e");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme://auth/a/b/1/3/5/7", target_uri);
}

TEST_CASE(ResolveUri_NormalizeEscapes_PathQueryFragment) {
  auto target_uri = ResolveUri(
      "#A Fr%61gment", "scheme:/This%09Is A P%61th?This%09Is A Qu%65ry");
  EXPECT(target_uri);
  EXPECT_USTREQ(
      "scheme:/This%09Is%20A%20Path?This%09Is%20A%20Query#A%20Fragment",
      target_uri);
}

TEST_CASE(ResolveUri_NormalizeEscapes_UppercaseHexPreferred) {
  auto target_uri = ResolveUri("", "scheme:/%1b%1B");
  EXPECT(target_uri);
  EXPECT_USTREQ("scheme:/%1B%1B", target_uri);
}

TEST_CASE(ResolveUri_NormalizeEscapes_Authority) {
  auto target_uri = ResolveUri("", "scheme://UsEr N%61%4de@h%4FsT.c%6fm:80/");
  EXPECT(target_uri);
  // userinfo is normalized and case is preserved.  host is normalized
  // and lower-cased.
  EXPECT_USTREQ("scheme://UsEr%20NaMe@host.com:80/", target_uri);
}

TEST_CASE(ResolveUri_NormalizeEscapes_BrokenEscapeSequence) {
  auto target_uri = ResolveUri("", "scheme:/%1g");
  EXPECT(target_uri);
  // We don't change broken escape sequences.
  EXPECT_USTREQ("scheme:/%1g", target_uri);
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

  auto target_uri = ResolveUri(
      data_uri, "bscheme://buser@bhost:11/base/path?baseQuery#bfragment");
  EXPECT(target_uri);
  EXPECT_USTREQ(data_uri, target_uri);
}

// dart:core Uri allows for the base url to be relative (no scheme, no
// authority, relative path) but this behavior is not in RFC 3986.  We
// do not implement this.
TEST_CASE(ResolveUri_RelativeBase_NotImplemented) {
  EXPECT(!ResolveUri("../r1", "b1/b2").get());

  EXPECT(!ResolveUri("..", "b1/b2").get());

  EXPECT(!ResolveUri("../..", "b1/b2").get());

  EXPECT(!ResolveUri("../../..", "b1/b2").get());

  EXPECT(!ResolveUri("../../../r1", "b1/b2").get());

  EXPECT(!ResolveUri("../r1", "../../b1/b2/b3").get());

  EXPECT(!ResolveUri("../../../r1", "../../b1/b2/b3").get());
}

CStringUniquePtr TestResolve(const char* base_uri, const char* uri) {
  auto target_uri = ResolveUri(uri, base_uri);
  EXPECT(target_uri);
  return target_uri;
}

// This test is ported from sdk/tests/corelib/uri_test.dart (testUriPerRFCs).
TEST_CASE(ResolveUri_TestUriPerRFCs) {
  const char* base = "http://a/b/c/d;p?q";

  // From RFC 3986
  EXPECT_USTREQ("g:h", TestResolve(base, "g:h"));
  EXPECT_USTREQ("http://a/b/c/g", TestResolve(base, "g"));
  EXPECT_USTREQ("http://a/b/c/g", TestResolve(base, "./g"));
  EXPECT_USTREQ("http://a/b/c/g/", TestResolve(base, "g/"));
  EXPECT_USTREQ("http://a/g", TestResolve(base, "/g"));
  EXPECT_USTREQ("http://g", TestResolve(base, "//g"));
  EXPECT_USTREQ("http://a/b/c/d;p?y", TestResolve(base, "?y"));
  EXPECT_USTREQ("http://a/b/c/g?y", TestResolve(base, "g?y"));
  EXPECT_USTREQ("http://a/b/c/d;p?q#s", TestResolve(base, "#s"));
  EXPECT_USTREQ("http://a/b/c/g#s", TestResolve(base, "g#s"));
  EXPECT_USTREQ("http://a/b/c/g?y#s", TestResolve(base, "g?y#s"));
  EXPECT_USTREQ("http://a/b/c/;x", TestResolve(base, ";x"));
  EXPECT_USTREQ("http://a/b/c/g;x", TestResolve(base, "g;x"));
  EXPECT_USTREQ("http://a/b/c/g;x?y#s", TestResolve(base, "g;x?y#s"));
  EXPECT_USTREQ("http://a/b/c/d;p?q", TestResolve(base, ""));
  EXPECT_USTREQ("http://a/b/c/", TestResolve(base, "."));
  EXPECT_USTREQ("http://a/b/c/", TestResolve(base, "./"));
  EXPECT_USTREQ("http://a/b/", TestResolve(base, ".."));
  EXPECT_USTREQ("http://a/b/", TestResolve(base, "../"));
  EXPECT_USTREQ("http://a/b/g", TestResolve(base, "../g"));
  EXPECT_USTREQ("http://a/", TestResolve(base, "../.."));
  EXPECT_USTREQ("http://a/", TestResolve(base, "../../"));
  EXPECT_USTREQ("http://a/g", TestResolve(base, "../../g"));
  EXPECT_USTREQ("http://a/g", TestResolve(base, "../../../g"));
  EXPECT_USTREQ("http://a/g", TestResolve(base, "../../../../g"));
  EXPECT_USTREQ("http://a/g", TestResolve(base, "/./g"));
  EXPECT_USTREQ("http://a/g", TestResolve(base, "/../g"));
  EXPECT_USTREQ("http://a/b/c/g.", TestResolve(base, "g."));
  EXPECT_USTREQ("http://a/b/c/.g", TestResolve(base, ".g"));
  EXPECT_USTREQ("http://a/b/c/g..", TestResolve(base, "g.."));
  EXPECT_USTREQ("http://a/b/c/..g", TestResolve(base, "..g"));
  EXPECT_USTREQ("http://a/b/g", TestResolve(base, "./../g"));
  EXPECT_USTREQ("http://a/b/c/g/", TestResolve(base, "./g/."));
  EXPECT_USTREQ("http://a/b/c/g/h", TestResolve(base, "g/./h"));
  EXPECT_USTREQ("http://a/b/c/h", TestResolve(base, "g/../h"));
  EXPECT_USTREQ("http://a/b/c/g;x=1/y", TestResolve(base, "g;x=1/./y"));
  EXPECT_USTREQ("http://a/b/c/y", TestResolve(base, "g;x=1/../y"));
  EXPECT_USTREQ("http://a/b/c/g?y/./x", TestResolve(base, "g?y/./x"));
  EXPECT_USTREQ("http://a/b/c/g?y/../x", TestResolve(base, "g?y/../x"));
  EXPECT_USTREQ("http://a/b/c/g#s/./x", TestResolve(base, "g#s/./x"));
  EXPECT_USTREQ("http://a/b/c/g#s/../x", TestResolve(base, "g#s/../x"));
  EXPECT_USTREQ("http:g", TestResolve(base, "http:g"));

  // Additional tests (not from RFC 3986).
  EXPECT_USTREQ("http://a/b/g;p/h;s", TestResolve(base, "../g;p/h;s"));

  base = "s:a/b";
  EXPECT_USTREQ("s:/c", TestResolve(base, "../c"));
}

// This test is ported from sdk/tests/corelib/uri_test.dart (testResolvePath).
TEST_CASE(ResolveUri_MoreDotSegmentTests) {
  const char* base = "/";
  EXPECT_USTREQ("/a/g", TestResolve(base, "/a/b/c/./../../g"));
  EXPECT_USTREQ("/a/g", TestResolve(base, "/a/b/c/./../../g"));
  EXPECT_USTREQ("/mid/6", TestResolve(base, "mid/content=5/../6"));
  EXPECT_USTREQ("/a/b/e", TestResolve(base, "a/b/c/d/../../e"));
  EXPECT_USTREQ("/a/b/e", TestResolve(base, "../a/b/c/d/../../e"));
  EXPECT_USTREQ("/a/b/e", TestResolve(base, "./a/b/c/d/../../e"));
  EXPECT_USTREQ("/a/b/e", TestResolve(base, "../a/b/./c/d/../../e"));
  EXPECT_USTREQ("/a/b/e", TestResolve(base, "./a/b/./c/d/../../e"));
  EXPECT_USTREQ("/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/."));
  EXPECT_USTREQ("/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/./."));
  EXPECT_USTREQ("/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/././."));

#define LH "http://localhost"
  base = LH;
  EXPECT_USTREQ(LH "/a/g", TestResolve(base, "/a/b/c/./../../g"));
  EXPECT_USTREQ(LH "/a/g", TestResolve(base, "/a/b/c/./../../g"));
  EXPECT_USTREQ(LH "/mid/6", TestResolve(base, "mid/content=5/../6"));
  EXPECT_USTREQ(LH "/a/b/e", TestResolve(base, "a/b/c/d/../../e"));
  EXPECT_USTREQ(LH "/a/b/e", TestResolve(base, "../a/b/c/d/../../e"));
  EXPECT_USTREQ(LH "/a/b/e", TestResolve(base, "./a/b/c/d/../../e"));
  EXPECT_USTREQ(LH "/a/b/e", TestResolve(base, "../a/b/./c/d/../../e"));
  EXPECT_USTREQ(LH "/a/b/e", TestResolve(base, "./a/b/./c/d/../../e"));
  EXPECT_USTREQ(LH "/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/."));
  EXPECT_USTREQ(LH "/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/./."));
  EXPECT_USTREQ(LH "/a/b/e/", TestResolve(base, "./a/b/./c/d/../../e/././."));
#undef LH
}

TEST_CASE(ResolveUri_WindowsPaths_Forwardslash_NoScheme) {
  EXPECT_USTREQ(
      "c:/Users/USERNA~1/AppData/Local/Temp/a/b.dll",
      TestResolve("C:/Users/USERNA~1/AppData/Local/Temp/a/out.dill", "b.dll"));
}

// > Here are some examples which may be accepted by some applications on
// > Windows systems
// https://en.wikipedia.org/wiki/File_URI_scheme
// "file:///C:/"
TEST_CASE(ResolveUri_WindowsPaths_Forwardslash_FileScheme) {
  EXPECT_USTREQ(
      "file:///"
      "C:/Users/USERNA~1/AppData/Local/Temp/a/b.dll",
      TestResolve("file:///C:/Users/USERNA~1/AppData/Local/Temp/a/out.dill",
                  "b.dll"));
}

TEST_CASE(ResolveUri_WindowsPaths_Backslash) {
  EXPECT_USTREQ(
      "file:///b.dll",
      TestResolve(
          "file:///C:\\Users\\USERNA~1\\AppData\\Local\\Temp\\a\\out.dill",
          "b.dll"));
}

}  // namespace dart
