// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REGEXP_REGEXP_H_
#define RUNTIME_VM_REGEXP_REGEXP_H_

#include "platform/unicode.h"

#include "vm/object.h"
#include "vm/regexp/regexp_assembler.h"
#include "vm/splay-tree.h"

namespace dart {

class NodeVisitor;
class RegExpCompiler;
class RegExpMacroAssembler;
class RegExpNode;
class RegExpTree;
class BoyerMooreLookahead;

// Represents code units in the range from from_ to to_, both ends are
// inclusive.
class CharacterRange {
 public:
  CharacterRange() : from_(0), to_(0) {}
  CharacterRange(int32_t from, int32_t to) : from_(from), to_(to) {}

  static void AddClassEscape(uint16_t type,
                             ZoneGrowableArray<CharacterRange>* ranges);
  // Add class escapes with case equivalent closure for \w and \W if necessary.
  static void AddClassEscape(uint16_t type,
                             ZoneGrowableArray<CharacterRange>* ranges,
                             bool add_unicode_case_equivalents);
  static GrowableArray<const intptr_t> GetWordBounds();
  static inline CharacterRange Singleton(int32_t value) {
    return CharacterRange(value, value);
  }
  static inline CharacterRange Range(int32_t from, int32_t to) {
    ASSERT(from <= to);
    return CharacterRange(from, to);
  }
  static inline CharacterRange Everything() {
    return CharacterRange(0, Utf::kMaxCodePoint);
  }
  static inline ZoneGrowableArray<CharacterRange>* List(Zone* zone,
                                                        CharacterRange range) {
    auto list = new (zone) ZoneGrowableArray<CharacterRange>(1);
    list->Add(range);
    return list;
  }
  bool Contains(int32_t i) const { return from_ <= i && i <= to_; }
  int32_t from() const { return from_; }
  void set_from(int32_t value) { from_ = value; }
  int32_t to() const { return to_; }
  void set_to(int32_t value) { to_ = value; }
  bool is_valid() const { return from_ <= to_; }
  bool IsEverything(int32_t max) const { return from_ == 0 && to_ >= max; }
  bool IsSingleton() const { return (from_ == to_); }
  static void AddCaseEquivalents(ZoneGrowableArray<CharacterRange>* ranges,
                                 bool is_one_byte,
                                 Zone* zone);
  static void Split(ZoneGrowableArray<CharacterRange>* base,
                    GrowableArray<const intptr_t> overlay,
                    ZoneGrowableArray<CharacterRange>** included,
                    ZoneGrowableArray<CharacterRange>** excluded,
                    Zone* zone);
  // Whether a range list is in canonical form: Ranges ordered by from value,
  // and ranges non-overlapping and non-adjacent.
  static bool IsCanonical(ZoneGrowableArray<CharacterRange>* ranges);
  // Convert range list to canonical form. The characters covered by the ranges
  // will still be the same, but no character is in more than one range, and
  // adjacent ranges are merged. The resulting list may be shorter than the
  // original, but cannot be longer.
  static void Canonicalize(ZoneGrowableArray<CharacterRange>* ranges);
  // Negate the contents of a character range in canonical form.
  static void Negate(ZoneGrowableArray<CharacterRange>* src,
                     ZoneGrowableArray<CharacterRange>* dst);
  static constexpr intptr_t kStartMarker = (1 << 24);
  static constexpr intptr_t kPayloadMask = (1 << 24) - 1;

 private:
  int32_t from_;
  int32_t to_;

  DISALLOW_ALLOCATION();
};

// A set of unsigned integers that behaves especially well on small
// integers (< 32).  May do zone-allocation.
class OutSet : public ZoneAllocated {
 public:
  OutSet() : first_(0), remaining_(nullptr), successors_(nullptr) {}
  OutSet* Extend(unsigned value, Zone* zone);
  bool Get(unsigned value) const;
  static constexpr unsigned kFirstLimit = 32;

 private:
  // Destructively set a value in this set.  In most cases you want
  // to use Extend instead to ensure that only one instance exists
  // that contains the same values.
  void Set(unsigned value, Zone* zone);

  // The successors are a list of sets that contain the same values
  // as this set and the one more value that is not present in this
  // set.
  ZoneGrowableArray<OutSet*>* successors() { return successors_; }

  OutSet(uint32_t first, ZoneGrowableArray<unsigned>* remaining)
      : first_(first), remaining_(remaining), successors_(nullptr) {}
  uint32_t first_;
  ZoneGrowableArray<unsigned>* remaining_;
  ZoneGrowableArray<OutSet*>* successors_;
  friend class Trace;
};

// A mapping from integers, specified as ranges, to a set of integers.
// Used for mapping character ranges to choices.
class ChoiceTable : public ValueObject {
 public:
  explicit ChoiceTable(Zone* zone) : tree_(zone) {}

  class Entry {
   public:
    Entry() : from_(0), to_(0), out_set_(nullptr) {}
    Entry(int32_t from, int32_t to, OutSet* out_set)
        : from_(from), to_(to), out_set_(out_set) {
      ASSERT(from <= to);
    }
    int32_t from() { return from_; }
    int32_t to() { return to_; }
    void set_to(int32_t value) { to_ = value; }
    void AddValue(int value, Zone* zone) {
      out_set_ = out_set_->Extend(value, zone);
    }
    OutSet* out_set() { return out_set_; }

   private:
    int32_t from_;
    int32_t to_;
    OutSet* out_set_;
  };

  class Config {
   public:
    typedef int32_t Key;
    typedef Entry Value;
    static const int32_t kNoKey;
    static const Entry NoValue() { return Value(); }
    static inline int Compare(int32_t a, int32_t b) {
      if (a == b)
        return 0;
      else if (a < b)
        return -1;
      else
        return 1;
    }
  };

  void AddRange(CharacterRange range, int32_t value, Zone* zone);
  OutSet* Get(int32_t value);
  void Dump();

  template <typename Callback>
  void ForEach(Callback* callback) {
    return tree()->ForEach(callback);
  }

 private:
  // There can't be a static empty set since it allocates its
  // successors in a zone and caches them.
  OutSet* empty() { return &empty_; }
  OutSet empty_;
  ZoneSplayTree<Config>* tree() { return &tree_; }
  ZoneSplayTree<Config> tree_;
};

// Categorizes character ranges into BMP, non-BMP, lead, and trail surrogates.
class UnicodeRangeSplitter : public ValueObject {
 public:
  UnicodeRangeSplitter(Zone* zone, ZoneGrowableArray<CharacterRange>* base);
  void Call(uint32_t from, ChoiceTable::Entry entry);

  ZoneGrowableArray<CharacterRange>* bmp() { return bmp_; }
  ZoneGrowableArray<CharacterRange>* lead_surrogates() {
    return lead_surrogates_;
  }
  ZoneGrowableArray<CharacterRange>* trail_surrogates() {
    return trail_surrogates_;
  }
  ZoneGrowableArray<CharacterRange>* non_bmp() const { return non_bmp_; }

