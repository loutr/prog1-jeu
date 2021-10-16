(*****************************************************************************)
(* logic.ml: construit une partie de sudoku en fonction des choix de         *)
(*           l'utilisateur                                                   *)
(*****************************************************************************)


open Global



(********************************** données **********************************)
let chance_bombe = 3 (* inverse de la probabilité qu'une bombe soit lancée *)

(* Plusieurs approches sont possibles pour se souvenir des différents conflits
   entre les cases. Celle employée par Dynamique pourra être modifiée pour être
   plus efficace.
   Remarquons que toute case ne peut être en conflit qu'avec au plus
   8 + 6 + 6 = 20 autres cases. D'où le choix pour la taille des tables. *)
let ensemble_conflits = Array.init 9
 (fun n -> Array.init 9 (fun n -> (Dynamique.creer 20 (0, 0))))
(*****************************************************************************)


(************ fonctions diverses utilisées par le reste du module ************)
let dec9 i = if i = 0 then 8 else i - 1
let inc9 i = if i = 8 then 0 else i + 1

let compt a b c = (a < b) && (b < c)   

let vers_chiffre = function
  | '1' -> 1 | '2' -> 2 | '3' -> 3
  | '4' -> 4 | '5' -> 5 | '6' -> 6
  | '7' -> 7 | '8' -> 8 | '9' -> 9
  | '0' | ' ' -> 0
  | _ -> -1

(* à une case de la grille associe les coordonnées du pixel inférieur gauche *)
let coord_vers_pix (x, y) =
  let {ligne; cellule; marge} = config in
  (marge + x * (ligne + cellule) + ligne,
   marge + y * (ligne + cellule) + ligne)

(* itère parmi les cases voisines et distinctes d'une case sur une grille
   de sudoku: par ligne, colonne ou bloc *)
let iter_voisins f (x, y) =
  let cx = x / 3 and cy = y / 3 in
  for i = 0 to 8 do
    if i <> x then f (i, y);
    if i <> y then f (x, i);
    let x' = cx * 3 + (i / 3)
    and y' = cy * 3 + (i mod 3)
    in if x' <> x && y' <> y then f (x', y')
  done

(* vérifie un prédicat p sur tous les éléments d'une matrice *)
let for_all2 p a =
  let n1 = Array.length a
  and n2 = Array.length a.(0) in
  let rec loop i j =
    if i = n1 then true
    else if j = n2 then loop (i + 1) 0
    else if p a.(i).(j) then loop i (j + 1) else false
  in loop 0 0
(*****************************************************************************)


(* réinitialise tous les conflits
   à utiliser quand on recommence une partie *)
let reinit_conflits () =
  Array.iter (Array.iter Dynamique.vider) ensemble_conflits


(* détermine les chiffres disponibles dans une certaine
   case de la grille, actualise 'disponibles' *)
let chiffres_disponibles () =
  let (x, y) = !curseur in
  for i = 1 to 9 do
    disponibles.(i) <- true
  done;
  iter_voisins (fun (i, j) ->
    disponibles.(grille.(i).(j)) <- false) (x, y);
  disponibles.(0) <- true (* on peut toujours vider une cellule *)


(* met à jour la position du curseur puis les valeurs autorisées *)
let maj_curseur key =
  let (x, y) = !curseur in begin match key with
    | 'z' -> curseur := (x, inc9 y)
    | 'q' -> curseur := (dec9 x, y)
    | 's' -> curseur := (x, dec9 y)
    | 'd' -> curseur := (inc9 x, y)
    | _ -> ()
  end; chiffres_disponibles ()


(* Change de numéro dans la case indiquée, avec les effets de bord que ça
   implique (ajuster les conflits, détecter une victoire). *)
let changer_chiffre v (x, y) =
  if v <> -1 && (not !est_dispo_affiche || disponibles.(v)) (* 1 *)
     && v <> grille.(x).(y) && not defaut.(x).(y) then begin
    (* on retire la case des listes de conflits des cases qui étaient en conflit
       avec elle *)
    Dynamique.iter (fun (i, j) ->
      Dynamique.suppr (x, y) ensemble_conflits.(i).(j);
      conflits.(i).(j) <- not (Dynamique.est_vide ensemble_conflits.(i).(j)))
        ensemble_conflits.(x).(y);

    Dynamique.vider ensemble_conflits.(x).(y);
    
    (* on met à jour ses nouveaux conflits *)
    if v <> 0 then begin
      iter_voisins (fun (i, j) ->
        if grille.(i).(j) = v then begin
          Dynamique.ajout (x, y) ensemble_conflits.(i).(j);
          Dynamique.ajout (i, j) ensemble_conflits.(x).(y)
        end;
        conflits.(i).(j) <- not (Dynamique.est_vide ensemble_conflits.(i).(j))) (x, y)
    end;
    conflits.(x).(y) <- not (Dynamique.est_vide ensemble_conflits.(x).(y));
    grille.(x).(y) <- v
  end
(* (* 1 *): v <> - 1: la touche appuyée est bien un chiffre
            (not !est ...): n'autorise que les chiffres disponibles
            quand le mode facile est activé
            v <> grille.(x).(y): on change de chiffre
            not defaut.(x).(y): la case n'est pas initiale
 *)


(* réagis en fonction de la position de la souris et des
   actions efffectuées. *)
let maj_curseur_souris () =
  let {ligne; cellule; marge; marge_nombres; _} = config in
  let cadre = 10 * ligne + 9 * cellule in
  let d_aux = marge + cadre + marge_nombres + ligne in

  let (x, y) = Graphics.mouse_pos () in
  let (x', y') = (x - marge - ligne, y - marge - ligne) in
  (* la souris est dans le cadre *)
  if compt marge x (marge + cadre) && compt marge y (marge + cadre)
  (* la souris est exactement dans une case *)
  && compt 0 (x' mod (cellule + ligne)) cellule
  && compt 0 (y' mod (cellule + ligne)) cellule
    then begin (* 1 *)
      let ncurseur = (x' / (cellule + ligne), y' / (cellule + ligne)) in
      if ncurseur = !curseur
        then changer_chiffre 0 !curseur
        else (curseur := ncurseur; chiffres_disponibles ())
    end
  else if compt d_aux x (d_aux + cellule) && compt marge y (marge + cadre)
  && compt 0 (y' mod (cellule + ligne)) cellule 
    then changer_chiffre ((y' / (cellule + ligne)) + 1) !curseur (* 2 *)
(* (* 1 *): Déplace le curseur pour une position bien définie.
            Supprime la valeur actuelle si on clique au même endroit
   (* 2 *): Ajoute la valeur choisie dans la colonne auxiliaire
 *)


let hesiter_bombarder () =
  if 0 = Random.int chance_bombe then begin
    let (x_cible, y_cible) = (Random.int 9, Random.int 9) in
    if grille.(x_cible).(y_cible) <> 0
    && not defaut.(x_cible).(y_cible)
    && not !existe_cible then begin
      existe_cible := true;
      cible_case := (x_cible, y_cible);
      cible := coord_vers_pix (x_cible, y_cible)
    end
  end


(* détermine si la partie est fini *)
let test_est_jeu_battu () =
  let est_grille_remplie = for_all2 ((<>) 0) grille
  and pas_de_conflit = for_all2 (not) conflits in
  est_jeu_battu := est_grille_remplie && pas_de_conflit
