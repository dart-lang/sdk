/*
 * Copyright 2012 Dart project authors.
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
package com.google.dart.compiler.parser;

import com.google.dart.compiler.ast.DartImportDirective;
import com.google.dart.compiler.ast.DartStringLiteral;

import java.util.Set;

/**
 * An extension of {@link DartParser} that updates the prefixes collection
 */
public class DartPrefixParser extends DartParser {

  private final Set<String> prefixes;

  public DartPrefixParser(ParserContext parserCtx, boolean isDietParse, Set<String> prefixes) {
    super(parserCtx, isDietParse, prefixes);
    this.prefixes = prefixes;
  }
  
  @Override
  protected DartImportDirective parseImportDirective() {
    DartImportDirective directive = super.parseImportDirective();
    DartStringLiteral prefix = directive.getPrefix();
    if (prefix != null) {
      prefixes.add(prefix.getValue());
    }
    return directive;
  }
}
 