 private:
  static constexpr int kBase = 0;
  // Separate ranges into
  static constexpr int kBmpCodePoints = 1;
  static constexpr int kLeadSurrogates = 2;
  static constexpr int kTrailSurrogates = 3;
  static constexpr int kNonBmpCodePoints = 4;

  Zone* zone_;
  ChoiceTable table_;
  ZoneGrowableArray<CharacterRange>* bmp_;
  ZoneGrowableArray<CharacterRange>* lead_surrogates_;
  ZoneGrowableArray<CharacterRange>* trail_surrogates_;
  ZoneGrowableArray<CharacterRange>* non_bmp_;
};

#define FOR_EACH_NODE_TYPE(VISIT)                                              \
  VISIT(End)                                                                   \
  VISIT(Action)                                                                \
  VISIT(Choice)                                                                \
  VISIT(BackReference)                                                         \
  VISIT(Assertion)                                                             \
  VISIT(Text)

#define FOR_EACH_REG_EXP_TREE_TYPE(VISIT)                                      \
  VISIT(Disjunction)                                                           \
  VISIT(Alternative)                                                           \
  VISIT(Assertion)                                                             \
  VISIT(CharacterClass)                                                        \
  VISIT(Atom)                                                                  \
  VISIT(Quantifier)                                                            \
  VISIT(Capture)                                                               \
  VISIT(Lookaround)                                                            \
  VISIT(BackReference)                                                         \
  VISIT(Empty)                                                                 \
  VISIT(Text)

#define FORWARD_DECLARE(Name) class RegExp##Name;
FOR_EACH_REG_EXP_TREE_TYPE(FORWARD_DECLARE)
#undef FORWARD_DECLARE

class TextElement {
 public:
  enum TextType { ATOM, CHAR_CLASS };

  static TextElement Atom(RegExpAtom* atom);
  static TextElement CharClass(RegExpCharacterClass* char_class);

  intptr_t cp_offset() const { return cp_offset_; }
  void set_cp_offset(intptr_t cp_offset) { cp_offset_ = cp_offset; }
  intptr_t length() const;

  TextType text_type() const { return text_type_; }

  RegExpTree* tree() const { return tree_; }

  RegExpAtom* atom() const {
    ASSERT(text_type() == ATOM);
    return reinterpret_cast<RegExpAtom*>(tree());
  }

  RegExpCharacterClass* char_class() const {
    ASSERT(text_type() == CHAR_CLASS);
    return reinterpret_cast<RegExpCharacterClass*>(tree());
  }

 private:
  TextElement(TextType text_type, RegExpTree* tree)
      : cp_offset_(-1), text_type_(text_type), tree_(tree) {}

  intptr_t cp_offset_;
  TextType text_type_;
  RegExpTree* tree_;

  DISALLOW_ALLOCATION();
};

class Trace;
struct PreloadState;
class GreedyLoopState;
class AlternativeGenerationList;

struct NodeInfo {
  NodeInfo()
      : being_analyzed(false),
        been_analyzed(false),
        follows_word_interest(false),
        follows_newline_interest(false),
        follows_start_interest(false),
        at_end(false),
        visited(false),
        replacement_calculated(false) {}

  // Returns true if the interests and assumptions of this node
  // matches the given one.
  bool Matches(NodeInfo* that) {
    return (at_end == that->at_end) &&
           (follows_word_interest == that->follows_word_interest) &&
           (follows_newline_interest == that->follows_newline_interest) &&
           (follows_start_interest == that->follows_start_interest);
  }

  // Updates the interests of this node given the interests of the
  // node preceding it.
  void AddFromPreceding(NodeInfo* that) {
    at_end |= that->at_end;
    follows_word_interest |= that->follows_word_interest;
    follows_newline_interest |= that->follows_newline_interest;
    follows_start_interest |= that->follows_start_interest;
  }

  bool HasLookbehind() {
    return follows_word_interest || follows_newline_interest ||
           follows_start_interest;
  }

  // Sets the interests of this node to include the interests of the
  // following node.
  void AddFromFollowing(NodeInfo* that) {
    follows_word_interest |= that->follows_word_interest;
    follows_newline_interest |= that->follows_newline_interest;
    follows_start_interest |= that->follows_start_interest;
  }

  void ResetCompilationState() {
    being_analyzed = false;
    been_analyzed = false;
  }

  bool being_analyzed : 1;
  bool been_analyzed : 1;

  // These bits are set of this node has to know what the preceding
  // character was.
  bool follows_word_interest : 1;
  bool follows_newline_interest : 1;
  bool follows_start_interest : 1;

  bool at_end : 1;
  bool visited : 1;
  bool replacement_calculated : 1;
};

// Details of a quick mask-compare check that can look ahead in the
// input stream.
class QuickCheckDetails {
 public:
  QuickCheckDetails()
      : characters_(0), mask_(0), value_(0), cannot_match_(false) {}
  explicit QuickCheckDetails(intptr_t characters)
      : characters_(characters), mask_(0), value_(0), cannot_match_(false) {}
  bool Rationalize(bool one_byte);
  // Merge in the information from another branch of an alternation.
  void Merge(QuickCheckDetails* other, intptr_t from_index);
  // Advance the current position by some amount.
  void Advance(intptr_t by, bool one_byte);
  void Clear();
  bool cannot_match() { return cannot_match_; }
  void set_cannot_match() { cannot_match_ = true; }
  struct Position {
    Position() : mask(0), value(0), determines_perfectly(false) {}
    uint16_t mask;
    uint16_t value;
    bool determines_perfectly;
  };
  intptr_t characters() { return characters_; }
  void set_characters(intptr_t characters) { characters_ = characters; }
  Position* positions(intptr_t index) {
    ASSERT(index >= 0);
    ASSERT(index < characters_);
    return positions_ + index;
  }
  uint32_t mask() { return mask_; }
  uint32_t value() { return value_; }

 private:
  // How many characters do we have quick check information from.  This is
  // the same for all branches of a choice node.
  intptr_t characters_;
  Position positions_[4];
  // These values are the condensate of the above array after Rationalize().
  uint32_t mask_;
  uint32_t value_;
  // If set to true, there is no way this quick check can match at all.
  // E.g., if it requires to be at the start of the input, and isn't.
  bool cannot_match_;

