import azure.functions as func
from main import app as fastapi_app

# FastAPIアプリをそのままFunctionsのHTTPの入口に繋ぐ（main.pyは変えない）
app = func.AsgiFunctionApp(app=fastapi_app, http_auth_level=func.AuthLevel.ANONYMOUS)
