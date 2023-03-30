from django.shortcuts import render
from rest_framework.viewsets import ViewSet

from . forms import MyForm
from rest_framework import viewsets
from rest_framework.decorators import api_view
from django.core import serializers
from rest_framework.response import Response
from rest_framework import status
from django.http import JsonResponse
from rest_framework.parsers import JSONParser
from . models import approvals
from .serializers import approvalsSerializers, UploadSerializer
import pickle 
import json 
from django.http import HttpResponse
from django.shortcuts import render
import numpy
from numpy import asarray
from PIL import Image
from django.views.decorators.csrf import csrf_exempt
import tensorflow as tf
import pandas as pd 

# ViewSets define the view behavior.
class UploadViewSet(ViewSet):
    serializer_class = UploadSerializer

    def list(self, request):
        return Response("GET API")

    def create(self, request):
        try:
            model = tf.keras.models.load_model('./savedmodels/finalmodel.h5')
            input_user =request.FILES.get('file_uploaded')
            image = Image.open(input_user, "r")
            pixel_values = list(image.getdata())
            data = asarray(image)


            def prepare_image(img):
                image = tf.image.resize(img, [224, 224])
                image = tf.expand_dims(image, axis=0)
                rescal_layer = tf.keras.layers.Rescaling(scale=1. / 255)
                image = rescal_layer(image)
                return image

            prepared_input = prepare_image(data)
            out = model.predict(prepared_input)
            final_output = out.argmax(axis=1)
            response_data = {}
            result = ""
            if( final_output == 1):
                result = 'garbage'
            else:
                result = 'clean'
            response_data['result'] =  result
            response_data['error'] = False
            return JsonResponse(response_data, safe=False)
        except ValueError as e:
            response_data['result'] = e.args[0]
            response_data['error'] = True
            return JsonResponse(response_data, safe=False)


class ApprovalsView(viewsets.ModelViewSet):
    queryset=approvals.objects.all()
    serializer_class=approvalsSerializers

def myform(request):
    if request.method =="POST":
        form =MyForm(request.POST)
        if form.is_valid():
            myform=form.save(commit=False)
    else :
        form=MyForm()
        return  render(request,'myform/form.html',{'form' : form})

@api_view(["POST"])
def approvereject(request):
    try:
        model = tf.keras.models.load_model('./savedmodels/finalmodel.h5')
        input_user=request.FILES['filename']
        image = Image.open(input_user, "r")
        pixel_values = list(image.getdata())
        last=numpy.array(pixel_values)
        data = asarray(image)
        print(type(data))
        print(data.shape)
        def prepare_image(img):
            image=tf.image.resize(img,[224,224])
            image = tf.expand_dims(image,axis=0)
            rescal_layer=tf.keras.layers.Rescaling(scale=1./255)
            image=rescal_layer(image)
            return image 
        prepared_input=prepare_image(data)
        out=model.predict(prepared_input)
        final_output=out.argmax(axis=1)
        print(final_output)
        y_pred=(final_output == 1)
        newdf=pd.DataFrame(y_pred , columns=['status'])
        newdf=newdf.replace({True:'garbage', False:'clean'})
        return JsonResponse('You status is {}'.format(newdf),safe=False)
    except ValueError as e :
        return Response(e.args[0],status.HTTP_400_BAD_REQUEST)
        
        



# Create your views here.
