#!/usr/bin/env python3
"""Valide le frontmatter YAML des commandes, agents et skills du kit."""
import glob
import sys

import yaml

FICHIERS = sorted(
    glob.glob(".claude/commands/*.md")
    + glob.glob(".claude/agents/*.md")
    + glob.glob(".claude/skills/*/SKILL.md")
)
# Champs obligatoires selon le type de fichier.
OBLIGATOIRES = {"agents": {"name", "description"}, "skills": {"name", "description"}, "commands": {"description"}}

erreurs = 0
for f in FICHIERS:
    texte = open(f, encoding="utf-8").read()
    parties = texte.split("---\n", 2)
    if not texte.startswith("---\n") or len(parties) < 3:
        print(f"{f} : frontmatter absent ou non fermé")
        erreurs += 1
        continue
    try:
        meta = yaml.safe_load(parties[1])
    except yaml.YAMLError as e:
        print(f"{f} : YAML invalide ({e})")
        erreurs += 1
        continue
    type_ = f.split("/")[1]
    manquants = OBLIGATOIRES[type_] - set(meta or {})
    if manquants:
        print(f"{f} : champs manquants {sorted(manquants)}")
        erreurs += 1
print(f"{len(FICHIERS)} fichiers vérifiés, {erreurs} erreur(s)")
sys.exit(1 if erreurs else 0)
