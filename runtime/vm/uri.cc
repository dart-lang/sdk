// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/uri.h"

#include "vm/zone.h"

namespace dart {

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

static char* NormalizeEscapes(const char* str, intptr_t len) {
  // Allocate the buffer.
  Zone* zone = Thread::Current()->zone();
  // We multiply len by three because a percent-escape sequence is
  // three characters long (e.g. ' ' -> '%20).  +1 for '\0'.  We could
  // take two passes through the string and avoid the excess
  // allocation, but it's zone-memory so it doesn't seem necessary.
  char* buffer = zone->Alloc<char>(len * 3 + 1);

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
        OS::SNPrint(buffer + buffer_pos, 4, "%%%02X", escaped_value);
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
        OS::SNPrint(buffer + buffer_pos, 4, "%%%02X", c);
        buffer_pos += 3;
      }
      pos++;
    }
  }
  buffer[buffer_pos] = '\0';
  return buffer;
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
      // transforming any non-acii characters.
      char c = str[i];
      if (c >= 'A' && c <= 'Z') {
        str[i] = c + ('a' - 'A');
      }
      i++;
    }
  }
}

static void ClearParsedUri(ParsedUri* parsed_uri) {
  parsed_uri->scheme = NULL;
  parsed_uri->userinfo = NULL;
  parsed_uri->host = NULL;
  parsed_uri->port = NULL;
  parsed_uri->path = NULL;
  parsed_uri->query = NULL;
  parsed_uri->fragment = NULL;
}

static intptr_t ParseAuthority(const char* authority, ParsedUri* parsed_uri) {
  Zone* zone = Thread::Current()->zone();
  const char* current = authority;
  intptr_t len = 0;

  size_t userinfo_len = strcspn(current, "@/");
  if (current[userinfo_len] == '@') {
    // The '@' character follows the optional userinfo string.
    parsed_uri->userinfo = NormalizeEscapes(current, userinfo_len);
    current += userinfo_len + 1;
    len += userinfo_len + 1;
  } else {
    parsed_uri->userinfo = NULL;
  }

  size_t host_len = strcspn(current, ":/");
  char* host = NormalizeEscapes(current, host_len);
  StringLower(host);
  parsed_uri->host = host;
  len += host_len;

  if (current[host_len] == ':') {
    // The ':' character precedes the optional port string.
    const char* port_start = current + host_len + 1;  // +1 for ':'
    size_t port_len = strcspn(port_start, "/");
    parsed_uri->port = zone->MakeCopyOfStringN(port_start, port_len);
    len += 1 + port_len;  // +1 for ':'
  } else {
    parsed_uri->port = NULL;
  }
  return len;
}

