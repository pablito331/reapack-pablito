# @description Exibir informações completas do projeto no console
# @author MeuNome
# @version 1.0
# @about
#   Script de introdução ao Python no REAPER.
#   Exibe no console: nome do projeto, caminho, BPM, compasso,
#   número de tracks e uma lista resumida de cada track.
#   Bom ponto de partida para entender como a API funciona em Python.

from reaper_python import *


def vol_to_db(vol):
    """Converte volume linear para dB."""
    import math
    if vol <= 0:
        return "-inf dB"
    return f"{20 * math.log10(vol):.1f} dB"


def pan_to_str(pan):
    """Converte pan -1..1 para string legível."""
    if abs(pan) < 0.01:
        return "C"
    pct = abs(pan) * 100
    side = "L" if pan < 0 else "R"
    return f"{pct:.0f}% {side}"


def main():
    # -------------------------------------------------------
    # Informações do projeto
    # -------------------------------------------------------
    proj_name = RPR_GetProjectName(0, "", 512)[2]
    proj_path = RPR_GetProjectPath("", 512)[0]
    num_tracks = RPR_CountTracks(0)

    # BPM e compasso
    bpm, bpi = RPR_GetProjectTimeSignature2(0)[0:2]

    # Posição do cursor
    cursor_pos = RPR_GetCursorPosition()

    # -------------------------------------------------------
    # Montar saída
    # -------------------------------------------------------
    lines = []
    lines.append("=" * 55)
    lines.append("  INFORMAÇÕES DO PROJETO")
    lines.append("=" * 55)
    lines.append(f"  Nome     : {proj_name if proj_name else '(sem nome)'}")
    lines.append(f"  Caminho  : {proj_path if proj_path else '(não salvo)'}")
    lines.append(f"  BPM      : {bpm:.2f}")
    lines.append(f"  Compasso : {int(bpi[0])}/{int(bpi[1])}" if isinstance(bpi, (list, tuple)) else f"  Compasso : {int(bpm)}/4")
    lines.append(f"  Cursor   : {cursor_pos:.3f}s")
    lines.append(f"  Tracks   : {num_tracks}")
    lines.append("-" * 55)

    # Cabeçalho da tabela de tracks
    lines.append(f"  {'#':<4} {'Nome':<28} {'Vol':>8} {'Pan':>8} {'Items':>6}")
    lines.append("-" * 55)

    for i in range(num_tracks):
        track = RPR_GetTrack(0, i)

        # Nome — GetTrackName retorna (retval, track, buf, buf_sz)
        _, _, name, _ = RPR_GetTrackName(track, "", 256)

        vol  = RPR_GetMediaTrackInfo_Value(track, "D_VOL")
        pan  = RPR_GetMediaTrackInfo_Value(track, "D_PAN")
        mute = RPR_GetMediaTrackInfo_Value(track, "B_MUTE")
        items = RPR_CountTrackMediaItems(track)

        mute_tag = " [M]" if mute else ""
        lines.append(
            f"  {i+1:<4} {(name[:24] + mute_tag):<28} "
            f"{vol_to_db(vol):>8} {pan_to_str(pan):>8} {items:>6}"
        )

    lines.append("=" * 55)
    output = "\n".join(lines) + "\n"

    RPR_ShowConsoleMsg(output)


main()
