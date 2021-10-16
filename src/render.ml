(*****************************************************************************)
(* render.ml : gestion de l'affichage en fonction des données de global.ml   *)
(*****************************************************************************)

open Graphics
open Global



(* Avec la version 4.11.1 de OCaml sur Unix et la version 5.1 du module
   Graphics, les rectangles tracées par fill_rect sont trop larges et
   grands de 1 pixel *)
let fill_rect x y w h = fill_rect x y (w - 1) (h - 1)


(********************************** données **********************************)
let c_ligne_inter : Graphics.color = 0x888888
let c_ligne : Graphics.color = 0x000000
let c_texte : Graphics.color = 0x000000
let c_defaut : Graphics.color = 0xBBBBBB
let c_conflit : Graphics.color = 0xEEAAAA
let c_bombe : Graphics.color = 0xEEAAAA

let framerate = 60. (* taux de raffraîchissement *)
let vitesse = 4 (* vitesse de l'avion en pixel par frame *)
let vitesse_bombe = 3 (* vitesse d'une bombe *)
let duree_explosion = 20 (* nombre de frame d'une étape de l'explosion *)
(*****************************************************************************)


(* onstruit une fenêtre selon la configuration donnée et
   renvoie la fonction traçant les grilles principale et auxiliaire *)
let creer_fenetre {ligne; cellule; marge; cadre_sup; marge_sup; marge_nombres} = 
  let cadre = 10 * ligne + 9 * cellule in
  let cadre_aux = 2 * ligne + cellule in
  let x = 2 * marge + cadre + marge_nombres + cadre_aux
  and y = 2 * marge + cadre + marge_sup + cadre_sup in
  open_graph (" " ^ (string_of_int x) ^ "x" ^ (string_of_int y));
  set_window_title "Super Sudoku 3000";
  auto_synchronize false;
  (function () ->
    set_color c_ligne_inter;
    for i = 0 to 9 do
      let coord = marge + i * (cellule + ligne) in
      fill_rect coord marge ligne cadre;
      fill_rect marge coord cadre ligne
    done;
    set_color c_ligne;
    for i = 0 to 3 do
      let coord = marge + 3 * i * (cellule + ligne) in
      fill_rect coord marge ligne cadre;
      fill_rect marge coord cadre ligne
    done;
    set_color c_ligne;
    let x' = marge + cadre + marge_nombres in
    fill_rect x' marge ligne cadre;
    fill_rect (x' + ligne + cellule) marge ligne cadre;
    for i = 0 to 9 do
      let y = marge + i * (cellule + ligne) in
      fill_rect (x' + ligne) y cellule ligne
    done)

let tracer_grille = creer_fenetre config


(* Import des différentes images (possible seulement après
   la création de la fenêtre) *)
let tableau_chiffres = Assets.tableau_images () 
let (image_jet, x_jet, y_jet) = Assets.image_jet ()
let (image_exp, x_exp, y_exp) = Assets.image_explosion ()


(* colorie la case (x, y) par la couleur couleur *)
let dessiner_fond couleur (x, y) =
  let {cellule} = config in
  let (x_pixel, y_pixel) = Logic.coord_vers_pix (x, y) in
  set_color couleur;
  fill_rect x_pixel y_pixel cellule cellule


(* dessine le chiffre v dans la case (x, y) *)
let dessiner_chiffre v (x, y) =
  let (x_pixel, y_pixel) = Logic.coord_vers_pix (x, y) in
  draw_image tableau_chiffres.(v) x_pixel y_pixel

let dessiner_curseur = dessiner_chiffre 0


(* dessiner le chiffre v dans le tableau auxiliaire *)
let dessiner_chiffre_aux v =
  let {ligne; cellule; marge; marge_nombres} = config in
  let cadre = 10 * ligne + 9 * cellule in
  let x = marge + cadre + marge_nombres + ligne in
  draw_image tableau_chiffres.(v) x (marge + ligne + (v - 1) * (ligne + cellule))


(* affiche le texte dans la partie supérieure de la fenêtre, de
   manière contextuelle *)
let afficher_texte () =
  let {ligne; cellule; marge; marge_sup} = config in
  let cadre = 10 * ligne + 9 * cellule in
  moveto marge (marge + cadre + marge_sup);
  set_color c_texte;
  if !est_jeu_battu then
    draw_string "Bravo ! r: recommencer | x: quitter"
  else
    draw_string "r: recommencer | a: indique les nombres disponibles | e: montre les conflits | x: quitter"



(*****************************************************************************)
(************************ mise à jour de l'affichage *************************)
(*****************************************************************************)


let maj_affichage_grille () =
  tracer_grille ();
  for x = 0 to 8 do
    for y = 0 to 8 do
      let v = grille.(x).(y) in
      let par_defaut = defaut.(x).(y) in
      let en_conflit = conflits.(x).(y) in
      if par_defaut then (dessiner_fond c_defaut (x, y));
      if en_conflit && !est_conflit_affiche then (dessiner_fond c_conflit (x, y));
      if v <> 0 then (dessiner_chiffre v (x, y))
    done;
  done;
  dessiner_curseur !curseur;
  for i = 1 to 9 do
    if not !est_dispo_affiche || disponibles.(i) then dessiner_chiffre_aux i
  done


let dessiner_bombe (i, j) =
  set_color c_bombe; fill_rect i j 5 10

(* déroule l'animation d'une bombe tombant sur une case *)
let maj_bombe =
  let etape_explosion = ref 0 and c = ref 0 in
  fun () -> begin match !etape_explosion with
    | 0 -> let (xb, yb) = !bombe and (_, yc) = !cible in
      dessiner_bombe (xb, yb);
      if yb > yc then
        bombe := (xb, yb - vitesse_bombe)
      else
        incr etape_explosion
    | 1 -> let (xc, yc) = !cible in
        if !c < duree_explosion then begin
          draw_image image_exp xc yc;
          incr c
        end else begin
          c := 0;
          incr etape_explosion
        end
    | 2 -> let (xc, yc) = !cible in
        if !c < duree_explosion then begin
          draw_image image_exp (xc - 5) yc;
          draw_image image_exp (xc + 5) (yc + 6);
          incr c
        end else begin
          c := 0; etape_explosion := 0;
          Logic.changer_chiffre 0 !cible_case;
          existe_cible := false; est_lancee_bombe := false
        end
    | _ -> failwith "maj_bombe: phase inconnue"
  end


(* raffraîchit le jet et une éventuelle bombe si elle est lancé *)
let maj_affichage_jet =
  let attente = 5 in
  let {ligne; cellule; marge; marge_sup; marge_nombres; zone_texte} = config in
  let cadre = 10 * ligne + 9 * cellule in
  let longueur = 2 * marge + cadre + marge_nombres + 2 * ligne + cellule in
  let hauteur = marge + cadre + marge_sup + zone_texte in
  let etendue_parcours = longueur + x_jet + vitesse * attente in
  (* x est une référence statique locale de la position du jet *)
  let x = ref (-x_jet) in function () -> begin
    (* quand l'avion a fait un tour complet *)
    if !x + vitesse > etendue_parcours then begin
      Logic.hesiter_bombarder ();
      x := (!x + vitesse) - etendue_parcours - x_jet
    end else
      x := (!x + vitesse);
    draw_image image_jet !x hauteur;
    if not !est_lancee_bombe && !existe_cible && !x >= (fst !cible) then begin
      est_lancee_bombe := true;
      bombe := (!x, hauteur)
    end;
    if !est_lancee_bombe then
      maj_bombe ()
  end


(* syncrhonise l'affichage avec le taux d'images par secondes demandé *)
let sync_framerate =
  let starting_frame_time = ref (Sys.time ()) in
  function () -> begin
    let remaining_time = (1.0 /. framerate) -. (Sys.time () -. !starting_frame_time) in
    if remaining_time > 0.0 then Unix.sleepf remaining_time; starting_frame_time := Sys.time ()
  end


(* raffraîchissement de l'écran *)
let maj_affichage () =
  clear_graph ();
  sync_framerate ();
  afficher_texte ();
  maj_affichage_grille ();
  maj_affichage_jet ();
  synchronize ()