  DISALLOW_ALLOCATION();
};

class RegExpNode : public ZoneAllocated {
 public:
  explicit RegExpNode(Zone* zone)
      : replacement_(nullptr), trace_count_(0), zone_(zone) {
    bm_info_[0] = bm_info_[1] = nullptr;
  }
  virtual ~RegExpNode();
  virtual void Accept(NodeVisitor* visitor) = 0;
  // Generates a goto to this node or actually generates the code at this point.
  virtual void Emit(RegExpCompiler* compiler, Trace* trace) = 0;
  // How many characters must this node consume at a minimum in order to
  // succeed.  If we have found at least 'still_to_find' characters that
  // must be consumed there is no need to ask any following nodes whether
  // they are sure to eat any more characters.  The not_at_start argument is
  // used to indicate that we know we are not at the start of the input.  In
  // this case anchored branches will always fail and can be ignored when
  // determining how many characters are consumed on success.
  virtual intptr_t EatsAtLeast(intptr_t still_to_find,
                               intptr_t budget,
                               bool not_at_start) = 0;
  // Emits some quick code that checks whether the preloaded characters match.
  // Falls through on certain failure, jumps to the label on possible success.
  // If the node cannot make a quick check it does nothing and returns false.
  bool EmitQuickCheck(RegExpCompiler* compiler,
                      Trace* bounds_check_trace,
                      Trace* trace,
                      bool preload_has_checked_bounds,
                      BlockLabel* on_possible_success,
                      QuickCheckDetails* details_return,
                      bool fall_through_on_failure);
  // For a given number of characters this returns a mask and a value.  The
  // next n characters are anded with the mask and compared with the value.
  // A comparison failure indicates the node cannot match the next n characters.
  // A comparison success indicates the node may match.
  virtual void GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t characters_filled_in,
                                    bool not_at_start) = 0;
  static constexpr intptr_t kNodeIsTooComplexForGreedyLoops = -1;
  virtual intptr_t GreedyLoopTextLength() {
    return kNodeIsTooComplexForGreedyLoops;
  }
  // Only returns the successor for a text node of length 1 that matches any
  // character and that has no guards on it.
  virtual RegExpNode* GetSuccessorOfOmnivorousTextNode(
      RegExpCompiler* compiler) {
    return nullptr;
  }

  // Collects information on the possible code units (mod 128) that can match if
  // we look forward.  This is used for a Boyer-Moore-like string searching
  // implementation.  TODO(erikcorry):  This should share more code with
  // EatsAtLeast, GetQuickCheckDetails.  The budget argument is used to limit
  // the number of nodes we are willing to look at in order to create this data.
  static constexpr intptr_t kRecursionBudget = 200;
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start) {
    UNREACHABLE();
  }

  // If we know that the input is one-byte then there are some nodes that can
  // never match.  This method returns a node that can be substituted for
  // itself, or nullptr if the node can never match.
  virtual RegExpNode* FilterOneByte(intptr_t depth) { return this; }
  // Helper for FilterOneByte.
  RegExpNode* replacement() {
    ASSERT(info()->replacement_calculated);
    return replacement_;
  }
  RegExpNode* set_replacement(RegExpNode* replacement) {
    info()->replacement_calculated = true;
    replacement_ = replacement;
    return replacement;  // For convenience.
  }

  // We want to avoid recalculating the lookahead info, so we store it on the
  // node.  Only info that is for this node is stored.  We can tell that the
  // info is for this node when offset == 0, so the information is calculated
  // relative to this node.
  void SaveBMInfo(BoyerMooreLookahead* bm, bool not_at_start, intptr_t offset) {
    if (offset == 0) set_bm_info(not_at_start, bm);
  }

  BlockLabel* label() { return &label_; }
  // If non-generic code is generated for a node (i.e. the node is not at the
  // start of the trace) then it cannot be reused.  This variable sets a limit
  // on how often we allow that to happen before we insist on starting a new
  // trace and generating generic code for a node that can be reused by flushing
  // the deferred actions in the current trace and generating a goto.
  static constexpr intptr_t kMaxCopiesCodeGenerated = 10;

  NodeInfo* info() { return &info_; }

  BoyerMooreLookahead* bm_info(bool not_at_start) {
    return bm_info_[not_at_start ? 1 : 0];
  }

  Zone* zone() const { return zone_; }

 protected:
  enum LimitResult { DONE, CONTINUE };
  RegExpNode* replacement_;

  LimitResult LimitVersions(RegExpCompiler* compiler, Trace* trace);

  void set_bm_info(bool not_at_start, BoyerMooreLookahead* bm) {
    bm_info_[not_at_start ? 1 : 0] = bm;
  }

 private:
  static constexpr intptr_t kFirstCharBudget = 10;
  BlockLabel label_;
  NodeInfo info_;
  // This variable keeps track of how many times code has been generated for
  // this node (in different traces).  We don't keep track of where the
  // generated code is located unless the code is generated at the start of
  // a trace, in which case it is generic and can be reused by flushing the
  // deferred operations in the current trace and generating a goto.
  intptr_t trace_count_;
  BoyerMooreLookahead* bm_info_[2];
  Zone* zone_;
};

// A simple closed interval.
class Interval {
 public:
  Interval() : from_(kNone), to_(kNone) {}
  Interval(intptr_t from, intptr_t to) : from_(from), to_(to) {}

  Interval Union(Interval that) {
    if (that.from_ == kNone)
      return *this;
    else if (from_ == kNone)
      return that;
    else
      return Interval(Utils::Minimum(from_, that.from_),
                      Utils::Maximum(to_, that.to_));
  }
  bool Contains(intptr_t value) const {
    return (from_ <= value) && (value <= to_);
  }
  bool is_empty() const { return from_ == kNone; }
  intptr_t from() const { return from_; }
  intptr_t to() const { return to_; }
  static Interval Empty() { return Interval(); }
  static constexpr intptr_t kNone = -1;

 private:
  intptr_t from_;
  intptr_t to_;

  DISALLOW_ALLOCATION();
};

class SeqRegExpNode : public RegExpNode {
 public:
  explicit SeqRegExpNode(RegExpNode* on_success)
      : RegExpNode(on_success->zone()), on_success_(on_success) {}
  RegExpNode* on_success() { return on_success_; }
  void set_on_success(RegExpNode* node) { on_success_ = node; }
  virtual RegExpNode* FilterOneByte(intptr_t depth);
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start) {
    on_success_->FillInBMInfo(offset, budget - 1, bm, not_at_start);
    if (offset == 0) set_bm_info(not_at_start, bm);
  }

 protected:
  RegExpNode* FilterSuccessor(intptr_t depth);

 private:
  RegExpNode* on_success_;
};

