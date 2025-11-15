-- ========================================
-- TRIGGERS PARA NOTIFICACIONES AUTOMÁTICAS
-- Sistema de notificaciones en tiempo real
-- ========================================

-- 1. TRIGGER PARA CREAR NOTIFICACIÓN AL DAR LIKE A UN POST
-- ========================================
CREATE OR REPLACE FUNCTION create_like_notification()
RETURNS TRIGGER AS $$
DECLARE
  post_author_id UUID;
  liker_name TEXT;
BEGIN
  -- Obtener el ID del autor del post
  SELECT author_id INTO post_author_id
  FROM posts
  WHERE id = NEW.post_id;

  -- No crear notificación si el usuario da like a su propio post
  IF post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Obtener el nombre del usuario que dio like
  SELECT name INTO liker_name
  FROM profiles
  WHERE id = NEW.user_id;

  -- Crear la notificación
  INSERT INTO notifications (user_id, type, content, sender_id, post_id, read)
  VALUES (
    post_author_id,
    'like',
    'le dio me gusta a tu publicación',
    NEW.user_id,
    NEW.post_id,
    false
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
DROP TRIGGER IF EXISTS trigger_like_notification ON likes;
CREATE TRIGGER trigger_like_notification
  AFTER INSERT ON likes
  FOR EACH ROW
  EXECUTE FUNCTION create_like_notification();


-- 2. TRIGGER PARA CREAR NOTIFICACIÓN AL COMENTAR UN POST
-- ========================================
CREATE OR REPLACE FUNCTION create_comment_notification()
RETURNS TRIGGER AS $$
DECLARE
  post_author_id UUID;
  commenter_name TEXT;
  comment_preview TEXT;
BEGIN
  -- Obtener el ID del autor del post
  SELECT author_id INTO post_author_id
  FROM posts
  WHERE id = NEW.post_id;

  -- No crear notificación si el usuario comenta su propio post
  IF post_author_id = NEW.author_id THEN
    RETURN NEW;
  END IF;

  -- Obtener el nombre del usuario que comentó
  SELECT name INTO commenter_name
  FROM profiles
  WHERE id = NEW.author_id;

  -- Crear preview del comentario (primeros 50 caracteres)
  comment_preview := LEFT(NEW.content, 50);
  IF LENGTH(NEW.content) > 50 THEN
    comment_preview := comment_preview || '...';
  END IF;

  -- Crear la notificación
  INSERT INTO notifications (user_id, type, content, sender_id, post_id, read)
  VALUES (
    post_author_id,
    'comment',
    'comentó: "' || comment_preview || '"',
    NEW.author_id,
    NEW.post_id,
    false
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
DROP TRIGGER IF EXISTS trigger_comment_notification ON comments;
CREATE TRIGGER trigger_comment_notification
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION create_comment_notification();


-- 3. TRIGGER PARA CREAR NOTIFICACIÓN AL SEGUIR A ALGUIEN
-- ========================================
CREATE OR REPLACE FUNCTION create_follow_notification()
RETURNS TRIGGER AS $$
DECLARE
  follower_name TEXT;
BEGIN
  -- Obtener el nombre del seguidor
  SELECT name INTO follower_name
  FROM profiles
  WHERE id = NEW.follower_id;

  -- Crear la notificación
  INSERT INTO notifications (user_id, type, content, sender_id, read)
  VALUES (
    NEW.following_id,
    'follow',
    'comenzó a seguir tu perfil',
    NEW.follower_id,
    false
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
DROP TRIGGER IF EXISTS trigger_follow_notification ON follows;
CREATE TRIGGER trigger_follow_notification
  AFTER INSERT ON follows
  FOR EACH ROW
  EXECUTE FUNCTION create_follow_notification();


-- ========================================
-- INSTRUCCIONES DE USO
-- ========================================
-- 1. Ejecuta este script completo en el SQL Editor de Supabase
-- 2. Los triggers se activarán automáticamente cuando:
--    - Un usuario dé like a un post
--    - Un usuario comente en un post
--    - Un usuario siga a otro usuario
-- 3. Las notificaciones se crearán automáticamente en tiempo real
-- 4. El hook use-notifications.ts escuchará estos cambios vía suscripción
-- ========================================

-- VERIFICACIÓN DE TRIGGERS
-- Ejecuta esta query para verificar que los triggers fueron creados:
SELECT 
  trigger_name, 
  event_object_table, 
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN ('likes', 'comments', 'follows')
ORDER BY event_object_table, trigger_name;
