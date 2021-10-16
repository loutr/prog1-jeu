(*****************************************************************************)
(* Dynamique: Implémentation d'une structure mutable permettant de mémoriser *)
(*            des éléments, d'en ajouter et d'en retirer.                    *)
(*            Il est bien sûr possible d'en changer le fonctionnement        *)
(*            interne afin de la rendre plus efficace (en utilisant des      *)
(*            arbres bicolores ou AVL, par exemple).                         *)
(*****************************************************************************)


exception DynamiquePlein


type 'a t = {
  content: 'a array;
  mutable taille: int;
  taille_max: int
}


(* initialise une structure vide *)
let creer taille_max e0 = {
  content = Array.make taille_max e0;
  taille = 0; taille_max
}


let est_vide {taille; _} = (taille = 0)
let vider a = a.taille <- 0


let ajout e a =
  let {content; taille; taille_max} = a in
  if taille < taille_max then
    let rec aux = function
      | i when i < taille -> if content.(i) <> e then aux (i + 1)
      | i -> content.(i) <- e; a.taille <- taille + 1
    in aux 0
  else raise DynamiquePlein


let suppr e a =
  let {content; taille; taille_max} = a in
  let decale i =
    for j = (i + 1) to taille do
      content.(j - 1) <- content.(j)
    done
  in
  let rec aux = function
    | i when i < taille -> if content.(i) = e
        then (a.taille <- taille - 1; decale i)
        else aux (i + 1)
    | i -> ()
  in aux 0


let mem e a = 
  let rec aux = function
    | i when i < a.taille -> (a.content.(i) = e) || (aux (i + 1))
    | i -> false
  in aux 0


(* itère la fonction f sur les éléments de la structure à la manière
   de Array.iter *)
let iter f {content; taille; _} =
  for i = 0 to taille do
    f content.(i)
  done
