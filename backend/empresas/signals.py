from django.db.models.signals import post_save
from django.dispatch import receiver

from empresas.checklist import ITENS
from empresas.models import Empresa, ItemChecklist


@receiver(post_save, sender=Empresa)
def criar_checklist(sender, instance, created, **kwargs):
    if not created:
        return
    ItemChecklist.objects.bulk_create(
        [
            ItemChecklist(empresa=instance, codigo=codigo, titulo=titulo, ordem=ordem)
            for ordem, (codigo, titulo) in enumerate(ITENS, start=1)
        ]
    )
