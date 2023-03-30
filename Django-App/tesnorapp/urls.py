
from django.contrib import admin
from django.urls import path , include
from . import views
from rest_framework import routers

from .views import UploadViewSet

router =routers.DefaultRouter()
router.register('tensorapp',views.ApprovalsView)
router.register(r'upload', UploadViewSet, basename="upload")
urlpatterns = [
    path('', views.myform ,name='myform'),
    path('api/', include(router.urls)),
    path('status/', views.approvereject),
]
