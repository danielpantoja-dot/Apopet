# 🚀 Guía de Configuración - Sistema de Perfiles de Mascotas

## 📋 Requisitos Previos

1. Proyecto de Supabase creado (ya conectado a Figma Make)
2. Las variables de entorno están configuradas automáticamente

## 🗄️ Configuración de Base de Datos

### 1. Ejecutar Scripts SQL

En tu panel de Supabase, ve a **SQL Editor** y ejecuta los siguientes scripts en orden:

#### Script 1: Crear Tablas

```sql
-- Tabla de Perfiles de Usuario
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  location TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Mascotas
CREATE TABLE IF NOT EXISTS pets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  breed TEXT NOT NULL,
  age TEXT,
  weight TEXT,
  color TEXT,
  personality TEXT[] DEFAULT '{}',
  favorite_food TEXT,
  favorite_toys TEXT[] DEFAULT '{}',
  vaccinated BOOLEAN DEFAULT false,
  microchip TEXT,
  image_url TEXT,
  likes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Publicaciones
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pet_id UUID REFERENCES pets(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  type TEXT DEFAULT 'normal' CHECK (type IN ('normal', 'lost', 'found')),
  pet_info JSONB,
  likes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Comentarios
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Likes
CREATE TABLE IF NOT EXISTS likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Tabla de Seguidores
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- Tabla de Notificaciones
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'follow', 'mention')),
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Script 2: Crear Índices

```sql
-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_post ON likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_user ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_pets_owner ON pets(owner_id);
```

#### Script 3: Políticas RLS (Row Level Security)

```sql
-- Habilitar RLS en todas las tablas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Políticas para Profiles
CREATE POLICY "Perfiles públicos - lectura" ON profiles FOR SELECT USING (true);
CREATE POLICY "Usuarios pueden actualizar su perfil" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Usuarios pueden insertar su perfil" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Políticas para Pets
CREATE POLICY "Mascotas públicas - lectura" ON pets FOR SELECT USING (true);
CREATE POLICY "Dueños pueden actualizar su mascota" ON pets FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Dueños pueden insertar su mascota" ON pets FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Dueños pueden eliminar su mascota" ON pets FOR DELETE USING (auth.uid() = owner_id);

-- Políticas para Posts
CREATE POLICY "Publicaciones públicas - lectura" ON posts FOR SELECT USING (true);
CREATE POLICY "Usuarios autenticados pueden crear posts" ON posts FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Autores pueden actualizar sus posts" ON posts FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Autores pueden eliminar sus posts" ON posts FOR DELETE USING (auth.uid() = author_id);

-- Políticas para Comments
CREATE POLICY "Comentarios públicos - lectura" ON comments FOR SELECT USING (true);
CREATE POLICY "Usuarios autenticados pueden comentar" ON comments FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Autores pueden eliminar sus comentarios" ON comments FOR DELETE USING (auth.uid() = author_id);

-- Políticas para Likes
CREATE POLICY "Likes públicos - lectura" ON likes FOR SELECT USING (true);
CREATE POLICY "Usuarios autenticados pueden dar like" ON likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuarios pueden quitar sus likes" ON likes FOR DELETE USING (auth.uid() = user_id);

-- Políticas para Follows
CREATE POLICY "Seguidores públicos - lectura" ON follows FOR SELECT USING (true);
CREATE POLICY "Usuarios pueden seguir" ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Usuarios pueden dejar de seguir" ON follows FOR DELETE USING (auth.uid() = follower_id);

-- Políticas para Notifications
CREATE POLICY "Usuarios ven sus notificaciones" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Sistema puede crear notificaciones" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Usuarios pueden marcar como leídas" ON notifications FOR UPDATE USING (auth.uid() = user_id);
```

#### Script 4: Funciones y Triggers

```sql
-- Función para actualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_pets_updated_at BEFORE UPDATE ON pets
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Función para crear perfil automáticamente al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, phone, location)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Usuario'),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'location', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear perfil al registrarse
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### 2. Configurar Storage

En tu panel de Supabase, ve a **Storage** y crea los siguientes buckets:

1. **avatars**
   - Público: ✅ Sí
   - Tipos de archivo permitidos: `image/*`
   - Tamaño máximo: 5MB

2. **pet-images**
   - Público: ✅ Sí
   - Tipos de archivo permitidos: `image/*`
   - Tamaño máximo: 5MB

3. **post-images**
   - Público: ✅ Sí
   - Tipos de archivo permitidos: `image/*`
   - Tamaño máximo: 5MB

#### Políticas de Storage

Para cada bucket, añade estas políticas:

