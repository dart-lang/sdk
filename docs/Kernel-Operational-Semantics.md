> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

The small-step operational semantics of Dart Kernel is given by an abstract machine in the style of the CEK machine.  The machine is defined by a single step transition function where each step of the machine starts in a configuration and deterministically gives a next configuration.  There are several different configurations defined below.

_x_ ranges over variables, &rho; ranges over environments, _K_ ranges over expression continuations, _A_ ranges over application continuations, _E_ ranges over expressions, _S_ ranges over statements, _V_ ranges over values.

Environments are finite functions from variables to values.  _&rho;_[_x_ &rarr; _V_] denotes the environment that maps _x_ to _V_ and _y_ to _&rho;_(_y_) for all _y_ &ne; _x_.

#### Expression configuration

An expression configuration indicates the evaluation of an expression with respect to an environment and an expression continuation.

Expression configuration | Next configuration
-- | --
<_x_, _&rho;_, _K_><sub>_expr_</sub> | <_K_, _&rho;_(_x_), _&rho;_><sub>_cont_</sub>
<_x = E_, _&rho;_, _K_><sub>_expr_</sub> | <_E_, _&rho;_, **VarSetK**(_x_, _K_)><sub>_expr_</sub>
<_!E_, _&rho;_, _K_><sub>_expr_</sub> | <_E_, _&rho;_, **NotK**(_K_)><sub>_expr_</sub>
<_E<sub>1</sub> **and** E<sub>2</sub>_, _&rho;_, _K_><sub>_expr_</sub> | <_E<sub>1</sub>_, _&rho;_, **AndK**(_E<sub>2</sub>_, _K_)><sub>_expr_</sub>
<_E<sub>1</sub> **or** E<sub>2</sub>_, _&rho;_, _K_><sub>_expr_</sub> | <_E<sub>1</sub>_, _&rho;_, **OrK**(_E<sub>2</sub>_, _K_)><sub>_expr_</sub>
<_E<sub>1</sub>? E<sub>2</sub> : E<sub>3</sub>_, _&rho;_, _K_><sub>_expr_</sub> | <_E<sub>1</sub>_, _&rho;_, **ConditionalK**(_E<sub>2</sub>_, _E<sub>3</sub>_, _K_)><sub>_expr_</sub>
<_StringConcat(exprList)_, _&rho;_, _K_><sub>_expr_</sub> | <_exprList_, _&rho;_, **StringConcatenationA**(_K_)><sub>_exprList_</sub>
<_print(E)_, _&rho;_, _K_><sub>_expr_</sub> | <_E_, _&rho;_, **PrintK**</sub>(_K_)><sub>_expr_</sub>
<_f(exprList)_, _&rho;_, _K_><sub>_expr_</sub> | <_exprList_, _&rho;_, **StaticInvocationA**(_S : f.body_, _K_)><sub>_exprList_</sub>
<_BasicLiteral_, _&rho;_, _K_><sub>_expr_</sub> | <_K_, _BasicLiteral_, _&rho;_><sub>_cont_</sub>
<_**Let** x = E<sub>1</sub> **in** E<sub>2</sub>_, _&rho;_, _K_><sub>_expr_</sub> | <_E<sub>1</sub>_, _&rho;_, **LetK**(_x_, E<sub>2</sub>, _&rho;_, _K_)><sub>_expr_</sub>


#### Expression continuation configuration

An expression continuation configuration indicates the application of an expression continuation __K__ to a value and an environment.  The environment is threaded to the continuation because expressions can mutate the environment.

Expression continuation configuration | Next configuration
-- | --
<**VarSetK**(_x_, _K_), _V_, _&rho;_><sub>_cont_</sub> | <_K_, _V_, _&rho;_[_x_ &rarr; _V_]><sub>cont</sub>
<**PrintK**(_K_), _V_, _&rho;_><sub>_cont_</sub> |  <_K_, _&empty;_, _&rho;_><sub>cont</sub>
<**ExpressionListK**(_exprList_, _A_), _V_, _&rho;_><sub>_cont_</sub> | <_exprList_, _&rho;_, **ValueApplicationA**(_V_, _A_)><sub>_exprList_</sub>
<**ExpressionK**(_C_), _V_, _&rho;_ ><sub>_cont_</sub> | _C_

#### Expression list configuration

An expression list configuration indicates the evaluation of a list of expressions with respect to an environment and an application continuation.

Expression list configuration | Next configuration
--|--
<_&empty;_, _&rho;_, _A_><sub>_exprList_</sub> | <_A_, _&empty;_><sub>_acont_</sub>
<_E :: tail_, _&rho;_, _A_><sub>_exprList_</sub> | <_E_, _&rho;_, **ExpressionListK**(_tail_, _A_)><sub>_expr_</sub>

#### Application continuation configuration 

An application continuation configuration indicates the application of __A__ to a list of values.

Application continuation configuration | Next configuration
--|--
<**StaticInvocationA**(_S_, _K_), _valList_><sub>_acont_</sub> | <_S_, _&rho;_[_formalList_ &rarr; _valList_], _&empty;_, **ExitC**(_K_), _K_><sub>_exec_</sub>
<**ValueApplicationA**(V, _A_), _valList_><sub>_acont_</sub> | <_A_, _V :: valList_><sub>_acont_</sub>

#### Statement configuration 

A statement configuration indicates the execution of a statement with respect to an environment.

_S_ ranges over statements, _L_ ranges over labels, _C_ ranges over statement configurations. 

Statement configuration | Next configuration
--|--
<**Expression**(_E_), _&rho;_, _L_, _C_, _K_><sub>_exec_</sub> | <_E_, _&rho;_, **ExpressionK**(_C_)><sub>_expr_</sub>
