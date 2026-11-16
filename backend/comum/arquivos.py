def url_absoluta(request, arquivo):
    if not arquivo:
        return None
    try:
        endereco = arquivo.url
    except ValueError:
        return None
    if request is None:
        return endereco
    return request.build_absolute_uri(endereco)
