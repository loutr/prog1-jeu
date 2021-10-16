(*****************************************************************************)
(* main.ml: routine du jeu s'appuyant sur les autres composantes             *)
(*****************************************************************************)


open Global
open Graphics



(* met à jour le mode de jeu en fonction du choix du joueur *)
let maj_mode = function
  | 'a' -> est_dispo_affiche := not !est_dispo_affiche
  | 'e' -> est_conflit_affiche := not !est_conflit_affiche
  | 'x' -> est_jeu_en_cours := false
  | _ -> ()


(* choisit une grille parmi celles disponibles dans grid et arrête le 
   programmae si aucune grille (valide) n'est disponible *)
let initialiser () =
  try 
    let fichiers_grilles = Sys.readdir "grids" in
    let n = Array.length fichiers_grilles in
    let choix = Random.int n in
    let fichier = open_in ("grids/" ^ fichiers_grilles.(choix)) in
    try 
      Logic.reinit_conflits ();
      for j = 8 downto 0 do
        let s = input_line fichier in
        for i = 0 to 8 do 
          let c = Logic.vers_chiffre s.[i] in
          if c = -1 then raise (Invalid_argument "");
          grille.(i).(j) <- c;
          defaut.(i).(j) <- (c <> 0);
          conflits.(i).(j) <- false
        done;
      done
    with _ -> close_in_noerr fichier;
      print_string ("Fichier de grille invalide: " ^ fichiers_grilles.(choix)); exit 1
  with _ -> print_string "Impossible de récupérer un fichier de grille"; exit 1


(*****************************************************************************)
(********************************** routine **********************************)
(*****************************************************************************)

let () =
  Random.self_init ();
  initialiser ();
  (* met à jour les chiffres une première fois *)
  Logic.chiffres_disponibles ();
  let est_bouton_presse = ref false in

  begin try
    while !est_jeu_en_cours do
      Logic.test_est_jeu_battu ();
      Render.maj_affichage ();

      let st = wait_next_event [ Button_down; Button_up; Poll ] in
      if st.keypressed then begin match read_key () with (* 1 *)
        | 'e' | 'x' | 'a' -> maj_mode st.key
        | 'r' -> initialiser ()
        | 'z' | 'q' | 's' | 'd' -> Logic.maj_curseur st.key
        | '0'..'9' | ' ' -> Logic.changer_chiffre (Logic.vers_chiffre st.key) !curseur
        | _ -> ()
      end
      else begin
        let b = button_down () in
        if b && not !est_bouton_presse then
          Logic.maj_curseur_souris ();
        (* on se souvient de l'état de la souris pour éviter beaucoup
           d'appels inutiles à cette fonction *)
        est_bouton_presse := b
      end
    done
  with
    | Graphic_failure("fatal I/O error") -> ()
  end;
  close_graph ()

(* (* 1 *): On peut aussi utiliser st.key à la place de read_key (), mais
            dans ce cas la queue des touches pressées n'est pas dépilée
            et le programme boucle sur la touche pressée.
            (Le comportement n'est pas le même si Poll n'est pas accepté,
            car alors st.key est nécessairement changé au prochain appel)
 *)
