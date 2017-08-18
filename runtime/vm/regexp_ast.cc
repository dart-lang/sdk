// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/regexp_ast.h"

#include "platform/utils.h"
#include "vm/os.h"

namespace dart {

#define MAKE_ACCEPT(Name)                                                      \
  void* RegExp##Name::Accept(RegExpVisitor* visitor, void* data) {             \
    return visitor->Visit##Name(this, data);                                   \
  }
FOR_EACH_REG_EXP_TREE_TYPE(MAKE_ACCEPT)
#undef MAKE_ACCEPT

#define MAKE_TYPE_CASE(Name)                                                   \
  RegExp##Name* RegExpTree::As##Name() { return NULL; }                        \
  bool RegExpTree::Is##Name() const { return false; }
FOR_EACH_REG_EXP_TREE_TYPE(MAKE_TYPE_CASE)
#undef MAKE_TYPE_CASE

#define MAKE_TYPE_CASE(Name)                                                   \
  RegExp##Name* RegExp##Name::As##Name() { return this; }                      \
  bool RegExp##Name::Is##Name() const { return true; }
FOR_EACH_REG_EXP_TREE_TYPE(MAKE_TYPE_CASE)
#undef MAKE_TYPE_CASE

static Interval ListCaptureRegisters(ZoneGrowableArray<RegExpTree*>* children) {
  Interval result = Interval::Empty();
  for (intptr_t i = 0; i < children->length(); i++)
    result = result.Union(children->At(i)->CaptureRegisters());
  return result;
}

Interval RegExpAlternative::CaptureRegisters() const {
  return ListCaptureRegisters(nodes());
}

Interval RegExpDisjunction::CaptureRegisters() const {
  return ListCaptureRegisters(alternatives());
}

Interval RegExpLookahead::CaptureRegisters() const {
  return body()->CaptureRegisters();
}

Interval RegExpCapture::CaptureRegisters() const {
  Interval self(StartRegister(index()), EndRegister(index()));
  return self.Union(body()->CaptureRegisters());
}

Interval RegExpQuantifier::CaptureRegisters() const {
  return body()->CaptureRegisters();
}

bool RegExpAssertion::IsAnchoredAtStart() const {
  return assertion_type() == RegExpAssertion::START_OF_INPUT;
}

bool RegExpAssertion::IsAnchoredAtEnd() const {
  return assertion_type() == RegExpAssertion::END_OF_INPUT;
}

bool RegExpAlternative::IsAnchoredAtStart() const {
  ZoneGrowableArray<RegExpTree*>* nodes = this->nodes();
  for (intptr_t i = 0; i < nodes->length(); i++) {
    RegExpTree* node = nodes->At(i);
    if (node->IsAnchoredAtStart()) {
      return true;
    }
    if (node->max_match() > 0) {
      return false;
    }
  }
  return false;
}

bool RegExpAlternative::IsAnchoredAtEnd() const {
  ZoneGrowableArray<RegExpTree*>* nodes = this->nodes();
  for (intptr_t i = nodes->length() - 1; i >= 0; i--) {
    RegExpTree* node = nodes->At(i);
    if (node->IsAnchoredAtEnd()) {
      return true;
    }
    if (node->max_match() > 0) {
      return false;
    }
  }
  return false;
}

bool RegExpDisjunction::IsAnchoredAtStart() const {
  ZoneGrowableArray<RegExpTree*>* alternatives = this->alternatives();
  for (intptr_t i = 0; i < alternatives->length(); i++) {
    if (!alternatives->At(i)->IsAnchoredAtStart()) return false;
  }
  return true;
}

bool RegExpDisjunction::IsAnchoredAtEnd() const {
  ZoneGrowableArray<RegExpTree*>* alternatives = this->alternatives();
  for (intptr_t i = 0; i < alternatives->length(); i++) {
    if (!alternatives->At(i)->IsAnchoredAtEnd()) return false;
  }
  return true;
}

bool RegExpLookahead::IsAnchoredAtStart() const {
  return is_positive() && body()->IsAnchoredAtStart();
}

bool RegExpCapture::IsAnchoredAtStart() const {
  return body()->IsAnchoredAtStart();
}

bool RegExpCapture::IsAnchoredAtEnd() const {
  return body()->IsAnchoredAtEnd();
}

// Convert regular expression trees to a simple sexp representation.
// This representation should be different from the input grammar
// in as many cases as possible, to make it more difficult for incorrect
// parses to look as correct ones which is likely if the input and
// output formats are alike.
class RegExpUnparser : public RegExpVisitor {
 public:
  void VisitCharacterRange(CharacterRange that);
#define MAKE_CASE(Name) virtual void* Visit##Name(RegExp##Name*, void* data);
  FOR_EACH_REG_EXP_TREE_TYPE(MAKE_CASE)
#undef MAKE_CASE
};

void* RegExpUnparser::VisitDisjunction(RegExpDisjunction* that, void* data) {
  OS::Print("(|");
  for (intptr_t i = 0; i < that->alternatives()->length(); i++) {
    OS::Print(" ");
    (*that->alternatives())[i]->Accept(this, data);
  }
  OS::Print(")");
  return NULL;
}