class ActionNode : public SeqRegExpNode {
 public:
  enum ActionType {
    SET_REGISTER,
    INCREMENT_REGISTER,
    STORE_POSITION,
    BEGIN_SUBMATCH,
    POSITIVE_SUBMATCH_SUCCESS,
    EMPTY_MATCH_CHECK,
    CLEAR_CAPTURES
  };
  static ActionNode* SetRegister(intptr_t reg,
                                 intptr_t val,
                                 RegExpNode* on_success);
  static ActionNode* IncrementRegister(intptr_t reg, RegExpNode* on_success);
  static ActionNode* StorePosition(intptr_t reg,
                                   bool is_capture,
                                   RegExpNode* on_success);
  static ActionNode* ClearCaptures(Interval range, RegExpNode* on_success);
  static ActionNode* BeginSubmatch(intptr_t stack_pointer_reg,
                                   intptr_t position_reg,
                                   RegExpNode* on_success);
  static ActionNode* PositiveSubmatchSuccess(intptr_t stack_pointer_reg,
                                             intptr_t restore_reg,
                                             intptr_t clear_capture_count,
                                             intptr_t clear_capture_from,
                                             RegExpNode* on_success);
  static ActionNode* EmptyMatchCheck(intptr_t start_register,
                                     intptr_t repetition_register,
                                     intptr_t repetition_limit,
                                     RegExpNode* on_success);
  virtual void Accept(NodeVisitor* visitor);
  virtual void Emit(RegExpCompiler* compiler, Trace* trace);
  virtual intptr_t EatsAtLeast(intptr_t still_to_find,
                               intptr_t budget,
                               bool not_at_start);
  virtual void GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t filled_in,
                                    bool not_at_start) {
    return on_success()->GetQuickCheckDetails(details, compiler, filled_in,
                                              not_at_start);
  }
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start);
  ActionType action_type() { return action_type_; }
  // TODO(erikcorry): We should allow some action nodes in greedy loops.
  virtual intptr_t GreedyLoopTextLength() {
    return kNodeIsTooComplexForGreedyLoops;
  }

 private:
  union {
    struct {
      intptr_t reg;
      intptr_t value;
    } u_store_register;
    struct {
      intptr_t reg;
    } u_increment_register;
    struct {
      intptr_t reg;
      bool is_capture;
    } u_position_register;
    struct {
      intptr_t stack_pointer_register;
      intptr_t current_position_register;
      intptr_t clear_register_count;
      intptr_t clear_register_from;
    } u_submatch;
    struct {
      intptr_t start_register;
      intptr_t repetition_register;
      intptr_t repetition_limit;
    } u_empty_match_check;
    struct {
      intptr_t range_from;
      intptr_t range_to;
    } u_clear_captures;
  } data_;
  ActionNode(ActionType action_type, RegExpNode* on_success)
      : SeqRegExpNode(on_success), action_type_(action_type) {}
  ActionType action_type_;
  friend class DotPrinter;
};

class TextNode : public SeqRegExpNode {
 public:
  TextNode(ZoneGrowableArray<TextElement>* elms,
           bool read_backward,
           RegExpNode* on_success)
      : SeqRegExpNode(on_success), elms_(elms), read_backward_(read_backward) {}
  TextNode(RegExpCharacterClass* that,
           bool read_backward,
           RegExpNode* on_success)
      : SeqRegExpNode(on_success),
        elms_(new (zone()) ZoneGrowableArray<TextElement>(1)),
        read_backward_(read_backward) {
    elms_->Add(TextElement::CharClass(that));
  }
  // Create TextNode for a single character class for the given ranges.
  static TextNode* CreateForCharacterRanges(
      ZoneGrowableArray<CharacterRange>* ranges,
      bool read_backward,
      RegExpNode* on_success,
      RegExpFlags flags);
  // Create TextNode for a surrogate pair with a range given for the
  // lead and the trail surrogate each.
  static TextNode* CreateForSurrogatePair(CharacterRange lead,
                                          CharacterRange trail,
                                          bool read_backward,
                                          RegExpNode* on_success,
                                          RegExpFlags flags);
  virtual void Accept(NodeVisitor* visitor);
  virtual void Emit(RegExpCompiler* compiler, Trace* trace);
  virtual intptr_t EatsAtLeast(intptr_t still_to_find,
                               intptr_t budget,
                               bool not_at_start);
  virtual void GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t characters_filled_in,
                                    bool not_at_start);
  ZoneGrowableArray<TextElement>* elements() { return elms_; }
  bool read_backward() { return read_backward_; }
  void MakeCaseIndependent(bool is_one_byte);
  virtual intptr_t GreedyLoopTextLength();
  virtual RegExpNode* GetSuccessorOfOmnivorousTextNode(
      RegExpCompiler* compiler);
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start);
  void CalculateOffsets();
  virtual RegExpNode* FilterOneByte(intptr_t depth);

 private:
  enum TextEmitPassType {
    NON_LATIN1_MATCH,            // Check for characters that can't match.
    SIMPLE_CHARACTER_MATCH,      // Case-dependent single character check.
    NON_LETTER_CHARACTER_MATCH,  // Check characters that have no case equivs.
    CASE_CHARACTER_MATCH,        // Case-independent single character check.
    CHARACTER_CLASS_MATCH        // Character class.
  };
  static bool SkipPass(intptr_t pass, bool ignore_case);
  static constexpr intptr_t kFirstRealPass = SIMPLE_CHARACTER_MATCH;
  static constexpr intptr_t kLastPass = CHARACTER_CLASS_MATCH;
  void TextEmitPass(RegExpCompiler* compiler,
                    TextEmitPassType pass,
                    bool preloaded,
                    Trace* trace,
                    bool first_element_checked,
                    intptr_t* checked_up_to);
  intptr_t Length();
  ZoneGrowableArray<TextElement>* elms_;
  bool read_backward_;
};

class AssertionNode : public SeqRegExpNode {
 public:
  enum AssertionType {
    AT_END,
    AT_START,
    AT_BOUNDARY,
    AT_NON_BOUNDARY,
    AFTER_NEWLINE
  };
  static AssertionNode* AtEnd(RegExpNode* on_success) {
    return new (on_success->zone()) AssertionNode(AT_END, on_success);
  }
  static AssertionNode* AtStart(RegExpNode* on_success) {
    return new (on_success->zone()) AssertionNode(AT_START, on_success);
  }
  static AssertionNode* AtBoundary(RegExpNode* on_success) {
    return new (on_success->zone()) AssertionNode(AT_BOUNDARY, on_success);
  }
  static AssertionNode* AtNonBoundary(RegExpNode* on_success) {
    return new (on_success->zone()) AssertionNode(AT_NON_BOUNDARY, on_success);
  }
  static AssertionNode* AfterNewline(RegExpNode* on_success) {
    return new (on_success->zone()) AssertionNode(AFTER_NEWLINE, on_success);
  }
  virtual void Accept(NodeVisitor* visitor);
  virtual void Emit(RegExpCompiler* compiler, Trace* trace);
  virtual intptr_t EatsAtLeast(intptr_t still_to_find,
                               intptr_t budget,
                               bool not_at_start);
  virtual void GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t filled_in,
                                    bool not_at_start);
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start);
  AssertionType assertion_type() { return assertion_type_; }

 private:
  void EmitBoundaryCheck(RegExpCompiler* compiler, Trace* trace);
  enum IfPrevious { kIsNonWord, kIsWord };
  void BacktrackIfPrevious(RegExpCompiler* compiler,
                           Trace* trace,
                           IfPrevious backtrack_if_previous);
  AssertionNode(AssertionType t, RegExpNode* on_success)
      : SeqRegExpNode(on_success), assertion_type_(t) {}
  AssertionType assertion_type_;
};

