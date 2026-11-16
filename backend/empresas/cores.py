"""Cores predominantes de uma logomarca, para a página do fornecedor."""

from __future__ import annotations

from collections import Counter

from PIL import Image, UnidentifiedImageError

COR_PADRAO = {
    "primaria": "#0F6B4C",
    "secundaria": "#E8A317",
    "destaque": "#FFFFFF",
}


def extrair_cores(origem) -> dict[str, str]:
    try:
        if hasattr(origem, "seek"):
            origem.seek(0)
        with Image.open(origem) as imagem:
            reduzida = imagem.convert("RGBA").resize((48, 48), Image.Resampling.NEAREST)
            amostras = list(reduzida.getdata())
    except (UnidentifiedImageError, OSError, ValueError):
        return dict(COR_PADRAO)

    contagem: Counter[tuple[int, int, int]] = Counter()
    for vermelho, verde, azul, alfa in amostras:
        if alfa < 200:
            continue
        if vermelho > 240 and verde > 240 and azul > 240:
            continue
        if vermelho < 12 and verde < 12 and azul < 12:
            continue
        tom = ((vermelho // 16) * 16, (verde // 16) * 16, (azul // 16) * 16)
        contagem[tom] += 1

    if not contagem:
        return dict(COR_PADRAO)

    ordenadas = [cor for cor, _ in contagem.most_common()]
    primaria = ordenadas[0]
    secundaria = next(
        (cor for cor in ordenadas[1:] if _distancia(cor, primaria) >= 80),
        None,
    )
    if secundaria is None:
        secundaria = _deslocar(primaria)

    return {
        "primaria": _hex(primaria),
        "secundaria": _hex(secundaria),
        "destaque": "#1A1A1A" if _luminancia(primaria) > 0.62 else "#FFFFFF",
    }


def _hex(rgb: tuple[int, int, int]) -> str:
    return "#{:02X}{:02X}{:02X}".format(*rgb)


def _distancia(primeira, segunda) -> int:
    return sum(abs(a - b) for a, b in zip(primeira, segunda))


def _deslocar(rgb: tuple[int, int, int]) -> tuple[int, int, int]:
    vermelho, verde, azul = rgb
    if vermelho + verde + azul < 380:
        return (min(255, vermelho + 90), min(255, verde + 70), min(255, azul + 20))
    return (max(0, vermelho - 90), max(0, verde - 40), max(0, azul - 20))


def _luminancia(rgb: tuple[int, int, int]) -> float:
    def canal(valor: int) -> float:
        escala = valor / 255
        if escala <= 0.04045:
            return escala / 12.92
        return ((escala + 0.055) / 1.055) ** 2.4

    vermelho, verde, azul = (canal(parte) for parte in rgb)
    return 0.2126 * vermelho + 0.7152 * verde + 0.0722 * azul
