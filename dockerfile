# -----------------------------
# Etapa 1: Build (Next.js)
# -----------------------------
FROM node:18-alpine AS builder

WORKDIR /app

# Copiamos manifests de npm
COPY package*.json ./

# Instalar deps (prod+dev) para el build
RUN npm ci

# Copiar el resto del código
COPY . .

# Desactivar telemetría de Next
ENV NEXT_TELEMETRY_DISABLED=1

# Hornear la URL del backend en build
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# Build standalone
RUN npm run build

# -----------------------------
# Etapa 2: Runtime mínimo
# -----------------------------
FROM node:18-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# También dejamos disponible la variable en runtime (por si la usas)
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# Dependencias para next/image / libc
RUN apk add --no-cache libc6-compat

# Copiar salida standalone
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static      ./.next/static
COPY --from=builder /app/public            ./public

EXPOSE 3000
CMD ["node","server.js"]
