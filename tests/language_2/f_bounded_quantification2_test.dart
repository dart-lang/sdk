// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for F-Bounded Quantification. Regression test for issue 9291.

class Entities<T extends ConceptEntity<T>> implements EntitiesApi {}

class ConceptEntity<T extends ConceptEntity<T>> implements EntityApi {}

abstract class EntityApi<T extends EntityApi<T>> {}

abstract class EntitiesApi<T extends EntityApi<T>> {}

class Concept extends ConceptEntity<Concept> {}

main() {
  new ConceptEntity<Concept>();
}