class BackReferenceNode : public SeqRegExpNode {
 public:
  BackReferenceNode(intptr_t start_reg,
                    intptr_t end_reg,
                    RegExpFlags flags,
                    bool read_backward,
                    RegExpNode* on_success)
      : SeqRegExpNode(on_success),
        start_reg_(start_reg),
        end_reg_(end_reg),
        flags_(flags),
        read_backward_(read_backward) {}
  virtual void Accept(NodeVisitor* visitor);
  intptr_t start_register() { return start_reg_; }
  intptr_t end_register() { return end_reg_; }
  bool read_backward() { return read_backward_; }
  virtual void Emit(RegExpCompiler* compiler, Trace* trace);
  virtual intptr_t EatsAtLeast(intptr_t still_to_find,
                               intptr_t recursion_depth,
                               bool not_at_start);
  virtual void GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t characters_filled_in,
                                    bool not_at_start) {
    return;
  }
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start);

 private:
  intptr_t start_reg_;
  intptr_t end_reg_;
  RegExpFlags flags_;
  bool read_backward_;
};

class EndNode : public RegExpNode {
 public:
  enum Action { ACCEPT, BACKTRACK, NEGATIVE_SUBMATCH_SUCCESS };
  explicit EndNode(Action action, Zone* zone)
      : RegExpNode(zone), action_(action) {}
  virtual void Accept(NodeVisitor* visitor);
  virtual void Emit(RegExpCompiler* compiler, Trace* trace);
  virtual intptr_t EatsAtLeast(intptr_t still_to_find,
                               intptr_t recursion_depth,
                               bool not_at_start) {
    return 0;
  }
  virtual void GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t characters_filled_in,
                                    bool not_at_start) {
    // Returning 0 from EatsAtLeast should ensure we never get here.
    UNREACHABLE();
  }
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start) {
    // Returning 0 from EatsAtLeast should ensure we never get here.
    UNREACHABLE();
  }

 private:
  Action action_;
};

class NegativeSubmatchSuccess : public EndNode {
 public:
  NegativeSubmatchSuccess(intptr_t stack_pointer_reg,
                          intptr_t position_reg,
                          intptr_t clear_capture_count,
                          intptr_t clear_capture_start,
                          Zone* zone)
      : EndNode(NEGATIVE_SUBMATCH_SUCCESS, zone),
        stack_pointer_register_(stack_pointer_reg),
        current_position_register_(position_reg),
        clear_capture_count_(clear_capture_count),
        clear_capture_start_(clear_capture_start) {}
  virtual void Emit(RegExpCompiler* compiler, Trace* trace);

 private:
  intptr_t stack_pointer_register_;
  intptr_t current_position_register_;
  intptr_t clear_capture_count_;
  intptr_t clear_capture_start_;
};

class Guard : public ZoneAllocated {
 public:
  enum Relation { LT, GEQ };
  Guard(intptr_t reg, Relation op, intptr_t value)
      : reg_(reg), op_(op), value_(value) {}
  intptr_t reg() { return reg_; }
  Relation op() { return op_; }
  intptr_t value() { return value_; }

 private:
  intptr_t reg_;
  Relation op_;
  intptr_t value_;
};

class GuardedAlternative {
 public:
  explicit GuardedAlternative(RegExpNode* node)
      : node_(node), guards_(nullptr) {}
  void AddGuard(Guard* guard, Zone* zone);
  RegExpNode* node() const { return node_; }
  void set_node(RegExpNode* node) { node_ = node; }
  ZoneGrowableArray<Guard*>* guards() const { return guards_; }

 private:
  RegExpNode* node_;
  ZoneGrowableArray<Guard*>* guards_;

  DISALLOW_ALLOCATION();
};

struct AlternativeGeneration;

class ChoiceNode : public RegExpNode {
 public:
  explicit ChoiceNode(intptr_t expected_size, Zone* zone)
      : RegExpNode(zone),
        alternatives_(new (zone)
                          ZoneGrowableArray<GuardedAlternative>(expected_size)),
        not_at_start_(false),
        being_calculated_(false) {}
  virtual void Accept(NodeVisitor* visitor);
  void AddAlternative(GuardedAlternative node) { alternatives()->Add(node); }
  ZoneGrowableArray<GuardedAlternative>* alternatives() {
    return alternatives_;
  }
  virtual void Emit(RegExpCompiler* compiler, Trace* trace);
  virtual intptr_t EatsAtLeast(intptr_t still_to_find,
                               intptr_t budget,
                               bool not_at_start);
  intptr_t EatsAtLeastHelper(intptr_t still_to_find,
                             intptr_t budget,
                             RegExpNode* ignore_this_node,
                             bool not_at_start);
  virtual void GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t characters_filled_in,
                                    bool not_at_start);
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start);

  bool being_calculated() { return being_calculated_; }
  bool not_at_start() { return not_at_start_; }
  void set_not_at_start() { not_at_start_ = true; }
  void set_being_calculated(bool b) { being_calculated_ = b; }
  virtual bool try_to_emit_quick_check_for_alternative(bool is_first) {
    return true;
  }
  virtual RegExpNode* FilterOneByte(intptr_t depth);
  virtual bool read_backward() { return false; }

 protected:
  intptr_t GreedyLoopTextLengthForAlternative(
      const GuardedAlternative* alternative);
  ZoneGrowableArray<GuardedAlternative>* alternatives_;

 private:
  friend class Analysis;
  void GenerateGuard(RegExpMacroAssembler* macro_assembler,
                     Guard* guard,
                     Trace* trace);
  intptr_t CalculatePreloadCharacters(RegExpCompiler* compiler,
                                      intptr_t eats_at_least);
  void EmitOutOfLineContinuation(RegExpCompiler* compiler,
                                 Trace* trace,
                                 GuardedAlternative alternative,
                                 AlternativeGeneration* alt_gen,
                                 intptr_t preload_characters,
                                 bool next_expects_preload);
  void SetUpPreLoad(RegExpCompiler* compiler,
                    Trace* current_trace,
                    PreloadState* preloads);
  void AssertGuardsMentionRegisters(Trace* trace);
  intptr_t EmitOptimizedUnanchoredSearch(RegExpCompiler* compiler,
                                         Trace* trace);
  Trace* EmitGreedyLoop(RegExpCompiler* compiler,
                        Trace* trace,
                        AlternativeGenerationList* alt_gens,
                        PreloadState* preloads,
                        GreedyLoopState* greedy_loop_state,
                        intptr_t text_length);
  void EmitChoices(RegExpCompiler* compiler,
                   AlternativeGenerationList* alt_gens,
                   intptr_t first_choice,
                   Trace* trace,
                   PreloadState* preloads);
  // If true, this node is never checked at the start of the input.
  // Allows a new trace to start with at_start() set to false.
  bool not_at_start_;
  bool being_calculated_;
};

