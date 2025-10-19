// Configuración de Supabase para J Alvarez Express SVC
class SupabaseConfig {
  // Project URL
  static const String supabaseUrl = 'https://fbbvfzeyhhopdwzsooew.supabase.co';
  
  // Anon Key (pública)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZiYnZmemV5aGhvcGR3enNvb2V3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3MTIyMDAsImV4cCI6MjA3NjI4ODIwMH0.EWjNVwscWi3gbz01RYaUjlCsGJddgbjUoO_qaqGmffg';
  
  // Service Role Key (secreta - NO usar en el cliente)
  // Esta key solo debe usarse en el backend/servidor
  static const String supabaseServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZiYnZmemV5aGhvcGR3enNvb2V3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDcxMjIwMCwiZXhwIjoyMDc2Mjg4MjAwfQ.MPTGcHJiorsCIk619KIfjphfdgZC3Fq5fHPpZwluhFw';
}
