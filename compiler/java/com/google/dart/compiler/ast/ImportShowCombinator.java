/*
 * Copyright (c) 2012, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.dart.compiler.ast;

/**
 * Instances of the class <code>ImportShowCombinator</code> represent a combinator that restricts
 * the names being imported to those in a given list.
 * 
 * <pre>
 * importShowCombinator ::=
 *     'show:' {@link DartArrayLiteral listLiteral}
 * </pre>
 */
public class ImportShowCombinator extends ImportCombinator {
  /**
   * The list of names from the library that are made visible by this combinator.
   */
  private DartArrayLiteral shownNames;

  /**
   * Initialize a newly created import show combinator.
   */
  public ImportShowCombinator() {
    super();
  }

  /**
   * Initialize a newly created import show combinator.
   * 
   * @param shownNames the list of names from the library that are made visible by this combinator
   */
  public ImportShowCombinator(DartArrayLiteral shownNames) {
    this.shownNames = becomeParentOf(shownNames);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitImportShowCombinator(this);
  }

  /**
   * Return the list of names from the library that are made visible by this combinator.
   * 
   * @return the list of names from the library that are made visible by this combinator
   */
  public DartArrayLiteral getShownNames() {
    return shownNames;
  }

  /**
   * Set the list of names from the library that are made visible by this combinator to the given
   * list.
   * 
   * @param shownNames the list of names from the library that are made visible by this combinator
   */
  public void setShownNames(DartArrayLiteral shownNames) {
    this.shownNames = becomeParentOf(shownNames);
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    if (shownNames != null) {
      shownNames.visitChildren(visitor);
    }
  }
}
