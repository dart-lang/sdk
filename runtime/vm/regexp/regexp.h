// Copyright 2012 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef V8_REGEXP_REGEXP_H_
#define V8_REGEXP_REGEXP_H_

#include "vm/object.h"
#include "vm/regexp/base.h"
#include "vm/regexp/regexp-error.h"
#include "vm/regexp/regexp-flags.h"
#include "vm/regexp/zone-containers.h"

namespace dart {

class JSRegExp;
class RegExpCapture;
class RegExpData;
class IrRegExpData;
class AtomRegExpData;
class RegExpMatchInfo;
class RegExpNode;
class RegExpTree;

enum class RegExpCompilationTarget : int { kBytecode, kNative };

// TODO(jgruber): Do not expose in regexp.h.
// TODO(jgruber): Consider splitting between ParseData and CompileData.
struct RegExpCompileData {
  // The parsed AST as produced by the RegExpParser.
  RegExpTree* tree = nullptr;

  // The compiled Node graph as produced by RegExpTree::ToNode methods.
  RegExpNode* node = nullptr;

  // Either the generated code as produced by the compiler or a trampoline
  // to the interpreter.
  Object* code;

  // True, iff the pattern is a 'simple' atom with zero captures. In other
  // words, the pattern consists of a string with no metacharacters and special
  // regexp features, and can be implemented as a standard string search.
  bool simple = true;

  // True, iff the pattern is anchored at the start of the string with '^'.
  bool contains_anchor = false;

  // Only set if the pattern contains named captures.
  // Note: the lifetime equals that of the parse/compile zone.
  ZoneVector<RegExpCapture*>* named_captures = nullptr;

  // The error message. Only used if an error occurred during parsing or
  // compilation.
  RegExpError error = RegExpError::kNone;

  // The position at which the error was detected. Only used if an
  // error occurred.
  int error_pos = 0;

  // The number of capture groups, without the global capture \0.
  int capture_count = 0;

  // The number of registers used by the generated code.
  int register_count = 0;

  // The compilation target (bytecode or native code).
  RegExpCompilationTarget compilation_target;
};

class RegExpStatics final : public AllStatic {
 public:
  // Whether the irregexp engine generates interpreter bytecode.
  static bool CanGenerateBytecode();

  // Verify that the given flags combination is valid.
  static bool VerifyFlags(RegExpFlags flags);

  // Verify the given pattern, i.e. check that parsing succeeds. If
  // verification fails, `regexp_error_out` is set.
  template <class CharT>
  static bool VerifySyntax(Zone* zone,
                           uintptr_t stack_limit,
                           const CharT* input,
                           int input_length,
                           RegExpFlags flags,
                           RegExpError* regexp_error_out);

  // Parses the RegExp pattern and prepares the JSRegExp object with
  // generic data and choice of implementation - as well as what
  // the implementation wants to store in the data field.
  // Returns false if compilation fails.
  V8_WARN_UNUSED_RESULT static ObjectPtr Compile(Isolate* isolate,
                                                 const RegExp& re,
                                                 const String& pattern,
                                                 RegExpFlags flags,
                                                 uint32_t backtrack_limit);

  // Ensures that a regexp is fully compiled and ready to be executed on a
  // subject string.  Returns true on success. Throw and return false on
  // failure.
  V8_WARN_UNUSED_RESULT static bool EnsureFullyCompiled(Isolate* isolate,
                                                        const RegExp& re_data,
                                                        const String& subject);

  enum CallOrigin : int {
    kFromRuntime = 0,
    kFromJs = 1,
  };

  // See ECMA-262 section 15.10.6.2.
  // This function calls the garbage collector if necessary.
  V8_WARN_UNUSED_RESULT static std::optional<int> Exec(
      Isolate* isolate,
      RegExp& regexp,
      const String& subject,
      int index,
      int32_t* result_offsets_vector,
      uint32_t result_offsets_vector_length);
  // As above, but passes the result through the old-style RegExpMatchInfo|Null
  // interface. At most one match is returned.
  V8_WARN_UNUSED_RESULT static ObjectPtr Exec_Single(Isolate* isolate,
                                                     RegExp& regexp,
                                                     const String& subject,
                                                     int index,
                                                     Object& last_match_info);

  V8_WARN_UNUSED_RESULT static std::optional<int> ExperimentalOneshotExec(
      Isolate* isolate,
      RegExp& regexp,
      const String& subject,
      int index,
      int32_t* result_offsets_vector,
      uint32_t result_offsets_vector_length);

  // Called directly from generated code through ExternalReference.
  static intptr_t AtomExecRaw(Isolate* isolate,
                              uword /* AtomRegExpData */ data_address,
                              uword /* String */ subject_address,
                              int32_t index,
                              int32_t* result_offsets_vector,
                              int32_t result_offsets_vector_length);

  // Integral return values used throughout regexp code layers.
  static constexpr int kInternalRegExpFailure = 0;
  static constexpr int kInternalRegExpSuccess = 1;
  static constexpr int kInternalRegExpException = -1;
  static constexpr int kInternalRegExpRetry = -2;
  static constexpr int kInternalRegExpFallbackToExperimental = -3;
  static constexpr int kInternalRegExpSmallestResult = -3;

  enum IrregexpResult : int32_t {
    RE_FAILURE = kInternalRegExpFailure,
    RE_SUCCESS = kInternalRegExpSuccess,
    RE_EXCEPTION = kInternalRegExpException,
    RE_RETRY = kInternalRegExpRetry,
    RE_FALLBACK_TO_EXPERIMENTAL = kInternalRegExpFallbackToExperimental,
  };

  // Set last match info.  If match is nullptr, then setting captures is
  // omitted.
  static ObjectPtr SetLastMatchInfo(Isolate* isolate,
                                    ObjectPtr last_match_info,
                                    const String& subject,
                                    int capture_count,
                                    int32_t* match);

  static bool CompileForTesting(Isolate* isolate,
                                Zone* zone,
                                RegExpCompileData* input,
                                RegExpFlags flags,
                                const String& pattern,
                                const String& sample_subject,
                                Object& re_data,
                                bool is_one_byte);

  static void DotPrintForTesting(const char* label, RegExpNode* node);

  static const int kRegExpTooLargeToOptimize = 20 * KB;

  V8_WARN_UNUSED_RESULT
  static ObjectPtr ThrowRegExpException(Isolate* isolate,
                                        RegExpFlags flags,
                                        const String& pattern,
                                        RegExpError error);
  static void ThrowRegExpException(Isolate* isolate,
                                   const RegExp& re_data,
                                   RegExpError error_text);

  static bool IsUnmodifiedRegExp(Isolate* isolate, const RegExp& regexp);

  static ArrayPtr CreateCaptureNameMap(
      Isolate* isolate,
      ZoneVector<RegExpCapture*>* named_captures);

  static ObjectPtr Interpret(Thread* thread,
                             const RegExp& regexp,
                             const String& subject,
                             int start_index,
                             bool sticky);
};

}  // namespace dart

#endif  // V8_REGEXP_REGEXP_H_
