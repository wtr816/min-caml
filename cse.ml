open KNormal
 
module Em =
  Map.Make
    (struct
      type t = KNormal.t
      let compare = compare
    end)

let rec sanitize (r, e) = (*kNormal.astのみを比較できるように、rangeを無効化*)
  let e' = match e with
    | Unit | Int(_) | Float(_) | Neg(_) | Add(_) | Sub(_) | Lsl(_) | Lsr(_)  | Lor(_) | Land(_) | FNeg(_) | FAdd(_) | FSub(_) | FMul(_) | FDiv(_) | FInv(_) |Var(_) | App(_) | Tuple(_) | Get(_) | Put(_) | ExtArray(_) | ExtTuple(_) | ExtFunApp(_) | Read | Write(_) | Fasi(_) | Iasf(_) | Ftoi(_) | Itof(_) | Floor(_) | Fabs(_) | Sqrt(_) -> e
    | IfEq (n1, n2, t1, t2) -> IfEq (n1, n2, sanitize t1, sanitize t2)
    | IfLE (n1, n2, t1, t2) -> IfLE (n1, n2, sanitize t1, sanitize t2)
    | Let ((n, ty), t1, t2) -> Let ((n, ty), sanitize t1, sanitize t2)
    | LetRec ({name = (n, ty); args = ags; body = b}, t) -> LetRec ({name = (n, ty); args = ags; body = sanitize b}, sanitize t)
    | LetTuple (xs, n, t) -> LetTuple (xs, n, sanitize t)
  in
  (((0,0),(0,0)), e')

let rec cost (r, e) =
  match e with
  | Unit | Int(_) | Float(_) -> 0
  | _ -> 1

let rec eliminatable (r, e) = 
  match e with
  | Unit | App _ | Get _ | Put _ | ExtFunApp _ | Read | Write _ -> false
  | Int _ | Float _ | Neg _ | Add _ | Sub _ | Lsl _ | Lsr _ | Lor _ | Land _ | FNeg _ | FAdd _ | FSub _ | FMul _ | FDiv _ | FInv _ | Var _ | Tuple _ | ExtArray _ | ExtTuple _ | Fasi _ | Iasf _ | Ftoi _ | Itof _ | Floor _ | Fabs _ | Sqrt _ -> true
  | IfEq(_, _, e1, e2) | IfLE(_, _, e1, e2) -> eliminatable e1 && eliminatable e2
  | Let _ | LetRec _ | LetTuple _ -> false

let rec g env (r, e) = (*共通部分式除去*)
  let (c, e') =
    try
      let n = Em.find (sanitize (r, e)) env in
      Format.eprintf "replacing following expression at %s with variable \"%s\".\n%s" (Id.pp_range r) (Id.pp_t n) (pp_t (r, e));
      (false, Var(n))
    with
      Not_found ->
      match e with
      | Unit | Int(_) | Float(_) | Neg(_) | Add(_) | Sub(_) | Lsl(_) | Lsr(_) | Lor(_) | Land(_) | FNeg(_) | Var(_) | Tuple(_) | Get(_) | Put(_) | ExtArray(_) | ExtTuple(_) | Read | Write(_) | Fasi(_) | Iasf(_)  | Ftoi(_) | Itof(_) | Floor(_) | Fabs(_) | Sqrt(_) -> (false, e)
      | FAdd(_) | FSub(_) | FMul(_) | FDiv(_) | FInv(_) | App(_) | ExtFunApp(_) -> (true, e)
      | IfEq (n1, n2, t1, t2) ->
	 let c1, t1' = g env t1 in
	 let c2, t2' = g env t2 in
	 (c1 || c2, IfEq (n1, n2, t1', t2'))
      | IfLE (n1, n2, t1, t2) -> 
	 let c1, t1' = g env t1 in
	 let c2, t2' = g env t2 in
	 (c1 || c2, IfLE (n1, n2, t1', t2'))
      | Let ((n, t), t1, t2) ->
	 let c1, t1' = g env t1 in
	 (* let env = if c1 then Em.filter (fun e n -> cost e > 0) env else env in  (\* 関数呼び出しがあったら退避が起こるので、置き換えをやめる *\) *)
	 let env = if eliminatable t1' then Em.add (sanitize t1') n env else env in
	 let c2, t2' = g env t2 in
	 (c2, Let ((n, t), t1', t2'))
      | LetRec ({name = (n, ty); args = ags; body = b}, t) ->
	 let c1, b' = g (Em.empty) b in
	 let c2, t' = g env t in
	 (c2, LetRec ({name = (n, ty); args = ags; body = b'}, t'))
      | LetTuple (xs, n, t) -> 
	 let c, t' = g env t in
	 (c, LetTuple (xs, n, t'))
  in
  (c, (r, e'))

let f t = 
  let t' = snd (g (Em.empty) t) in
  t'
