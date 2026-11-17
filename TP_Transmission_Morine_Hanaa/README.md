# TP Chaîne de transmission numérique (Matlab/Simulink)

**ENSIM 5A ASTRE – Théorie de l'information et du codage – 2026-2027**

Hanaa MORINE – Enseignant : Youssef SERRESTOU

## Contenu du dépôt

| Élément | Où le trouver |
|---|---|
| Rapport | Dossier [`rapport/`](rapport/) |
| Programmes Matlab et modèles Simulink | Dossier [`matlab/`](matlab/) |
| Vidéo de présentation (partie 2, codage de source) | [Lien Google Drive](https://drive.google.com/file/d/1_zS_u4LZXxvzqMcdxIF4yAUI5iZU3nUz/view?usp=sharing), copie dans [`presentation/`](presentation/) |
| Déclaration sur l'usage de l'IA | [`DECLARATION_IA.md`](DECLARATION_IA.md) |

## Comment lancer les programmes

1. Ouvrir Matlab (R2023b ou plus récent, avec Simulink) et se placer dans le dossier `matlab/`. Aucune toolbox supplémentaire n'est nécessaire.
2. Taper `Parametres` : ce script charge les paramètres enregistrés dans `mes_parametres.mat` (ne pas supprimer ce fichier).
3. Lancer le script de la partie souhaitée :

| Partie | Script | Contenu |
|---|---|---|
| 2 – Codage de source | `partie2` | Entropie, code de Huffman, extension, gzip |
| 2 – Lempel-Ziv | `partie2_lz` | Codeur et décodeur LZ78 |
| 3 – Chaîne de base | `partie3`, puis `partie3_q12` | Canaux CBS, uniforme et gaussien, détecteur optimal, TEB |
| 4 – Code de Hamming | `partie4` | Matrices, registre, décodage par syndrome, TEB avec et sans codage |
| 5 – QPSK | `partie5` | Mapping de Gray et mapping naturel, QPSK et Hamming |
| 6 – Filtre RRC | `partie6` | Filtre porte et filtre RRC, spectre, diagramme de l'œil |
| 7 – Canal à écho | `partie7` | Interférence entre symboles, transmission d'un texte |

Dans chaque script, les questions sont séparées par `%%`. Il est possible de les exécuter individuellement avec **Run Section** (Ctrl+Entrée).

## Modèles Simulink

- **Construits manuellement :** `source_simulink.slx`, `canal_cbs.slx` et `chaine_gauss.slx` (parties 2 et 3).
- **Générés par script :** pour les parties 4 et 5, les modèles `codeur_registre.slx`, `decodeur_hamming.slx`, `chaine_hamming.slx` et `chaine_qpsk.slx` sont créés par les scripts `creer_codeur_registre`, `creer_decodeur_hamming`, `creer_chaine_hamming` et `creer_chaine_qpsk`. Les scripts `partie4` et `partie5` les lancent automatiquement si les modèles n'existent pas encore.

Les scripts des différentes parties permettent de réaliser les simulations, d'obtenir les figures et d'analyser les performances de la chaîne de transmission numérique. Les résultats peuvent varier légèrement d'une exécution à l'autre (tirages aléatoires), dans la marge des intervalles de confiance.
