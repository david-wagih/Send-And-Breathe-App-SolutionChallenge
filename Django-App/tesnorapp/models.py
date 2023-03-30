from django.db import models

# Create your models here.
class approvals(models.Model):
    trial=models.IntegerField(max_length=100)
    trial2=models.ImageField()

    def __str__(self):
        return '{},{}'.format(self.trial,self.trial2)