void* RegExpUnparser::VisitAlternative(RegExpAlternative* that, void* data) {
  OS::Print("(:");
  for (intptr_t i = 0; i < that->nodes()->length(); i++) {
    OS::Print(" ");
    (*that->nodes())[i]->Accept(this, data);
  }
  OS::Print(")");
  return NULL;
}

void RegExpUnparser::VisitCharacterRange(CharacterRange that) {
  PrintUtf16(that.from());
  if (!that.IsSingleton()) {
    OS::Print("-");
    PrintUtf16(that.to());
  }
}

void* RegExpUnparser::VisitCharacterClass(RegExpCharacterClass* that,
                                          void* data) {
  if (that->is_negated()) OS::Print("^");
  OS::Print("[");
  for (intptr_t i = 0; i < that->ranges()->length(); i++) {
    if (i > 0) OS::Print(" ");
    VisitCharacterRange((*that->ranges())[i]);
  }
  OS::Print("]");
  return NULL;
}

void* RegExpUnparser::VisitAssertion(RegExpAssertion* that, void* data) {
  switch (that->assertion_type()) {
    case RegExpAssertion::START_OF_INPUT:
      OS::Print("@^i");
      break;
    case RegExpAssertion::END_OF_INPUT:
      OS::Print("@$i");
      break;
    case RegExpAssertion::START_OF_LINE:
      OS::Print("@^l");
      break;
    case RegExpAssertion::END_OF_LINE:
      OS::Print("@$l");
      break;
    case RegExpAssertion::BOUNDARY:
      OS::Print("@b");
      break;
    case RegExpAssertion::NON_BOUNDARY:
      OS::Print("@B");
      break;
  }
  return NULL;
}

void* RegExpUnparser::VisitAtom(RegExpAtom* that, void* data) {
  OS::Print("'");
  ZoneGrowableArray<uint16_t>* chardata = that->data();
  for (intptr_t i = 0; i < chardata->length(); i++) {
    PrintUtf16(chardata->At(i));
  }
  OS::Print("'");
  return NULL;
}

void* RegExpUnparser::VisitText(RegExpText* that, void* data) {
  if (that->elements()->length() == 1) {
    (*that->elements())[0].tree()->Accept(this, data);
  } else {
    OS::Print("(!");
    for (intptr_t i = 0; i < that->elements()->length(); i++) {
      OS::Print(" ");
      (*that->elements())[i].tree()->Accept(this, data);
    }
    OS::Print(")");
  }
  return NULL;
}

void* RegExpUnparser::VisitQuantifier(RegExpQuantifier* that, void* data) {
  OS::Print("(# %" Pd " ", that->min());
  if (that->max() == RegExpTree::kInfinity) {
    OS::Print("- ");
  } else {
    OS::Print("%" Pd " ", that->max());
  }
  OS::Print(that->is_greedy() ? "g " : that->is_possessive() ? "p " : "n ");
  that->body()->Accept(this, data);
  OS::Print(")");
  return NULL;
}

void* RegExpUnparser::VisitCapture(RegExpCapture* that, void* data) {
  OS::Print("(^ ");
  that->body()->Accept(this, data);
  OS::Print(")");
  return NULL;
}

void* RegExpUnparser::VisitLookahead(RegExpLookahead* that, void* data) {
  OS::Print("(-> %s", (that->is_positive() ? "+ " : "- "));
  that->body()->Accept(this, data);
  OS::Print(")");
  return NULL;
}

void* RegExpUnparser::VisitBackReference(RegExpBackReference* that, void*) {
  OS::Print("(<- %" Pd ")", that->index());
  return NULL;
}

void* RegExpUnparser::VisitEmpty(RegExpEmpty*, void*) {
  OS::Print("%%");
  return NULL;
}

void RegExpTree::Print() {
  RegExpUnparser unparser;
  Accept(&unparser, NULL);
}

RegExpDisjunction::RegExpDisjunction(
    ZoneGrowableArray<RegExpTree*>* alternatives)
    : alternatives_(alternatives) {
  ASSERT(alternatives->length() > 1);
  RegExpTree* first_alternative = alternatives->At(0);
  min_match_ = first_alternative->min_match();
  max_match_ = first_alternative->max_match();
  for (intptr_t i = 1; i < alternatives->length(); i++) {
    RegExpTree* alternative = alternatives->At(i);
    min_match_ = Utils::Minimum(min_match_, alternative->min_match());
    max_match_ = Utils::Maximum(max_match_, alternative->max_match());
  }
}

static intptr_t IncreaseBy(intptr_t previous, intptr_t increase) {
  if (RegExpTree::kInfinity - previous < increase) {
    return RegExpTree::kInfinity;
  } else {
    return previous + increase;
  }
}

RegExpAlternative::RegExpAlternative(ZoneGrowableArray<RegExpTree*>* nodes)
    : nodes_(nodes) {
  ASSERT(nodes->length() > 1);
  min_match_ = 0;
  max_match_ = 0;
  for (intptr_t i = 0; i < nodes->length(); i++) {
    RegExpTree* node = nodes->At(i);
    intptr_t node_min_match = node->min_match();
    min_match_ = IncreaseBy(min_match_, node_min_match);
    intptr_t node_max_match = node->max_match();
    max_match_ = IncreaseBy(max_match_, node_max_match);
  }
}

}  // namespace dart
