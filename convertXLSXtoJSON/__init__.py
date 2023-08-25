import logging

import azure.functions as func

import excel2json


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function convert XLSXtoJSON processed a request.')

    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

