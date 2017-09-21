# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

GRAMMAR=../../docs/language/Dart.g
JAVA_PATH=/usr/lib/jvm/java-7-openjdk-amd64/bin
JAVA=$(JAVA_PATH)/java
JAVAC=javac
ANTLR_JAR=/usr/share/java/antlr3-runtime.jar
ANTLR_FILES=DartLexer.java DartParser.java Dart.tokens
ANTLR_CMD=PATH=$(JAVA_PATH):$(PATH) antlr3 -dfa -fo . $<
JAVA_FILES=DartLexer.java DartParser.java
CLASS_FILES=SpecParser.class SpecParserRunner.class DartLexer.class DartParser.class

.PHONY: default parser clean touch parse_hello

default: $(JAVA_FILES)

parser: SpecParser.class

SpecParser.class: $(ANTLR_FILES) SpecParser.java
	$(JAVAC) -cp .:$(ANTLR_JAR) SpecParser.java

%Lexer.java: ../../docs/language/%.g Makefile ; $(ANTLR_CMD)

%Parser.java: ../../docs/language/%.g Makefile ; $(ANTLR_CMD)

%.tokens: ../../docs/language/%.g Makefile ; $(ANTLR_CMD)

clean:
	rm -f $(CLASS_FILES) $(ANTLR_FILES)

touch:
	touch $(GRAMMAR)