class NegativeLookaroundChoiceNode : public ChoiceNode {
 public:
  explicit NegativeLookaroundChoiceNode(GuardedAlternative this_must_fail,
                                        GuardedAlternative then_do_this,
                                        Zone* zone)
      : ChoiceNode(2, zone) {
    AddAlternative(this_must_fail);
    AddAlternative(then_do_this);
  }
  virtual intptr_t EatsAtLeast(intptr_t still_to_find,
                               intptr_t budget,
                               bool not_at_start);
  virtual void GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t characters_filled_in,
                                    bool not_at_start);
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start) {
    (*alternatives_)[1].node()->FillInBMInfo(offset, budget - 1, bm,
                                             not_at_start);
    if (offset == 0) set_bm_info(not_at_start, bm);
  }
  // For a negative lookahead we don't emit the quick check for the
  // alternative that is expected to fail.  This is because quick check code
  // starts by loading enough characters for the alternative that takes fewest
  // characters, but on a negative lookahead the negative branch did not take
  // part in that calculation (EatsAtLeast) so the assumptions don't hold.
  virtual bool try_to_emit_quick_check_for_alternative(bool is_first) {
    return !is_first;
  }
  virtual RegExpNode* FilterOneByte(intptr_t depth);
};

class LoopChoiceNode : public ChoiceNode {
 public:
  explicit LoopChoiceNode(bool body_can_be_zero_length,
                          bool read_backward,
                          Zone* zone)
      : ChoiceNode(2, zone),
        loop_node_(nullptr),
        continue_node_(nullptr),
        body_can_be_zero_length_(body_can_be_zero_length),
        read_backward_(read_backward) {}
  void AddLoopAlternative(GuardedAlternative alt);
  void AddContinueAlternative(GuardedAlternative alt);
  virtual void Emit(RegExpCompiler* compiler, Trace* trace);
  virtual intptr_t EatsAtLeast(intptr_t still_to_find,
                               intptr_t budget,
                               bool not_at_start);
  virtual void GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t characters_filled_in,
                                    bool not_at_start);
  virtual void FillInBMInfo(intptr_t offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start);
  RegExpNode* loop_node() { return loop_node_; }
  RegExpNode* continue_node() { return continue_node_; }
  bool body_can_be_zero_length() { return body_can_be_zero_length_; }
  virtual bool read_backward() { return read_backward_; }
  virtual void Accept(NodeVisitor* visitor);
  virtual RegExpNode* FilterOneByte(intptr_t depth);

 private:
  // AddAlternative is made private for loop nodes because alternatives
  // should not be added freely, we need to keep track of which node
  // goes back to the node itself.
  void AddAlternative(GuardedAlternative node) {
    ChoiceNode::AddAlternative(node);
  }

  RegExpNode* loop_node_;
  RegExpNode* continue_node_;
  bool body_can_be_zero_length_;
  bool read_backward_;
};

// Improve the speed that we scan for an initial point where a non-anchored
// regexp can match by using a Boyer-Moore-like table. This is done by
// identifying non-greedy non-capturing loops in the nodes that eat any
// character one at a time.  For example in the middle of the regexp
// /foo[\s\S]*?bar/ we find such a loop.  There is also such a loop implicitly
// inserted at the start of any non-anchored regexp.
//
// When we have found such a loop we look ahead in the nodes to find the set of
// characters that can come at given distances. For example for the regexp
// /.?foo/ we know that there are at least 3 characters ahead of us, and the
// sets of characters that can occur are [any, [f, o], [o]]. We find a range in
// the lookahead info where the set of characters is reasonably constrained. In
// our example this is from index 1 to 2 (0 is not constrained). We can now
// look 3 characters ahead and if we don't find one of [f, o] (the union of
// [f, o] and [o]) then we can skip forwards by the range size (in this case 2).
//
// For Unicode input strings we do the same, but modulo 128.
//
// We also look at the first string fed to the regexp and use that to get a hint
// of the character frequencies in the inputs. This affects the assessment of
// whether the set of characters is 'reasonably constrained'.
//
// We also have another lookahead mechanism (called quick check in the code),
// which uses a wide load of multiple characters followed by a mask and compare
// to determine whether a match is possible at this point.
enum ContainedInLattice {
  kNotYet = 0,
  kLatticeIn = 1,
  kLatticeOut = 2,
  kLatticeUnknown = 3  // Can also mean both in and out.
};

inline ContainedInLattice Combine(ContainedInLattice a, ContainedInLattice b) {
  return static_cast<ContainedInLattice>(a | b);
}

ContainedInLattice AddRange(ContainedInLattice a,
                            const intptr_t* ranges,
                            intptr_t ranges_size,
                            Interval new_range);

class BoyerMoorePositionInfo : public ZoneAllocated {
 public:
  explicit BoyerMoorePositionInfo(Zone* zone)
      : map_(new (zone) ZoneGrowableArray<bool>(kMapSize)),
        map_count_(0),
        w_(kNotYet),
        s_(kNotYet),
        d_(kNotYet),
        surrogate_(kNotYet) {
    for (intptr_t i = 0; i < kMapSize; i++) {
      map_->Add(false);
    }
  }

  bool& at(intptr_t i) { return (*map_)[i]; }

  static constexpr intptr_t kMapSize = 128;
  static constexpr intptr_t kMask = kMapSize - 1;

  intptr_t map_count() const { return map_count_; }

  void Set(intptr_t character);
  void SetInterval(const Interval& interval);
  void SetAll();
  bool is_non_word() { return w_ == kLatticeOut; }
  bool is_word() { return w_ == kLatticeIn; }

 private:
  ZoneGrowableArray<bool>* map_;
  intptr_t map_count_;            // Number of set bits in the map.
  ContainedInLattice w_;          // The \w character class.
  ContainedInLattice s_;          // The \s character class.
  ContainedInLattice d_;          // The \d character class.
  ContainedInLattice surrogate_;  // Surrogate UTF-16 code units.
};

class BoyerMooreLookahead : public ZoneAllocated {
 public:
  BoyerMooreLookahead(intptr_t length, RegExpCompiler* compiler, Zone* Zone);

  intptr_t length() { return length_; }
  intptr_t max_char() { return max_char_; }
  RegExpCompiler* compiler() { return compiler_; }

  intptr_t Count(intptr_t map_number) {
    return bitmaps_->At(map_number)->map_count();
  }

  BoyerMoorePositionInfo* at(intptr_t i) { return bitmaps_->At(i); }

  void Set(intptr_t map_number, intptr_t character) {
    if (character > max_char_) return;
    BoyerMoorePositionInfo* info = bitmaps_->At(map_number);
    info->Set(character);
  }

  void SetInterval(intptr_t map_number, const Interval& interval) {
    if (interval.from() > max_char_) return;
    BoyerMoorePositionInfo* info = bitmaps_->At(map_number);
    if (interval.to() > max_char_) {
      info->SetInterval(Interval(interval.from(), max_char_));
    } else {
      info->SetInterval(interval);
    }
  }

