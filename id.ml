type t = string (* 変数の名前 (caml2html: id_t) *)
type l = L of string (* トップレベル関数やグローバル配列のラベル (caml2html: id_l) *)

type pos = (int * int) (* (line number, column) *)
type range = (pos * pos) 

let pp_range r = Format.sprintf "%d.%d-%d.%d" (fst (fst r)) (snd (fst r)) (fst (snd r)) (snd (snd r))

let rec pp_list = function
  | [] -> ""
  | [x] -> x
  | x :: xs -> x ^ " " ^ pp_list xs

let pp_t t = t

let pp_l (L l) = l

let counter = ref 0
let genid s =
  incr counter;
  Format.sprintf "%s_%d" s !counter

let rec id_of_typ = function
  | Type.Unit -> "u"
  | Type.Bool -> "b"
  | Type.Int -> "i"
  | Type.Float -> "d"
  | Type.Fun _ -> "f"
  | Type.Tuple _ -> "t"
  | Type.Array _ -> "a" 
  | Type.Var _ -> assert false
let gentmp typ =
  incr counter;
  Printf.sprintf "_t%s%d" (id_of_typ typ) !counter
