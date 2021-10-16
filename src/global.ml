(*****************************************************************************)
(* global.ml : définition des structures générales du programme              *)
(*****************************************************************************)



let grille = Array.make_matrix 9 9 0 (* 0: cellule vide, 1-9: chiffre inscrit *)
let defaut = Array.make_matrix 9 9 false (* vrai ssi la case est une case de la grille initiale *)
let conflits = Array.make_matrix 9 9 false (* vrai ssi la case est incompatible avec une autre *)

let curseur = ref (4, 4)
let disponibles = Array.make 10 true (* valeurs disponibles sous le curseur *)

let est_dispo_affiche = ref false (* mode activé par a *)
let est_conflit_affiche = ref false (* mode activé par e *)
let est_jeu_en_cours = ref true
let est_jeu_battu = ref false

let existe_cible = ref false
let est_lancee_bombe = ref false
let bombe = ref (0, 0)
let cible_case = ref (0, 0)
let cible = ref (0, 0)

type config_fenetre = {
  ligne: int; (* largeur en pixel d'une ligne de la grille *)
  cellule: int; (* côté d'une cellule (doit correspondre aux fichiers fournis) *)
  marge: int; (* marge entre la grille et la bordure de la fenêtre, le menu aux. et la fenêtre,
                 et la barre supérieure et la fenêtre *)
  cadre_sup: int; (* zone supérieure contenant l'avion et le texte *)
  marge_sup: int; (* marge entre la grille et la zone supérieure *)
  marge_nombres: int; (* marge entre la grille et le menu aux. *)
  zone_texte: int (* zone supérieure réservée au texte *)
}


(* Proposition de réglages graphiques pour l'application *)
let config = {
  ligne = 2; 
  cellule = 50;
  marge = 20;
  cadre_sup = 60;
  marge_sup = 10;
  marge_nombres = 4;
  zone_texte = 20
}
