type bop =
  | Add
  | Mult
  | Leq

type expr =
  | Var of string
  | Int of int
  | Bool of bool
  | Binop of bop * expr * expr
  | Let of string * expr * expr
  | If of expr * expr * expr

(** [is_value e] is whether [e] is a value. *)
let is_value = function
    | Int _ | Bool _ -> true
    | Var _ | Let _ | Binop _ | If _ -> false

(** [subst e v x] is [e] with [v] substituted for [x], that
    is, [e{v/x}]. *)
let rec subst e v x =
    match e with
    | Var y ->
        if x = y then
          v
        else
          e
    | Bool _ -> e
    | Int _ -> e
    | Binop (bop, e1, e2) -> Binop (bop, subst e1 v x, subst e2 v x)
    | Let (y, e1, e2) ->
        let e1' = subst e1 v x in
            if x = y then
              Let (y, e1', e2)
            else
              Let (y, e1', subst e2 v x)
    | If (e1, e2, e3) -> If (subst e1 v x, subst e2 v x, subst e3 v x)

(** [step] is the [-->] relation, that is, a single step of 
    evaluation. *)
let rec step = function
    | Int _ | Bool _ -> failwith "Does not step"
    | Var _ -> failwith Error.unbound_var_err
    | Binop (bop, e1, e2) when is_value e1 && is_value e2 -> step_bop bop e1 e2
    | Binop (bop, e1, e2) when is_value e1 -> Binop (bop, e1, step e2)
    | Binop (bop, e1, e2) -> Binop (bop, step e1, e2)
    | Let (x, e1, e2) when is_value e1 -> subst e2 e1 x
    | Let (x, e1, e2) -> Let (x, step e1, e2)
    | If (Bool true, e2, _) -> e2
    | If (Bool false, _, e3) -> e3
    | If (Int _, _, _) -> failwith Error.if_guard_err
    | If (e1, e2, e3) -> If (step e1, e2, e3)

(** [step_bop bop v1 v2] implements the primitive operation
    [v1 bop v2].  Requires: [v1] and [v2] are both values. *)
and step_bop bop e1 e2 =
    match (bop, e1, e2) with
    | Add, Int a, Int b -> Int (a + b)
    | Mult, Int a, Int b -> Int (a * b)
    | Leq, Int a, Int b -> Bool (a <= b)
    | _ -> failwith Error.bop_err