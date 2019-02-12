// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//
// Constant values used for relevance values when creating completion
// suggestions in Dart code.
//

/// The relevance boost for available declarations with the matching tag.
const int DART_RELEVANCE_BOOST_AVAILABLE_DECLARATION = 10;

/// The relevance boost for available enum constants with the matching tag.
///
/// It is so large to move enum constants to the very top.
const int DART_RELEVANCE_BOOST_AVAILABLE_ENUM = 1100;

const int DART_RELEVANCE_BOOST_SUBTYPE = 100;
const int DART_RELEVANCE_BOOST_TYPE = 200;
const int DART_RELEVANCE_COMMON_USAGE = 1200;
const int DART_RELEVANCE_DEFAULT = 1000;
const int DART_RELEVANCE_HIGH = 2000;
const int DART_RELEVANCE_INHERITED_ACCESSOR = 1057;
const int DART_RELEVANCE_INHERITED_FIELD = 1058;
const int DART_RELEVANCE_INHERITED_METHOD = 1057;
const int DART_RELEVANCE_KEYWORD = 1055;
const int DART_RELEVANCE_LOCAL_ACCESSOR = 1057;
const int DART_RELEVANCE_LOCAL_FIELD = 1058;
const int DART_RELEVANCE_LOCAL_FUNCTION = 1056;
const int DART_RELEVANCE_LOCAL_METHOD = 1057;
const int DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE = 1056;
const int DART_RELEVANCE_LOCAL_VARIABLE = 1059;
const int DART_RELEVANCE_LOW = 500;
const int DART_RELEVANCE_NAMED_PARAMETER = 1060;
const int DART_RELEVANCE_NAMED_PARAMETER_REQUIRED = 1065;
const int DART_RELEVANCE_PARAMETER = 1059;
const int DART_RELEVANCE_TYPE_PARAMETER = 1058;
