(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
   for details.  All rights reserved.  Use of this source code is governed by a
   BSD-style license that can be found in the LICENSE file.
 *)

(* Syntax of Henry I, more or less.

   Some things are different, for example ReturnStatement has an optional
   expression.  References are implemented as SML ref types though in a real
   implementation they would have to be option refs, provided the tree was built
   bottom up, so that they could be initialized to ref NONE.

   Integer ids are assigned to variable declarations and classes, so that they
   can be compared for identity or so-called pointer equality.
 *)
structure Syntax
= struct
    type identifier = string

    datatype type_
      = InterfaceType of {class: class ref}
      | FunctionType of {returnType: type_, parameterType: type_}
    and expression
      = VariableGet of {variable: variable_declaration ref}
      | MethodInvocation of
          {receiver: expression,
           name: identifier,
           argument: expression}
      | ConstructorInvocation of {class: class ref}
      | PropertyGet of {receiver: expression, name: identifier}
    and statement
      = ExpressionStatement of {expression: expression}
      | ReturnStatement of {expression: expression option}
      | Block of {statements: statement list}
    and member
      = Class of class
      | Procedure of procedure
    withtype variable_declaration = {id: int, type_: type_}
    and procedure =
      {returnType: type_,
       name: identifier,
       parameter: variable_declaration,
       body: statement}
    and class = {id: int, procedures: procedure list}

    type library = {members: member list}
  end

(* The higher-order interpreter. *)
structure Semantics
= struct
    structure S = Syntax

    (* The environment maps variable declaration ids to their values.  It is
       implemented as a list of pairs.

       There is a non-exhaustive pattern match which should not be reached for
       well-formed Henry I programs.
     *)
    type 'a environment = (int * 'a) list
    fun apply_env ((i, v) :: env, d: S.variable_declaration ref)
        = if i = #id (!d) then v else apply_env (env, d)

    (* - A (runtime) class is a pair of the class id and a getter suite.
       - A getter suite is a map from getter names (identifiers) to getters.
       - A getter is a function from receiver to result values.  In Henry I
         getters are method tearoffs and so they have no effects (they cannot
         throw, for example).
       - Object values have only a class (objects have no fields in Henry I).
         Null and NoSuchMethod are objects with distinguished classes.
       - Functions are method tearoffs.  They also have a getter suite because
         they can have getters (e.g., "call" or "equals").  They hold a method
         which is a function taking the single argument and a error and return
         continuations.
     *)
    datatype value
      = ObjectValue of class
      | FunctionValue of class * (value * (value -> unit) * (value -> unit) -> unit)
    withtype getter = value -> value
    and getter_suite = (S.identifier * getter) list
    and class = int * getter_suite

    (* Given a name and a value, lookup a getter which may not exist. *)
    fun lookup_getter (name, v)
        = let fun find_in nil
                  = NONE
                | find_in ((x, f) :: gs)
                  = if name = x then SOME f else find_in gs
          in case v
              of ObjectValue (_, gs)
                 => find_in gs
               | FunctionValue ((_, gs), _)
                 => find_in gs
          end

    (* A class table is a map from a class id to its getter suite.

       There is a non-exhaustive pattern match which should not be reached for
       well-formed Henry I programs.
     *)
    type class_table = (int * getter_suite) list
    fun lookup_class (c: S.class ref, (cid, gs) :: ct)
        = if #id (!c) = cid then gs else lookup_class (c, ct)

    (* For convenience we just use a global class table because it's annoying to
       pass it.  It is immutable and doesn't change once initialized before
       program execution.
     *)
    val ct: class_table option ref = ref NONE
    fun class_table () = Option.valOf (!ct)

    (* Getter suites for builtin in classes. *)
    (* The getter that tears off the call method of a FunctionValue is cute. *)
    fun function_class (): class = (~1, [("call", fn v => v)])
    fun null_class (): class = (~2, nil)
    fun no_such_method_class(): class = (~3, nil)

    fun apply (v0 as ObjectValue _, v1, ek, k)
        = (case lookup_getter ("call", v0)
            of NONE => ek (ObjectValue (no_such_method_class ()))
             | SOME g => apply (g v0, v1, ek, k))
      | apply (FunctionValue (_, f), v, ek, k)
        = f (v, ek, k)

    fun eval (S.VariableGet {variable = d}, env, ek, k)
        = k (apply_env (env, d))
      | eval (S.MethodInvocation {receiver = e0, name = x, argument = e1},
              env, ek, k)
        = eval (e0, env, ek,
            fn v0 =>
               (case lookup_getter (x, v0)
                 of NONE
                    => eval (e1, env, ek,
                         fn _ =>
                           ek (ObjectValue (no_such_method_class ())))
                  | SOME g
                    => let val f = g v0
                       in eval (e1, env, ek, fn v1 => apply (f, v1, ek, k))
                       end))
      | eval (S.ConstructorInvocation {class = c}, env, ek, k)
        = k (ObjectValue (#id (!c), lookup_class (c, class_table ())))
      | eval (S.PropertyGet {receiver = e, name = x}, env, ek, k)
        = eval (e, env, ek,
            fn v =>
               (case lookup_getter (x, v)
                 of NONE
                    => ek (ObjectValue (no_such_method_class ()))
                  | SOME g
                    => k (g v)))

    fun exec (S.ExpressionStatement {expression = e}, env, rk, ek, sk)
        = eval (e, env, ek, fn _ => sk ())
      | exec (S.ReturnStatement {expression = NONE}, env, rk, ek, sk)
        = rk (ObjectValue (null_class ()))
      | exec (S.ReturnStatement {expression = SOME e}, env, rk, ek, sk)
        = eval (e, env, ek, rk)
      | exec (S.Block {statements = ss}, env, rk, ek, sk)
        = exec_stmts (ss, env, rk, ek, sk)
    and exec_stmts (nil, env, rk, ek, sk)
        = sk ()
      | exec_stmts (s :: ss, env, rk, ek, sk)
        = exec (s, env, rk, ek,
                fn () => exec_stmts (ss, env, rk, ek, sk))

    (* Loading the class table.  A procedure in a class induces a getter which
       tears off the procedure.
     *)
    fun process_procedure ({returnType = t,
                            name = x,
                            parameter = p,
                            body = b}: S.procedure): S.identifier * getter
        = (x, fn _ =>
                 FunctionValue
                     (function_class (),
                      fn (v, ek, k) =>
                         exec (b, [(#id p, v)], ek, k,
                           fn () => k (ObjectValue (null_class ())))))

    fun process_class ({id = n, procedures = ps}: S.class): int * getter_suite
        = (n, List.map process_procedure ps)

    fun run {members = ms}
        = let fun process_members nil
                  = nil
                | process_members (S.Class c :: ms)
                  = process_class c :: process_members ms
                | process_members (S.Procedure p :: ms)
                  = process_members ms
              val _ = ct := SOME (process_members ms)
              (* There is a non-exhaustive pattern match below which should not
                 be possible for well-formed Henry I programs.
               *)
              fun find_main (S.Class c :: ms)
                  = find_main ms
                | find_main (S.Procedure p :: ms)
                  = if #name p = "main" then p else find_main ms
          in exec (#body (find_main ms), nil,
                   fn v => print "done",
                   fn e => print "error",
                   fn () => print "done")
          end
end
