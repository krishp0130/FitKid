import 'dotenv/config'

type EnvConfig = {
  supabaseUrl: string
  supabaseServiceRoleKey: string
  port: number
}

function requireEnv(key: string): string {
  const value = process.env[key]
  if (!value) {
    throw new Error(`Missing required env var: ${key}`)
  }
  return value
}

export const env: EnvConfig = {
  supabaseUrl: requireEnv('SUPABASE_URL'),
  supabaseServiceRoleKey: requireEnv('SUPABASE_SERVICE_ROLE_KEY'),
  port: Number(process.env.PORT ?? 3001)
}
