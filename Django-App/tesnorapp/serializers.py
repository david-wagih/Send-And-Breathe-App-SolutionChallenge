from rest_framework import serializers
from .models import approvals
from rest_framework.serializers import Serializer, FileField


class UploadSerializer(Serializer):
    file_uploaded = FileField()

    class Meta:
        fields = ['file_uploaded']


class approvalsSerializers(serializers.Serializer):
    model = approvals
    fields = '__all__'