  void SetAll(intptr_t map_number) { bitmaps_->At(map_number)->SetAll(); }

  void SetRest(intptr_t from_map) {
    for (intptr_t i = from_map; i < length_; i++)
      SetAll(i);
  }
  void EmitSkipInstructions(RegExpMacroAssembler* masm);

 private:
  // This is the value obtained by EatsAtLeast.  If we do not have at least this
  // many characters left in the sample string then the match is bound to fail.
  // Therefore it is OK to read a character this far ahead of the current match
  // point.
  intptr_t length_;
  RegExpCompiler* compiler_;
  // 0xff for Latin1, 0xffff for UTF-16.
  intptr_t max_char_;
  ZoneGrowableArray<BoyerMoorePositionInfo*>* bitmaps_;

  intptr_t GetSkipTable(intptr_t min_lookahead,
                        intptr_t max_lookahead,
                        const TypedData& boolean_skip_table);
  bool FindWorthwhileInterval(intptr_t* from, intptr_t* to);
  intptr_t FindBestInterval(intptr_t max_number_of_chars,
                            intptr_t old_biggest_points,
                            intptr_t* from,
                            intptr_t* to);
};

// There are many ways to generate code for a node.  This class encapsulates
// the current way we should be generating.  In other words it encapsulates
// the current state of the code generator.  The effect of this is that we
// generate code for paths that the matcher can take through the regular
// expression.  A given node in the regexp can be code-generated several times
// as it can be part of several traces.  For example for the regexp:
// /foo(bar|ip)baz/ the code to match baz will be generated twice, once as part
// of the foo-bar-baz trace and once as part of the foo-ip-baz trace.  The code
// to match foo is generated only once (the traces have a common prefix).  The
// code to store the capture is deferred and generated (twice) after the places
// where baz has been matched.
class Trace {
 public:
  // A value for a property that is either known to be true, know to be false,
  // or not known.
  enum TriBool { UNKNOWN = -1, FALSE_VALUE = 0, TRUE_VALUE = 1 };

  class DeferredAction {
   public:
    DeferredAction(ActionNode::ActionType action_type, intptr_t reg)
        : action_type_(action_type), reg_(reg), next_(nullptr) {}
    DeferredAction* next() { return next_; }
    bool Mentions(intptr_t reg);
    intptr_t reg() { return reg_; }
    ActionNode::ActionType action_type() { return action_type_; }

   private:
    ActionNode::ActionType action_type_;
    intptr_t reg_;
    DeferredAction* next_;
    friend class Trace;

    DISALLOW_ALLOCATION();
  };

  class DeferredCapture : public DeferredAction {
   public:
    DeferredCapture(intptr_t reg, bool is_capture, Trace* trace)
        : DeferredAction(ActionNode::STORE_POSITION, reg),
          cp_offset_(trace->cp_offset()),
          is_capture_(is_capture) {}
    intptr_t cp_offset() { return cp_offset_; }
    bool is_capture() { return is_capture_; }

   private:
    intptr_t cp_offset_;
    bool is_capture_;
    void set_cp_offset(intptr_t cp_offset) { cp_offset_ = cp_offset; }
  };

  class DeferredSetRegister : public DeferredAction {
   public:
    DeferredSetRegister(intptr_t reg, intptr_t value)
        : DeferredAction(ActionNode::SET_REGISTER, reg), value_(value) {}
    intptr_t value() { return value_; }

   private:
    intptr_t value_;
  };

  class DeferredClearCaptures : public DeferredAction {
   public:
    explicit DeferredClearCaptures(Interval range)
        : DeferredAction(ActionNode::CLEAR_CAPTURES, -1), range_(range) {}
    Interval range() { return range_; }

   private:
    Interval range_;
  };

  class DeferredIncrementRegister : public DeferredAction {
   public:
    explicit DeferredIncrementRegister(intptr_t reg)
        : DeferredAction(ActionNode::INCREMENT_REGISTER, reg) {}
  };

  Trace()
      : cp_offset_(0),
        actions_(nullptr),
        backtrack_(nullptr),
        stop_node_(nullptr),
        loop_label_(nullptr),
        characters_preloaded_(0),
        bound_checked_up_to_(0),
        flush_budget_(100),
        at_start_(UNKNOWN) {}

  // End the trace.  This involves flushing the deferred actions in the trace
  // and pushing a backtrack location onto the backtrack stack.  Once this is
  // done we can start a new trace or go to one that has already been
  // generated.
  void Flush(RegExpCompiler* compiler, RegExpNode* successor);
  intptr_t cp_offset() { return cp_offset_; }
  DeferredAction* actions() { return actions_; }
  // A trivial trace is one that has no deferred actions or other state that
  // affects the assumptions used when generating code.  There is no recorded
  // backtrack location in a trivial trace, so with a trivial trace we will
  // generate code that, on a failure to match, gets the backtrack location
  // from the backtrack stack rather than using a direct jump instruction.  We
  // always start code generation with a trivial trace and non-trivial traces
  // are created as we emit code for nodes or add to the list of deferred
  // actions in the trace.  The location of the code generated for a node using
  // a trivial trace is recorded in a label in the node so that gotos can be
  // generated to that code.
  bool is_trivial() {
    return backtrack_ == nullptr && actions_ == nullptr && cp_offset_ == 0 &&
           characters_preloaded_ == 0 && bound_checked_up_to_ == 0 &&
           quick_check_performed_.characters() == 0 && at_start_ == UNKNOWN;
  }
  TriBool at_start() { return at_start_; }
  void set_at_start(TriBool at_start) { at_start_ = at_start; }
  BlockLabel* backtrack() { return backtrack_; }
  BlockLabel* loop_label() { return loop_label_; }
  RegExpNode* stop_node() { return stop_node_; }
  intptr_t characters_preloaded() { return characters_preloaded_; }
  intptr_t bound_checked_up_to() { return bound_checked_up_to_; }
  intptr_t flush_budget() { return flush_budget_; }
  QuickCheckDetails* quick_check_performed() { return &quick_check_performed_; }
  bool mentions_reg(intptr_t reg);
  // Returns true if a deferred position store exists to the specified
  // register and stores the offset in the out-parameter.  Otherwise
  // returns false.
  bool GetStoredPosition(intptr_t reg, intptr_t* cp_offset);
  // These set methods and AdvanceCurrentPositionInTrace should be used only on
  // new traces - the intention is that traces are immutable after creation.
  void add_action(DeferredAction* new_action) {
    ASSERT(new_action->next_ == nullptr);
    new_action->next_ = actions_;
    actions_ = new_action;
  }
  void set_backtrack(BlockLabel* backtrack) { backtrack_ = backtrack; }
  void set_stop_node(RegExpNode* node) { stop_node_ = node; }
  void set_loop_label(BlockLabel* label) { loop_label_ = label; }
  void set_characters_preloaded(intptr_t count) {
    characters_preloaded_ = count;
  }
  void set_bound_checked_up_to(intptr_t to) { bound_checked_up_to_ = to; }
  void set_flush_budget(intptr_t to) { flush_budget_ = to; }
  void set_quick_check_performed(QuickCheckDetails* d) {
    quick_check_performed_ = *d;
  }
  void InvalidateCurrentCharacter();
  void AdvanceCurrentPositionInTrace(intptr_t by, RegExpCompiler* compiler);

