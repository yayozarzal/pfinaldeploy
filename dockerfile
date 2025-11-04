# -----------------------------
# Etapa 1: Build (Next.js)
# -----------------------------
FROM node:18-alpine AS builder

WORKDIR /app

# Habilitar pnpm (Corepack viene en Node 18+)
RUN corepack enable && corepack prepare pnpm@9.0.0 --activate

# Dependencias de compilación (sharp/next-opt)
RUN apk add --no-cache libc6-compat

# Copiar manifests primero para cache
COPY package.json pnpm-lock.yaml ./
# Si usas .npmrc o .pnpmfile.cjs, cópialos también
# COPY .npmrc ./

# Instalar deps (prod+dev para build)
RUN pnpm install --frozen-lockfile

# Copiar el resto del código
COPY . .

# Desactivar telemetría de Next
ENV NEXT_TELEMETRY_DISABLED=1

# Construir en modo standalone
RUN pnpm build

# -----------------------------
# Etapa 2: Runtime mínimo
# -----------------------------
FROM node:18-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Para imágenes/optimizadores nativos
RUN apk add --no-cache libc6-compat

# Copiar salida standalone
# (Next genera server.js y node_modules necesarios en .next/standalone)
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static      ./.next/static
COPY --from=builder /app/public            ./public

# Si usas Tailwind o fuentes en /public, ya están copiadas

# Puerto por defecto
EXPOSE 3000

# Iniciar el servidor Next.js standalone
CMD ["node", "server.js"]
