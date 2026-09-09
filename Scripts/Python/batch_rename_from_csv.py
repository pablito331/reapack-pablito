# @description Renomear tracks em lote a partir de um arquivo CSV
# @author MeuNome
# @version 1.0
# @about
#   Lê um arquivo CSV com duas colunas (índice, nome) e renomeia
#   as tracks correspondentes no projeto. Demonstra a vantagem do
#   Python no REAPER: integração com arquivos externos e bibliotecas
#   padrão (csv, os) que não existem em Lua/EEL.
#
#   Formato do CSV (sem cabeçalho):
#     1,Kick
#     2,Snare
#     3,Hi-Hat
#     4,Overhead L
#     5,Overhead R
#
#   Salve o CSV com encoding UTF-8.

import csv
import os
from reaper_python import *


def get_project_dir():
    """Retorna o diretório do projeto atual, ou o home se não salvo."""
    path = RPR_GetProjectPath("", 512)[0]
    if path:
        return path
    return os.path.expanduser("~")


def load_csv(filepath):
    """
    Lê o CSV e retorna dict {track_index (int): nome (str)}.
    Suporta CSV com ou sem cabeçalho (detecta se 1ª coluna é número).
    """
    mapping = {}
    with open(filepath, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) < 2:
                continue
            try:
                idx = int(row[0].strip())
                name = row[1].strip()
                if name:
                    mapping[idx] = name
            except ValueError:
                # Linha de cabeçalho ou inválida — pular
                continue
    return mapping


def main():
    # -------------------------------------------------------
    # Selecionar arquivo CSV
    # -------------------------------------------------------
    default_path = os.path.join(get_project_dir(), "tracks.csv")

    ok, filepath, _ = RPR_GetUserFileNameForRead(default_path, "Selecionar CSV de tracks", "csv")
    if not ok or not filepath:
        return

    if not os.path.isfile(filepath):
        RPR_ShowMessageBox(
            f"Arquivo não encontrado:\n{filepath}",
            "Batch Rename",
            0
        )
        return

    # -------------------------------------------------------
    # Carregar mapeamento
    # -------------------------------------------------------
    try:
        mapping = load_csv(filepath)
    except Exception as e:
        RPR_ShowMessageBox(
            f"Erro ao ler o CSV:\n{str(e)}",
            "Batch Rename",
            0
        )
        return

    if not mapping:
        RPR_ShowMessageBox(
            "CSV vazio ou sem linhas válidas.\n"
            "Formato esperado: índice,nome\nEx: 1,Kick",
            "Batch Rename",
            0
        )
        return

    num_tracks = RPR_CountTracks(0)
    if num_tracks == 0:
        RPR_ShowMessageBox("Projeto sem tracks.", "Batch Rename", 0)
        return

    # -------------------------------------------------------
    # Aplicar renomeação
    # -------------------------------------------------------
    renamed = []
    skipped = []

    RPR_Undo_BeginBlock()

    for track_idx, new_name in mapping.items():
        # Índice 1-based no CSV → 0-based na API
        api_idx = track_idx - 1

        if api_idx < 0 or api_idx >= num_tracks:
            skipped.append(f"  Índice {track_idx}: fora do range (projeto tem {num_tracks} tracks)")
            continue

        track = RPR_GetTrack(0, api_idx)
        _, _, old_name, _ = RPR_GetTrackName(track, "", 256)

        RPR_GetSetMediaTrackInfo_String(track, "P_NAME", new_name, True)
        renamed.append(f"  {track_idx}: '{old_name}' → '{new_name}'")

    RPR_Undo_EndBlock("Renomear tracks via CSV", -1)

    # -------------------------------------------------------
    # Relatório
    # -------------------------------------------------------
    report_lines = [f"Renomeadas: {len(renamed)} track(s)\n"]

    if renamed:
        report_lines.append("Alterações:")
        report_lines.extend(renamed)

    if skipped:
        report_lines.append(f"\nIgnoradas ({len(skipped)}):")
        report_lines.extend(skipped)

    report = "\n".join(report_lines)

    RPR_ShowConsoleMsg(report + "\n")
    RPR_ShowMessageBox(
        f"Concluído: {len(renamed)} renomeada(s), {len(skipped)} ignorada(s).\nDetalhes no console.",
        "Batch Rename",
        0
    )


main()