 private:
  intptr_t FindAffectedRegisters(OutSet* affected_registers, Zone* zone);
  void PerformDeferredActions(RegExpMacroAssembler* macro,
                              intptr_t max_register,
                              const OutSet& affected_registers,
                              OutSet* registers_to_pop,
                              OutSet* registers_to_clear,
                              Zone* zone);
  void RestoreAffectedRegisters(RegExpMacroAssembler* macro,
                                intptr_t max_register,
                                const OutSet& registers_to_pop,
                                const OutSet& registers_to_clear);
  intptr_t cp_offset_;
  DeferredAction* actions_;
  BlockLabel* backtrack_;
  RegExpNode* stop_node_;
  BlockLabel* loop_label_;
  intptr_t characters_preloaded_;
  intptr_t bound_checked_up_to_;
  QuickCheckDetails quick_check_performed_;
  intptr_t flush_budget_;
  TriBool at_start_;

  DISALLOW_ALLOCATION();
};

class GreedyLoopState {
 public:
  explicit GreedyLoopState(bool not_at_start);

  BlockLabel* label() { return &label_; }
  Trace* counter_backtrack_trace() { return &counter_backtrack_trace_; }

 private:
  BlockLabel label_;
  Trace counter_backtrack_trace_;
};

struct PreloadState {
  static constexpr intptr_t kEatsAtLeastNotYetInitialized = -1;
  bool preload_is_current_;
  bool preload_has_checked_bounds_;
  intptr_t preload_characters_;
  intptr_t eats_at_least_;
  void init() { eats_at_least_ = kEatsAtLeastNotYetInitialized; }

  DISALLOW_ALLOCATION();
};

class NodeVisitor : public ValueObject {
 public:
  virtual ~NodeVisitor() {}
#define DECLARE_VISIT(Type) virtual void Visit##Type(Type##Node* that) = 0;
  FOR_EACH_NODE_TYPE(DECLARE_VISIT)
#undef DECLARE_VISIT
  virtual void VisitLoopChoice(LoopChoiceNode* that) { VisitChoice(that); }
};

// Assertion propagation moves information about assertions such as
// \b to the affected nodes.  For instance, in /.\b./ information must
// be propagated to the first '.' that whatever follows needs to know
// if it matched a word or a non-word, and to the second '.' that it
// has to check if it succeeds a word or non-word.  In this case the
// result will be something like:
//
//   +-------+        +------------+
//   |   .   |        |      .     |
//   +-------+  --->  +------------+
//   | word? |        | check word |
//   +-------+        +------------+
class Analysis : public NodeVisitor {
 public:
  explicit Analysis(bool is_one_byte)
      : is_one_byte_(is_one_byte), error_message_(nullptr) {}
  void EnsureAnalyzed(RegExpNode* node);

#define DECLARE_VISIT(Type) virtual void Visit##Type(Type##Node* that);
  FOR_EACH_NODE_TYPE(DECLARE_VISIT)
#undef DECLARE_VISIT
  virtual void VisitLoopChoice(LoopChoiceNode* that);

  bool has_failed() { return error_message_ != nullptr; }
  const char* error_message() {
    ASSERT(error_message_ != nullptr);
    return error_message_;
  }
  void fail(const char* error_message) { error_message_ = error_message; }

 private:
  bool is_one_byte_;
  const char* error_message_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(Analysis);
};

struct RegExpCompileData : public ZoneAllocated {
  RegExpCompileData()
      : tree(nullptr),
        node(nullptr),
        simple(true),
        contains_anchor(false),
        capture_name_map(Array::Handle(Array::null())),
        error(String::Handle(String::null())),
        capture_count(0) {}
  RegExpTree* tree;
  RegExpNode* node;
  bool simple;
  bool contains_anchor;
  Array& capture_name_map;
  String& error;
  intptr_t capture_count;
};

class RegExpEngine : public AllStatic {
 public:
  struct CompilationResult {
    explicit CompilationResult(const char* error_message)
        : error_message(error_message),
#if !defined(DART_PRECOMPILED_RUNTIME)
          backtrack_goto(nullptr),
          graph_entry(nullptr),
          num_blocks(-1),
          num_stack_locals(-1),
#endif
          bytecode(nullptr),
          num_registers(-1) {
    }

    CompilationResult(TypedData* bytecode, intptr_t num_registers)
        : error_message(nullptr),
#if !defined(DART_PRECOMPILED_RUNTIME)
          backtrack_goto(nullptr),
          graph_entry(nullptr),
          num_blocks(-1),
          num_stack_locals(-1),
#endif
          bytecode(bytecode),
          num_registers(num_registers) {
    }

#if !defined(DART_PRECOMPILED_RUNTIME)
    CompilationResult(IndirectGotoInstr* backtrack_goto,
                      GraphEntryInstr* graph_entry,
                      intptr_t num_blocks,
                      intptr_t num_stack_locals,
                      intptr_t num_registers)
        : error_message(nullptr),
          backtrack_goto(backtrack_goto),
          graph_entry(graph_entry),
          num_blocks(num_blocks),
          num_stack_locals(num_stack_locals),
          bytecode(nullptr) {}
#endif

    const char* error_message;

    NOT_IN_PRECOMPILED(IndirectGotoInstr* backtrack_goto);
    NOT_IN_PRECOMPILED(GraphEntryInstr* graph_entry);
    NOT_IN_PRECOMPILED(const intptr_t num_blocks);
    NOT_IN_PRECOMPILED(const intptr_t num_stack_locals);

    TypedData* bytecode;
    intptr_t num_registers;
  };

#if !defined(DART_PRECOMPILED_RUNTIME)
  static CompilationResult CompileIR(
      RegExpCompileData* input,
      const ParsedFunction* parsed_function,
      const ZoneGrowableArray<const ICData*>& ic_data_array,
      intptr_t osr_id);
#endif

  static CompilationResult CompileBytecode(RegExpCompileData* data,
                                           const RegExp& regexp,
                                           bool is_one_byte,
                                           bool sticky,
                                           Zone* zone);

  static RegExpPtr CreateRegExp(Thread* thread,
                                const String& pattern,
                                RegExpFlags flags);

  static void DotPrint(const char* label, RegExpNode* node, bool ignore_case);
};

void CreateSpecializedFunction(Thread* thread,
                               Zone* zone,
                               const RegExp& regexp,
                               intptr_t specialization_cid,
                               bool sticky,
                               const Object& owner);

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_REGEXP_H_
