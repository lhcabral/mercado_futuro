from django.utils.text import slugify


def gerar_slug(texto, modelo, instancia=None):
    base = (slugify(texto) or "item")[:60]
    slug = base
    numero = 2
    consulta = modelo.objects.all()
    if getattr(instancia, "pk", None):
        consulta = consulta.exclude(pk=instancia.pk)
    while consulta.filter(slug=slug).exists():
        slug = f"{base}-{numero}"[:80]
        numero += 1
    return slug
