#### App where I developed Backend for Kawach Hackathon.

Stack used

- Prisma - for Postgres ORM
- reddis - Cache secondary storage
- Docker - to host and run postgres [locally only] `railway` for hosting cloud postgres
- NestJS(express-TS) - backend framework
- python - api testing
- Typescript
- PassportJs - Auth and jwt management
- Twillio - SMS messaging
- Yarn - as Package manager

### How did it Go

- I used Compose Docs for generating the documentation and i am serving it over `/docs` route of [server](https://kawach-hackathonbackend-production.up.railway.app/)
- Prisma well i used to maintain all my db works and i guess i am in love with it 🥰 , Prisma ORM is flexible for me to setup relations easily and manage creating via `npx prisma migrate dev` and moniter my database from `npx prisma studio`
- i am maintaining several tables and several many to many relations from dbs. Got few tables with infor prefetched from national cyber forensics cordination centre and other tables which has demand data about our current users prisma ORM manages them for me
- Postgres was awesome to work with rn as i was currently using Prisma it doesnt make sense for me as it is `Mysql` or `Postgres`
- Docker i am using to run my postgres instance on port `5434` on locally and on railway for cloud
- Running Redis instance on docker for OTP support

Pending tasks

- Lay pipelines for 6 types of fraud detection
- trigger ml models
- query tables and calculate stats of an entity

<br>

## Guide To RUN/BUILD:

- close this git repo using git clone `<repo URL>`
- install required dependecies using `yarn`
- Create and update `.env` files according to .`env.example` file
- try `yarn start:dev` to start server in dev mode
- or try `yarn start:prod` to start server in production mode
- FOR DOCUMENTATION click here --> [docs](https://kawach-hackathonbackend-production.up.railway.app/docs)
- for SERVER API endpoint click here --> [SERVER](https://kawach-hackathonbackend-production.up.railway.app/)
- To view database u can use `prisma studio`

Incomplete things [GUIDE TO IMPLEMENT NLP]

- NLP trigger must be implemted
- close this project and run it
- got to `src/core/core.service.ts` write JS code to run NLP model
- i have seeded database with dummy gen data can look up stuff in it
- `main.py` has data organised already to test core endpoints

## How to use API

> AVAILABLE APIS

```js
{
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

```

> Respective Payloads

```js
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

```

<br>

## Dependencies and Architecture

![Image](./graph/dependencies.svg)

![Image](./modules/AppModule/dependencies.svg)
