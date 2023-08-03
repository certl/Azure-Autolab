import logging

import azure.functions as func

import secrets
import string



def generate_password(length):
    alphabet = string.ascii_letters + string.digits + "%$&()!§*#?"
    password = ''.join(secrets.choice(alphabet) for i in range(length))  # for a 20-character password
    return password




def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    length = req.params.get('length')
    if not length:
        try:
            return func.HttpResponse(generate_password(20))
        except ValueError:
            pass
        else:
            return func.HttpResponse(generate_password(20))

    return func.HttpResponse(generate_password(length))
