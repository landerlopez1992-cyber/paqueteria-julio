-- =====================================================
-- VERIFICAR TABLAS EXISTENTES
-- =====================================================

-- Ver todas las tablas en el esquema public
SELECT 
  schemaname,
  tablename,
  tableowner
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verificar si existen las tablas que necesitamos
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'usuarios' AND table_schema = 'public') 
    THEN '✅ usuarios' 
    ELSE '❌ usuarios' 
  END as usuarios,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ordenes' AND table_schema = 'public') 
    THEN '✅ ordenes' 
    ELSE '❌ ordenes' 
  END as ordenes,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emisores' AND table_schema = 'public') 
    THEN '✅ emisores' 
    ELSE '❌ emisores' 
  END as emisores,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'destinatarios' AND table_schema = 'public') 
    THEN '✅ destinatarios' 
    ELSE '❌ destinatarios' 
  END as destinatarios,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'repartidores' AND table_schema = 'public') 
    THEN '✅ repartidores' 
    ELSE '❌ repartidores' 
  END as repartidores,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chat_conversaciones' AND table_schema = 'public') 
    THEN '✅ chat_conversaciones' 
    ELSE '❌ chat_conversaciones' 
  END as chat_conversaciones,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chat_mensajes' AND table_schema = 'public') 
    THEN '✅ chat_mensajes' 
    ELSE '❌ chat_mensajes' 
  END as chat_mensajes;