```sql
-- Política de lectura pública
CREATE POLICY "Lectura pública" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Lectura pública" ON storage.objects FOR SELECT USING (bucket_id = 'pet-images');
CREATE POLICY "Lectura pública" ON storage.objects FOR SELECT USING (bucket_id = 'post-images');

-- Política de subida autenticada
CREATE POLICY "Usuarios autenticados pueden subir" ON storage.objects 
FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "Usuarios autenticados pueden subir" ON storage.objects 
FOR INSERT WITH CHECK (bucket_id = 'pet-images' AND auth.role() = 'authenticated');

CREATE POLICY "Usuarios autenticados pueden subir" ON storage.objects 
FOR INSERT WITH CHECK (bucket_id = 'post-images' AND auth.role() = 'authenticated');

-- Política de eliminación (solo dueños)
CREATE POLICY "Usuarios pueden eliminar sus archivos" ON storage.objects 
FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Usuarios pueden eliminar sus archivos" ON storage.objects 
FOR DELETE USING (bucket_id = 'pet-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Usuarios pueden eliminar sus archivos" ON storage.objects 
FOR DELETE USING (bucket_id = 'post-images' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## ✅ Verificación

Para verificar que todo está configurado correctamente:

1. **Verificar Tablas**: En SQL Editor ejecuta:
   ```sql
   SELECT tablename FROM pg_tables WHERE schemaname = 'public';
   ```

2. **Verificar Políticas RLS**: Ejecuta:
   ```sql
   SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public';
   ```

3. **Verificar Storage**: Ve a Storage y confirma que los 3 buckets existen.

## 🎯 Arquitectura de la Aplicación

### Estructura de Carpetas

```
├── /lib
│   ├── /supabase
│   │   └── storage.ts         # Funciones para subir/eliminar imágenes
│   └── types.ts               # Tipos TypeScript
├── /hooks
│   ├── use-auth.ts            # Hook de autenticación
│   ├── use-storage.ts         # Hook para manejo de archivos
│   ├── use-posts.ts           # Hook para publicaciones
│   └── use-profile.ts         # Hook para perfiles
├── /components
│   ├── auth-modal.tsx         # Modal de autenticación (mejorado)
│   ├── create-post.tsx        # Crear publicaciones (mejorado)
│   ├── edit-pet-profile.tsx   # Editar perfil mascota (mejorado)
│   └── ...
└── /utils/supabase
    └── client.tsx             # Cliente de Supabase
```

### Nuevas Funcionalidades

✅ **Sistema de Autenticación Real**
- Registro con email/contraseña
- Login persistente
- Logout
- Subida de avatar en registro

✅ **Sistema de Storage**
- Subida de avatares de usuario
- Subida de fotos de mascotas
- Subida de imágenes en publicaciones
- Vista previa antes de subir
- Validación de tamaño (5MB max)

✅ **Hooks Personalizados**
- `useAuth`: Gestión de sesión y autenticación
- `useStorage`: Subida y eliminación de archivos
- `usePosts`: CRUD de publicaciones
- `useProfile`: Gestión de perfiles y mascotas

✅ **Mejoras en Componentes**
- Avatar con subida real en `auth-modal.tsx`
- Subida de imágenes en `create-post.tsx`
- Editor de fotos de mascota en `edit-pet-profile.tsx`

## 🔐 Seguridad

- ✅ Row Level Security (RLS) habilitado en todas las tablas
- ✅ Políticas de acceso granulares
- ✅ Los usuarios solo pueden modificar sus propios datos
- ✅ Validación de tipos de archivo
- ✅ Límites de tamaño de archivo

## 🚀 Próximos Pasos

1. **Configurar Email** (opcional): En Authentication > Email Templates
2. **Personalizar Auth**: En Authentication > Settings
3. **Monitoreo**: Usar Dashboard de Supabase para monitorear uso
4. **Backup**: Configurar backups automáticos en Settings > Database

## 📝 Notas Importantes

- Las credenciales de Supabase ya están configuradas en el entorno de Figma Make
- No es necesario crear archivos `.env` manualmente
- La aplicación usa la autenticación de Supabase integrada con los edge functions existentes
- Los buckets de Storage deben ser públicos para mostrar las imágenes

## 🆘 Solución de Problemas

### Error: "relation does not exist"
- Verifica que ejecutaste todos los scripts SQL en orden

### Las imágenes no se muestran
- Verifica que los buckets de Storage sean públicos
- Verifica las políticas de Storage

### Error de autenticación
- Verifica que las políticas RLS estén correctamente configuradas
- Revisa los logs en Supabase Dashboard

---

**¡Configuración completa!** 🎉 

La aplicación ahora tiene un sistema completo de backend con Supabase, incluyendo autenticación real, storage de imágenes, y base de datos relacional con seguridad RLS.
