// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/uri.h"

#include <memory>
#include <utility>

#include "platform/allocation.h"
#include "platform/utils.h"

// TODO(https://dartbug.com/55925): Move this file to bin/.

namespace dart {

static CStringUniquePtr MakeCopyOfString(const char* str) {
  if (str == nullptr) {
    return CStringUniquePtr();
  }
  intptr_t len = strlen(str) + 1;  // '\0'-terminated.
  char* copy = static_cast<char*>(malloc(len));
  strncpy(copy, str, len);
  return CStringUniquePtr(copy);
}

static CStringUniquePtr MakeCopyOfStringN(const char* str, intptr_t len) {
  ASSERT(len >= 0);
  for (intptr_t i = 0; i < len; i++) {
    if (str[i] == '\0') {
      len = i;
      break;
    }
  }
  char* copy = static_cast<char*>(malloc(len + 1));  // +1 for '\0'
  strncpy(copy, str, len);
  copy[len] = '\0';
  return CStringUniquePtr(copy);
}

static CStringUniquePtr PrintToString(const char* format, ...) {
  va_list args;
  va_start(args, format);
  char* buffer = Utils::VSCreate(format, args);
  va_end(args);
  return CStringUniquePtr(buffer);
}

static bool IsUnreservedChar(intptr_t value) {
  return ((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z') ||
          (value >= '0' && value <= '9') || value == '-' || value == '.' ||
          value == '_' || value == '~');
}

static bool IsDelimiter(intptr_t value) {
  switch (value) {
    case ':':
    case '/':
    case '?':
    case '#':
    case '[':
    case ']':
    case '@':
    case '!':
    case '$':
    case '&':
    case '\'':
    case '(':
    case ')':
    case '*':
    case '+':
    case ',':
    case ';':
    case '=':
      return true;
    default:
      return false;
  }
}

static bool IsHexDigit(char value) {
  return ((value >= '0' && value <= '9') || (value >= 'A' && value <= 'F') ||
          (value >= 'a' && value <= 'f'));
}

static int HexValue(char digit) {
  if ((digit >= '0' && digit <= '9')) {
    return digit - '0';
  }
  if ((digit >= 'A' && digit <= 'F')) {
    return digit - 'A' + 10;
  }
  if ((digit >= 'a' && digit <= 'f')) {
    return digit - 'a' + 10;
  }
  UNREACHABLE();
  return 0;
}

static int GetEscapedValue(const char* str, intptr_t pos, intptr_t len) {
  if (pos + 2 >= len) {
    // Not enough room for a valid escape sequence.
    return -1;
  }
  if (str[pos] != '%') {
    // Escape sequences start with '%'.
    return -1;
  }

  char digit1 = str[pos + 1];
  char digit2 = str[pos + 2];
  if (!IsHexDigit(digit1) || !IsHexDigit(digit2)) {
    // Invalid escape sequence.  Ignore it.
    return -1;
  }
  return HexValue(digit1) * 16 + HexValue(digit2);
}

CStringUniquePtr NormalizeEscapes(const char* str, intptr_t len) {
  // Allocate the buffer.
  // We multiply len by three because a percent-escape sequence is
  // three characters long (e.g. ' ' -> '%20).  +1 for '\0'.  We could
  // take two passes through the string and avoid the excess
  // allocation, but it's zone-memory so it doesn't seem necessary.
  char* buffer = static_cast<char*>(malloc(len * 3 + 1));

  // Copy the string, normalizing as we go.
  intptr_t buffer_pos = 0;
  intptr_t pos = 0;
  while (pos < len) {
    int escaped_value = GetEscapedValue(str, pos, len);
    if (escaped_value >= 0) {
      // If one of the special "unreserved" characters has been
      // escaped, revert the escaping.  Otherwise preserve the
      // escaping.
      if (IsUnreservedChar(escaped_value)) {
        buffer[buffer_pos] = escaped_value;
        buffer_pos++;
      } else {
        Utils::SNPrint(buffer + buffer_pos, 4, "%%%02X", escaped_value);
        buffer_pos += 3;
      }
      pos += 3;
    } else {
      char c = str[pos];
      // If a delimiter or unreserved character is currently not
      // escaped, preserve that.  If there is a busted %-sequence in
      // the input, preserve that too.
      if (c == '%' || IsDelimiter(c) || IsUnreservedChar(c)) {
        buffer[buffer_pos] = c;
        buffer_pos++;
      } else {
        // Escape funky characters.
        Utils::SNPrint(buffer + buffer_pos, 4, "%%%02X", c);
        buffer_pos += 3;
      }
      pos++;
    }
  }
  buffer[buffer_pos] = '\0';
  return CStringUniquePtr(buffer);
}

// Lower-case a string in place.
static void StringLower(char* str) {
  const intptr_t len = strlen(str);
  intptr_t i = 0;
  while (i < len) {
    int escaped_value = GetEscapedValue(str, i, len);
    if (escaped_value >= 0) {
      // Don't lowercase escape sequences.
      i += 3;
    } else {
      // I don't use tolower() because I don't want the locale
      // transforming any non-ascii characters.
      char c = str[i];
      if (c >= 'A' && c <= 'Z') {
        str[i] = c + ('a' - 'A');
      }
      i++;
    }
  }
}

static intptr_t ParseAuthority(const char* authority, ParsedUri& parsed_uri) {
  const char* current = authority;
  intptr_t len = 0;

  size_t userinfo_len = strcspn(current, "@/");
  if (current[userinfo_len] == '@') {
    // The '@' character follows the optional userinfo string.
    parsed_uri.userinfo = NormalizeEscapes(current, userinfo_len);
    current += userinfo_len + 1;
    len += userinfo_len + 1;
  }

  size_t host_len = strcspn(current, ":/");
  CStringUniquePtr host = NormalizeEscapes(current, host_len);
  StringLower(host.get());
  parsed_uri.host = std::move(host);
  len += host_len;

  if (current[host_len] == ':') {
    // The ':' character precedes the optional port string.
    const char* port_start = current + host_len + 1;  // +1 for ':'
    size_t port_len = strcspn(port_start, "/");
    parsed_uri.port = MakeCopyOfStringN(port_start, port_len);
    len += 1 + port_len;  // +1 for ':'
  }
  return len;
}

// Performs a simple parse of a uri into its components.
// See RFC 3986 Section 3: Syntax.
std::unique_ptr<ParsedUri> ParseUri(const char* uri) {
  auto parsed_uri = std::make_unique<ParsedUri>();

  // The first ':' separates the scheme from the rest of the uri.  If
  // a ':' occurs after the first '/' it doesn't count.
  size_t scheme_len = strcspn(uri, ":/");
  const char* rest = uri;
  if (uri[scheme_len] == ':') {
    CStringUniquePtr scheme = MakeCopyOfStringN(uri, scheme_len);
    StringLower(scheme.get());
    parsed_uri->scheme = std::move(scheme);
    rest = uri + scheme_len + 1;
  }

  // The first '#' separates the optional fragment
  const char* hash_pos = rest + strcspn(rest, "#");
  if (*hash_pos == '#') {
    // There is a fragment part.
    const char* fragment_start = hash_pos + 1;
    parsed_uri->fragment =
        NormalizeEscapes(fragment_start, strlen(fragment_start));
  }

  // The first '?' or '#' separates the hierarchical part from the
  // optional query.
  const char* question_pos = rest + strcspn(rest, "?#");
  if (*question_pos == '?') {
    // There is a query part.
    const char* query_start = question_pos + 1;
    parsed_uri->query = NormalizeEscapes(query_start, (hash_pos - query_start));
  }

  const char* path_start = rest;
  if (rest[0] == '/' && rest[1] == '/') {
    // There is an authority part.
    const char* authority_start = rest + 2;  // 2 for '//'.

    intptr_t authority_len = ParseAuthority(authority_start, *parsed_uri.get());
    if (authority_len < 0) {
      return std::unique_ptr<ParsedUri>();
    }
    path_start = authority_start + authority_len;
  }

  // The path is the substring between the authority and the query.
  parsed_uri->path = NormalizeEscapes(path_start, (question_pos - path_start));
  return parsed_uri;
}

static char* RemoveLastSegment(char* current, char* base) {
  if (current == base) {
    return current;
  }
  ASSERT(current > base);
  for (current--; current > base; current--) {
    if (*current == '/') {
      // We have found the beginning of the last segment.
      return current;
    }
  }
  ASSERT(current == base);
  return current;
}

static intptr_t SegmentLength(const char* input) {
  const char* cp = input;

  // Include initial slash in the segment, if any.
  if (*cp == '/') {
    cp++;
  }

  // Don't include trailing slash in the segment.
  cp += strcspn(cp, "/");
  return cp - input;
}

// See RFC 3986 Section 5.2.4: Remove Dot Segments.
CStringUniquePtr RemoveDotSegments(const char* path) {
  const char* input = path;

  // The output path will always be less than or equal to the size of
  // the input path.

  char* buffer = static_cast<char*>(malloc(strlen(path) + 1));  // +1 for '\0'
  char* output = buffer;

  while (*input != '\0') {
    if (strncmp("../", input, 3) == 0) {
      // Discard initial "../" from the input.  It's junk.
      input += 3;

    } else if (strncmp("./", input, 3) == 0) {
      // Discard initial "./" from the input.  It's junk.
      input += 2;

    } else if (strncmp("/./", input, 3) == 0) {
      // Advance past the "/." part of the input.
      input += 2;

    } else if (strcmp("/.", input) == 0) {
      // Pretend the input just contains a "/".
      input = "/";

    } else if (strncmp("/../", input, 4) == 0) {
      // Advance past the "/.." part of the input and remove one
      // segment from the output.
      input += 3;
      output = RemoveLastSegment(output, buffer);

    } else if (strcmp("/..", input) == 0) {
      // Pretend the input contains a "/" and remove one segment from
      // the output.
      input = "/";
      output = RemoveLastSegment(output, buffer);

    } else if (strcmp("..", input) == 0) {
      // The input has been reduced to nothing useful.
      input += 2;

    } else if (strcmp(".", input) == 0) {
      // The input has been reduced to nothing useful.
      input += 1;

    } else {
      intptr_t segment_len = SegmentLength(input);
      if (input[0] != '/' && output != buffer) {
        *output = '/';
        output++;
      }
      strncpy(output, input, segment_len);
      output += segment_len;
      input += segment_len;
    }
  }
  *output = '\0';
  return CStringUniquePtr(buffer);
}

// See RFC 3986 Section 5.2.3: Merge Paths.
CStringUniquePtr MergePaths(const char* base_path, const char* ref_path) {
  if (base_path[0] == '\0') {
    // If the base_path is empty, we prepend '/'.
    return PrintToString("/%s", ref_path);
  }

  // We need to find the last '/' in base_path.
  const char* last_slash = strrchr(base_path, '/');
  if (last_slash == nullptr) {
    // There is no slash in the base_path.  Return the ref_path unchanged.
    return MakeCopyOfString(ref_path);
  }

  // We found a '/' in the base_path.  Cut off everything after it and
  // add the ref_path.
  intptr_t truncated_base_len = last_slash - base_path;
  intptr_t ref_path_len = strlen(ref_path);
  intptr_t len = truncated_base_len + ref_path_len + 1;  // +1 for '/'
  char* buffer = static_cast<char*>(malloc(len + 1));    // +1 for '\0'

  // Copy truncated base.
  strncpy(buffer, base_path, truncated_base_len);

  // Add a slash.
  buffer[truncated_base_len] = '/';

  // Copy the ref_path.
  strncpy((buffer + truncated_base_len + 1), ref_path, ref_path_len + 1);

  return CStringUniquePtr(buffer);
}

CStringUniquePtr BuildUri(const ParsedUri& uri) {
  ASSERT(uri.path != nullptr);

  const char* fragment = uri.fragment == nullptr ? "" : uri.fragment.get();
  const char* fragment_separator = uri.fragment == nullptr ? "" : "#";
  const char* query = uri.query == nullptr ? "" : uri.query.get();
  const char* query_separator = uri.query == nullptr ? "" : "?";

  // If there is no scheme for this uri, just build a relative uri of
  // the form: "path[?query][#fragment]".  This occurs when we resolve
  // relative urls inside a "dart:" library.
  if (uri.scheme == nullptr) {
    ASSERT(uri.userinfo == nullptr && uri.host == nullptr &&
           uri.port == nullptr);
    return PrintToString("%s%s%s%s%s", uri.path.get(), query_separator, query,
                         fragment_separator, fragment);
  }

  // Uri with no authority: "scheme:path[?query][#fragment]"
  if (uri.host == nullptr) {
    ASSERT(uri.userinfo == nullptr && uri.port == nullptr);
    return PrintToString("%s:%s%s%s%s%s", uri.scheme.get(), uri.path.get(),
                         query_separator, query, fragment_separator, fragment);
  }

  const char* user = uri.userinfo == nullptr ? "" : uri.userinfo.get();
  const char* user_separator = uri.userinfo == nullptr ? "" : "@";
  const char* port = uri.port == nullptr ? "" : uri.port.get();
  const char* port_separator = uri.port == nullptr ? "" : ":";

  // If the path doesn't start with a '/', add one.  We need it to
  // separate the path from the authority.
  const char* path_separator =
      ((uri.path.get()[0] == '\0' || uri.path.get()[0] == '/') ? "" : "/");

  // Uri with authority:
  //   "scheme://[userinfo@]host[:port][/]path[?query][#fragment]"
  return PrintToString(
      "%s://%s%s%s%s%s%s%s%s%s%s%s",  // There is *nothing* wrong with this.
      uri.scheme.get(), user, user_separator, uri.host.get(), port_separator,
      port, path_separator, uri.path.get(), query_separator, query,
      fragment_separator, fragment);
}

// See RFC 3986 Section 5: Reference Resolution
CStringUniquePtr ResolveUri(const char* ref_uri, const char* base_uri) {
  // Parse the reference uri.
  std::unique_ptr<ParsedUri> ref = ParseUri(ref_uri);
  if (!ref) {
    return CStringUniquePtr();
  }

  ParsedUri target;
  if (ref->scheme != nullptr) {
    if (strcmp(ref->scheme.get(), "dart") == 0) {
      return MakeCopyOfString(ref_uri);
    }

    // When the ref_uri specifies a scheme, the base_uri is ignored.
    target.scheme = std::move(ref->scheme);
    target.userinfo = std::move(ref->userinfo);
    target.host = std::move(ref->host);
    target.port = std::move(ref->port);
    target.path = std::move(ref->path);
    target.query = std::move(ref->query);
    target.fragment = std::move(ref->fragment);
    return BuildUri(target);
  }

  // Parse the base uri.
  std::unique_ptr<ParsedUri> base = ParseUri(base_uri);
  if (!base) {
    return CStringUniquePtr();
  }

  if ((base->scheme != nullptr) && strcmp(base->scheme.get(), "dart") == 0) {
    return MakeCopyOfString(ref_uri);
  }

  if (ref->host != nullptr) {
    // When the ref_uri specifies an authority, we only use the base scheme.
    target.scheme = std::move(base->scheme);
    target.userinfo = std::move(ref->userinfo);
    target.host = std::move(ref->host);
    target.port = std::move(ref->port);
    target.path = RemoveDotSegments(ref->path.get());
    target.query = std::move(ref->query);
    target.fragment = std::move(ref->fragment);
    return BuildUri(target);
  }

  if (ref->path.get()[0] == '\0') {
    // Empty path.  Use most parts of base_uri.
    target.scheme = std::move(base->scheme);
    target.userinfo = std::move(base->userinfo);
    target.host = std::move(base->host);
    target.port = std::move(base->port);
    target.path = std::move(base->path);
    target.query = ((ref->query == nullptr) ? std::move(base->query)
                                            : std::move(ref->query));
    target.fragment = std::move(ref->fragment);
    return BuildUri(target);

  } else if (ref->path.get()[0] == '/') {
    // Absolute path.  ref_path wins.
    target.scheme = std::move(base->scheme);
    target.userinfo = std::move(base->userinfo);
    target.host = std::move(base->host);
    target.port = std::move(base->port);
    target.path = RemoveDotSegments(ref->path.get());
    target.query = std::move(ref->query);
    target.fragment = std::move(ref->fragment);
    return BuildUri(target);

  } else {
    // Relative path.  We need to merge the base path and the ref path.

    if (base->scheme == nullptr && base->host == nullptr &&
        base->path.get()[0] != '/') {
      // The dart:core Uri class handles resolving a relative uri
      // against a second relative uri specially, in a way not
      // described in the RFC.  We do not need to support this for
      // library resolution.  If we need to implement this later, we
      // can.
      return CStringUniquePtr();
    }

    target.scheme = std::move(base->scheme);
    target.userinfo = std::move(base->userinfo);
    target.host = std::move(base->host);
    target.port = std::move(base->port);
    CStringUniquePtr merged_paths =
        MergePaths(base->path.get(), ref->path.get());
    target.path = RemoveDotSegments(merged_paths.get());
    target.query = std::move(ref->query);
    target.fragment = std::move(ref->fragment);
    return BuildUri(target);
  }
}

}  // namespace dart
