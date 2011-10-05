;;; dart-mode.el --- a Dart mode for emacs based upon CC mode. 

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This is a basic Dart mode based on Martin Stjernholm's GPL'd
;; derived-mode-ex.el template.  It uses cc-mode and falls back on
;; Java for basic rules.
;;
;; Note: The interface used in this file requires CC Mode 5.30 or
;; later.

;;; Code:

(require 'cc-mode)

;; These are only required at compile time to get the sources for the
;; language constants.  (The cc-fonts require and the font-lock
;; related constants could additionally be put inside an
;; (eval-after-load "font-lock" ...) but then some trickery is
;; necessary to get them compiled.)
(eval-when-compile
  (require 'cc-langs)
  (require 'cc-fonts))

(eval-and-compile
  ;; Make our mode known to the language constant system.  Use Java
  ;; mode as the fallback for the constants we don't change here.
  ;; This needs to be done also at compile time since the language
  ;; constants are evaluated then.
  (c-add-language 'dart-mode 'java-mode))

;; Dart has no boolean but a string and a vector type.
(c-lang-defconst c-primitive-type-kwds
  dart (append '("bool" "var")
	     (delete "boolean"
		     ;; Use append to not be destructive on the
		     ;; return value below.
		     (append
		      ;; Due to the fallback to Java, we need not give
		      ;; a language to `c-lang-const'.
		      (c-lang-const c-primitive-type-kwds)
		      nil))))

;; Recognize member init lists after colons in Dart.
(c-lang-defconst c-nonlabel-token-key
  dart (concat "\\s\(\\|" (c-lang-const c-nonlabel-token-key)))

;; No cpp in this language, but there's still a "#include" directive to
;; fontify.  (The definitions for the extra keywords above are enough
;; to incorporate them into the fontification regexps for types and
;; keywords, so no additional font-lock patterns are required.)
(c-lang-defconst c-cpp-matchers
  dart (cons
      ;; Use the eval form for `font-lock-keywords' to be able to use
      ;; the `c-preprocessor-face-name' variable that maps to a
      ;; suitable face depending on the (X)Emacs version.
      '(eval . (list "^\\s *\\(#include\\)\\>\\(.*\\)"
		     (list 1 c-preprocessor-face-name)
		     '(2 font-lock-string-face)))
      ;; There are some other things in `c-cpp-matchers' besides the
      ;; preprocessor support, so include it.
      (c-lang-const c-cpp-matchers)))

(defcustom dart-font-lock-extra-types nil
  "*List of extra types (aside from the type keywords) to recognize in Dart mode.
Each list item should be a regexp matching a single identifier.")

(defconst dart-font-lock-keywords-1 (c-lang-const c-matchers-1 dart)
  "Minimal highlighting for Dart mode.")

(defconst dart-font-lock-keywords-2 (c-lang-const c-matchers-2 dart)
  "Fast normal highlighting for Dart mode.")

(defconst dart-font-lock-keywords-3 (c-lang-const c-matchers-3 dart)
  "Accurate normal highlighting for Dart mode.")

(defvar dart-font-lock-keywords dart-font-lock-keywords-3
  "Default expressions to highlight in Dart mode.")

(defvar dart-mode-syntax-table nil
  "Syntax table used in dart-mode buffers.")
(or dart-mode-syntax-table
    (setq dart-mode-syntax-table
	  (funcall (c-lang-const c-make-mode-syntax-table dart))))

(defvar dart-mode-abbrev-table nil
  "Abbreviation table used in dart-mode buffers.")
(c-define-abbrev-table 'dart-mode-abbrev-table
  ;; Keywords that if they occur first on a line might alter the
  ;; syntactic context, and which therefore should trig reindentation
  ;; when they are completed.
  '(("else" "else" c-electric-continued-statement 0)
    ("while" "while" c-electric-continued-statement 0)
    ("catch" "catch" c-electric-continued-statement 0)
    ("finally" "finally" c-electric-continued-statement 0)))

(defvar dart-mode-map (let ((map (c-make-inherited-keymap)))
		      ;; Add bindings which are only useful for Dart
		      map)
  "Keymap used in dart-mode buffers.")

(easy-menu-define dart-menu dart-mode-map "Dart Mode Commands"
		  ;; Can use `dart' as the language for `c-mode-menu'
		  ;; since its definition covers any language.  In
		  ;; this case the language is used to adapt to the
		  ;; nonexistence of a cpp pass and thus removing some
		  ;; irrelevant menu alternatives.
		  (cons "Dart" (c-lang-const c-mode-menu dart)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.dart\\'" . dart-mode))

;;;###autoload
(defun dart-mode ()
  "Major mode for editing Dart code.
This is a simple example of a separate mode derived from CC Mode to
support a language with syntax similar to C/C++/ObjC/Java/IDL/Pike.

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `dart-mode-hook'.

Key bindings:
\\{dart-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (c-initialize-cc-mode t)
  (set-syntax-table dart-mode-syntax-table)
  (setq major-mode 'dart-mode
	mode-name "Dart"
	local-abbrev-table dart-mode-abbrev-table
	abbrev-mode t)
  (use-local-map c-mode-map)
  ;; `c-init-language-vars' is a macro that is expanded at compile
  ;; time to a large `setq' with all the language variables and their
  ;; customized values for our language.
  (c-init-language-vars dart-mode)
  ;; `c-common-init' initializes most of the components of a CC Mode
  ;; buffer, including setup of the mode menu, font-lock, etc.
  ;; There's also a lower level routine `c-basic-common-init' that
  ;; only makes the necessary initialization to get the syntactic
  ;; analysis and similar things working.
  (c-common-init 'dart-mode)
  (easy-menu-add dart-menu)
  (run-hooks 'c-mode-common-hook)
  (run-hooks 'dart-mode-hook)
  (c-update-modeline))

(provide 'dart-mode)

;;; dart-mode.el ends here
