import 'package:flutter/material.dart';
import '../main.dart';
import 'login_supabase_screen.dart';

enum _AdminMenu { empresas, usuarios }

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  // Estado general
  bool _isLoading = true;
  _AdminMenu _selectedMenu = _AdminMenu.empresas;

  // Empresas (tenants)
  List<Map<String, dynamic>> _tenants = [];
  List<Map<String, dynamic>> _tenantsStats = [];
  String _filtro = 'TODOS'; // TODOS, ACTIVOS, INACTIVOS

  // Usuarios por empresa
  List<Map<String, dynamic>> _usuarios = [];
  String? _selectedTenantIdForUsers;
  bool _loadingUsuarios = false;

  @override
  void initState() {
    super.initState();
    _cargarTenants();
  }

  Future<void> _cargarTenants() async {
    setState(() => _isLoading = true);
    try {
      final tenantsData = await supabase
          .from('tenants')
          .select('*')
          .order('fecha_creacion', ascending: false);

      final statsData = await supabase.from('tenant_stats').select('*');

      setState(() {
        _tenants = List<Map<String, dynamic>>.from(tenantsData);
        _tenantsStats = List<Map<String, dynamic>>.from(statsData);
        _isLoading = false;
        // Preseleccionar primer tenant para la sección Usuarios
        if (_tenants.isNotEmpty && _selectedTenantIdForUsers == null) {
          _selectedTenantIdForUsers = _tenants.first['id'];
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar empresas: $e');
    }
  }

  Future<void> _cargarUsuarios([String? tenantId]) async {
    final String? id = tenantId ?? _selectedTenantIdForUsers;
    if (id == null) return;

    setState(() {
      _loadingUsuarios = true;
      _usuarios = [];
    });

    try {
      final data = await supabase
          .from('usuarios')
          .select('auth_id, email, nombre, rol, tenant_id')
          .eq('tenant_id', id)
          .order('nombre', ascending: true);
      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(data);
        _loadingUsuarios = false;
      });
    } catch (e) {
      setState(() => _loadingUsuarios = false);
      _mostrarMensaje('Error al cargar usuarios: $e');
    }
  }

  List<Map<String, dynamic>> get _tenantsFiltrados {
    if (_filtro == 'ACTIVOS') {
      return _tenants.where((t) => t['activo'] == true).toList();
    } else if (_filtro == 'INACTIVOS') {
      return _tenants.where((t) => t['activo'] == false).toList();
    }
    return _tenants;
  }

  Map<String, dynamic>? _getStats(String tenantId) {
    try {
      return _tenantsStats.firstWhere((s) => s['id'] == tenantId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _selectedMenu == _AdminMenu.empresas
                            ? _buildEmpresasContent()
                            : _buildUsuariosContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sidebar izquierdo
  Widget _buildSidebar() {
    return Container(
      width: 240,
      height: double.infinity,
      color: const Color(0xFF37474F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF37474F),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white),
                SizedBox(width: 8),
                Text('Super Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _buildSidebarItem(
            icon: Icons.business,
            label: 'Empresas',
            selected: _selectedMenu == _AdminMenu.empresas,
            onTap: () => setState(() => _selectedMenu = _AdminMenu.empresas),
          ),
          _buildSidebarItem(
            icon: Icons.people_alt,
            label: 'Usuarios',
            selected: _selectedMenu == _AdminMenu.usuarios,
            onTap: () {
              setState(() => _selectedMenu = _AdminMenu.usuarios);
              _cargarUsuarios();
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF455A64) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // Barra superior
  Widget _buildTopBar() {
    return Container(
      height: 56,
      width: double.infinity,
      color: const Color(0xFF37474F),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            _selectedMenu == _AdminMenu.empresas ? 'Empresas' : 'Usuarios',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: _cargarTenants,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  // Contenido - Empresas
  Widget _buildEmpresasContent() {
    final totalTenants = _tenants.length;
    final activos = _tenants.where((t) => t['activo'] == true).length;
    final inactivos = totalTenants - activos;

    return Column(
      children: [
        // Resumen
        Container(
          color: const Color(0xFFF5F5F5),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildStatCard('Total Empresas', totalTenants.toString(), const Color(0xFF1976D2)),
              const SizedBox(width: 12),
              _buildStatCard('Activas', activos.toString(), const Color(0xFF4CAF50)),
              const SizedBox(width: 12),
              _buildStatCard('Inactivas', inactivos.toString(), const Color(0xFFDC2626)),
              const Spacer(),
              _buildFiltros(),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoCrearTenant,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Empresa'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        // Lista
        Expanded(child: _buildTenantsList()),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 150,
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Row(
      children: [
        const Text('Filtrar:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Todos'),
          selected: _filtro == 'TODOS',
          onSelected: (s) => setState(() => _filtro = 'TODOS'),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Activos'),
          selected: _filtro == 'ACTIVOS',
          selectedColor: const Color(0xFF4CAF50).withOpacity(0.25),
          onSelected: (s) => setState(() => _filtro = 'ACTIVOS'),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Inactivos'),
          selected: _filtro == 'INACTIVOS',
          selectedColor: const Color(0xFFDC2626).withOpacity(0.25),
          onSelected: (s) => setState(() => _filtro = 'INACTIVOS'),
        ),
      ],
    );
  }

  Widget _buildTenantsList() {
    if (_tenantsFiltrados.isEmpty) {
      return const Center(child: Text('No hay empresas registradas'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tenantsFiltrados.length,
      itemBuilder: (context, index) {
        final tenant = _tenantsFiltrados[index];
        final stats = _getStats(tenant['id']);
        return _buildTenantCard(tenant, stats);
      },
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant, Map<String, dynamic>? stats) {
    final activo = tenant['activo'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: activo ? const Color(0xFF4CAF50) : const Color(0xFF999999),
          child: tenant['logo_url'] != null && tenant['logo_url'].toString().isNotEmpty
              ? ClipOval(child: Image.network(tenant['logo_url'], width: 40, height: 40, fit: BoxFit.cover))
              : Text(
                  (tenant['nombre'] ?? 'E').toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
        title: Text(tenant['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Slug: ${tenant['slug']} • Plan: ${tenant['plan']?.toString().toUpperCase()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: activo ? const Color(0xFF4CAF50) : const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(activo ? 'ACTIVO' : 'INACTIVO', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, tenant),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Editar')])),
                PopupMenuItem(
                  value: activo ? 'desactivar' : 'activar',
                  child: Row(children: [Icon(activo ? Icons.block : Icons.check_circle), SizedBox(width: 8), Text(activo ? 'Desactivar' : 'Activar')]),
                ),
                const PopupMenuItem(value: 'cambiar_logo', child: Row(children: [Icon(Icons.image), SizedBox(width: 8), Text('Cambiar Logo')])),
                const PopupMenuItem(value: 'ver_detalles', child: Row(children: [Icon(Icons.info), SizedBox(width: 8), Text('Ver Detalles')])),
                const PopupMenuItem(value: 'eliminar', child: Row(children: [Icon(Icons.delete, color: Color(0xFFDC2626)), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Color(0xFFDC2626)))])),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (stats != null)
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _buildMiniStat('Usuarios', stats['total_usuarios']?.toString() ?? '0', Icons.people),
                      _buildMiniStat('Órdenes', stats['total_ordenes']?.toString() ?? '0', Icons.inventory),
                      _buildMiniStat('Activas', stats['ordenes_activas']?.toString() ?? '0', Icons.local_shipping),
                      _buildMiniStat('Entregadas', stats['ordenes_entregadas']?.toString() ?? '0', Icons.check_circle),
                      _buildMiniStat('Emisores', stats['total_emisores']?.toString() ?? '0', Icons.send),
                      _buildMiniStat('Destinatarios', stats['total_destinatarios']?.toString() ?? '0', Icons.location_on),
                    ],
                  )
                else
                  const Text('No hay estadísticas disponibles'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedMenu = _AdminMenu.usuarios;
                      _selectedTenantIdForUsers = tenant['id'];
                    });
                    _cargarUsuarios(tenant['id']);
                  },
                  icon: const Icon(Icons.people_alt),
                  label: const Text('Administrar Usuarios de esta Empresa'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: const Color(0xFF37474F)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }

  // Contenido - Usuarios
  Widget _buildUsuariosContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Empresa:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<String>(
                  value: _selectedTenantIdForUsers,
                  items: _tenants
                      .map((t) => DropdownMenuItem<String>(
                            value: t['id'],
                            child: Text(t['nombre'] ?? 'Empresa'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedTenantIdForUsers = val);
                    _cargarUsuarios(val);
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Seleccionar empresa'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _cargarUsuarios(),
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingUsuarios
              ? const Center(child: CircularProgressIndicator())
              : _usuarios.isEmpty
                  ? const Center(child: Text('No hay usuarios en esta empresa'))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Nombre')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Rol')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: _usuarios.map((u) => _buildUsuarioRow(u)).toList(),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  DataRow _buildUsuarioRow(Map<String, dynamic> u) {
    return DataRow(cells: [
      DataCell(Text(u['nombre']?.toString() ?? '-')),
      DataCell(Text(u['email']?.toString() ?? '-')),
      DataCell(Text(u['rol']?.toString() ?? '-')),
      DataCell(Row(
        children: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit, color: Color(0xFFFF9800)),
            onPressed: () => _mostrarDialogoEditarUsuario(u),
          ),
          IconButton(
            tooltip: 'Resetear contraseña (email)',
            icon: const Icon(Icons.lock_reset, color: Color(0xFF37474F)),
            onPressed: () => _resetearPassword(u['email']),
          ),
          IconButton(
            tooltip: 'Eliminar de esta tabla',
            icon: const Icon(Icons.delete, color: Color(0xFFDC2626)),
            onPressed: () => _eliminarUsuarioTabla(u),
          ),
        ],
      )),
    ]);
  }

  Future<void> _resetearPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      _mostrarMensaje('Se envió un enlace de restablecimiento a $email');
    } catch (e) {
      _mostrarMensaje('Error al solicitar restablecimiento: $e');
    }
  }

  Future<void> _eliminarUsuarioTabla(Map<String, dynamic> u) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Eliminar a ${u['email']} de la tabla usuarios? (No elimina el Auth)') ,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await supabase.from('usuarios').delete().eq('auth_id', u['auth_id']);
      _mostrarMensaje('Usuario eliminado de la tabla');
      _cargarUsuarios();
    } catch (e) {
      _mostrarMensaje('Error al eliminar: $e');
    }
  }

  Future<void> _mostrarDialogoEditarUsuario(Map<String, dynamic> u) async {
    final nombreCtrl = TextEditingController(text: u['nombre'] ?? '');
    String rolSel = (u['rol']?.toString() ?? 'ADMINISTRADOR').toUpperCase();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) => AlertDialog(
          title: Text('Editar ${u['email']}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: rolSel,
                  items: const [
                    DropdownMenuItem(value: 'ADMINISTRADOR', child: Text('ADMINISTRADOR')),
                    DropdownMenuItem(value: 'REPARTIDOR', child: Text('REPARTIDOR')),
                  ],
                  onChanged: (v) => setStateSB(() => rolSel = v ?? 'ADMINISTRADOR'),
                  decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await supabase.from('usuarios').update({
                    'nombre': nombreCtrl.text.trim(),
                    'rol': rolSel,
                  }).eq('auth_id', u['auth_id']);

                  if (mounted) Navigator.pop(ctx);
                  _mostrarMensaje('Usuario actualizado');
                  _cargarUsuarios();
                } catch (e) {
                  _mostrarMensaje('Error: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // Acciones empresas existentes (reutilizadas)
  void _handleMenuAction(String action, Map<String, dynamic> tenant) {
    switch (action) {
      case 'editar':
        _mostrarDialogoEditarTenant(tenant);
        break;
      case 'activar':
      case 'desactivar':
        _toggleActivarTenant(tenant);
        break;
      case 'cambiar_logo':
        _mostrarDialogoCambiarLogo(tenant);
        break;
      case 'ver_detalles':
        _mostrarDetallesTenant(tenant);
        break;
      case 'eliminar':
        _confirmarEliminarTenant(tenant);
        break;
    }
  }

  // ============= Código existente adaptado (crear/editar tenants, logout, utilidades) =============
  Future<void> _mostrarDialogoCrearTenant() async {
    final nombreCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final logoUrlCtrl = TextEditingController();
    final notasCtrl = TextEditingController();
    String planSeleccionado = 'basico';

    nombreCtrl.addListener(() {
      final slug = nombreCtrl.text
          .toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^a-z0-9-]'), '');
      slugCtrl.text = slug;
    });

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) => AlertDialog(
          title: const Text('Crear Nueva Empresa'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                    controller: slugCtrl,
                    decoration: const InputDecoration(labelText: 'Slug *', helperText: 'Ej: mi-empresa', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: planSeleccionado,
                    items: const [
                      DropdownMenuItem(value: 'basico', child: Text('Básico')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium')),
                      DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
                    ],
                    onChanged: (v) => setStateSB(() => planSeleccionado = v ?? 'basico'),
                    decoration: const InputDecoration(labelText: 'Plan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: logoUrlCtrl, decoration: const InputDecoration(labelText: 'URL del Logo', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: notasCtrl, decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()), maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty || slugCtrl.text.trim().isEmpty) {
                  _mostrarMensaje('Nombre y Slug son obligatorios');
                  return;
                }
                try {
                  await supabase.from('tenants').insert({
                    'nombre': nombreCtrl.text.trim(),
                    'slug': slugCtrl.text.trim(),
                    'email_contacto': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                    'logo_url': logoUrlCtrl.text.trim().isEmpty ? null : logoUrlCtrl.text.trim(),
                    'plan': planSeleccionado,
                    'activo': true,
                    'notas': notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                  });
                  if (mounted) Navigator.pop(ctx);
                  _mostrarMensaje('Empresa creada exitosamente');
                  _cargarTenants();
                } catch (e) {
                  _mostrarMensaje('Error al crear empresa: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
              child: const Text('Crear Empresa'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoEditarTenant(Map<String, dynamic> tenant) async {
    final nombreCtrl = TextEditingController(text: tenant['nombre']);
    final emailCtrl = TextEditingController(text: tenant['email_contacto'] ?? '');
    final telefonoCtrl = TextEditingController(text: tenant['telefono'] ?? '');
    final logoUrlCtrl = TextEditingController(text: tenant['logo_url'] ?? '');
    final notasCtrl = TextEditingController(text: tenant['notas'] ?? '');
    String planSeleccionado = tenant['plan'] ?? 'basico';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) => AlertDialog(
          title: Text('Editar: ${tenant['nombre']}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: planSeleccionado,
                    items: const [
                      DropdownMenuItem(value: 'basico', child: Text('Básico')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium')),
                      DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
                    ],
                    onChanged: (v) => setStateSB(() => planSeleccionado = v ?? 'basico'),
                    decoration: const InputDecoration(labelText: 'Plan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: logoUrlCtrl, decoration: const InputDecoration(labelText: 'URL del Logo', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: notasCtrl, decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()), maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await supabase.from('tenants').update({
                    'nombre': nombreCtrl.text.trim(),
                    'email_contacto': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                    'plan': planSeleccionado,
                    'logo_url': logoUrlCtrl.text.trim().isEmpty ? null : logoUrlCtrl.text.trim(),
                    'notas': notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                  }).eq('id', tenant['id']);
                  if (mounted) Navigator.pop(ctx);
                  _mostrarMensaje('Empresa actualizada');
                  _cargarTenants();
                } catch (e) {
                  _mostrarMensaje('Error: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white),
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActivarTenant(Map<String, dynamic> tenant) async {
    final nuevoEstado = !(tenant['activo'] ?? false);
    try {
      await supabase.from('tenants').update({'activo': nuevoEstado}).eq('id', tenant['id']);
      _mostrarMensaje('Empresa ${nuevoEstado ? 'activada' : 'desactivada'}');
      _cargarTenants();
    } catch (e) {
      _mostrarMensaje('Error: $e');
    }
  }

  Future<void> _mostrarDialogoCambiarLogo(Map<String, dynamic> tenant) async {
    final logoUrlCtrl = TextEditingController(text: tenant['logo_url'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar Logo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: logoUrlCtrl, decoration: const InputDecoration(labelText: 'URL del Logo', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            if (logoUrlCtrl.text.isNotEmpty)
              Image.network(logoUrlCtrl.text, height: 100, errorBuilder: (c, e, s) => const Text('No se pudo cargar la imagen')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase.from('tenants').update({'logo_url': logoUrlCtrl.text.trim().isEmpty ? null : logoUrlCtrl.text.trim()}).eq('id', tenant['id']);
                if (mounted) Navigator.pop(ctx);
                _mostrarMensaje('Logo actualizado');
                _cargarTenants();
              } catch (e) {
                _mostrarMensaje('Error: $e');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesTenant(Map<String, dynamic> tenant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tenant['nombre']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${tenant['id']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              const Divider(),
              Text('Slug: ${tenant['slug']}'),
              Text('Email: ${tenant['email_contacto'] ?? 'N/A'}'),
              Text('Teléfono: ${tenant['telefono'] ?? 'N/A'}'),
              Text('Plan: ${tenant['plan']}'),
              Text('Estado: ${tenant['activo'] == true ? 'ACTIVO' : 'INACTIVO'}'),
              const Divider(),
              if ((tenant['notas'] ?? '').toString().isNotEmpty) Text('Notas: ${tenant['notas']}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminarTenant(Map<String, dynamic> tenant) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Confirmar Eliminación'),
        content: Text(
          '¿Eliminar la empresa "${tenant['nombre']}"?\n\n'
          'Esto eliminará Usuarios, Órdenes, Emisores, Destinatarios y Conversaciones asociadas.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Eliminar Permanentemente'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await supabase.from('tenants').delete().eq('id', tenant['id']);
      _mostrarMensaje('Empresa eliminada');
      _cargarTenants();
    } catch (e) {
      _mostrarMensaje('Error al eliminar: $e');
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Cierre de Sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), 
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión')
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      print('🚪 Cerrando sesión desde Super-Admin...');
      await supabase.auth.signOut();
      print('✅ Sesión cerrada, navegando...');
      
      if (!mounted) return;
      
      // Usar Navigator con popUntil primero
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // Luego reemplazar con login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginSupabaseScreen(),
        ),
      );
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      if (mounted) {
        _mostrarMensaje('Error al cerrar sesión: $e');
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }
}