// Performs a simple parse of a uri into its components.
// See RFC 3986 Section 3: Syntax.
bool ParseUri(const char* uri, ParsedUri* parsed_uri) {
  Zone* zone = Thread::Current()->zone();

  // The first ':' separates the scheme from the rest of the uri.  If
  // a ':' occurs after the first '/' it doesn't count.
  size_t scheme_len = strcspn(uri, ":/");
  const char* rest = uri;
  if (uri[scheme_len] == ':') {
    char* scheme = zone->MakeCopyOfStringN(uri, scheme_len);
    StringLower(scheme);
    parsed_uri->scheme = scheme;
    rest = uri + scheme_len + 1;
  } else {
    parsed_uri->scheme = NULL;
  }

  // The first '#' separates the optional fragment
  const char* hash_pos = rest + strcspn(rest, "#");
  if (*hash_pos == '#') {
    // There is a fragment part.
    const char* fragment_start = hash_pos + 1;
    parsed_uri->fragment =
        NormalizeEscapes(fragment_start, strlen(fragment_start));
  } else {
    parsed_uri->fragment = NULL;
  }

  // The first '?' or '#' separates the hierarchical part from the
  // optional query.
  const char* question_pos = rest + strcspn(rest, "?#");
  if (*question_pos == '?') {
    // There is a query part.
    const char* query_start = question_pos + 1;
    parsed_uri->query = NormalizeEscapes(query_start, (hash_pos - query_start));
  } else {
    parsed_uri->query = NULL;
  }

  const char* path_start = rest;
  if (rest[0] == '/' && rest[1] == '/') {
    // There is an authority part.
    const char* authority_start = rest + 2;  // 2 for '//'.

    intptr_t authority_len = ParseAuthority(authority_start, parsed_uri);
    if (authority_len < 0) {
      ClearParsedUri(parsed_uri);
      return false;
    }
    path_start = authority_start + authority_len;
  } else {
    parsed_uri->userinfo = NULL;
    parsed_uri->host = NULL;
    parsed_uri->port = NULL;
  }

  // The path is the substring between the authority and the query.
  parsed_uri->path = NormalizeEscapes(path_start, (question_pos - path_start));
  return true;
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
static const char* RemoveDotSegments(const char* path) {
  const char* input = path;

  // The output path will always be less than or equal to the size of
  // the input path.
  Zone* zone = Thread::Current()->zone();
  char* buffer = zone->Alloc<char>(strlen(path) + 1);  // +1 for '\0'
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
  return buffer;
}

// See RFC 3986 Section 5.2.3: Merge Paths.
static const char* MergePaths(const char* base_path, const char* ref_path) {
  Zone* zone = Thread::Current()->zone();
  if (base_path[0] == '\0') {
    // If the base_path is empty, we prepend '/'.
    return zone->PrintToString("/%s", ref_path);
  }

  // We need to find the last '/' in base_path.
  const char* last_slash = strrchr(base_path, '/');
  if (last_slash == NULL) {
    // There is no slash in the base_path.  Return the ref_path unchanged.
    return ref_path;
  }

  // We found a '/' in the base_path.  Cut off everything after it and
  // add the ref_path.
  intptr_t truncated_base_len = last_slash - base_path;
  intptr_t ref_path_len = strlen(ref_path);
  intptr_t len = truncated_base_len + ref_path_len + 1;  // +1 for '/'
  char* buffer = zone->Alloc<char>(len + 1);             // +1 for '\0'

  // Copy truncated base.
  strncpy(buffer, base_path, truncated_base_len);

  // Add a slash.
  buffer[truncated_base_len] = '/';

  // Copy the ref_path.
  strncpy((buffer + truncated_base_len + 1), ref_path, ref_path_len);

  // Add the trailing '\0'.
  buffer[len] = '\0';

  return buffer;
}

static char* BuildUri(const ParsedUri& uri) {
  Zone* zone = Thread::Current()->zone();
  ASSERT(uri.path != NULL);

  const char* fragment = uri.fragment == NULL ? "" : uri.fragment;
  const char* fragment_separator = uri.fragment == NULL ? "" : "#";
  const char* query = uri.query == NULL ? "" : uri.query;
  const char* query_separator = uri.query == NULL ? "" : "?";

  // If there is no scheme for this uri, just build a relative uri of
  // the form: "path[?query][#fragment]".  This occurs when we resolve
  // relative urls inside a "dart:" library.
  if (uri.scheme == NULL) {
    ASSERT(uri.userinfo == NULL && uri.host == NULL && uri.port == NULL);
    return zone->PrintToString("%s%s%s%s%s", uri.path, query_separator, query,
                               fragment_separator, fragment);
  }

  // Uri with no authority: "scheme:path[?query][#fragment]"
  if (uri.host == NULL) {
    ASSERT(uri.userinfo == NULL && uri.port == NULL);
    return zone->PrintToString("%s:%s%s%s%s%s", uri.scheme, uri.path,
                               query_separator, query, fragment_separator,
                               fragment);
  }

  const char* user = uri.userinfo == NULL ? "" : uri.userinfo;
  const char* user_separator = uri.userinfo == NULL ? "" : "@";
  const char* port = uri.port == NULL ? "" : uri.port;
  const char* port_separator = uri.port == NULL ? "" : ":";

  // If the path doesn't start with a '/', add one.  We need it to
  // separate the path from the authority.
  const char* path_separator =
      ((uri.path[0] == '\0' || uri.path[0] == '/') ? "" : "/");

  // Uri with authority:
  //   "scheme://[userinfo@]host[:port][/]path[?query][#fragment]"
  return zone->PrintToString(
      "%s://%s%s%s%s%s%s%s%s%s%s%s",  // There is *nothing* wrong with this.
      uri.scheme, user, user_separator, uri.host, port_separator, port,
      path_separator, uri.path, query_separator, query, fragment_separator,
      fragment);
}

// See RFC 3986 Section 5: Reference Resolution
bool ResolveUri(const char* ref_uri,
                const char* base_uri,
                const char** target_uri) {
  // Parse the reference uri.
  ParsedUri ref;
  if (!ParseUri(ref_uri, &ref)) {
    *target_uri = NULL;
    return false;
  }

  ParsedUri target;
  if (ref.scheme != NULL) {
    if (strcmp(ref.scheme, "dart") == 0) {
      Zone* zone = Thread::Current()->zone();
      *target_uri = zone->MakeCopyOfString(ref_uri);
      return true;
    }

    // When the ref_uri specifies a scheme, the base_uri is ignored.
    target.scheme = ref.scheme;
    target.userinfo = ref.userinfo;
    target.host = ref.host;
    target.port = ref.port;
    target.path = RemoveDotSegments(ref.path);
    target.query = ref.query;
    target.fragment = ref.fragment;
    *target_uri = BuildUri(target);
    return true;
  }

  // Parse the base uri.
  ParsedUri base;
  if (!ParseUri(base_uri, &base)) {
    *target_uri = NULL;
    return false;
  }

  if ((base.scheme != NULL) && strcmp(base.scheme, "dart") == 0) {
    Zone* zone = Thread::Current()->zone();
    *target_uri = zone->MakeCopyOfString(ref_uri);
    return true;
  }

  if (ref.host != NULL) {
    // When the ref_uri specifies an authority, we only use the base scheme.
    target.scheme = base.scheme;
    target.userinfo = ref.userinfo;
    target.host = ref.host;
    target.port = ref.port;
    target.path = RemoveDotSegments(ref.path);
    target.query = ref.query;
    target.fragment = ref.fragment;
    *target_uri = BuildUri(target);
    return true;
  }

  if (ref.path[0] == '\0') {
    // Empty path.  Use most parts of base_uri.
    target.scheme = base.scheme;
    target.userinfo = base.userinfo;
    target.host = base.host;
    target.port = base.port;
    target.path = base.path;
    target.query = ((ref.query == NULL) ? base.query : ref.query);
    target.fragment = ref.fragment;
    *target_uri = BuildUri(target);
    return true;

  } else if (ref.path[0] == '/') {
    // Absolute path.  ref_path wins.
    target.scheme = base.scheme;
    target.userinfo = base.userinfo;
    target.host = base.host;
    target.port = base.port;
    target.path = RemoveDotSegments(ref.path);
    target.query = ref.query;
    target.fragment = ref.fragment;
    *target_uri = BuildUri(target);
    return true;

  } else {
    // Relative path.  We need to merge the base path and the ref path.

    if (base.scheme == NULL && base.host == NULL && base.path[0] != '/') {
      // The dart:core Uri class handles resolving a relative uri
      // against a second relative uri specially, in a way not
      // described in the RFC.  We do not need to support this for
      // library resolution.  If we need to implement this later, we
      // can.
      *target_uri = NULL;
      return false;
    }

    target.scheme = base.scheme;
    target.userinfo = base.userinfo;
    target.host = base.host;
    target.port = base.port;
    target.path = RemoveDotSegments(MergePaths(base.path, ref.path));
    target.query = ref.query;
    target.fragment = ref.fragment;
    *target_uri = BuildUri(target);
    return true;
  }
}

}  // namespace dart
