type id_or_imm = V of Id.t | C of int
type t = 
  | Ans of exp
  | Let of (Id.t * Type.t) * exp * t
and exp = 
  | Nop
  | Li of int32
  (* | FLi of Id.l *)
  | SetL of Id.l
  | Mr of Id.t
  | Neg of Id.t
  | Add of Id.t * id_or_imm
  | Sub of Id.t * Id.t
  | And of Id.t * Id.t
  | Or of Id.t * Id.t
  | Slw of Id.t * id_or_imm
  | Srw of Id.t * id_or_imm
  | Lwz of Id.t * int
  | Stw of Id.t * Id.t * int
  (* | FMr of Id.t  *)
  | FNeg of Id.t
  (* | FAdd of Id.t * Id.t *)
  (* | FSub of Id.t * Id.t *)
  (* | FMul of Id.t * Id.t *)
  (* | FDiv of Id.t * Id.t *)
  (* | Lfd of Id.t * id_or_imm *)
  (* | Stfd of Id.t * Id.t * id_or_imm *)
  | Comment of string
  (* virtual instructions *)
  | IfEq of Id.t * Id.t * t * t
  | IfLE of Id.t * Id.t * t * t
  (* | IfGE of Id.t * id_or_imm * t * t (\* for simm *\) *)
  (* | IfFEq of Id.t * Id.t * t * t *)
  (* | IfFLE of Id.t * Id.t * t * t *)
  (* closure address, integer arguments, and float arguments *)
  | CallCls of Id.t * Id.t list
  | CallDir of Id.l * Id.t list
  | Save of Id.t * Id.t (* レジスタ変数の値をスタック変数へ保存 *)
  | Restore of Id.t (* スタック変数から値を復元 *)
type fundef =
    { name : Id.l; args : Id.t list; body : t; ret : Type.t }
type prog = Prog of (Id.l * float) list * fundef list * t

val fletd : Id.t * exp * t -> t (* shorthand of Let for float *)
val seq : exp * t -> t (* shorthand of Let for unit *)

val regs : Id.t array
(* val fregs : Id.t array *)
val allregs : Id.t list
(* val allfregs : Id.t list *)
val reg_cl : Id.t
val reg_sw : Id.t
(* val reg_fsw : Id.t *)
val reg_hp : Id.t
val reg_sp : Id.t
val hp_default : int32
val sp_default : int32
val reg_tmp : Id.t
val is_reg : Id.t -> bool

val fv : t -> Id.t list
val concat : t -> Id.t * Type.t -> t -> t

val align : int -> int

val imm_max : int32
val imm_min : int32

val load_ext_var : string -> t
