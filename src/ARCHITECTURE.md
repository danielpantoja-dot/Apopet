# 🏗️ Arquitectura del Sistema - Perfiles de Mascotas

## 📁 Estructura del Proyecto

```
/
├── App.tsx                          # Componente principal
├── /components                      # Componentes React
│   ├── /ui                         # Componentes shadcn/ui
│   ├── auth-modal.tsx              # ✨ Modal de autenticación (con upload de avatar)
│   ├── create-post.tsx             # ✨ Crear publicaciones (con upload de imágenes)
│   ├── edit-pet-profile.tsx        # ✨ Editar perfil mascota (con upload de fotos)
│   ├── edit-user-profile.tsx       # Editar perfil usuario
│   ├── community-feed.tsx          # Feed de comunidad
│   ├── pet-profile.tsx             # Vista de perfil de mascota
│   ├── user-dashboard.tsx          # Dashboard de usuario
│   ├── navigation-header.tsx       # Navegación principal
│   ├── notifications.tsx           # Sistema de notificaciones
│   ├── post-card.tsx              # Tarjeta de publicación
│   ├── qr-options.tsx             # Opciones de QR
│   └── user-profile-view.tsx      # Vista de perfil de otro usuario
├── /hooks                          # 🆕 Hooks personalizados
│   ├── use-auth.ts                # Hook de autenticación
│   ├── use-storage.ts             # Hook para subida de archivos
│   ├── use-posts.ts               # Hook para gestión de posts
│   └── use-profile.ts             # Hook para perfiles
├── /lib                            # 🆕 Librerías y utilidades
│   ├── /supabase
│   │   └── storage.ts             # Funciones de Supabase Storage
│   └── types.ts                   # Tipos TypeScript
├── /utils/supabase                # Configuración de Supabase
│   ├── client.tsx                 # Cliente de Supabase
│   └── info.tsx                   # Información del proyecto
├── /supabase/functions/server     # Edge Functions (servidor)
│   ├── index.tsx                  # Endpoints del servidor
│   └── kv_store.tsx              # Store de clave-valor
└── /styles
    └── globals.css                # Estilos globales
```

## 🔑 Componentes Clave

### 1. Sistema de Autenticación

#### `useAuth` Hook
```typescript
const { user, session, loading, signUp, signIn, signOut, isAuthenticated } = useAuth()
```

**Funcionalidades:**
- ✅ Registro de usuarios con metadata
- ✅ Login con email/contraseña
- ✅ Persistencia de sesión
- ✅ Logout
- ✅ Estado de autenticación reactivo

**Uso:**
```tsx
const { user, signIn, signOut } = useAuth()

// Login
await signIn({ email, password })

// Logout
await signOut()
```

### 2. Sistema de Storage (Imágenes)

#### `useStorage` Hook
```typescript
const { upload, remove, getPreview, uploading, progress } = useStorage()
```

**Funcionalidades:**
- ✅ Subida de imágenes a Supabase Storage
- ✅ Validación de tipo y tamaño (5MB max)
- ✅ Preview de imágenes antes de subir
- ✅ Eliminación de imágenes
- ✅ Indicador de progreso

**Buckets Disponibles:**
- `avatars` - Fotos de perfil de usuarios
- `pet-images` - Fotos de mascotas
- `post-images` - Imágenes en publicaciones

**Uso:**
```tsx
const { upload, uploading } = useStorage()

// Subir imagen
const url = await upload(file, 'pet-images', 'pet-123')

// El URL público se retorna automáticamente
```

### 3. Sistema de Publicaciones

#### `usePosts` Hook
```typescript
const { posts, loading, createPost, toggleLike, addComment, deletePost } = usePosts(userId)
```

**Funcionalidades:**
- ✅ Listar publicaciones con datos completos
- ✅ Crear publicaciones (normal, lost, found)
- ✅ Sistema de likes
- ✅ Sistema de comentarios
- ✅ Eliminar publicaciones propias
- ✅ Actualización reactiva del estado

**Tipos de Publicaciones:**
- `normal` - Publicación estándar
- `lost` - Mascota extraviada
- `found` - Mascota encontrada

**Uso:**
```tsx
const { posts, createPost, toggleLike } = usePosts(user?.id)

// Crear post
await createPost({
  author_id: user.id,
  content: "Mi perro está feliz!",
  image_url: imageUrl,
  type: 'normal'
})

// Dar/quitar like
await toggleLike(postId)
```

### 4. Sistema de Perfiles

#### `useProfile` Hook
```typescript
const { profile, pet, loading, updateProfile, updatePet, createPet } = useProfile(userId)
```

**Funcionalidades:**
- ✅ Obtener perfil de usuario y mascota
- ✅ Actualizar perfil de usuario
- ✅ Crear/actualizar perfil de mascota
- ✅ Validación de datos

**Uso:**
```tsx
const { profile, pet, updatePet } = useProfile(user?.id)

// Actualizar mascota
await updatePet({
  name: "Max",
  breed: "Golden Retriever",
  image_url: uploadedUrl
})
```

## 🗄️ Modelo de Base de Datos

### Tablas Principales

