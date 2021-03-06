let limit = ref 1000
let verbose = ref false

let rec iter n e = (* 最適化処理をくりかえす (caml2html: main_iter) *)
  Format.eprintf "iteration %d@." n;
  if n = 0 then 
    (if !verbose then
       (print_string "(* =====Optimized===== *)\n" ;
	print_string (KNormal.pp_t e));
     e)
    else
    let e' = Cse.f (Elim.f (ConstFold.f (Inline.f (Assoc.f (Beta.f e))))) in
    if e = e' then 
      (if !verbose then
	 (print_string "(* =====Optimized===== *)\n" ;
	  print_string (KNormal.pp_t e));
       e)
    else
      iter (n - 1) e'

let lexbuf outchan l = (* バッファをコンパイルしてチャンネルへ出力する (caml2html: main_lexbuf) *)
  Id.counter := 0;
  Typing.extenv := M.empty;
  Emit.f outchan
	 (Trim.f 
	    (RegAlloc.f
	       (Simm.f
		  (Virtual.f
		     (Closure.f
			(iter !limit
			      (Alpha.f
				 (KNormal.f
				    (Typing.f
				       (let e = Parser.program Lexer.token l in
					if !verbose then
					  (print_string "(* =====SyntaxTree===== *)\n";
					   print_string (Syntax.pp_t e)); e))))))))))

let string s = lexbuf stdout (Lexing.from_string s) (* 文字列をコンパイルして標準出力に表示する (caml2html: main_string) *)

let file f = (* ファイルをコンパイルしてファイルに出力する (caml2html: main_file) *)
  let inchan = open_in (f ^ ".ml") in
  let outchan = open_out (f ^ ".s") in
  try
    lexbuf outchan (Lexing.from_channel inchan);
    close_in inchan;
    close_out outchan;
  with e -> (close_in inchan; close_out outchan; raise e)

let () = (* ここからコンパイラの実行が開始される (caml2html: main_entry) *)
  let files = ref [] in
  Arg.parse
    [("-inline", Arg.Int(fun i -> Inline.threshold := i), "maximum size of functions inlined");
     ("-iter", Arg.Int(fun i -> limit := i), "maximum number of optimizations iterated");
     ("-print", Arg.Unit(fun () -> verbose := true), "maximum number of optimizations iterated");
     ("-iconst", Arg.Int(fun x -> Asm.add_constreg x), "constant register");
     ("-fconst", Arg.Float(fun x -> Asm.add_constfreg x), "constant floating-point register");
     ("-fconst-hex", Arg.Rest(fun x -> Asm.add_constfreg_hex (Int32.of_string x)), "constant floating-point register by hex expression")]
    (fun s -> files := !files @ [s])
    ("Mitou Min-Caml Compiler (C) Eijiro Sumii\n" ^
       Printf.sprintf "usage: %s [-inline m] [-iter n] ...filenames without \".ml\"..." Sys.argv.(0));
  List.iter
    (fun f -> ignore (file f))
    !files
