from PIL import Image
import numpy as np

deb = """\
(*****************************************************************************)
(* assets.ml: fichier généré automatiquement contenant les différents        *)
(*            assets du jeu.                                                 *)
(*****************************************************************************)

let t = Graphics.transp

"""

fin = """\
let image_jet () =
  let x = Array.length djet.(0) and y = Array.length djet in
  (Graphics.make_image djet, x, y)
let image_explosion () =
  let x = Array.length dexplosion.(0) and y = Array.length dexplosion in
  (Graphics.make_image dexplosion, x, y)

let tableau_images () =
  Array.map Graphics.make_image [|d0; d1; d2; d3; d4; d5; d6; d7; d8; d9|]"""

def rgb_to_str(t):
    [r, g, b] = t
    v = (r << 16) + (g << 8) + b
    return "t" if v == 0xFFFFFF else hex(v)

with open("../assets.ml", "w") as code:
    code.write(deb)

l = [str(i) for i in range(10)] + ["jet", "explosion"]
for asset in l:
    im = Image.open(asset + ".bmp")
    p = np.array(im)
    with open("../assets.ml", "a") as code:
        code.write("let d" + asset + " = [|\n")
        a = ";\n".join([
            "[| " + "; ".join([rgb_to_str(e)
                for e in ligne]) + "|]"
            for ligne in p])
        code.write(a)
        code.write("\n|]\n\n")

with open("../assets.ml", "a") as code:
    code.write(fin)