#### `profiles`
```sql
- id (UUID, PK, FK → auth.users)
- name (TEXT)
- email (TEXT, UNIQUE)
- phone (TEXT)
- location (TEXT)
- avatar_url (TEXT)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### `pets`
```sql
- id (UUID, PK)
- owner_id (UUID, FK → profiles)
- name (TEXT)
- breed (TEXT)
- age (TEXT)
- weight (TEXT)
- color (TEXT)
- personality (TEXT[])
- favorite_food (TEXT)
- favorite_toys (TEXT[])
- vaccinated (BOOLEAN)
- microchip (TEXT)
- image_url (TEXT)
- likes (INTEGER)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### `posts`
```sql
- id (UUID, PK)
- author_id (UUID, FK → profiles)
- pet_id (UUID, FK → pets, nullable)
- content (TEXT)
- image_url (TEXT)
- type (TEXT: 'normal'|'lost'|'found')
- pet_info (JSONB, para lost/found)
- likes (INTEGER)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### `comments`
```sql
- id (UUID, PK)
- post_id (UUID, FK → posts)
- author_id (UUID, FK → profiles)
- content (TEXT)
- created_at (TIMESTAMP)
```

#### `likes`
```sql
- id (UUID, PK)
- post_id (UUID, FK → posts)
- user_id (UUID, FK → profiles)
- created_at (TIMESTAMP)
- UNIQUE(post_id, user_id)
```

#### `follows`
```sql
- id (UUID, PK)
- follower_id (UUID, FK → profiles)
- following_id (UUID, FK → profiles)
- created_at (TIMESTAMP)
- UNIQUE(follower_id, following_id)
```

#### `notifications`
```sql
- id (UUID, PK)
- user_id (UUID, FK → profiles)
- type (TEXT: 'like'|'comment'|'follow'|'mention')
- content (TEXT)
- read (BOOLEAN)
- sender_id (UUID, FK → profiles, nullable)
- post_id (UUID, FK → posts, nullable)
- created_at (TIMESTAMP)
```

## 🔐 Seguridad (RLS)

### Row Level Security

Todas las tablas tienen RLS habilitado con políticas específicas:

#### Perfiles
- ✅ Lectura pública de todos los perfiles
- ✅ Solo el usuario puede actualizar su perfil
- ✅ Solo el usuario puede crear su perfil

#### Mascotas
- ✅ Lectura pública de todas las mascotas
- ✅ Solo el dueño puede modificar su mascota
- ✅ Solo el dueño puede eliminar su mascota

#### Publicaciones
- ✅ Lectura pública de todas las publicaciones
- ✅ Usuarios autenticados pueden crear posts
- ✅ Solo el autor puede modificar/eliminar sus posts

#### Comentarios y Likes
- ✅ Lectura pública
- ✅ Usuarios autenticados pueden crear
- ✅ Solo el autor puede eliminar

### Storage Security

```sql
-- Lectura pública de todos los buckets
-- Solo usuarios autenticados pueden subir
-- Solo el dueño puede eliminar sus archivos
```

## 🎨 Paleta de Colores

```css
/* Colores Primarios */
--primary: #C4A57B (Beige/Tierra)
--secondary: #8B7355 (Marrón)
--accent: #D4A574 (Dorado)

/* Colores de Estado */
--destructive: #DC2626 (Rojo para errores/lost)
--success: #16A34A (Verde para éxito)

/* Colores de Fondo */
--background: #FAFAF9 (Blanco cálido)
--card: #FFFFFF (Blanco)
--muted: #F5F5F4 (Gris claro)
```

## 🔄 Flujo de Datos

### 1. Autenticación
```
Usuario → Formulario → useAuth.signUp/signIn 
       → Supabase Auth → Session creada 
       → Edge Function crea profile 
       → Estado global actualizado
```

### 2. Subida de Imágenes
```
Usuario → Selector de archivo → useStorage.upload
       → Validación (tipo, tamaño)
       → Supabase Storage
       → URL pública retornada
       → Guardada en base de datos
```

### 3. Crear Publicación
```
Usuario → Formulario → (Opcional) subir imagen
       → useStorage.upload → URL
       → usePosts.createPost
       → Supabase Database
       → Feed actualizado localmente
```

### 4. Likes y Comentarios
```
Usuario → Click → usePosts.toggleLike/addComment
       → Supabase Database
       → Estado local actualizado (optimistic UI)
```

## 📊 Optimizaciones

### Índices de Base de Datos
```sql
-- Índices para mejorar rendimiento
idx_posts_author      → posts(author_id)
idx_posts_created     → posts(created_at DESC)
idx_comments_post     → comments(post_id)
idx_likes_post        → likes(post_id)
idx_likes_user        → likes(user_id)
idx_follows_follower  → follows(follower_id)
idx_follows_following → follows(following_id)
idx_notifications_user → notifications(user_id)
idx_pets_owner        → pets(owner_id)
```

### Caché y Rendimiento
- ✅ Estado local reactivo con hooks
- ✅ Actualización optimista de UI
- ✅ Caché de sesión de Supabase
- ✅ Compresión de imágenes (cliente)
- ✅ Lazy loading de imágenes

## 🚀 Próximas Mejoras

### Funcionalidades Planificadas
- [ ] Sistema de chat en tiempo real
- [ ] Notificaciones push
- [ ] Geolocalización para lost/found
- [ ] Búsqueda y filtros avanzados
- [ ] Sistema de recompensas/gamificación
- [ ] Integración con servicios veterinarios
- [ ] Exportación de datos QR mejorada
- [ ] Modo oscuro
- [ ] PWA (Progressive Web App)
- [ ] Compartir en redes sociales

### Optimizaciones Técnicas
- [ ] Paginación infinita en feed
- [ ] Compresión de imágenes en servidor
- [ ] CDN para assets estáticos
- [ ] Caché de datos con React Query
- [ ] Tests unitarios y e2e
- [ ] CI/CD pipeline
- [ ] Monitoreo y analytics

---

**Arquitectura diseñada para:**
- ✅ Escalabilidad
- ✅ Mantenibilidad
- ✅ Seguridad
- ✅ Rendimiento
- ✅ Experiencia de usuario

🎯 **Objetivo:** Sistema robusto y profesional listo para presentación CORFO y uso real.
