# Backend

Fastify-based BFF for Kidzone, wrapping Supabase Auth and domain APIs.

## Structure
```
backend/
├── package.json        # deps + scripts
├── tsconfig.json
└── src/
    ├── server.ts       # Fastify bootstrap
    ├── config/
    │   ├── env.ts      # env parsing
    │   └── supabase.ts # Supabase admin client
    └── modules/
        └── auth/
            └── routes.ts
```

## Env
Create a `.env` with:
```
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
PORT=3000
```

## Run
```
cd backend
npm install
npm run dev
```
