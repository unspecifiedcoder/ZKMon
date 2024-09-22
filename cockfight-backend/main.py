import requests
import json

# testing broo testing
urls = {
    'auth': [
        '/auth/Signup',
        '/auth/Signin',
        '/auth/requestOtp',
        '/auth/verifyOTP',
        '/auth/hehe',  # get
    ],
    'user': [
        '/user/me',  # get
        '/user/edit'
    ],
    'core': [
        '/core/query'
        '/core/mutate'
    ]
}

data = {
    'auth': {
        'Signup': {
            'username': 'mikasa',
            'phnum': '9100572305',
            'password': 'erenily'
        },
        'Signin': {
            'phnum': '9100572305',
            'password': 'erenily'
        },
        'verify': {
            'OTP': 919465,
            'email': '9100572305'
        },

    },
    'user': {
        'edit': {
            'username': 'Mikasa',
            'phnum': '9100572305',
            'password': 'erenIly'
        }
    },
    'core': {
        'query': {
            'Item': 'ZZZSCRY',
            'Type': 'MobileNum',
            'SmsContext': 'hehe thisss'
        },
        'mutate': {
            'Item': 'ZZZSCRY',
            'Type': 'MobileNum',
            'Context': 'hehe thisss',
            'type': 'Spam'
        }
    }
}


JWT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjE0LCJpYXQiOjE2Nzk2NDg4NzUsImV4cCI6MTY3OTczNTI3NX0.h6EMVD2QCtuRUdn1CBj7Ft4QZJHrwVD12J3ER-akREU"
resp = requests.post(
    f'http://localhost:3333{urls["core"][0]}', data=data['core']['query'], headers={
        'Authorization': f'Bearer {JWT_TOKEN}'
    }
)

# resp = requests.get(f'http://localhost:3333{urls["user"][0]}', headers={
#     'Authorization': f'Bearer {JWT_TOKEN}'
# })
print(resp.text, resp.status_code)
